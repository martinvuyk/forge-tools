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
alias Arr = Array[DType.uint8, 3, True]
var a = Arr(1, 2, 3)
var b = Arr(1, 2, 3)
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
a.apply(applyfunc)
print(a) # [6, 4, 2]

print(a.concat(a.reversed() // 2)) # [6, 4, 2, 1, 2, 3]
```
"""

from math import sqrt, acos, sin
from algorithm import vectorize

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

    fn __next__(
        inout self,
    ) -> Scalar[T]:
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


fn _closest_upper_pow_2(val: Int) -> Int:
    var v = val
    v -= 1
    v |= v >> 1
    v |= v >> 2
    v |= v >> 4
    v |= v >> 8
    v |= v >> 16
    v += 1
    return v


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
    alias Arr = Array[DType.uint8, 3, True]
    var a = Arr(1, 2, 3)
    var b = Arr(1, 2, 3)
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
    a.apply(applyfunc)
    print(a) # [6, 4, 2]

    print(a.concat(a.reversed() // 2)) # [6, 4, 2, 1, 2, 3]
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
            methods like append(), extend(), concat(), etc. do.
    """

    alias _simd_size = _closest_upper_pow_2(capacity)
    alias _vec_type = SIMD[T, Self._simd_size]
    var vec: Self._vec_type
    """The underlying SIMD vector."""
    alias _scalar = Scalar[T]
    var capacity_left: UInt8
    """The current capacity left."""
    # TODO: should be per system
    alias fits_in_page_size = capacity * T.bitwidth() <= 64 * 64
    """Whether the Array fits in the system's page size."""

    @always_inline
    fn __init__(inout self):
        """This constructor creates an empty Array.

        Constraints:
            Maximum capacity is 256.
        """

        constrained[capacity <= 256, "Maximum capacity is 256."]()
        self.vec = Self._vec_type(0)

        @parameter
        if static:
            self.capacity_left = 0
        else:
            self.capacity_left = capacity

    @always_inline
    fn __init__(inout self, *, fill: Self._scalar):
        """Constructs an Array by filling it with the
        given value. Sets the capacity_left var to 0.

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
    fn __init__(inout self, *values: Self._scalar):
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
            for i in range(capacity):
                self.vec[i] = values[i]
            self.capacity_left = 0
        else:
            self.vec = Self._vec_type(0)
            self.capacity_left = capacity
            for i in range(len(values)):
                self.vec[i] = values[i]
                self.capacity_left -= 1

    fn __init__[
        size: Int
    ](
        inout self,
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
        if static and size == Self._simd_size:
            self.vec = rebind[Self._vec_type](values)
            self.capacity_left = 0
        elif static:
            self.vec = Self._vec_type(0)

            @parameter
            for i in range(min(size, capacity)):
                self.vec[i] = values[i]
            self.capacity_left = 0
        elif size == Self._simd_size:
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
    ](inout self, owned existing: Array[D, cap, static]):
        """Constructs an Array from an existing Array.

        Parameters:
            D: The DType of the elements that the Array holds.
            cap: The number of elements that the Array can hold.

        Args:
            existing: The existing Array.

        Constraints:
            Maximum capacity is 256.
        """

        constrained[capacity <= 256, "Maximum capacity is 256."]()

        @parameter
        if D == T and existing._vec_type.size == Self._simd_size:
            self.vec = rebind[Self._vec_type](existing.vec)
            self.capacity_left = 0

            @parameter
            if capacity != existing.capacity:
                Self._mask_vec_capacity_delta(self.vec)
        elif existing._vec_type.size == Self._simd_size:
            self.vec = existing.vec.cast[T]()

            @parameter
            if capacity != existing.capacity:
                Self._mask_vec_capacity_delta(self.vec)
            self.capacity_left = 0
        else:
            self.vec = Self._vec_type(0)

            @parameter
            for i in range(min(existing._vec_type.size, Self._simd_size)):
                self.vec[i] = existing.vec[i]

            @parameter
            if existing.capacity > capacity:
                Self._mask_vec_capacity_delta(self.vec)
                self.capacity_left = 0
            elif existing.capacity < capacity:
                self.capacity_left = capacity - existing.capacity
            else:
                self.capacity_left = 0

    fn __init__(
        inout self,
        *,
        unsafe_pointer: UnsafePointer[Self._scalar],
        length: Int,
    ):
        """Constructs an Array from a pointer and its length.

        Args:
            unsafe_pointer: The pointer to the data.
            length: The number of elements pointed to.

        Constraints:
            Maximum capacity is 256.
        """

        constrained[capacity <= 256, "Maximum capacity is 256."]()
        var s = min(capacity, length)
        self.vec = Self._vec_type(0)
        for i in range(s):  # FIXME: is there no faster way?
            self.vec[i] = unsafe_pointer[i]

        @parameter
        if static:
            self.capacity_left = 0
        else:
            self.capacity_left = capacity - s

    fn __init__(inout self, existing: List[Self._scalar]):
        """Constructs an Array from an existing List.

        Args:
            existing: The existing List.

        Constraints:
            Maximum capacity is 256.
        """

        constrained[capacity <= 256, "Maximum capacity is 256."]()
        self = Self(unsafe_pointer=existing.unsafe_ptr(), length=len(existing))
        _ = existing

    fn __init__[size: Int](inout self, owned existing: List[Self._scalar]):
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
            capacity == Self._simd_size,
            "Array capacity must be power of 2.",
        ]()
        constrained[size == capacity, "Size must be == capacity."]()
        self.vec = SIMD[T, size].load(DTypePointer(existing.steal_data()))
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
            return int(capacity - self.capacity_left)

    @always_inline
    fn append(inout self, owned value: Self._scalar):
        """Appends a value to the Array. If full, sets
        the last element to the given value.

        Args:
            value: The value to append.

        Constaints:
            Array can't be static.
        """

        constrained[not static, "Array can't be static."]()
        if self.capacity_left == 0:
            self.unsafe_set(capacity - 1, value)
            return
        self.unsafe_set(len(self), value)
        self.capacity_left -= 1

    @always_inline
    fn append[cap: Int](inout self, other: Array[T, cap, static]):
        """Appends the values of another Array up to Self.capacity.

        Parameters:
            cap: The capacity of the other Array.

        Args:
            other: The Array to append.

        Constraints:
            Array can't be static.
        """

        constrained[not static, "Array can't be static."]()
        for i in range(min(self.capacity_left, len(other))):
            self.append(other[i])

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

        @parameter
        if Self.fits_in_page_size:
            if value != 0:
                return (self.vec == value).reduce_or()
            var vec = self.vec
            Self._mask_vec_size[T, 1](vec, len(self))
            return (vec == value).reduce_or()
        else:
            for i in range(len(self)):
                if self.vec[i] == value:
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
        var arr = Arr(self.vec, length=len(self))
        arr.append(Arr(other.vec, length=len(other)))
        return arr

    fn __str__(self) -> String:
        """Returns a string representation of an `Array`.

        Returns:
            A string representation of the array.

        Examples:

        ```mojo
        from forge_tools.collections import Array
        print(str(Array[DType.uint8, 3](1, 2, 3)))
        ```
        .
        """
        # we do a rough estimation of the number of chars that we'll see
        # in the final string, we assume that str(x) will be at least one char.
        var minimum_capacity = (
            2  # '[' and ']'
            + len(self) * 3  # str(x) and ", "
            - 2  # remove the last ", "
        )
        var string_buffer = List[UInt8](capacity=minimum_capacity)
        string_buffer.append(0)  # Null terminator
        var result = String(string_buffer^)
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
        var my_array = Array[DType.uint8, 3](1, 2, 3)
        print(repr(my_array))
        ```
        .
        """
        return str(self)

    @always_inline
    fn insert(inout self, i: Int, owned value: Self._scalar):
        """Inserts a value to the Array at the given index.
        `a.insert(len(a), value)` is equivalent to `a.append(value)`.

        Args:
            i: The index for the value.
            value: The value to insert.
        """

        debug_assert(
            abs(i) < capacity or i == -1 * capacity, "insert index out of range"
        )
        var norm_idx = min(i, capacity - 1) if i > -1 else max(0, capacity + i)

        var previous = value
        for i in range(norm_idx, capacity):
            var tmp = self.vec[i]
            self.vec[i] = previous
            previous = tmp
        if self.capacity_left > 0:
            self.capacity_left = min(
                self.capacity_left - 1, capacity - (norm_idx + 1)
            )

    fn pop(inout self, i: Int = -1) -> Self._scalar:
        """Pops a value from the Array at the given index.

        Args:
            i: The index of the value to pop.

        Returns:
            The popped value.

        Constraints:
            The Array can't be static.
        """

        constrained[not static, "The Array can't be static."]()
        var size = len(self)
        debug_assert(abs(i) < size or i == -1 * size, "pop index out of range")
        var norm_idx = min(i, size - 1) if i > -1 else max(0, size + i)
        self.capacity_left += 1
        var val = self.vec[norm_idx]
        for i in range(size - norm_idx):
            var offset = norm_idx + i
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
        var item = Array[DType.uint8, 3](1, 2, 3).index(2)
        print(item.or_else(-1)) # prints `1`
        ```
        .
        """

        fn from_range[simd_size: Int]() -> SIMD[DType.uint8, simd_size]:
            var vec = SIMD[DType.uint8, simd_size]()
            var idx = 0

            @parameter
            for i in range(simd_size - 1, -1, -1):
                vec[idx] = i
                idx += 1
            return vec

        alias indices = from_range[Self._simd_size]()
        var idx = (
            (self.vec == value).cast[DType.uint8]() * indices
        ).reduce_max()
        var res = Self._simd_size - int(idx)

        @parameter
        if capacity == 1:
            if idx == 0:
                return None

        @parameter
        if not static:
            if res > capacity - int(self.capacity_left):
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
        var item = Array[DType.uint8, 3](1, 2, 3).index(2, start=1)
        print(item.or_else(-1)) # prints `1`
        ```
        .
        """

        var size = len(self)
        debug_assert(
            abs(start) < size or start == -1 * size,
            "start index must be within bounds",
        )
        var start_norm = min(start, size - 1) if start > -1 else max(
            0, size + start
        )

        debug_assert(
            abs(stop) < size or stop == -1 * size,
            "stop index must be within bounds",
        )
        var stop_norm: Int = min(stop, size - 1) if stop > -1 else max(
            0, size + stop + 1
        )
        if start == stop_norm:  # FIXME
            return None
        var s = (self.vec == Self._vec_type(value))
        for i in range(start_norm, stop_norm):
            if s[i]:
                return i
        return None

    fn remove(inout self, value: Int):
        """Remove the first occurrence of value from the array.

        Args:
            value: The value.
        """
        var idx = self.index(value)
        if idx:
            _ = self.pop(idx.value())

    fn reverse(inout self):
        """Reverse the order of the items in the array inplace."""

        # @parameter
        # if not Self.fits_in_page_size:
        #     # TODO: pointer?

        fn from_range[simd_size: Int]() -> StaticIntTuple[simd_size]:
            var values = StaticIntTuple[simd_size]()
            var idx = 0

            @parameter
            for i in range(capacity - 1, -1, -1):
                values[idx] = i
                idx += 1

            @parameter
            for i in range(capacity, simd_size):
                values[i] = i
            return values

        var vec = self.vec.shuffle[from_range[Self._simd_size]()]()

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

        var start: Int
        var end: Int
        var step: Int
        start, end, step = span.indices(len(self))
        var r = range(start, end, step)

        if not len(r):
            return Self()

        var res = Self()
        for i in r:
            res.append(self[i])

        return res

    fn __setitem__(inout self, idx: Int, owned value: Self._scalar):
        """Sets an Array element at the given index. This will
        not update self.capacity_left.

        Args:
            idx: The index of the element.
            value: The value to assign.
        """
        debug_assert(
            abs(idx) < len(self) or idx == -1 * len(self),
            "index must be within bounds",
        )
        var norm_idx = min(idx, len(self) - 1) if idx > -1 else max(
            0, len(self) + idx
        )
        self.vec[norm_idx] = value

    @always_inline
    fn __getitem__(self, idx: Int) -> Self._scalar:
        """Gets a copy of the element at the given index.

        Args:
            idx: The index of the element.

        Returns:
            A copy of the element at the given index.
        """
        var size = len(self)
        debug_assert(-size <= idx < size, "index must be within bounds")
        # var norm_idx = min(idx, size - 1) if idx > -1 else max(0, size + idx)
        var norm_idx = idx if idx > -1 else max(0, size + idx)
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
        var my_array = Array[DType.uint8, 3](1, 2, 3)
        print(my_array.count(1)) # 1
        ```
        .
        """

        var null_amnt: UInt8 = 0
        if value == 0:
            null_amnt = self.capacity_left

        @parameter
        if capacity != Self._simd_size:
            var same = (self.vec == value).cast[DType.uint8]()
            Self._mask_vec_capacity_delta(same)
            return int(same.reduce_add() - null_amnt)
        else:
            var count = (self.vec == value).cast[DType.uint8]().reduce_add()
            return int(count - null_amnt)

    # FIXME: is this possible?
    # @always_inline
    # fn unsafe_ptr(self) -> UnsafePointer[Self._vec_type]:
    #     """Retrieves a pointer to the SIMD vector.

    #     Returns:
    #         The UnsafePointer to the SIMD vector.
    #     """
    #     return UnsafePointer[Self._scalar].address_of(self.vec)

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
    fn unsafe_set(inout self, idx: Int, value: Self._scalar):
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
            return self.vec.reduce_or()
        elif D != T:
            return self.vec.cast[D]().reduce_add()
        else:
            return self.vec.reduce_add()

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
            return bool(round(self.sum[DType.uint8]() / len(self)))
        return self.sum[D]() / len(self)

    @always_inline("nodebug")
    fn min(self) -> Self._scalar:
        """Calculates the minimum of all elements.

        Returns:
            The result.
        """

        var vec = self.vec

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
            vec = self.vec.min(rebind[Self._vec_type](other.vec))
        elif delta > 0:
            var o = Self(other)
            vec = self.vec.min(o.vec)
        else:
            vec = self.vec.min(other.vec.slice[Self._simd_size]())

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
            vec = self.vec.max(rebind[Self._vec_type](other.vec))
        elif delta > 0:
            var o = Self(other)
            vec = self.vec.max(o.vec)
        else:
            vec = self.vec.max(other.vec.slice[Self._simd_size]())

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
        D: DType = T, value: Scalar[D] = 0
    ](inout vec: SIMD[D, Self._simd_size]):
        @parameter
        for i in range(Self._simd_size - capacity):
            vec[capacity + i] = value

    @staticmethod
    fn _mask_vec_size[
        D: DType = T, value: Scalar[D] = 0
    ](inout vec: SIMD[D, Self._simd_size], length: Int = capacity):
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
        return Self(self.vec * other.vec, length=max(len(self), len(other)))

    @always_inline("nodebug")
    fn __imul__(inout self, other: Self):
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
        return Self(self.vec * value, length=len(self))

    @always_inline("nodebug")
    fn __imul__(inout self, owned value: Self._scalar):
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
    fn __itruediv__(inout self, owned value: Self._scalar):
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
    fn __ifloordiv__(inout self, owned value: Self._scalar):
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
    fn __imod__(inout self, owned value: Self._scalar):
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
    fn __ipow__(inout self, exp: Int):
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
            var vec = Self._vec_type(value)
            Self._mask_vec_capacity_delta(vec)
            return Self(self.vec + vec)
        else:
            var arr = Self(Self._vec_type(value), length=len(self))
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
            var vec = Self._vec_type(value)
            Self._mask_vec_capacity_delta(vec)
            return Self(self.vec - vec)
        else:
            var arr = Self(Self._vec_type(value), length=len(self))
            return Self(self.vec - arr.vec, length=len(self))

    @always_inline("nodebug")
    fn __iadd__(inout self, owned other: Self):
        """Computes the elementwise addition between the two Arrays
        inplace.

        Args:
            other: The other Array.
        """
        self.vec += other.vec

    @always_inline("nodebug")
    fn __iadd__(inout self, owned value: Self._scalar):
        """Computes the elementwise addition of the value.

        Args:
            value: The value to broadcast.
        """

        @parameter
        if static:
            var vec = Self._vec_type(value)
            Self._mask_vec_capacity_delta(vec)
            self.vec += vec
        else:
            var arr = Self(Self._vec_type(value), length=len(self))
            self.vec += arr.vec

    @always_inline("nodebug")
    fn __isub__(inout self, owned other: Self):
        """Computes the elementwise subtraction between the two Arrays
        inplace.

        Args:
            other: The other Array.
        """
        self.vec -= other.vec

    @always_inline("nodebug")
    fn __isub__(inout self, owned value: Self._scalar):
        """Computes the elementwise subtraction of the value.

        Args:
            value: The value to broadcast.
        """

        @parameter
        if static:
            var vec = Self._vec_type(value)
            Self._mask_vec_capacity_delta(vec)
            self.vec -= vec
        else:
            var arr = Self(Self._vec_type(value), length=len(self))
            self.vec -= arr.vec

    fn clear(inout self):
        """Zeroes the Array."""
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
        var vec = self.vec
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
        var vec = self.vec

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

        alias f = DType.float64

        @parameter
        if T.is_floating_point():
            var magn1 = (self.vec.cast[f]() ** 2).reduce_add()
            var magn2 = (other.vec.cast[f]() ** 2).reduce_add()
            return rebind[Float64](self.dot[f](other) / (magn1 * magn2))
        elif T.is_signed():
            var magn1 = (self.vec.cast[DType.int64]() ** 2).reduce_add()
            var magn2 = (other.vec.cast[DType.int64]() ** 2).reduce_add()
            return rebind[Float64](
                (self.dot[DType.int64](other) / (magn1 * magn2)).cast[f]()
            )
        else:
            var magn1 = (self.vec.cast[DType.uint64]() ** 2).reduce_add()
            var magn2 = (other.vec.cast[DType.uint64]() ** 2).reduce_add()
            return rebind[Float64](
                (self.dot[DType.uint64](other) / (magn1 * magn2)).cast[f]()
            )

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
            Array must be static.
        """

        constrained[not T.is_unsigned(), "Array can't be unsigned."]()
        constrained[static, "Array must be static."]()
        alias size = Self._simd_size

        @parameter
        if capacity == 3:
            var s = self.vec.shuffle[1, 2, 0, 3]()
            var o = other.vec.shuffle[2, 0, 1, 3]()
            return s.fma(o, -(s * other.vec).shuffle[1, 2, 0, 3]())
        elif capacity == size:
            var x0 = self.vec.rotate_left[1]()
            var y0 = other.vec.rotate_left[2]()
            var vec0 = x0.join(y0)
            var x1 = self.vec.rotate_left[2]()
            var y1 = other.vec.rotate_left[1]()
            var vec1 = x1.join(y1)
            return vec0.reduce_mul[size]() - vec1.reduce_mul[size]()
        else:
            var s_vec_l = self.vec
            var o_vec_l = other.vec

            @parameter
            for i in range(2):
                s_vec_l[capacity + i] = self.vec[i]
                o_vec_l[capacity + i] = other.vec[i]

            var x0 = s_vec_l.shift_left[1]()
            var y1 = o_vec_l.shift_left[1]()

            var y0 = o_vec_l.shift_left[2]()
            var vec0 = x0.join(y0)
            var x1 = s_vec_l.shift_left[2]()
            var vec1 = x1.join(y1)
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

        fn mapfunc(a: UInt8) -> Scalar[DType.bool]:
            return a < 3

        var arr = Array[DType.uint8, 3](3, 2, 1)
        print(arr.map(mapfunc)) # [False, True, True]
        %# from testing import assert_equal
        %# assert_equal(str(arr.map(mapfunc)), "[False, True, True]")
        ```
        .
        """

        alias amnt = Self._simd_size
        var res = SIMD[D, amnt](0)

        @parameter
        if Self.fits_in_page_size:

            @parameter
            fn closure[simd_width: Int](i: Int):
                res[i] = func(self.vec[i])

            vectorize[closure, 1, size=capacity, unroll_factor=amnt]()

        else:
            for i in range(len(self)):
                res[i] = func(self.vec[i])

        @parameter
        if static:
            return Array[D, capacity, static](res)
        else:
            return Array[D, capacity, static](res, length=len(self))

    fn apply(inout self, func: fn (Self._scalar) -> Self._scalar):
        """Apply a function to the Array inplace.

        Args:
            func: The function to apply.

        Examples:
        ```mojo
        from forge_tools.collections.array import Array
        var arr = Array[DType.uint8, 3](3, 2, 1)
        fn applyfunc(a: UInt8) -> UInt8:
            return a * 2
        arr.apply(applyfunc)
        print(arr) # [6, 4, 2]
        %# from testing import assert_equal
        %# assert_equal(str(arr), "[6, 4, 2]")
        ```
        .
        """

        @parameter
        if Self.fits_in_page_size:
            self = self.map(func)
        elif static:

            @parameter
            for i in range(capacity):
                self.vec[i] = func(self.vec[i])
        else:
            for i in range(len(self)):
                self.vec[i] = func(self.vec[i])

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
        fn filterfunc(a: UInt8) -> Scalar[DType.bool]:
            return a < 3

        var arr = Array[DType.uint8, 3](3, 2, 1)
        print(arr.filter(filterfunc)) # [2, 1]
        %# from testing import assert_equal
        %# assert_equal(str(arr.filter(filterfunc)), "[2, 1]")
        ```
        .
        """

        var res = Array[T, capacity, False]()
        var idx = 0

        @parameter
        if Self.fits_in_page_size:
            var vec = self.map(func)

            @parameter
            for i in range(capacity):
                if vec[i]:
                    res.vec[idx] = self.vec[i]
                    idx += 1
        else:
            for i in range(len(self)):
                if func(self.vec[i]):
                    res.vec[idx] = self.vec[i]
                    idx += 1

        res.capacity_left = capacity - (idx + 1)
        return res
