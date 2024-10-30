"""Arena Pointer module."""

from memory import UnsafePointer, memset
from collections import Optional
from utils import Span
from sys.info import bitwidthof, simdwidthof
from os import abort
from .pointer import Pointer


@value
struct ArenaPointer[
    is_mutable: Bool, //,
    type: AnyType,
    origin: Origin[is_mutable].type,
    address_space: AddressSpace = AddressSpace.GENERIC,
]:
    """Arena Pointer.

    Safety:
        This is not thread safe.
    """

    var _free_slots: UnsafePointer[Byte]
    """Bits indicating whether the slot is free."""
    var _len: Int
    """In the case of a parent ArenaPointer, this is the amount of bits set in
    the _free_slots pointer. In the case of a child ArenaPointer, it is the
    length of its given _ptr."""
    alias _P = Pointer[type, origin, address_space]
    var _ptr: Self._P
    """The data."""
    var parent: Optional[UnsafePointer[Int]]
    """The address of the parent ArenaPointer's free slots."""

    # TODO: __getitem__ should check whether parent is alive (self.parent.value())

    fn __init__(inout self):
        self.parent = None
        self._free_slots = UnsafePointer[Byte]()
        self._len = 0
        self._ptr = Pointer[type, origin, address_space]()

    @doc_private
    @always_inline("nodebug")
    fn __init__(
        inout self,
        *,
        ptr: UnsafePointer[type, address_space],
        is_allocated: Bool,
        in_registers: Bool,
        is_initialized: Bool,
        length: Int,
    ):
        """Constructs an ArenaPointer from an UnsafePointer.

        Args:
            ptr: The UnsafePointer.
            is_allocated: Whether the pointer's memory is allocated.
            in_registers: Whether the pointer is allocated in registers.
            is_initialized: Whether the memory is initialized.
            length: The length of the pointer.
        """
        self._ptr = Self._P(
            ptr=ptr,
            is_allocated=is_allocated,
            in_registers=in_registers,
            is_initialized=is_initialized,
            self_is_owner=True,
        )
        amnt = length // 8 + int(length < 8)
        p = UnsafePointer[Byte].alloc(amnt)
        memset(p, 0xFF, amnt)
        self._free_slots = p
        self._len = length // 8 + length % 8
        self.parent = None

    fn __init__(inout self, *, ptr: Self._P, length: Int, parent: Int):
        """Constructs an ArenaPointer from a Pointer.

        Args:
            ptr: The Pointer.
            length: The length of the pointer.
            parent: The parent pointer.
        """

        p = rebind[Pointer[type, MutableAnyOrigin, address_space]](ptr)
        self._ptr = Self._P(
            ptr=p.unsafe_ptr(),
            is_allocated=ptr.is_allocated,
            in_registers=ptr.in_registers,
            is_initialized=ptr.is_initialized,
            self_is_owner=False,
        )
        self._free_slots = UnsafePointer[Byte]()
        self._len = length
        par = UnsafePointer[Int].alloc(1)
        par.init_pointee_copy(parent)
        self.parent = par

    @staticmethod
    @always_inline
    fn alloc[
        O: MutableOrigin
    ](count: Int) -> ArenaPointer[type, O, address_space]:
        """Allocate an array with specified or default alignment.

        Parameters:
            O: The origin of the Pointer.

        Args:
            count: The number of elements in the array.

        Returns:
            The pointer to the newly allocated array.
        """
        return ArenaPointer[type, O, address_space](
            ptr=UnsafePointer[type]
            .alloc(count)
            .bitcast[address_space=address_space, origin=O](),
            is_allocated=True,
            in_registers=False,
            is_initialized=False,
            length=count,
        )

    @always_inline
    fn alloc[
        O: MutableOrigin
    ](
        inout self: ArenaPointer[type, O, address_space], count: Int
    ) -> __type_of(self):
        """Allocate an array with specified or default alignment.

        Parameters:
            O: The origin of the Pointer.

        Args:
            count: The number of elements in the array.

        Returns:
            The pointer to the newly allocated array.
        """
        if self.parent:
            return __type_of(self).alloc[O](count)
        alias int_bitwidth = bitwidthof[Int]()
        alias int_simdwidth = simdwidthof[Int]()
        mask = Scalar[DType.index](0)
        for i in range(min(count, int_bitwidth)):
            mask |= 1 << (int_bitwidth - i)

        alias widths = (128, 64, 32, 16, 8)
        ptr = self._free_slots.bitcast[DType.index]()
        num_bytes = self._len // 8 + int(self._len < 8)
        amnt = UInt8(0)
        start = 0

        @parameter
        for i in range(len(widths)):
            alias w = widths.get[i, Int]()

            @parameter
            if simdwidthof[Int]() >= w:
                rest = num_bytes - start
                for _ in range(rest // w):
                    vec = (ptr + start).load[width=w]()
                    res = vec == mask
                    if res.reduce_or():
                        amnt = res.cast[DType.uint8]().reduce_add()
                        break
                    start += w

        if amnt * int_bitwidth < count:
            # TODO: realloc parent
            # TODO: return call alloc
            abort("support for realloc is still in development")

        if start == num_bytes:
            return __type_of(self)()

        p = self._free_slots.offset(start // 8)
        mask = ~mask
        remaining = count - int_bitwidth
        if remaining > int_bitwidth:
            while remaining > int_bitwidth:
                p = p + remaining - int_bitwidth
                new_value = (
                    p.bitcast[Scalar[DType.index]]().load[width=int_simdwidth]()
                    & mask
                )
                p.store(0, new_value.cast[DType.uint8]())
                remaining -= int_bitwidth
            mask = 0
            for i in range(remaining):
                mask |= 1 << (int_bitwidth - i)
            mask = ~mask
        new_value = (
            p.bitcast[Scalar[DType.index]]().load[width=int_simdwidth]() & mask
        )
        p.store(0, new_value.cast[DType.uint8]())

        return __type_of(self)(
            ptr=__type_of(self)._P(
                ptr=self._ptr.unsafe_ptr() + start,
                is_allocated=self._ptr.is_allocated,
                in_registers=self._ptr.in_registers,
                is_initialized=self._ptr.is_initialized,
                self_is_owner=False,
            ),
            length=count,
            parent=int(self),
        )

    fn __int__(self) -> Int:
        return int(self._ptr)

    fn __bool__(self) -> Bool:
        return bool(self._ptr)

    fn __del__(owned self):
        """Free the memory referenced by the pointer or ignore."""

        self._free_slots.free()

        @parameter
        if not (address_space is AddressSpace.GENERIC and is_mutable):
            return  # self._ptr frees itself
        if not self.parent:
            return  # self._ptr frees itself
        p = self.parent.value()
        parent_free_slots_addr = 0
        if not p:
            return  # parent is dead
        else:
            parent_free_slots_addr = p[0]
            p.free()
        s = int(self)
        self_start = s // 8 + s % 8
        self_end = self._len
        # TODO: mark as freed
