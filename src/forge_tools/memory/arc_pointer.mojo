"""Atomic Reference Counted Pointer module."""

from memory.arc import Arc
from memory import UnsafePointer
from .pointer import Pointer


@value
struct ArcPointer[
    is_mutable: Bool, //,
    type: AnyType,
    origin: Origin[is_mutable.value].type,
    address_space: AddressSpace = AddressSpace.GENERIC,
]:
    """Atomic Reference Counted Pointer."""

    alias _P = Pointer[type, origin, address_space]
    var _ptr: Arc[Self._P]

    @doc_private
    @always_inline("nodebug")
    fn __init__(
        inout self,
        *,
        ptr: UnsafePointer[type, address_space],
        is_allocated: Bool,
        in_registers: Bool,
        is_initialized: Bool,
    ):
        """Constructs an ArcPointer from an UnsafePointer.

        Args:
            ptr: The UnsafePointer.
            is_allocated: Whether the pointer's memory is allocated.
            in_registers: Whether the pointer is allocated in registers.
            is_initialized: Whether the memory is initialized.
        """
        self._ptr = Arc(
            Self._P(
                ptr=ptr,
                is_allocated=is_allocated,
                in_registers=in_registers,
                is_initialized=is_initialized,
            )
        )

    fn __init__(inout self, *, ptr: Self._P):
        """Constructs a Pointer from an Pointer.

        Args:
            ptr: The Pointer.
        """
        self._ptr = Arc(ptr)

    @staticmethod
    @always_inline
    fn alloc[
        O: MutableOrigin
    ](count: Int) -> ArcPointer[type, O, address_space]:
        """Allocate an array with specified or default alignment.

        Parameters:
            O: The origin of the Pointer.

        Args:
            count: The number of elements in the array.

        Returns:
            The pointer to the newly allocated array.
        """
        return ArcPointer[type, O, address_space](
            ptr=UnsafePointer[type]
            .alloc(count)
            .bitcast[address_space=address_space, origin=O](),
            is_allocated=True,
            in_registers=False,
            is_initialized=False,
        )

    fn free[O: MutableOrigin](inout self: ArcPointer[type, O, address_space]):
        """Free the memory referenced by the pointer.

        Parameters:
            O: The mutable origin.

        Safety:
            Pointer is not reference counted, so any dereferencing of another
            pointer to this same address that was copied before the free is
            **not safe**.
        """

        @parameter
        if address_space is AddressSpace.GENERIC:
            alias P = Pointer[type, O, AddressSpace.GENERIC]
            if self._ptr.count() == 1:
                rebind[P](self._ptr.unsafe_ptr()[0]).free()

    fn __del__(owned self):
        self.free()
