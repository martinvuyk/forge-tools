# ===----------------------------------------------------------------------=== #
# Copyright (c) 2024, Martin Vuyk Loperena
#
# Licensed under the Apache License v2.0 with LLVM Exceptions:
# https://llvm.org/LICENSE.txt
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ===----------------------------------------------------------------------=== #
"""Defines Quaternion and DualQuaternion."""

from math import sqrt, sin, asin, cos, acos, exp, log


# ===----------------------------------------------------------------------===#
# Quaternion
# ===----------------------------------------------------------------------===#


@register_passable("trivial")
struct Quaternion[T: DType = DType.float64]:
    """Quaternion, a structure often used to represent rotations.
    Allocated on the stack with very efficient vectorized operations.

    Parameters:
        T: The type of the elements in the Quaternion, must be a
            floating point type.
    """

    alias _vec_type = SIMD[T, 4]
    alias _scalar_type = Scalar[T]
    var vec: Self._vec_type
    """The underlying SIMD vector."""

    fn __init__(
        inout self,
        w: Self._scalar_type = 1,
        i: Self._scalar_type = 0,
        j: Self._scalar_type = 0,
        k: Self._scalar_type = 0,
    ):
        """Construct a Quaternion from a real and an imaginary vector part.

        Args:
            w: Real part.
            i: Imaginary i, equivalent to vector part x.
            j: Imaginary j, equivalent to vector part y.
            k: Imaginary k, equivalent to vector part z.
        """

        alias msg = "Quaternions can only be expressed with floating point types"
        constrained[T.is_floating_point(), msg=msg]()
        self.vec = Self._vec_type(w, i, j, k)

    fn __init__(inout self, vec: Self._vec_type):
        """Construct a Quaternion from a SIMD vector.

        Args:
            vec: A SIMD vector representing the Quaternion.
        """

        alias msg = "Quaternions can only be expressed with floating point types"
        constrained[T.is_floating_point(), msg=msg]()
        self.vec = vec

    fn __init__(
        inout self,
        *,
        x: Self._scalar_type,
        y: Self._scalar_type,
        z: Self._scalar_type,
        theta: Self._scalar_type,
        is_normalized: Bool = False,
    ):
        """Construct a unit Quaternion from a rotation axis vector and an angle.

        Args:
            x: Vector part x.
            y: Vector part y.
            z: Vector part z.
            theta: Rotation angle.
            is_normalized: Whether the input vector is normalized.
        """

        alias msg = "Quaternions can only be expressed with floating point types"
        constrained[T.is_floating_point(), msg=msg]()
        vec = Self._vec_type(0, x, y, z)
        if not is_normalized:
            vec = vec / sqrt((vec**2).reduce_add())

        sin_a = sin(theta * 0.5)
        cos_a = cos(theta * 0.5)
        self.vec = vec * sin_a
        self.vec[0] = cos_a
        self.normalize()

    fn __abs__(self) -> Self._scalar_type:
        """Get the magnitude of the Quaternion.

        Returns:
            The magnitude.
        """
        return sqrt((self.vec**2).reduce_add())

    fn normalize(inout self):
        """Normalize the Quaternion."""
        self.vec /= self.__abs__()

    fn normalized(self) -> Self:
        """Get the normalized Quaternion.

        Returns:
            The normalized Quaternion.
        """
        return self.vec / self.__abs__()

    fn __getattr__[name: StringLiteral](self) -> Self._scalar_type:
        """Get the attribute.

        Parameters:
            name: The name of the attribute: {"w", "i", "j", "k"}.

        Returns:
            The attribute value.
        """

        @parameter
        if name == "w":
            return self.vec[0]
        elif name == "i":
            return self.vec[1]
        elif name == "j":
            return self.vec[2]
        elif name == "k":
            return self.vec[3]
        else:
            constrained[False, msg="that attribute isn't defined"]()
            return 0

    fn __add__(self, other: Self) -> Self:
        """Add other to self.

        Args:
            other: The other Quaternion.

        Returns:
            The result.
        """
        return Self(self.vec + other.vec)

    fn __iadd__(inout self, other: Self):
        """Add other to self inplace.

        Args:
            other: The other Quaternion.
        """
        self.vec += other.vec

    fn __sub__(self, other: Self) -> Self:
        """Subtract other from self.

        Args:
            other: The other Quaternion.

        Returns:
            The result.
        """
        return Self(self.vec - other.vec)

    fn __isub__(inout self, other: Self):
        """Subtract other from self inplace.

        Args:
            other: The other Quaternion.
        """
        self.vec -= other.vec

    fn conjugate(self) -> Self:
        """Return the conjugate of the Quaternion.

        Returns:
            The conjugate.
        """
        return Self(self.vec * Self._vec_type(1, -1, -1, -1))

    fn inverse(self, is_normalized: Bool = False) -> Self:
        """Return the inverse of the Quaternion `q^-1`.

        Returns:
            The inverse.
        """

        if is_normalized:
            return self.conjugate()
        qr_1 = self.conjugate()
        return Self(qr_1.vec / ((self.vec**2).reduce_add()))

    fn __invert__(self) -> Self:
        """Return the conjugate of the Quaternion.

        Returns:
            The conjugate.
        """
        return self.conjugate()

    @always_inline("nodebug")
    fn dot(self, other: Self) -> Self._scalar_type:
        """Calculate the dot product of self with other.

        Args:
            other: The other Quaternion.

        Returns:
            The result.
        """
        return (self.vec * other.vec).reduce_add()

    fn __mul__(self, other: Self) -> Self:
        """Calculate the Hamilton product of self with other.

        Args:
            other: The other Quaternion.

        Returns:
            The result.
        """

        alias sign0 = Self._vec_type(1, -1, -1, -1)
        alias sign1 = Self._vec_type(1, 1, 1, -1)
        alias sign2 = Self._vec_type(1, -1, 1, 1)
        alias sign3 = Self._vec_type(1, 1, -1, 1)
        rev = other.vec.shuffle[3, 2, 1, 0]()
        w = self.dot(other.vec * sign0)
        i = self.dot(rev.rotate_right[2]() * sign1)
        j = self.dot(other.vec.rotate_right[2]() * sign2)
        k = self.dot(rev * sign3)
        return Self(w, i, j, k)

    fn __imul__(inout self, other: Self):
        """Calculate the Hamilton product of self with other inplace.

        Args:
            other: The other Quaternion.
        """
        self = self * other

    fn __truediv__(self, other: Self) -> Self:
        """Calculate the division of self with other.

        Args:
            other: The other Quaternion.

        Returns:
            The result.
        """

        return self * other.inverse()

    fn __itruediv__(inout self, other: Self):
        """Calculate the division of self with other inplace.

        Args:
            other: The other Quaternion.
        """
        self = self / other

    fn v(self) -> Self._vec_type:
        """Return the vector part of the Quaternion.

        Returns:
            The vector.
        """
        return self.vec * Self._vec_type(0, 1, 1, 1)

    fn n(self) -> Self._vec_type:
        """Calculate the unit vector n for the vector
        part of the Quaternion. Used for polar decomposition:
        `q = |q| * e**(phi*n) = |q| * (cos(phi) + n * sin(phi))`
        where phi is the angle of the Quaternion.

        Returns:
            The unit vector.
        """
        v = self.v()
        v_magn = sqrt((v**2).reduce_add())
        return v / v_magn

    fn phi(self) -> Self._scalar_type:
        """Calculate the Quaternion angle phi.
        Used for polar decomposition:
        `q = |q| * e**(phi*n) = |q| * (cos(phi) + n * sin(phi))`
        where n is the unit vector of the vector part of the Quaternion.

        Returns:
            The angle.
        """
        return acos(self.w / self.__abs__())

    fn sqrt(self) -> Self:
        """Calculate the square root of the Quaternion.

        Returns:
            The result.
        """

        vec_magn = (self.v() ** 2).reduce_add()
        vec = self.vec * (sqrt((self.__abs__() - self.w) / 2) / vec_magn)
        return Self(sqrt((self.__abs__() + self.w) / 2), vec[1], vec[2], vec[3])

    fn exp(self) -> Self:
        """Calculate `e**Quaternion`.

        Returns:
            The result.
        """
        v = self.v()
        v_magn = sqrt((v**2).reduce_add())
        w = exp(self.w) * cos(v_magn)
        v_new = v * (sin(v_magn) / v_magn)
        return Self(w, v_new[1], v_new[2], v_new[3])

    fn ln(self) -> Self:
        """Calculate the natural logarithm of the Quaternion.

        Returns:
            The result.
        """
        v = self.v()
        v_magn = sqrt((v**2).reduce_add())
        w = log(self.__abs__())
        v_new = v * (acos(self.w / self.__abs__()) / v_magn)
        return Self(w, v_new[1], v_new[2], v_new[3])

    fn __pow__(self, value: Int) -> Self:
        """Raise the Quaternion to the given power.

        Args:
            value: The exponent.

        Returns:
            The result.
        """

        # we could use the self.n() and self.phi() functions
        # for readability but this is more efficient
        v = self.v()
        q_magn = self.__abs__()
        q_norm = self / Self._vec_type(q_magn)
        phi = acos(q_norm.w)
        w = q_magn**value * cos(value * phi)
        v_new = v * ((q_magn ** (value - 1)) / sin(value * phi))
        return Self(w, v_new[1], v_new[2], v_new[3])

    fn __ipow__(inout self, value: Int):
        """Raise the Quaternion to the given power inplace.

        Args:
            value: The exponent.
        """
        self = self**value

    # TODO: need Matrix[T, 3, 3]
    # fn to_matrix(self) -> Matrix[T, 3, 3]:
    #     """Calculate the 3x3 rotation Matrix from the Quaternion.

    #     Returns:
    #         The resulting 3x3 Matrix.
    #     """
    #     vec = (~self).vec
    #     wxyz_x = vec * vec[1]
    #     wxyz_y = vec * vec[2]
    #     wxyz_z = vec * vec[3]
    #     wx = wxyz_x[0]
    #     xx = wxyz_x[1]
    #     yx = wxyz_x[2]
    #     zx = wxyz_x[3]

    #     wy = wxyz_y[0]
    #     xy = wxyz_y[1]
    #     yy = wxyz_y[2]
    #     zy = wxyz_y[3]

    #     wz = wxyz_z[0]
    #     xz = wxyz_z[1]
    #     yz = wxyz_z[2]
    #     zz = wxyz_z[3]

    #     mat = Matrix[T, 3, 3](
    #         1 - 2 * (yy + zz),
    #         2 * (xy + wz),
    #         2 * (zx - wy),
    #         2 * (xy - wz),
    #         1 - 2 * (xx + zz),
    #         2 * (zy + wz),
    #         2 * (zx + wy),
    #         2 * (zy - wz),
    #         1 - 2 * (xx + yy),
    #     )
    #     return mat

    fn __eq__(self, other: Self) -> Bool:
        """Whether self is equal to other.

        Args:
            other: The other Quaternion.

        Returns:
            The result.
        """
        return (self.vec == other.vec).reduce_and()

    fn __str__(self) -> String:
        s = String("[")

        @parameter
        for i in range(8):
            if i > 0:
                s += ", "
            s += str(self.vec[i])

        s += "]"
        return s^


# ===----------------------------------------------------------------------===#
# DualQuaternion
# ===----------------------------------------------------------------------===#


@register_passable("trivial")
struct DualQuaternion[T: DType = DType.float64]:
    """DualQuaternion, a structure nascently used to represent 3D
    transformations and rigid body kinematics. Allocated on the
    stack with very efficient vectorized operations.

    Parameters:
        T: The type of the elements in the DualQuaternion, must be a
            floating point type.
    """

    alias _vec_type = SIMD[T, 8]
    alias _scalar_type = Scalar[T]
    var vec: Self._vec_type
    """The underlying SIMD vector."""

    fn __init__(
        inout self,
        w: Self._scalar_type = 1,
        i: Self._scalar_type = 0,
        j: Self._scalar_type = 0,
        k: Self._scalar_type = 0,
        ew: Self._scalar_type = 0,
        ei: Self._scalar_type = 0,
        ej: Self._scalar_type = 0,
        ek: Self._scalar_type = 0,
    ):
        """Construct a Quaternion from a real, imaginary, and dual
        vector part.

        Args:
            w: Real part.
            i: Imaginary i, equivalent to vector part x.
            j: Imaginary j, equivalent to vector part y.
            k: Imaginary k, equivalent to vector part z.
            ew: Dual Part.
            ei: Dual Imaginary i, equivalent to vector part x.
            ej: Dual Imaginary j, equivalent to vector part y.
            ek: Dual Imaginary k, equivalent to vector part z.
        """

        alias msg = "DualQuaternions can only be expressed with floating point types"
        constrained[T.is_floating_point(), msg=msg]()
        self.vec = Self._vec_type(w, i, j, k, ew, ei, ej, ek)

    fn __init__(inout self, vec: Self._vec_type):
        """Construct a DualQuaternion from a SIMD vector.

        Args:
            vec: The SIMD vector.
        """

        alias msg = "DualQuaternions can only be expressed with floating point types"
        constrained[T.is_floating_point(), msg=msg]()
        self.vec = vec

    fn __init__(
        inout self, rotatational: Quaternion[T], displacement: Quaternion[T]
    ):
        """Construct a DualQuaternion from a set of Quaternions.

        Args:
            rotatational: The rotatational Quaternion.
            displacement: The displacement Quaternion.
        """

        alias msg = "DualQuaternions can only be expressed with floating point types"
        constrained[T.is_floating_point(), msg=msg]()
        self.vec = rotatational.vec.join(rotatational.vec)
        self.vec *= SIMD[T, 4](1, 1, 1, 1).join(displacement.vec)

    fn __init__(inout self, screw_vec: SIMD[T, 8], dual_angle: SIMD[T, 2]):
        """Construct a DualQuaternion from a Screw and a dual angle.

        Args:
            screw_vec: The Screw vectors. It is assumed that 6 of the 8
                dimensions represent the vectors such that:
                `screw_vec = (lx, ly, lz, _, mx, my, mz, _)`, `|l| = 1`.
            dual_angle: The dual angle: `(theta, d)`.
        """

        alias msg = "DualQuaternions can only be expressed with floating point types"
        constrained[T.is_floating_point(), msg=msg]()

        cos_theta_2 = cos(dual_angle[0] * 0.5)
        w = cos_theta_2
        sin_theta_2 = sin(dual_angle[0] * 0.5)
        d_2 = dual_angle[1] * 0.5
        ew = -d_2 * sin_theta_2
        sin_theta_2_vec = SIMD[T, 8](sin_theta_2)
        l_d_cos_vec = screw_vec.slice[4]() * (d_2 * cos_theta_2)
        l_vec = SIMD[T, 8](
            0, 0, 0, ew, l_d_cos_vec[0], l_d_cos_vec[1], l_d_cos_vec[2], w
        )
        sin_vec = screw_vec * sin_theta_2_vec
        self = Self((sin_vec + l_vec).rotate_right[1]())

    fn __getattr__[name: StringLiteral](self) -> Self._scalar_type:
        """Get the attribute.

        Parameters:
            name: The name of the attribute: {"w", "i", "j", "k",
                "ew", "ei", "ej", "ek"}.

        Returns:
            The attribute value.
        """

        @parameter
        if name == "w":
            return self.vec[0]
        elif name == "i":
            return self.vec[1]
        elif name == "j":
            return self.vec[2]
        elif name == "k":
            return self.vec[3]
        elif name == "ew":
            return self.vec[3]
        elif name == "ei":
            return self.vec[3]
        elif name == "ej":
            return self.vec[3]
        elif name == "ek":
            return self.vec[3]
        else:
            constrained[False, msg="that attribute isn't defined"]()
            return 0

    fn __add__(self, other: Self) -> Self:
        """Add other to self.

        Args:
            other: The other DualQuaternion.

        Returns:
            The result.
        """
        return Self(self.vec + other.vec)

    fn __iadd__(inout self, other: Self):
        """Add other to self inplace.

        Args:
            other: The other DualQuaternion.
        """
        self.vec += other.vec

    fn __sub__(self, other: Self) -> Self:
        """Subtract other from self.

        Args:
            other: The other DualQuaternion.

        Returns:
            The result.
        """
        return Self(self.vec - other.vec)

    fn __isub__(inout self, other: Self):
        """Subtract other from self inplace.

        Args:
            other: The other DualQuaternion.
        """
        self.vec -= other.vec

    fn __mul__(self, other: Self) -> Self:
        """Multiply self with other.

        Args:
            other: The other DualQuaternion.

        Returns:
            The result.
        """

        alias Quat = Quaternion[T]
        a = Quat(self.vec.slice[4]())
        b = Quat(self.vec.slice[4, offset=4]())
        c = Quat(other.vec.slice[4]())
        d = Quat(other.vec.slice[4, offset=4]())
        return Self((a * c).vec.join((a * d + b * c).vec))

    fn __imul__(inout self, other: Self):
        """Multiply self with other inplace.

        Args:
            other: The other DualQuaternion.
        """
        self = self * other

    fn conjugate_v(self) -> Self:
        """Return the vector conjugate of the DualQuaternion.
        `self.vec * (1, -1, -1, -1, -1, -1, -1, -1)`.

        Returns:
            The vector conjugate.
        """
        return Self(self.vec * Self._vec_type(1, -1, -1, -1, -1, -1, -1, -1))

    fn __invert__(self) -> Self:
        """Return the vector conjugate of the DualQuaternion.
        `self.vec * (1, -1, -1, -1, -1, -1, -1, -1)`.

        Returns:
            The vector conjugate.
        """
        return self.conjugate_v()

    fn conjugate_d(self) -> Self:
        """Return the dual conjugate of the DualQuaternion.
        `self.vec * (1, 1, 1, 1, -1, -1, -1, -1)`.

        Returns:
            The dual conjugate.
        """
        return Self(self.vec * Self._vec_type(1, 1, 1, 1, -1, -1, -1, -1))

    fn inverse(self) -> Self:
        """Return the inverse of the DualQuaternion `dq^-1`.

        Notes:
            This assumes the rotational quaternion is not zero.

        Returns:
            The inverse.
        """

        qr = Quaternion[T](self.vec.slice[4]()).inverse()
        qd = Quaternion[T](self.vec.slice[4, offset=4]() * -1)
        return Self(qr, qr * (qd * qr))

    fn __abs__(self) -> Self._scalar_type:
        """Get the magnitude of the DualQuaternion.

        Returns:
            The magnitude.
        """
        return sqrt((self.vec**2).reduce_add())

    fn normalize(inout self):
        """Normalize the DualQuaternion."""
        self.vec /= self.__abs__()

    fn normalized(self) -> Self:
        """Get the normalized DualQuaternion.

        Returns:
            The normalized DualQuaternion.
        """
        return self.vec / self.__abs__()

    fn dot(self, other: Self) -> Self._scalar_type:
        """Calculate the dot product of self with other.

        Args:
            other: The other DualQuaternion.

        Returns:
            The result.
        """
        return (self.vec * other.vec).reduce_add()

    fn displace(inout self, *dual_quaternions: Self):
        """Displace the DualQuaternion by a set of DualQuaternions.

        Args:
            dual_quaternions: The DualQuaternions to displace by.
        """
        for i in range(len(dual_quaternions)):
            self *= dual_quaternions[i]

    fn transform(inout self, rotate: Quaternion[T], displace: Quaternion[T]):
        """Transform the DualQuaternion by a set of Quaternions.

        Args:
            rotate: The Quaternion to rotate by.
            displace: The Quaternion to displace by.
        """

        self *= Self(rotate, displace)

    fn to_quaternions(self) -> (Quaternion[T], Quaternion[T]):
        """Get the Quaternion representation such that
        `q = r + n * t * r`, where r is the rotation quaternion
        and t is the translation quaternion and n is the unit
        vector for the DualQuaternion's dual part.

        Returns:
            Tuple[Quaternion[T], Quaternion[T])]: (r, t).
        """

        r = Quaternion[T](self.vec.slice[4]())
        rest = self.vec / r.vec.join(SIMD[T, 4](0))
        d = Quaternion[T](rest.slice[4, offset=4]()) * SIMD[T, 4](2)
        return r, d

    fn to_screw(self) -> (SIMD[T, 8], SIMD[T, 2]):
        """Get the screw representation:
        `screw_vec = (lx, ly, lz, _, mx, my, mz, _)` ,
        `dual_angle: (theta, d)`.

        Notes:
            This assumes it's a normalized dual quaternion.

        Returns:
            Tuple[SIMD[T, 8], SIMD[T, 2])]: (screw_vec, dual_angle).
        """

        theta = acos(self.w) * 2
        sin_theta_2 = sin(theta * 0.5)
        cos_theta_2 = cos(theta * 0.5)
        d = 2 * self.ew / (-sin_theta_2)
        q1 = SIMD[T, 4](self.i, self.j, self.k, 0)
        q2 = SIMD[T, 4](self.ei, self.ej, self.ek, 0)
        l = q1 / sin_theta_2
        l_dual = l * (d * 0.5 * cos_theta_2)
        m = (q2 - l_dual) / sin_theta_2
        return l.join(m), SIMD[T, 2](theta, d)

    fn __pow__(self, value: Int) -> Self:
        """Raise the DualQuaternion to the given power.

        Notes:
            This assumes it's a normalized dual quaternion.

        Args:
            value: The exponent.

        Returns:
            The result.
        """

        screw = self.to_screw()
        screw_vec = screw[0]
        dual_angle = screw[1]
        return Self(screw_vec, dual_angle * value)

    # TODO: need Matrix[T, 4, 4]
    # fn to_matrix(self) -> Matrix[T, 4, 4]:
    #     """Calculate the 4x4 homogeneous Transformation Matrix from the
    #     DualQuaternion for a 3D vector `v = (1, x, y, z)` such that
    #     `v' = T * v`.

    #     Returns:
    #         The resulting 4x4 Matrix.
    #     """

    #     qs = self.to_quaternions()
    #     r = qs[0]
    #     d = qs[1]
    #     m = Matrix[T, 4, 4]
    #     wk = 2 * (r.w * r.k)
    #     wi = 2 * (r.w * r.i)
    #     wj = 2 * (r.w * r.j)
    #     ij = 2 * (r.i * r.j)
    #     ik = 2 * (r.i * r.k)
    #     jk = 2 * (r.j * r.k)
    #     r2 = r**2
    #     i1 = (r2 * SIMD[T, 4](1, 1, -1, -1)).reduce_add()
    #     i2 = (r2 * SIMD[T, 4](1, -1, 1, -1)).reduce_add()
    #     i3 = (r2 * SIMD[T, 4](1, -1, -1, 1)).reduce_add()
    #     m[0] = (1, 0, 0, 0)
    #     m[1] = (d.i, i1, ij - wk, ik + wj)
    #     m[2] = (d.j, ij + wk, i2, jk - wi)
    #     m[3] = (d.k, ik - wj, jk + wi, i3)
    #     return m

    fn differential(self, w: Quaternion[T], v: Quaternion[T]) -> Self:
        """Calculate the value of the derivative of the DualQuaternion
        with given parameters.

        Args:
            w: Omega, the angular velocity.
            v: Translational velocity.

        Returns:
            The DualQuaternion value.
        """

        qs = self.to_quaternions()
        r = qs[0]
        t = qs[1]
        half_4 = SIMD[T, 4](0.5)
        half_8 = SIMD[T, 8](0.5)
        q1 = w * r
        q2 = (v + (t * w) * half_4) * r
        return Self(q1.vec.join(q2.vec) * half_8)

    # TODO: capturing closures cannot be materialized as runtime values
    # fn sclerp(self, other: Self) -> fn (Int) capturing -> Self:
    #     """Get the tick function for performing Screw Linear
    #     Interpolation (ScLERP) from self to other using the function
    #     `fn(tau: Int) -> DualQuaternion[T]` , `tau: [0, 1]`.

    #     Notes:
    #         This assumes both are normalized dual quaternions.

    #     Args:
    #         other: The other DualQuaternion.

    #     Returns:
    #         The tick function.
    #     """

    #     @parameter
    #     fn closure(tau: Int) -> Self:
    #         return self * ((~self * other) ** tau)

    #     return closure

    # TODO: capturing closures cannot be materialized as runtime values
    # fn dlb(self, other: Self) -> fn (Int) capturing -> Self:
    #     """Get the tick function for performing Dual Linear Blending
    #     (DLB) from self to other using the function
    #     `fn(tau: Int) -> DualQuaternion[T]` , `tau: [0, 1]`.

    #     Notes:
    #         This assumes both are normalized dual quaternions.

    #     Args:
    #         other: The other DualQuaternion.

    #     Returns:
    #         The tick function.
    #     """

    #     @parameter
    #     fn closure(tau: Int) -> Self:
    #         w = 1 - tau
    #         vec_t = SIMD[T, 8](0, tau, tau, tau, tau, tau, tau, tau)
    #         vec = (~self * other).vec * vec_t
    #         vec[0] = w
    #         return vec / sqrt((vec**2).reduce_add())

    #     return closure

    fn __eq__(self, other: Self) -> Bool:
        """Whether self is equal to other.

        Args:
            other: The other DualQuaternion.

        Returns:
            The result.
        """
        return (self.vec == other.vec).reduce_and()

    fn __str__(self) -> String:
        s = String("[")

        @parameter
        for i in range(8):
            if i > 0:
                s += ", "
            s += str(self.vec[i])

        s += "]"
        return s^
