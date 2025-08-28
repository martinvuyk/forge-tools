"""Reference Counted Pointer module."""

from memory import UnsafePointer
from .pointer import Pointer
from .rc import Rc


struct RcPointer[
    is_mutable: Bool, //,
    type: AnyType,
    origin: Origin[is_mutable.value].type,
    address_space: AddressSpace = AddressSpace.GENERIC,
](Copyable, Movable):
    """Reference Counted Pointer.

    Safety:
        This is not thread safe.
    """

    alias _P = Pointer[type, origin, address_space]
    alias _U = UnsafePointer[type, address_space]
    var _ptr: Rc[Self._P]

    @doc_private
    @always_inline("nodebug")
    fn __init__(
        out self,
        *,
        ptr: Self._U,
        is_allocated: Bool,
        in_registers: Bool,
        is_initialized: Bool,
    ):
        """Constructs an RcPointer from an UnsafePointer.

        Args:
            ptr: The UnsafePointer.
            is_allocated: Whether the pointer's memory is allocated.
            in_registers: Whether the pointer is allocated in registers.
            is_initialized: Whether the memory is initialized.
        """
        self._ptr = Rc(
            Self._P(
                ptr=ptr,
                is_allocated=is_allocated,
                in_registers=in_registers,
                is_initialized=is_initialized,
                self_is_owner=True,
            )
        )

    fn __init__(out self, *, ptr: Self._P):
        """Constructs a Pointer from an Pointer.

        Args:
            ptr: The Pointer.
        """
        self._ptr = Rc(ptr)

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
            ptr=Self._U.alloc(count).bitcast[address_space=address_space](),
            is_allocated=True,
            in_registers=False,
            is_initialized=False,
        )

    fn __del__(deinit self):
        """Free the memory referenced by the pointer or ignore."""

        @parameter
        if address_space is AddressSpace.GENERIC and is_mutable:
            alias P = Pointer[type, MutableAnyOrigin, AddressSpace.GENERIC]
            if self._ptr.count() == 1:
                p = rebind[P](self._ptr)
                p._flags = p._flags | 0b0101_0000
                self._ptr = rebind[__type_of(self)._P](p)
