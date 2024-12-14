from documentation import doc_private
from collections import Optional
from memory.unsafe_pointer import _default_alignment, UnsafePointer
from memory import stack_allocation
from os import abort


trait SafePointer:
    """Trait for generic safe pointers."""

    # TODO: this needs parametrized __getitem__, unsafe_ptr() etc.

    @staticmethod
    @always_inline
    fn alloc(count: Int) -> Self:
        """Allocate memory according to the pointer's logic.

        Args:
            count: The number of elements in the buffer.

        Returns:
            The pointer to the newly allocated buffer.
        """
        ...

    fn __del__(owned self):
        """Free the memory referenced by the pointer or ignore."""
        ...


@value
struct Pointer[
    is_mutable: Bool, //,
    type: AnyType,
    origin: Origin[is_mutable],
    address_space: AddressSpace = AddressSpace.GENERIC,
]:
    """Defines a base pointer.

    Safety:
        This is not thread safe. This is not reference counted. When doing an
        explicit copy from another pointer, the self_is_owner flag is set to
        False.
    """

    alias _mlir_type = __mlir_type[
        `!lit.ref<`,
        type,
        `, `,
        origin,
        `, `,
        address_space._value.value,
        `>`,
    ]

    var _mlir_value: Self._mlir_type
    """The underlying MLIR representation."""
    var _flags: UInt8
    """Bitwise flags for the pointer.
    
    #### Bits:

    - 0: in_registers: Whether the pointer is allocated in registers.
    - 1: is_allocated: Whether the pointer's memory is allocated.
    - 2: is_initialized: Whether the memory is initialized.
    - 3: self_is_owner: Whether the pointer owns the memory.
    - 4: unset.
    - 5: unset.
    - 6: unset.
    - 7: unset.
    """

    # ===------------------------------------------------------------------===#
    # Initializers
    # ===------------------------------------------------------------------===#

    fn __init__(out self):
        self = Self(
            ptr=UnsafePointer[type, address_space](),
            is_allocated=False,
            in_registers=False,
            is_initialized=False,
            self_is_owner=True,
        )

    @doc_private
    @always_inline("nodebug")
    fn __init__(
        out self,
        *,
        _mlir_value: Self._mlir_type,
        is_allocated: Bool,
        in_registers: Bool = False,
        is_initialized: Bool = True,
        self_is_owner: Bool = True,
    ):
        """Constructs a Pointer from its MLIR prepresentation.

        Args:
            _mlir_value: The MLIR representation of the pointer.
            is_allocated: Whether the pointer's memory is allocated.
            in_registers: Whether the pointer is allocated in registers.
            is_initialized: Whether the memory is initialized.
            self_is_owner: Whether the pointer owns the memory.
        """
        self._mlir_value = _mlir_value
        self._flags = (
            (UInt8(in_registers) << 7)
            | (UInt8(is_allocated) << 6)
            | (UInt8(is_initialized) << 5)
            | (UInt8(self_is_owner) << 4)
        )

    @staticmethod
    @always_inline("nodebug")
    fn address_of(ref [origin, address_space._value.value]value: type) -> Self:
        """Constructs a Pointer from a reference to a value.

        Args:
            value: The value to get the address of.

        Returns:
            The result Pointer.
        """
        return Pointer(
            _mlir_value=__get_mvalue_as_litref(value),
            is_allocated=True,
            in_registers=True,
            is_initialized=True,
            self_is_owner=False,
        )

    fn __init__(out self, *, other: Self):
        """Constructs a copy from another Pointer **(not the data)**.

        Args:
            other: The `Pointer` to copy.
        """
        self._mlir_value = other._mlir_value
        self._flags = other._flags & 0b1110_1111

    @doc_private
    @always_inline("nodebug")
    fn __init__(
        out self,
        *,
        ptr: UnsafePointer[type, address_space],
        is_allocated: Bool,
        in_registers: Bool,
        is_initialized: Bool,
        self_is_owner: Bool,
    ):
        """Constructs a Pointer from an UnsafePointer.

        Args:
            ptr: The UnsafePointer.
            is_allocated: Whether the pointer's memory is allocated.
            in_registers: Whether the pointer is allocated in registers.
            is_initialized: Whether the memory is initialized.
            self_is_owner: Whether the pointer owns the memory.
        """
        self = __type_of(self)(
            _mlir_value=__mlir_op.`lit.ref.from_pointer`[
                _type = __type_of(self)._mlir_type
            ](ptr.address),
            is_allocated=is_allocated,
            in_registers=in_registers,
            is_initialized=is_initialized,
            self_is_owner=self_is_owner,
        )

    @staticmethod
    @always_inline
    fn alloc(count: Int) -> Self:
        """Allocate memory according to the pointer's logic.

        Args:
            count: The number of elements in the buffer.

        Returns:
            The pointer to the newly allocated buffer.
        """
        return Self(
            ptr=UnsafePointer[type, address_space]
            .alloc(count)
            .bitcast[address_space=address_space](),
            is_allocated=True,
            in_registers=False,
            is_initialized=False,
            self_is_owner=True,
        )

    @staticmethod
    @always_inline
    fn alloc[
        count: Int,
        /,
        O: MutableOrigin,
        *,
        stack_alloc_limit: Int = 1 * 2**20,
        name: Optional[StringLiteral] = None,
    ]() -> Pointer[type, O, address_space]:
        """Allocate an array on the stack with specified or default alignment.

        Parameters:
            count: The number of elements in the array.
            O: The origin of the Pointer.
            stack_alloc_limit: The limit of bytes to allocate on the stack
                (default 1 MiB).
            name: The name of the global variable (only honored in certain
                cases).

        Returns:
            The pointer to the newly allocated array.
        """
        return Pointer[type, O, address_space](
            ptr=stack_allocation[count, type, address_space=address_space](),
            is_allocated=True,
            in_registers=True,
            is_initialized=True,
            self_is_owner=True,
        )

    fn bitcast[
        T: AnyType = Self.type
    ](self) -> Pointer[T, origin, address_space] as output:
        """Bitcasts a `Pointer` to a different type.

        Parameters:
            T: The target type.

        Returns:
            A new `Pointer` object with the specified type and the same address,
            as the original `Pointer`.
        """
        alias P = Pointer[T, MutableAnyOrigin, address_space]
        s = rebind[Pointer[T, MutableAnyOrigin, address_space]](self)
        output = rebind[__type_of(output)](
            P(
                ptr=s.unsafe_ptr().bitcast[T](),
                is_allocated=s.is_allocated,
                in_registers=s.in_registers,
                is_initialized=s.is_initialized,
                self_is_owner=s.self_is_owner,
            )
        )

    fn unsafe_ptr(self) -> UnsafePointer[type, address_space] as output:
        """Get a raw pointer to the underlying data.

        Returns:
            The raw pointer to the data.
        """
        p = __mlir_op.`lit.ref.to_pointer`(self._mlir_value)
        output = __type_of(output)(rebind[__type_of(output)._mlir_type](p))

    @always_inline
    fn __getattr__[name: StringLiteral](self) -> Bool:
        """Get the attribute.

        Parameters:
            name: The name of the attribute.

        Returns:
            The attribute value.
        """

        @parameter
        if name == "in_registers":
            return bool((self._flags >> 7) & 0b1)
        elif name == "is_allocated":
            return bool((self._flags >> 6) & 0b1)
        elif name == "is_initialized":
            return bool((self._flags >> 5) & 0b1)
        elif name == "self_is_owner":
            return bool((self._flags >> 4) & 0b1)
        else:
            constrained[False, "unknown attribute"]()
            return abort[Bool]()

    @always_inline
    fn __setattr__[name: StringLiteral](out self, value: Bool):
        """Set the attribute.

        Parameters:
            name: The name of the attribute.

        Args:
            value: The value to set the attribute to.
        """

        @parameter
        if name == "in_registers":
            self._flags &= (UInt8(value) << 7) | 0b0111_1111
        elif name == "is_allocated":
            self._flags &= (UInt8(value) << 6) | 0b1011_1111
        elif name == "is_initialized":
            self._flags &= (UInt8(value) << 5) | 0b1101_1111
        elif name == "self_is_owner":
            self._flags &= (UInt8(value) << 4) | 0b1110_1111
        else:
            constrained[False, "unknown attribute"]()

    fn __bool__(self) -> Bool:
        return (self._flags & 0b0110_0000) == 0b0110_0000

    fn __int__(self) -> Int:
        return int(
            rebind[Pointer[type, MutableAnyOrigin, address_space]](
                self
            ).unsafe_ptr()
        )

    fn __del__(owned self):
        @parameter
        if address_space is AddressSpace.GENERIC and is_mutable:
            if self._flags & 0b1101_0000 == 0b0101_0000:
                p = __mlir_op.`lit.ref.to_pointer`(self._mlir_value)
                alias UP = UnsafePointer[
                    type, AddressSpace.GENERIC, _default_alignment[type]()
                ]
                UP(rebind[UP._mlir_type](p)).free()
                self._flags &= 0b0001_1111
