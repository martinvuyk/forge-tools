"""Arena Pointer module."""

from memory import UnsafePointer, memset
from collections import Optional
from utils import Span
from sys.info import bitwidthof, simdwidthof
from os import abort
from .arc_pointer import ArcPointer


struct GladiatorPointer[
    is_mutable: Bool, //,
    type: AnyType,
    origin: Origin[is_mutable].type,
    address_space: AddressSpace = AddressSpace.GENERIC,
]:
    """Gladiator Pointer that resides in an Arena."""

    alias _P = UnsafePointer[type, address_space]
    var _ptr: Self._P
    """The Master data pointer."""
    var _start: Int
    """The absolute starting offset from the master pointer."""
    var _len: Int
    """The length of the pointer."""
    var _master_is_alive: ArcPointer[UnsafePointer[Bool]]
    """A pointer to determine whether the master is alive."""
    var _free_slots: UnsafePointer[Byte]
    """The pointer to the ArenaMasterPointer's free slots."""

    # TODO: __getitem__ should check whether _master_is_alive etc.

    fn __init__(inout self):
        self._free_slots = UnsafePointer[Byte]()
        self._start = 0
        self._len = 0
        self._ptr = Self._P()
        self._master_is_alive = UnsafePointer[Bool].alloc(1)
        self._master_is_alive[0] = False

    fn __init__(
        inout self,
        *,
        ptr: Self._P,
        start: Int,
        length: Int,
        master_is_alive: ArcPointer[UnsafePointer[Bool]],
        free_slots: UnsafePointer[Byte],
    ):
        """Constructs a GladiatorPointer from a Pointer.

        Args:
            ptr: The Master data pointer.
            start: The absolute starting offset from the master pointer.
            length: The length of the pointer.
            master_is_alive: A pointer to determine whether the master is alive.
            free_slots: The pointer to the ArenaMasterPointer's free slots.
        """

        self._ptr = ptr
        self._start = start
        self._len = length
        self._master_is_alive = master_is_alive
        self._free_slots = free_slots

    @staticmethod
    @always_inline
    fn alloc(count: Int) -> Self:
        """Allocate memory according to the pointer's logic.

        Args:
            count: The number of elements in the buffer.

        Returns:
            The pointer to the newly allocated buffer.
        """
        return Self(ptr=Self._P.alloc(count), length=count)

    fn __del__(owned self):
        """Free the memory referenced by the pointer or ignore."""
        if not self._master_is_alive:
            return
        elif not self._master_is_alive[0]:
            return
        p0 = self._free_slots - self._start
        full_byte_start = self._start // 8
        full_byte_end = self._len // 8
        memset(p0 + full_byte_start, 0xFF, full_byte_end)
        mask = 0
        for i in range(full_byte_end, full_byte_end + self._start % 8):
            mask |= 1 << (bitwidthof[Int]() - i)
        p0[full_byte_end] = p0[full_byte_end] | mask

    fn __int__(self) -> Int:
        return int(self._ptr)

    fn __bool__(self) -> Bool:
        return bool(self._ptr)


@value
struct ArenaMasterPointer[
    is_mutable: Bool, //,
    type: AnyType,
    origin: Origin[is_mutable].type,
    address_space: AddressSpace = AddressSpace.GENERIC,
]:
    """Arena Master Pointer that deallocates the arena when deleted."""

    var _free_slots: UnsafePointer[Byte]
    """Bits indicating whether the slot is free."""
    var _len: Int
    """The amount of bits set in the _free_slots pointer."""
    alias _P = UnsafePointer[type, address_space]
    var _ptr: Self._P
    """The data."""
    var _master_is_alive: ArcPointer[UnsafePointer[Bool]]
    """A pointer to determine whether the master is alive."""
    alias _G = GladiatorPointer[type, origin, address_space]

    fn __init__(inout self):
        self._free_slots = UnsafePointer[Byte]()
        self._len = 0
        self._ptr = Self._P()
        self._master_is_alive = UnsafePointer[Bool].alloc(1)
        self._master_is_alive[0] = True

    @doc_private
    @always_inline("nodebug")
    fn __init__(inout self, *, ptr: Self._P, length: Int):
        """Constructs an ArenaPointer from an UnsafePointer.

        Args:
            ptr: The UnsafePointer.
            length: The length of the pointer.
        """
        self._ptr = ptr
        amnt = length // 8 + int(length < 8)
        p = UnsafePointer[Byte].alloc(amnt)
        memset(p, 0xFF, amnt)
        self._free_slots = p
        self._len = length // 8 + length % 8
        self._master_is_alive = UnsafePointer[Bool].alloc(1)
        self._master_is_alive[0] = True

    @staticmethod
    @always_inline
    fn alloc(count: Int) -> Self:
        """Allocate memory according to the pointer's logic.

        Args:
            count: The number of elements in the buffer.

        Returns:
            The pointer to the newly allocated buffer.
        """
        return Self(ptr=Self._P.alloc(count), length=count)

    @always_inline
    fn alloc(inout self, count: Int) -> Self._G:
        """Allocate an array with specified or default alignment.

        Args:
            count: The number of elements in the array.

        Returns:
            The pointer to the newly allocated array.
        """

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
            return GladiatorPointer[type, origin, address_space]()

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

        return __type_of(self)._G(
            ptr=self._ptr,
            start=start,
            length=count,
            master_is_alive=self._master_is_alive,
            free_slots=self._free_slots,
        )

    fn unsafe_ptr(self) -> UnsafePointer[type, address_space]:
        alias P = Pointer[type, MutableAnyOrigin, address_space]
        return self._ptr.bitcast[address_space=address_space]()

    fn __int__(self) -> Int:
        return int(self._ptr)

    fn __bool__(self) -> Bool:
        return bool(self._ptr)

    fn __del__(owned self):
        """Free the memory referenced by the pointer or ignore."""
        self._free_slots.free()
        self._master_is_alive[0] = False  # mark as deleted first
        self._ptr.free()


@value
struct ArenaRcPointer[
    is_mutable: Bool, //,
    type: AnyType,
    origin: Origin[is_mutable].type,
    address_space: AddressSpace = AddressSpace.GENERIC,
]:
    """Arena Reference Counted Pointer that deallocates the arena when it's the
    last one.

    Safety:
        This is not thread safe.
    """

    ...


@value
struct ArenaArcPointer[
    is_mutable: Bool, //,
    type: AnyType,
    origin: Origin[is_mutable].type,
    address_space: AddressSpace = AddressSpace.GENERIC,
]:
    """Arena Atomic Reference Counted Pointer that deallocates the arena when
    it's the last one.
    """

    ...
