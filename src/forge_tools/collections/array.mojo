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
"""Defines the `Array` type.

An Array allocated on the stack with a capacity known at compile
time.

It is backed by a `SIMD` vector. This struct has the same API
as a regular `Array`.

This is typically faster than Python's `Array` as it is stack-allocated
and does not require any dynamic memory allocation and uses vectorized
operations wherever possible.

Examples:

```mojo
from forge_tools.collections import Array
alias Arr = Array[DType.int8, 3]
a = Arr(1, 2, 3)
b = Arr(1, 2, 3)
print(a.max()) # 3
print(a.min()) # 1
print((a - b).sum()) # 0
print(a.avg()) # 2
print(a * b) # [1, 4, 9]
print(2 in a) # True
print(a.index(2).or_else(-1)) # 1
print((Arr(2, 2, 2) % 2).sum()) # 0
print((Arr(2, 2, 2) // 2).sum()) # 3
print((Arr(2, 2, 2) ** 2).sum()) # 12
print(a.dot(b)) # 14
print(a.cross(b)) # [0, 0, 0]
print(a.cos(b)) # 1
print(a.theta(b)) # 0
a.reverse()
print(a) # [3, 2, 1]

fn mapfunc(a: UInt8) -> Scalar[DType.bool]:
    return a < 3
print(a.map(mapfunc)) # [False, True, True]

fn filterfunc(a: UInt8) -> Scalar[DType.bool]:
    return a < 3
print(a.filter(filterfunc)) # [2, 1]

fn applyfunc(a: UInt8) -> UInt8:
    return a * 2
a.apply(applyfunc, where=filterfunc)
print(a) # [3, 4, 2]

print(a.concat(a.reversed() // 2)) # [3, 4, 2, 1, 2, 1]
```
.
"""

from math import sqrt, acos, sin
from algorithm import vectorize
from bit import bit_ceil
from sys import info
from collections import Optional
from collections._index_normalization import normalize_index
from benchmark import clobber_memory
from memory import UnsafePointer
from utils import IndexList
from os import abort


# ===----------------------------------------------------------------------===#
# Array
# ===----------------------------------------------------------------------===#


@value
struct _ArrayIter[
    T: DType, capacity: Int, static: Bool = False, forward: Bool = True
](Sized):
    """Iterator for Array.

    Parameters:
        T: The type of the elements in the Array.
        capacity: The maximum number of elements that the Array can hold.
        static: Whether the Array always holds `capacity` amount of items.
        forward: The iteration direction. `False` is backwards.
    """

    var index: Int
    var src: Array[T, capacity, static]

    fn __iter__(self) -> Self:
        return self

    fn __next__(mut self) -> Scalar[T]:
        @parameter
        if forward:
            self.index += 1
            return self.src[self.index - 1]
        else:
            self.index -= 1
            return self.src[self.index]

    fn __len__(self) -> Int:
        @parameter
        if forward:
            return len(self.src) - self.index
        else:
            return self.index


@register_passable("trivial")
struct Array[T: DType, capacity: Int, static: Bool = False](
    CollectionElement, Sized, Boolable
):
    """An Array allocated on the stack with a capacity known at compile
    time.

    It is backed by a `SIMD` vector. This struct has the same API
    as a regular `Array`.

    This is typically faster than Python's `Array` as it is stack-allocated
    and does not require any dynamic memory allocation and uses vectorized
    operations wherever possible.

    Examples:

    ```mojo
    from forge_tools.collections import Array
    alias Arr = Array[DType.int8, 3]
    a = Arr(1, 2, 3)
    b = Arr(1, 2, 3)
    print(a.max()) # 3
    print(a.min()) # 1
    print((a - b).sum()) # 0
    print(a.avg()) # 2
    print(a * b) # [1, 4, 9]
    print(2 in a) # True
    print(a.index(2).or_else(-1)) # 1
    print((Arr(2, 2, 2) % 2).sum()) # 0
    print((Arr(2, 2, 2) // 2).sum()) # 3
    print((Arr(2, 2, 2) ** 2).sum()) # 12
    print(a.dot(b)) # 14
    print(a.cross(b)) # [0, 0, 0]
    print(a.cos(b)) # 1
    print(a.theta(b)) # 0
    a.reverse()
    print(a) # [3, 2, 1]

    fn mapfunc(a: Int8) -> Scalar[DType.bool]:
        return a < 3
    print(a.map(mapfunc)) # [False, True, True]

    fn filterfunc(a: Int8) -> Scalar[DType.bool]:
        return a < 3
    print(a.filter(filterfunc)) # [2, 1]

    fn applyfunc(a: Int8) -> Int8:
        return a * 2
    a.apply(applyfunc, where=filterfunc)
    print(a) # [3, 4, 2]

    print(a.concat(a.reversed() // 2)) # [3, 4, 2, 1, 2, 1]
    ```

    Parameters:
        T: The type of the elements in the Array.
        capacity: The number of elements that the Array can hold.
            Should be a power of two, otherwise space on the SIMD vector
            is wasted and many functions become slower as they have
            to mask the extra dimensions.
        static: Whether the Array always holds `capacity` amount of items.

    Constraints:
        Maximum capacity is 256.

    Notes:
        Setting Array items directly doesn't update self.capacity_left,
            methods like append(), concat(), etc. do.
    """

    alias simd_size = bit_ceil(capacity)
    """The size of the underlying SIMD vector."""
    alias _vec_type = SIMD[T, Self.simd_size]
    var vec: Self._vec_type
    """The underlying SIMD vector."""
    alias _scalar = Scalar[T]
    var capacity_left: UInt8
    """The current capacity left."""
    alias _slice_simd_size = Self.simd_size if (
        Self.simd_size * T.bitwidth() <= info.simdbitwidth()
    ) else (info.simdbitwidth() // T.bitwidth())

    @always_inline
    fn __init__(out self):
        """This constructor creates an empty Array.

        Constraints:
            Maximum capacity is 256.
            Can't instantiate an empty Array of `capacity=256`.
        """

        constrained[capacity <= 256, "Maximum capacity is 256."]()
        constrained[
            capacity != 256,
            "Can't instantiate an empty Array of `capacity=256`.",
        ]()
        self.vec = Self._vec_type(0)

        @parameter
        if static:
            self.capacity_left = 0
        else:
            self.capacity_left = capacity

    @always_inline
    fn __init__(out self, *, fill: Self._scalar):
        """Constructs an Array by filling it with the
        given value. Sets the capacity_left to 0.

        Args:
            fill: The value to populate the Array with.

        Constraints:
            Maximum capacity is 256.
        """

        constrained[capacity <= 256, "Maximum capacity is 256."]()
        self.vec = Self._vec_type(fill)
        Self._mask_vec_capacity_delta(self.vec)
        self.capacity_left = 0

    # TODO: Avoid copying elements in once owned varargs
    # allow transfers.
    fn __init__(out self, *values: Self._scalar):
        """Constructs an Array from the given values.

        Args:
            values: The values to populate the Array with.

        Constraints:
            Maximum capacity is 256.
        """

        constrained[capacity <= 256, "Maximum capacity is 256."]()

        # TODO: capacity should be statically determined from
        # this constructor
        @parameter
        if static:
            if len(values) != capacity:
                abort("Static sized Arrays must have capacity amount of items.")
            self.vec = Self._vec_type(0)

            @parameter
            fn closure[simd_width: Int](i: Int):
                self.vec[i] = values[i]

            self.capacity_left = 0
            vectorize[
                closure, 1, size=capacity, unroll_factor = Self._slice_simd_size
            ]()
        else:
            self.vec = Self._vec_type(0)
            self.capacity_left = capacity
            for i in range(len(values)):
                self.vec[i] = values[i]
                self.capacity_left -= 1

    fn __init__[
        size: Int
    ](
        out self,
        owned values: SIMD[T, size],
        length: Int = min(size, capacity),
    ):
        """Constructs an Array from the given values.

        Parameters:
            size: The size of the SIMD vector.

        Args:
            values: The values to populate the Array with.
            length: The amount of items to populate the Array with.

        Constraints:
            Maximum capacity is 256.
        """

        constrained[capacity <= 256, "Maximum capacity is 256."]()

        @parameter
        if static and size == Self.simd_size:
            self.vec = rebind[Self._vec_type](values)
            self.capacity_left = 0
        elif static:
            self.vec = Self._vec_type(0)

            @parameter
            fn closure[simd_width: Int](i: Int):
                self.vec[i] = values[i]

            self.capacity_left = 0
            vectorize[
                closure,
                1,
                size = min(size, capacity),
                unroll_factor = Self._slice_simd_size,
            ]()
        elif size == Self.simd_size:
            self.vec = rebind[Self._vec_type](values)
            Self._mask_vec_size(self.vec, length)
            self.capacity_left = capacity - length
        else:
            self.vec = Self._vec_type(0)
            for i in range(length):
                self.vec[i] = values[i]
            self.capacity_left = capacity - length

    fn __init__[
        D: DType = T, cap: Int = capacity
    ](out self, *, other: Array[D, cap, static]):
        """Constructs an Array from an existing Array.

        Parameters:
            D: The DType of the elements that the Array holds.
            cap: The number of elements that the Array can hold.

        Args:
            other: The other Array.

        Constraints:
            Maximum capacity is 256.
        """

        constrained[capacity <= 256, "Maximum capacity is 256."]()

        @parameter
        if D == T and other._vec_type.size == Self.simd_size:
            self.vec = rebind[Self._vec_type](other.vec)
            self.capacity_left = 0

            @parameter
            if capacity != other.capacity:
                Self._mask_vec_capacity_delta(self.vec)
        elif other._vec_type.size == Self.simd_size:
            self.vec = rebind[Self._vec_type](other.vec.cast[T]())

            @parameter
            if capacity != other.capacity:
                Self._mask_vec_capacity_delta(self.vec)
            self.capacity_left = 0
        else:
            self.vec = Self._vec_type(0)

            @parameter
            fn closure[simd_width: Int](i: Int):
                self.vec[i] = other.vec[i].cast[T]()

            @parameter
            if other.capacity > capacity:
                Self._mask_vec_capacity_delta(self.vec)
                self.capacity_left = 0
            elif other.capacity < capacity:
                self.capacity_left = capacity - other.capacity
            else:
                self.capacity_left = 0

            vectorize[
                closure,
                1,
                size = min(other._vec_type.size, Self.simd_size),
                unroll_factor = Self._slice_simd_size,
            ]()

    fn __init__(
        out self,
        *,
        unsafe_pointer: UnsafePointer[Self._scalar],
        length: Int,
        unsafe_simd_size: Bool = False,
    ):
        """Constructs an Array from a pointer and its length.

        Args:
            unsafe_pointer: The pointer to the data.
            length: The number of elements pointed to.
            unsafe_simd_size: Whether to unsafely load assuming the pointer has
                Self.simd_size allocated and length elements that are part of
                the valid values for the Array.

        Constraints:
            Maximum capacity is 256.
        """

        constrained[capacity <= 256, "Maximum capacity is 256."]()
        if unsafe_simd_size:
            ptr = unsafe_pointer
            self.vec = ptr.load[width = Self.simd_size]()
            self.capacity_left = capacity - length
            return

        s = min(capacity, length)
        self.vec = Self._vec_type(0)
        for i in range(s):  # FIXME: is there no faster way?
            self.vec[i] = unsafe_pointer[i]

        @parameter
        if static:
            self.capacity_left = 0
        else:
            self.capacity_left = capacity - s

    fn __init__(out self, existing: List[Self._scalar]):
        """Constructs an Array from an existing List.

        Args:
            existing: The existing List.

        Constraints:
            Maximum capacity is 256.
        """

        constrained[capacity <= 256, "Maximum capacity is 256."]()
        self = Self(unsafe_pointer=existing.unsafe_ptr(), length=len(existing))
        _ = existing

    fn __init__[size: Int](out self, owned existing: List[Self._scalar]):
        """Constructs an Array from an existing List.

        Parameters:
            size: The size of the List.

        Args:
            existing: The existing List.

        Constraints:
            Maximum capacity is 256.
            Array capacity must be power of 2.
            Size must be == capacity.
        """

        constrained[capacity <= 256, "Maximum capacity is 256."]()
        constrained[
            capacity == Self.simd_size,
            "Array capacity must be power of 2.",
        ]()
        constrained[size == capacity, "Size must be == capacity."]()
        self.vec = existing.steal_data().load[width = Self.simd_size]()
        self.capacity_left = 0

    @always_inline
    fn __len__(self) -> Int:
        """Returns the length of the Array.

        Returns:
            The length.
        """

        @parameter
        if static:
            return capacity
        else:
            return capacity - int(self.capacity_left.cast[DType.uint64]())

    @always_inline
    fn append(mut self, owned value: Self._scalar):
        """Appends a value to the Array. If full, it's a no-op.

        Args:
            value: The value to append.

        Constaints:
            Array can't be static.
        """

        constrained[not static, "Array can't be static."]()
        if self.capacity_left == 0:
            return
        self.vec[len(self)] = value
        self.capacity_left -= 1

    # FIXME
    # fn append(out self, other: Array[T, *_]):
    #     """Appends the values of another Array up to Self.capacity.

    #     Args:
    #         other: The Array to append.

    #     Constraints:
    #         Array can't be static.
    #     """

    #     constrained[not static, "Array can't be static."]()
    #     for i in range(min(self.capacity_left, len(other))):
    #         self.append(other.vec[i])

    fn __iter__(
        self,
    ) -> _ArrayIter[T, capacity, static]:
        """Iterate over elements of the Array, returning immutable references.

        Returns:
            An iterator of immutable references to the Array elements.
        """
        return _ArrayIter(0, self)

    fn __reversed__(
        self,
    ) -> _ArrayIter[T, capacity, static, False]:
        """Iterate backwards over the Array, returning immutable references.

        Returns:
            A reversed iterator of immutable references to the Array elements.
        """
        return _ArrayIter[static=static, forward=False](len(self), self)

    fn __contains__(self, value: Self._scalar) -> Bool:
        """Verify if a given value is present in the Array.

        Args:
            value: The value to find.

        Returns:
            True if the value is contained in the Array, False otherwise.
        """

        if value == 0:

            @parameter
            if static and Self._slice_simd_size == capacity:
                vec = self.vec
                Self._mask_vec_size[T, 1](vec, len(self))
                return (vec == value).reduce_or()
            for i in range(len(self)):
                if self.vec[i] == value:
                    return True
            return False

        alias size = Self._slice_simd_size

        @parameter
        for i in range(Self.simd_size // size):
            if (self.vec.slice[size, offset = i * size]() == value).reduce_or():
                return True
        return False

    @always_inline
    fn __bool__(self) -> Bool:
        """Checks whether the Array has any elements or not.

        Returns:
            `False` if the Array is empty, `True` if there is at least one
                element.
        """
        return len(self) > 0

    fn concat[
        cap: Int
    ](owned self, owned other: Array[T, cap, static]) -> Array[
        T, capacity + cap, False
    ]:
        """Concatenates self with other and returns the result as a new Array.

        Parameters:
            cap: The capacity of the other Array.

        Args:
            other: Array whose elements will be combined with the elements of
                self.

        Returns:
            The newly created Array.
        """

        alias Arr = Array[T, capacity + cap, False]
        arr = Arr(self.vec, length=len(self))
        for i in range(len(other)):
            arr.append(other.vec[i])
        return arr

    fn __str__(self) -> String:
        """Returns a string representation of an `Array`.

        Returns:
            A string representation of the array.

        Examples:

        ```mojo
        from forge_tools.collections import Array
        print(str(Array[DType.uint8, 3](1, 2, 3))) # [1, 2, 3]
        %# from testing import assert_equal
        %# assert_equal(str(Array[DType.uint8, 3](1, 2, 3)), "[1, 2, 3]")
        ```
        .
        """
        # we do a rough estimation of the number of chars that we'll see
        # in the final string, we assume that str(x) will be at least one char.
        minimum_capacity = (
            2  # '[' and ']'
            + len(self) * 3  # str(x) and ", "
            - 2  # remove the last ", "
        )
        string_buffer = List[UInt8](capacity=minimum_capacity)
        string_buffer.append(0)  # Null terminator
        result = String(string_buffer^)
        result += "["
        for i in range(len(self)):
            result += str(self.vec[i])
            if i < len(self) - 1:
                result += ", "
        result += "]"
        return result^

    fn __repr__(self) -> String:
        """Returns a string representation of an `Array`.

        Returns:
            A string representation of the array.

        Examples:

        ```mojo
        from forge_tools.collections import Array
        my_array = Array[DType.uint8, 3](1, 2, 3)
        print(repr(my_array)) # [1, 2, 3]
        %# from testing import assert_equal
        %# assert_equal(str(Array[DType.uint8, 3](1, 2, 3)), "[1, 2, 3]")
        ```
        .
        """
        return str(self)

    @always_inline
    fn insert(mut self, i: Int, owned value: Self._scalar):
        """Inserts a value to the Array at the given index.
        `a.insert(len(a), value)` is equivalent to `a.append(value)`.

        Args:
            i: The index for the value.
            value: The value to insert.
        """

        debug_assert(
            abs(i) < capacity or i == -1 * capacity, "insert index out of range"
        )
        norm_idx = min(i, capacity - 1) if i > -1 else max(0, capacity + i)

        previous = value
        for i in range(norm_idx, capacity):
            tmp = self.vec[i]
            self.vec[i] = previous
            previous = tmp
        if self.capacity_left > 0:
            self.capacity_left = min(
                self.capacity_left - 1, capacity - (norm_idx + 1)
            )

    fn pop(mut self, i: Int = -1) -> Self._scalar:
        """Pops a value from the Array at the given index.

        Args:
            i: The index of the value to pop.

        Returns:
            The popped value.

        Constraints:
            The Array can't be static.
        """

        constrained[not static, "The Array can't be static."]()
        size = len(self)
        debug_assert(abs(i) < size or i == -1 * size, "pop index out of range")
        norm_idx = min(i, size - 1) if i > -1 else max(0, size + i)
        self.capacity_left += 1
        val = self.vec[norm_idx]
        for i in range(size - norm_idx):
            offset = norm_idx + i
            if offset == size:
                self.vec[norm_idx] = 0
                break
            self.vec[offset] = self.vec[offset + 1]
        return val

    fn index(self, value: Self._scalar) -> Optional[Int]:
        """Returns the index of the first occurrence of a value in an Array.

        Args:
            value: The value to search for.

        Returns:
            The Optional index of the first occurrence of the value in the
                Array.

        Examples:

        ```mojo
        from forge_tools.collections import Array
        item = Array[DType.uint8, 3](1, 2, 3).index(2)
        print(item.or_else(-1)) # prints `1`
        ```
        .
        """

        fn from_range[simd_size: Int]() -> SIMD[DType.uint8, simd_size]:
            vec = SIMD[DType.uint8, simd_size]()
            idx = 0

            @parameter
            for i in range(simd_size - 1, -1, -1):
                vec[idx] = i
                idx += 1
            return vec

        alias indices = from_range[Self.simd_size]()
        alias size = Self._slice_simd_size
        var idx: UInt8

        @parameter
        if size == Self.simd_size:
            idx = (
                (self.vec == value).cast[DType.uint8]() * indices
            ).reduce_max()
        else:
            idxes = SIMD[DType.uint8, Self.simd_size // size](0)

            @parameter
            for i in range(Self.simd_size // size):
                ind = indices.slice[size, offset = i * size]()
                vec = self.vec.slice[size, offset = i * size]() == value
                idxes[i] = (ind * vec.cast[DType.uint8]()).reduce_max()

            idx = idxes.reduce_max()
        res = Self.simd_size - int(idx.cast[DType.uint64]())

        if idx == 0:
            return None

        @parameter
        if not static:
            if res > len(self):
                return None
        else:
            if res > capacity:
                return None
        return res - 1

    fn index(
        self,
        value: Self._scalar,
        start: Int,
        stop: Int = -1,
    ) -> Optional[Int]:
        """Returns the index of the first occurrence of a value in an Array
        restricted by the range given the start and stop bounds.

        Args:
            value: The value to search for.
            start: The starting index of the search, treated as a slice index.
            stop: The ending index of the search, treated as a slice index
                (defaults to the end of the Array).

        Returns:
            The Optional index of the first occurrence of the value in the
                Array.

        Examples:

        ```mojo
        from forge_tools.collections import Array
        item = Array[DType.uint8, 3](1, 2, 3).index(2, start=1)
        print(item.or_else(-1)) # prints `1`
        ```
        .
        """

        start_norm = normalize_index["Array"](start, self)
        stop_norm = min(len(self) + 1, stop) if stop > -1 else (
            len(self) + stop
        )
        if start_norm == stop_norm:
            return None
        vec = self.vec == value
        for i in range(start_norm, stop_norm):
            if vec[i]:
                return i
        return None

    fn remove(mut self, value: Int):
        """Remove the first occurrence of value from the array.

        Args:
            value: The value.

        Constraints:
            The Array can't be static.
        """
        idx = self.index(value)
        if idx:
            _ = self.pop(idx.value())

    fn reverse(mut self):
        """Reverse the order of the items in the array inplace."""

        @parameter
        fn from_range() -> IndexList[Self.simd_size]:
            values = IndexList[Self.simd_size]()
            idx = 0

            @parameter
            for i in reversed(range(capacity)):
                values[idx] = i
                idx += 1

            @parameter
            for i in range(capacity, Self.simd_size):
                values[i] = i
            return values

        vec = self.vec.shuffle[mask = from_range()]()

        @parameter
        if static:
            self.vec = vec
            return
        else:
            pass
        if self.capacity_left == 0:
            self.vec = vec
        elif self.capacity_left == 1:
            self.vec = vec.shift_left[1]()
        elif self.capacity_left == 2:
            self.vec = vec.shift_left[2]()
        elif self.capacity_left == 3:
            self.vec = vec.shift_left[3]()
        elif self.capacity_left == 4:
            self.vec = vec.shift_left[4]()
        else:
            for i in range(len(self)):
                self.vec[i] = vec[capacity - len(self) + i]

    fn reversed(owned self) -> Self:
        """Get the reversed Array.

        Returns:
            The reversed Array.
        """
        self.reverse()
        return self

    @always_inline
    fn __getitem__(self, span: Slice) -> Self:
        """Gets the sequence of elements at the specified positions.

        Args:
            span: A slice that specifies positions of the new array.

        Returns:
            A new array containing the array at the specified span.
        """

        start, end, step = span.indices(len(self))
        r = range(start, end, step)

        if not len(r):
            return Self()

        res = Self()
        for i in r:
            res.append(self[i])

        return res

    fn __setitem__(mut self, idx: Int, owned value: Self._scalar):
        """Sets an Array element at the given index. This will
        not update self.capacity_left.

        Args:
            idx: The index of the element.
            value: The value to assign.
        """
        # norm_idx = normalize_index["Array"](idx, self)
        norm_idx = idx if idx > -1 else len(self) + idx
        self.vec[norm_idx] = value

    @always_inline
    fn __getitem__(self, idx: Int) -> Self._scalar:
        """Gets a copy of the element at the given index.

        Args:
            idx: The index of the element.

        Returns:
            A copy of the element at the given index.
        """
        norm_idx = normalize_index["Array"](idx, self)
        return self.vec[norm_idx]

    fn count(self, value: Self._scalar) -> Int:
        """Counts the number of occurrences of a value in the Array.

        Args:
            value: The value to count.

        Returns:
            The number of occurrences of the value in the Array.

        Examples:

        ```mojo
        from forge_tools.collections import Array
        my_array = Array[DType.uint8, 3](1, 2, 3)
        print(my_array.count(1)) # 1
        ```
        .
        """

        alias size = Self._slice_simd_size
        amnt = UInt8(0)
        if value == 0:
            alias delta: UInt8 = Self.simd_size - capacity
            null_amnt = self.capacity_left + delta

            @parameter
            for i in range(Self.simd_size // size):
                vec = self.vec.slice[size, offset = i * size]() == value
                amnt += vec.cast[DType.uint8]().reduce_add()
            return int(amnt - null_amnt)

        @parameter
        for i in range(Self.simd_size // size):
            vec = self.vec.slice[size, offset = i * size]() == value
            amnt += vec.cast[DType.uint8]().reduce_add()
        return int(amnt)

    @always_inline
    fn unsafe_ptr(self) -> UnsafePointer[Self._scalar]:
        """Constructs a pointer to a copy of the SIMD vector.

        Returns:
            An UnsafePointer to a copy of the SIMD vector.
        """
        ptr = UnsafePointer[Scalar[T]].alloc(Self.simd_size)
        alias size = Self._slice_simd_size

        @parameter
        for i in range(Self.simd_size // size):
            ptr.store(i * size, self.vec.slice[size, offset = i * size]())

        return ptr

    @always_inline
    fn unsafe_get(self, idx: Int) -> Self._scalar:
        """Get a copy of an element of self without checking index bounds.
        Users should consider using `__getitem__` instead of this method as it
        is unsafe. If an index is out of bounds, this method will not abort, it
        will be considered undefined behavior.

        Note that there is no wraparound for negative indices, caution is
        advised. Using negative indices is considered undefined behavior. Never
        use `my_array.unsafe_get(-1)` to get the last element of the Array. It
        will not work. Instead, do `my_array.unsafe_get(len(my_array) - 1)`.

        Args:
            idx: The index of the element to get.

        Returns:
            A copy of the element at the given index.
        """
        return self.vec[idx]

    @always_inline
    fn unsafe_set(mut self, idx: Int, value: Self._scalar):
        """Set a copy to an element of self without checking index bounds.
        Users should consider using `__setitem__` instead of this method as it
        is unsafe. If an index is out of bounds, this method will not abort, it
        will be considered undefined behavior. Does not update
        `self.capacity_left`.

        Note that there is no wraparound for negative indices, caution is
        advised. Using negative indices is considered undefined behavior. Never
        use `my_array.unsafe_set(-1)` to set the last element of the Array. It
        will not work. Instead, do `my_array.unsafe_set(len(my_array) - 1)`.

        Args:
            idx: The index to set the element.
            value: The element.
        """
        self.vec[idx] = value

    @always_inline("nodebug")
    fn sum[D: DType = T](self) -> Scalar[D]:
        """Calculates the sum of all elements.

        Parameters:
            D: The DType to cast to before reducing to avoid overflow.

        Returns:
            The result.
        """

        @parameter
        if D == DType.bool:
            return rebind[Scalar[D]](self.vec.reduce_or())
        elif D != T:
            return self.vec.cast[D]().reduce_add()
        else:
            return rebind[Scalar[D]](self.vec.reduce_add())

    @always_inline("nodebug")
    fn avg[D: DType = T](self) -> Scalar[D]:
        """Calculates the average of all elements.

        Parameters:
            D: The DType to cast to before reducing to avoid overflow.

        Returns:
            The result.
        """

        @parameter
        if D == DType.bool:
            return rebind[Scalar[D]](
                bool(round(self.sum[DType.uint8]() / len(self)))
            )
        return self.sum[D]() / len(self)

    @always_inline("nodebug")
    fn min(self) -> Self._scalar:
        """Calculates the minimum of all elements.

        Returns:
            The result.
        """

        vec = self.vec

        @parameter
        if T.is_floating_point():
            Self._mask_vec_size[T, Self._scalar.MAX](vec, len(self))
        elif T.is_integral():
            Self._mask_vec_size[T, ~Self._scalar(0)](vec, len(self))
        else:
            Self._mask_vec_size[T, 1](vec, len(self))
        return vec.reduce_min()

    @always_inline("nodebug")
    fn max(self) -> Self._scalar:
        """Calculates the maximum of all elements.

        Returns:
            The result.
        """
        return self.vec.reduce_max()

    @always_inline("nodebug")
    fn min[cap: Int = capacity](self, other: Array[T, cap, static]) -> Self:
        """Computes the elementwise minimum between the two Arrays.

        Parameters:
            cap: The capacity of the other Array.

        Args:
            other: The other SIMD vector.

        Returns:
            A new SIMD vector where each element at position
                i is min(self[i], other[i]).
        """
        alias delta = Self.capacity - other.capacity
        var vec: Self._vec_type

        @parameter
        if delta == 0:
            vec = min(self.vec, rebind[Self._vec_type](other.vec))
        elif delta > 0:
            o = Self(other=other)
            vec = min(self.vec, o.vec)
        else:
            vec = min(self.vec, other.vec.slice[Self.simd_size]())

        @parameter
        if static:
            return Self(vec)
        else:
            return Self(vec, length=max(len(self), len(other)))

    @always_inline("nodebug")
    fn max[cap: Int = capacity](self, other: Array[T, cap, static]) -> Self:
        """Computes the elementwise maximum between the two Arrays.

        Parameters:
            cap: The capacity of the other Array.

        Args:
            other: The other SIMD vector.

        Returns:
            A new SIMD vector where each element at position
                i is max(self[i], other[i]).
        """
        alias delta = Self.capacity - other.capacity
        var vec: Self._vec_type

        @parameter
        if delta == 0:
            vec = max(self.vec, rebind[Self._vec_type](other.vec))
        elif delta > 0:
            o = Self(other=other)
            vec = max(self.vec, o.vec)
        else:
            vec = max(self.vec, other.vec.slice[Self.simd_size]())

        @parameter
        if static:
            return Self(vec)
        else:
            return Self(vec, length=max(len(self), len(other)))

    @always_inline("nodebug")
    fn dot[
        D: DType = T, cast_before_mult: Bool = True
    ](self, other: Self) -> Scalar[D]:
        """Calculates the dot product between two Arrays.

        Parameters:
            D: The DType to cast to before reducing to avoid overflow.
            cast_before_mult: Whether the vectors are casted before they are
                multiplied.

        Args:
            other: The other Array.

        Returns:
            The result.
        """

        @parameter
        if D == T:
            return rebind[Scalar[D]]((self.vec * other.vec).reduce_add())
        elif cast_before_mult:
            return (self.vec.cast[D]() * other.vec.cast[D]()).reduce_add()
        else:
            return (self.vec * other.vec).cast[D]().reduce_add()

    @staticmethod
    fn _mask_vec_capacity_delta[
        D: DType, //, value: Scalar[D] = 0
    ](mut vec: SIMD[D, Self.simd_size]):
        @parameter
        for i in range(Self.simd_size - capacity):
            vec[capacity + i] = value

    @staticmethod
    fn _mask_vec_size[
        D: DType, //, value: Scalar[D] = 0
    ](mut vec: SIMD[D, Self.simd_size], length: Int = capacity):
        @parameter
        if static:
            Self._mask_vec_capacity_delta[value=value](vec)
        else:
            for i in range(length, capacity):
                vec[i] = value
            Self._mask_vec_capacity_delta[value=value](vec)

    @always_inline("nodebug")
    fn __mul__(self, other: Self) -> Self:
        """Calculates the elementwise multiplication between two Arrays.

        Args:
            other: The other Array.

        Returns:
            The result.
        """

        @parameter
        if static:
            return Self(self.vec * other.vec)
        else:
            return Self(self.vec * other.vec, length=max(len(self), len(other)))

    @always_inline("nodebug")
    fn __imul__(mut self, other: Self):
        """Calculates the elementwise multiplication between two Arrays inplace.

        Args:
            other: The other Array.
        """
        self.vec *= other.vec

    @always_inline("nodebug")
    fn __mul__(self, value: Self._scalar) -> Self:
        """Calculates the elementwise multiplication by the given value.

        Args:
            value: The value.

        Returns:
            A new Array with the values.
        """

        @parameter
        if static:
            return Self(self.vec * value)
        else:
            return Self(self.vec * value, length=len(self))

    @always_inline("nodebug")
    fn __imul__(mut self, owned value: Self._scalar):
        """Calculates the elementwise multiplication by the given value inplace.

        Args:
            value: The value.
        """
        self.vec *= value

    @always_inline("nodebug")
    fn __truediv__(self, value: Self._scalar) -> Self:
        """Calculates the elementwise division by the given value.

        Args:
            value: The value.

        Returns:
            A new Array with the values.
        """

        if value == 0:
            abort("division by 0")
        return Self(self.vec / Self._vec_type(value), length=len(self))

    @always_inline("nodebug")
    fn __itruediv__(mut self, owned value: Self._scalar):
        """Calculates the elementwise division by the given value inplace.

        Args:
            value: The value.
        """

        if value == 0:
            abort("division by 0")
        self.vec /= Self._vec_type(value)

    @always_inline("nodebug")
    fn __floordiv__(self, value: Self._scalar) -> Self:
        """Calculates the elementwise floordiv of the given value.

        Args:
            value: The value.

        Returns:
            A new Array with the values.
        """
        if value == 0:
            abort("division by 0")
        return Self(self.vec // Self._vec_type(value), length=len(self))

    @always_inline("nodebug")
    fn __ifloordiv__(mut self, owned value: Self._scalar):
        """Calculates the elementwise floordiv of the given value inplace.

        Args:
            value: The value.
        """

        if value == 0:
            abort("division by 0")
        self.vec //= Self._vec_type(value)

    @always_inline("nodebug")
    fn __mod__(self, value: Self._scalar) -> Self:
        """Calculates the elementwise mod of the given value.

        Args:
            value: The value.

        Returns:
            A new Array with the values.
        """

        if value == 0:
            abort("modulo by 0")
        return Self(self.vec % Self._vec_type(value), length=len(self))

    @always_inline("nodebug")
    fn __imod__(mut self, owned value: Self._scalar):
        """Calculates the elementwise mod of the given value inplace.

        Args:
            value: The value.
        """

        if value == 0:
            abort("modulo by 0")
        self.vec %= Self._vec_type(value)

    @always_inline("nodebug")
    fn __pow__(self, exp: Int) -> Self:
        """Calculates the elementwise pow of the given exponent.

        Args:
            exp: The exponent.

        Returns:
            A new Array with the values.
        """
        return Self(self.vec**exp, length=len(self))

    @always_inline("nodebug")
    fn __ipow__(mut self, exp: Int):
        """Calculates the elementwise pow of the given exponent inplace.

        Args:
            exp: The exponent.
        """
        self.vec **= exp

    @always_inline("nodebug")
    fn __abs__(self) -> Int:
        """Calculates the magnitude of the Array.

        Returns:
            The result.
        """

        return int(sqrt((self.vec.cast[DType.index]() ** 2).reduce_add()))

    @always_inline
    fn __add__(self, other: Self) -> Self:
        """Computes the elementwise addition between the two Arrays.

        Args:
            other: The other Array.

        Returns:
            A new Array where each element at position i is self[i] + other[i].
        """

        @parameter
        if static:
            return Self(self.vec + other.vec)
        else:
            return Self(self.vec + other.vec, length=max(len(self), len(other)))

    @always_inline("nodebug")
    fn __add__(self, value: Self._scalar) -> Self:
        """Computes the elementwise addition of the value.

        Args:
            value: The value to broadcast.

        Returns:
            A new Array containing the result.
        """

        @parameter
        if static:
            vec = Self._vec_type(value)
            Self._mask_vec_capacity_delta(vec)
            return Self(self.vec + vec)
        else:
            arr = Self(Self._vec_type(value), length=len(self))
            return Self(self.vec + arr.vec, length=len(self))

    @always_inline
    fn __sub__(self, other: Self) -> Self:
        """Computes the elementwise subtraction between the two Arrays.

        Args:
            other: The other Array.

        Returns:
            A new Array where each element at position i is self[i] - other[i].
        """

        @parameter
        if static:
            return Self(self.vec - other.vec)
        else:
            return Self(self.vec - other.vec, length=max(len(self), len(other)))

    @always_inline("nodebug")
    fn __sub__(self, value: Self._scalar) -> Self:
        """Computes the elementwise subtraction of the value.

        Args:
            value: The value to broadcast.

        Returns:
            A new Array containing the result.
        """

        @parameter
        if static:
            vec = Self._vec_type(value)
            Self._mask_vec_capacity_delta(vec)
            return Self(self.vec - vec)
        else:
            arr = Self(Self._vec_type(value), length=len(self))
            return Self(self.vec - arr.vec, length=len(self))

    @always_inline("nodebug")
    fn __iadd__(mut self, owned other: Self):
        """Computes the elementwise addition between the two Arrays
        inplace.

        Args:
            other: The other Array.
        """
        self.vec += other.vec

    @always_inline("nodebug")
    fn __iadd__(mut self, owned value: Self._scalar):
        """Computes the elementwise addition of the value.

        Args:
            value: The value to broadcast.
        """

        @parameter
        if static:
            vec = Self._vec_type(value)
            Self._mask_vec_capacity_delta(vec)
            self.vec += vec
        else:
            arr = Self(Self._vec_type(value), length=len(self))
            self.vec += arr.vec

    @always_inline("nodebug")
    fn __isub__(mut self, owned other: Self):
        """Computes the elementwise subtraction between the two Arrays
        inplace.

        Args:
            other: The other Array.
        """
        self.vec -= other.vec

    @always_inline("nodebug")
    fn __isub__(mut self, owned value: Self._scalar):
        """Computes the elementwise subtraction of the value.

        Args:
            value: The value to broadcast.
        """

        @parameter
        if static:
            vec = Self._vec_type(value)
            Self._mask_vec_capacity_delta(vec)
            self.vec -= vec
        else:
            arr = Self(Self._vec_type(value), length=len(self))
            self.vec -= arr.vec

    fn clear(mut self):
        """Zeroes the Array.

        Constraints:
            The capacity can't be 256.
        """

        constrained[capacity != 256, "The capacity can't be 256."]()
        self.vec = self._vec_type(0)
        self.capacity_left = capacity

    @always_inline("nodebug")
    fn __eq__(self, other: Self) -> Array[DType.bool, capacity, static]:
        """Whether self is equal to other.

        Args:
            other: The other Array.

        Returns:
            The result.
        """

        @parameter
        if static:
            return Array[DType.bool, capacity, static](self.vec == other.vec)
        else:
            return Array[DType.bool, capacity, static](
                self.vec == other.vec, length=max(len(self), len(other))
            )

    @always_inline("nodebug")
    fn __ne__(self, other: Self) -> Array[DType.bool, capacity, static]:
        """Whether self is unequal to other.

        Args:
            other: The other Array.

        Returns:
            The result.
        """

        @parameter
        if static:
            return Array[DType.bool, capacity, static](self.vec != other.vec)
        else:
            return Array[DType.bool, capacity, static](
                self.vec != other.vec, length=max(len(self), len(other))
            )

    @always_inline("nodebug")
    fn __gt__(self, other: Self) -> Array[DType.bool, capacity, static]:
        """Whether self is greater than other.

        Args:
            other: The other Array.

        Returns:
            The result.
        """

        @parameter
        if static:
            return Array[DType.bool, capacity, static](self.vec > other.vec)
        else:
            return Array[DType.bool, capacity, static](
                self.vec > other.vec, length=max(len(self), len(other))
            )

    @always_inline("nodebug")
    fn __ge__(self, other: Self) -> Array[DType.bool, capacity, static]:
        """Whether self is greater than or equal to other.

        Args:
            other: The other Array.

        Returns:
            The result.
        """

        @parameter
        if static:
            return Array[DType.bool, capacity, static](self.vec >= other.vec)
        else:
            return Array[DType.bool, capacity, static](
                self.vec >= other.vec, length=max(len(self), len(other))
            )

    @always_inline("nodebug")
    fn __lt__(self, other: Self) -> Array[DType.bool, capacity, static]:
        """Whether self is less than other.

        Args:
            other: The other Array.

        Returns:
            The result.
        """

        @parameter
        if static:
            return Array[DType.bool, capacity, static](self.vec < other.vec)
        else:
            return Array[DType.bool, capacity, static](
                self.vec < other.vec, length=max(len(self), len(other))
            )

    @always_inline("nodebug")
    fn __le__(self, other: Self) -> Array[DType.bool, capacity, static]:
        """Whether self is less than or equal to other.

        Args:
            other: The other Array.

        Returns:
            The result.
        """

        @parameter
        if static:
            return Array[DType.bool, capacity, static](self.vec <= other.vec)
        else:
            return Array[DType.bool, capacity, static](
                self.vec <= other.vec, length=max(len(self), len(other))
            )

    fn reduce_mul(self) -> Self._scalar:
        """Reduces the Array using the `mul` operator.

        Returns:
            The reduced Array.
        """
        vec = self.vec
        Self._mask_vec_size[T, 1](vec, len(self))

        @parameter
        if T == DType.bool:
            return vec.reduce_and()
        return vec.reduce_mul()

    fn reduce_and(self) -> Self._scalar:
        """Reduces the Array using the bitwise `&` operator.

        Returns:
            The reduced Array.
        """
        vec = self.vec

        @parameter
        if T.is_floating_point():
            Self._mask_vec_size[T, Self._scalar.MAX](vec, len(self))
        elif T.is_integral():
            Self._mask_vec_size[T, ~Self._scalar(0)](vec, len(self))
        else:
            Self._mask_vec_size[T, 1](vec, len(self))
        return vec.reduce_and()

    fn reduce_or(self) -> Self._scalar:
        """Reduces the Array using the bitwise `|` operator.

        Returns:
            The reduced Array.
        """
        return self.vec.reduce_or()

    @always_inline("nodebug")
    fn cos(self, other: Self) -> Float64:
        """Calculates the cosine of the angle between two Arrays.

        Args:
            other: The other Array.

        Returns:
            The result.
        """

        alias i = DType.uint64

        @parameter
        if T.is_floating_point():
            alias f = DType.float64
            var magn1: Scalar[f] = (self.vec.cast[f]() ** 2).reduce_add()
            var magn2: Scalar[f] = (other.vec.cast[f]() ** 2).reduce_add()
            return rebind[Float64](self.dot[f](other) / (magn1 * magn2))
        elif T.is_signed():
            var magn1: Scalar[i] = (self.vec.cast[i]() ** 2).reduce_add()
            var magn2: Scalar[i] = (other.vec.cast[i]() ** 2).reduce_add()
            return (self.dot[i](other) / (magn1 * magn2)).cast[DType.float64]()
        else:
            var magn1: Scalar[i] = (self.vec.cast[i]() ** 2).reduce_add()
            var magn2: Scalar[i] = (other.vec.cast[i]() ** 2).reduce_add()
            return (self.dot[i](other) / (magn1 * magn2)).cast[DType.float64]()

    @always_inline("nodebug")
    fn theta(self, other: Self) -> Float64:
        """Calculates the angle (in radians) between two Arrays.

        Args:
            other: The other Array.

        Returns:
            The result.
        """
        return acos(self.cos(other))

    fn cross(
        self: Array[T, capacity, True], other: Array[T, capacity, True]
    ) -> Array[T, capacity, True]:
        """Calculates the cross product between two Arrays.

        Args:
            other: The other Array.

        Returns:
            The result.

        Constraints:
            Array can't be unsigned.
        """

        constrained[not T.is_unsigned(), "Array can't be unsigned."]()
        alias size = Self.simd_size

        @parameter
        if capacity == 3:
            s = self.vec.shuffle[1, 2, 0, 3]()
            o = other.vec.shuffle[2, 0, 1, 3]()
            return s.fma(o, -(s * other.vec).shuffle[1, 2, 0, 3]())
        elif capacity == size:
            x0 = self.vec.rotate_left[1]()
            y0 = other.vec.rotate_left[2]()
            vec0 = x0.join(y0)
            x1 = self.vec.rotate_left[2]()
            y1 = other.vec.rotate_left[1]()
            vec1 = x1.join(y1)
            return vec0.reduce_mul[size]() - vec1.reduce_mul[size]()
        else:
            s_vec_l = self.vec
            o_vec_l = other.vec

            @parameter
            for i in range(2):
                s_vec_l[capacity + i] = self.vec[i]
                o_vec_l[capacity + i] = other.vec[i]

            x0 = s_vec_l.shift_left[1]()
            y1 = o_vec_l.shift_left[1]()

            y0 = o_vec_l.shift_left[2]()
            vec0 = x0.join(y0)
            x1 = s_vec_l.shift_left[2]()
            vec1 = x1.join(y1)
            return vec0.reduce_mul[size]() - vec1.reduce_mul[size]()

    fn map[
        D: DType
    ](owned self, func: fn (Self._scalar) -> Scalar[D]) -> Array[
        D, capacity, static
    ]:
        """Apply a function to the Array and return it.

        Parameters:
            D: The Dtype of the map return.

        Args:
            func: The function to apply.

        Returns:
            The altered Array.

        Examples:
        ```mojo
        from forge_tools.collections.array import Array

        fn mapfunc(a: Int8) -> Scalar[DType.bool]:
            return a < 3

        arr = Array[DType.int8, 3](3, 2, 1)
        print(arr.map(mapfunc)) # [False, True, True]
        %# from testing import assert_equal
        %# assert_equal(str(arr.map(mapfunc)), "[False, True, True]")
        ```
        .
        """

        @parameter
        if D != T:
            # FIXME: experimental
            res_p = UnsafePointer[Scalar[D]].alloc(Self.simd_size)
            alias size = Self._slice_simd_size

            for i in range(len(self), Self.simd_size):
                res_p[i] = Scalar[D](0)
            s_p = self.unsafe_ptr()

            for i in range(len(self)):
                res_p[i] = func(s_p[i])

            res = Array[D, capacity, static](
                unsafe_pointer=res_p, length=len(self), unsafe_simd_size=True
            )
            res_p.free()
            s_p.free()
            return res

        res = Array[D, capacity, static](fill=0)
        alias size = Self._slice_simd_size

        @parameter
        for i in range(Self.simd_size // size):
            alias offset = i * size
            sliced = self.vec.slice[size, offset=offset]()

            @parameter
            if static:

                @parameter
                for j in range(size):
                    res.vec[offset + j] = func(sliced[j])

            else:
                for j in range(min(size, (len(self) - offset))):
                    res.vec[offset + j] = func(sliced[j])

        @parameter
        if not static:
            res.capacity_left = capacity - len(self)
        return res

    fn apply(
        mut self,
        func: fn (Self._scalar) -> Self._scalar,
    ):
        """Apply a function to the Array inplace.

        Args:
            func: The function to apply.

        Examples:
        ```mojo
        from forge_tools.collections.array import Array
        arr = Array[DType.int8, 3](3, 2, 1)
        fn applyfunc(a: Int8) -> Int8:
            return a * 2
        arr.apply(applyfunc)
        print(arr) # [6, 4, 2]
        %# from testing import assert_equal
        %# assert_equal(str(arr), "[6, 4, 2]")
        ```
        .
        """

        self = self.map(func)

    fn apply(
        mut self,
        func: fn (Self._scalar) -> Self._scalar,
        *,
        where: fn (Self._scalar) -> Scalar[DType.bool],
    ):
        """Apply a function to the Array inplace where condition is True.

        Args:
            func: The function to apply.
            where: The condition to apply the function.

        Notes:
            The function gets applied to all values before masking. So division
            or modulo by 0 would still fail even if condition where False.

        Examples:
        ```mojo
        from forge_tools.collections.array import Array
        arr = Array[DType.int8, 3](3, 2, 1)

        fn filterfunc(a: Int8) -> Scalar[DType.bool]:
            return a < 3

        fn applyfunc(a: Int8) -> Int8:
            return a * 2

        arr.apply(applyfunc, where=filterfunc)
        print(arr) # [3, 4, 2]
        %# from testing import assert_equal
        %# assert_equal(str(arr), "[3, 4, 2]")
        ```
        .
        """

        res1 = self.map(func).vec
        res2 = self.map(where).vec
        self.vec *= (~res2).cast[T]()
        self.vec += res1 * (res2).cast[T]()

    fn filter(
        owned self, func: fn (Self._scalar) -> Scalar[DType.bool]
    ) -> Array[T, capacity, False]:
        """Filter the Array and return it.

        Args:
            func: The function to filter by.

        Returns:
            The filtered Array.

        Examples:
        ```mojo
        from forge_tools.collections.array import Array
        fn filterfunc(a: Int8) -> Scalar[DType.bool]:
            return a < 3

        arr = Array[DType.int8, 3](3, 2, 1)
        print(arr.filter(filterfunc)) # [2, 1]
        %# from testing import assert_equal
        %# assert_equal(str(arr.filter(filterfunc)), "[2, 1]")
        ```
        .
        """

        res_p = UnsafePointer[Scalar[T]].alloc(Self.simd_size)
        alias size = Self._slice_simd_size

        @parameter
        for i in range(Self.simd_size // size):
            res_p.store(i * size, SIMD[T, size](0))
        s_p = self.unsafe_ptr()
        idx = 0
        for i in range(len(self)):
            val = s_p[i]
            if func(val):
                res_p[idx] = val
                idx += 1

        res = Array[T, capacity, False](
            unsafe_pointer=res_p, length=(idx + 1), unsafe_simd_size=True
        )
        res_p.free()
        s_p.free()
        return res
