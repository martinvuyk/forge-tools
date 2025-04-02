"""Arena Pointer module."""

from memory import UnsafePointer, memset, stack_allocation
from collections import Optional
from memory import Span
from sys.info import bitwidthof, simdwidthof
from sys.ffi import OpaquePointer
from os import abort
from .arc_pointer import ArcPointer


struct GladiatorPointer[
    is_mutable: Bool, //,
    type: AnyType,
    origin: Origin[is_mutable],
    address_space: AddressSpace = AddressSpace.GENERIC,
]:
    """Gladiator Pointer (Weak Arena Pointer) that resides in an Arena."""

    alias _U = UnsafePointer[type, address_space]
    alias _C = ColosseumPointer[type, origin, address_space]
    alias _A = ArcPointer[UnsafePointer[OpaquePointer], origin, address_space]
    var _colosseum: Self._A
    """A pointer to the collosseum."""
    var _start: Int
    """The absolute starting offset from the colosseum pointer."""
    var _len: Int
    """The length of the pointer."""

    fn __init__(out self):
        self._colosseum = Self._A(
            ptr=stack_allocation[1, Self._C]().bitcast[OpaquePointer](),
            is_allocated=True,
            in_registers=True,
            is_initialized=True,
        )
        self._start = 0
        self._len = 0

    fn __init__(out self, *, colosseum: Self._A, start: Int, length: Int):
        """Constructs a GladiatorPointer from a Pointer.

        Args:
            colosseum: A pointer to the colosseum.
            start: The absolute starting offset from the colosseum pointer.
            length: The length of the pointer.
        """

        self._colosseum = colosseum
        self._start = start
        self._len = length

    @staticmethod
    @always_inline
    fn alloc(count: Int) -> Self:
        """Allocate memory according to the pointer's logic.

        Args:
            count: The number of elements in the buffer.

        Returns:
            The pointer to the newly allocated buffer.
        """
        return (
            self._colosseum._ptr.unsafe_ptr()[][]
            .bitcast[Self._C]()
            .alloc(count)
        )

    fn __del__(owned self):
        """Free the memory referenced by the pointer or ignore."""
        self._colosseum._ptr.unsafe_ptr()[].bitcast[Self._C]()[]._free(self^)

    fn __int__(self) -> Int:
        return Int(self._colosseum._ptr.unsafe_ptr()[])

    fn __bool__(self) -> Bool:
        return Bool(self._colosseum._ptr.unsafe_ptr()[])


@value
struct ColosseumPointer[
    is_mutable: Bool, //,
    type: AnyType,
    origin: Origin[is_mutable],
    address_space: AddressSpace = AddressSpace.GENERIC,
]:
    """Colosseum Pointer (Arena Owner Pointer) that deallocates the arena when
    deleted."""

    var _free_slots: UnsafePointer[Byte]
    """Bits indicating whether the slot is free."""
    var _len: Int
    """The amount of bits set in the _free_slots pointer."""
    alias _P = UnsafePointer[type, address_space]
    var _ptr: Self._P
    """The data."""
    alias _S = ArcPointer[UnsafePointer[OpaquePointer], origin, address_space]
    var _self_ptr: Self._S
    """A self pointer."""
    alias _G = GladiatorPointer[type, origin, address_space]

    fn __init__(out self):
        self._free_slots = UnsafePointer[Byte]()
        self._len = 0
        self._ptr = Self._P()
        self._self_ptr = Self._S.alloc(1)

    fn __init__(out self, *, owned other: Self):
        self._free_slots = other._free_slots
        self._len = other._len
        self._ptr = other._ptr
        self._self_ptr = other._self_ptr

    @doc_private
    @always_inline("nodebug")
    fn __init__(out self, *, ptr: Self._P, length: Int):
        """Constructs an ArenaPointer from an UnsafePointer.

        Args:
            ptr: The UnsafePointer.
            length: The length of the pointer.
        """
        s = Self()
        s._ptr = ptr
        amnt = length // 8 + Int(length < 8)
        p = UnsafePointer[Byte].alloc(amnt)
        memset(p, 0xFF, amnt)
        s._free_slots = p
        s._len = length // 8 + length % 8
        s._self_ptr = Self._S(
            UnsafePointer.address_of(s).bitcast[OpaquePointer]()
        )
        self = Self(other=s)

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
    fn alloc(out self, count: Int) -> Self._G:
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
        num_bytes = self._len // 8 + Int(self._len < 8)
        amnt = UInt8(0)
        start = 0

        @parameter
        for i in range(len(widths)):
            alias w = widths[i]

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
            owner_is_alive=self._owner_is_alive,
            free_slots=self._free_slots,
        )

    fn _free(out self, owned gladiator: Self._G):
        p0 = self._free_slots - gladiator._start
        full_byte_start = gladiator._start // 8
        full_byte_end = gladiator._len // 8
        memset(p0 + full_byte_start, 0xFF, full_byte_end)
        mask = 0
        for i in range(full_byte_end, full_byte_end + gladiator._start % 8):
            mask |= 1 << (bitwidthof[Int]() - i)
        p0[full_byte_end] = p0[full_byte_end] | mask

    fn unsafe_ptr(self) -> UnsafePointer[type, address_space]:
        alias P = Pointer[type, MutableAnyOrigin, address_space]
        return self._ptr.bitcast[address_space=address_space]()

    fn __int__(self) -> Int:
        return Int(self._ptr)

    fn __bool__(self) -> Bool:
        return Bool(self._ptr)

    fn __del__(owned self):
        """Free the memory referenced by the pointer or ignore."""
        self._free_slots.free()
        self._owner_is_alive[0] = False  # mark as deleted first
        self._ptr.free()


@value
struct SpartacusPointer[
    is_mutable: Bool, //,
    type: AnyType,
    origin: Origin[is_mutable],
    address_space: AddressSpace = AddressSpace.GENERIC,
]:
    """Reference Counted Arena Pointer that deallocates the arena when it's the
    last one.

    Safety:
        This is not thread safe.

    Notes:
        Spartacus is arguably the most famous Roman gladiator, a tough fighter
        who led a massive slave rebellion. After being enslaved and put through
        gladiator training school, an incredibly brutal place, he and 78 others
        revolted against their master Batiatus using only kitchen knives.
        [Source](
        https://www.historyextra.com/period/roman/who-were-roman-gladiators-famous-spartacus-crixus/
        ).
    """

    ...


@value
struct FlammaPointer[
    is_mutable: Bool, //,
    type: AnyType,
    origin: Origin[is_mutable],
    address_space: AddressSpace = AddressSpace.GENERIC,
]:
    """Atomic Reference Counted Arena Pointer that deallocates the arena when
    it's the last one.

    Notes:
        Gladiators were usually slaves, and Flamma came from the faraway
        province of Syria. However, the fighting lifestyle seemed to suit him
        well - he was offered his freedom four times, after winning 21 battles,
        but refused it and continued to entertain the crowds of the Colosseum
        until he died aged 30. His face was even used on coins. [Source](
        https://www.historyextra.com/period/roman/who-were-roman-gladiators-famous-spartacus-crixus/
        ).
    """

    ...
