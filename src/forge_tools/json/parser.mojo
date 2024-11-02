"""JSON Parser module."""

from math import log
from bit import bit_ceil
from utils.string_slice import StringSlice, _StringSliceIter
from utils.span import Span
from sys.info import bitwidthof


# TODO: UTF-16
struct Parser[
    origin: Origin[False].type,
    allow_trailing_comma: Bool = True,
    allow_c_whitespace: Bool = True,
    maximum_int_bitwidth: UInt = bitwidthof[Int](),
]:
    """A JSON Parser.

    Parameters:
        origin: The immutable origin of the data.
        allow_trailing_comma: Whether to allow (ignore) trailing comma or fail.
        allow_c_whitespace: Whether to allow c whitespace, since it is faster.
        maximum_int_bitwidth: The maximum int bitwidth to consider for parsing.
    """

    alias _Sp = Span[Byte, origin]
    var _buffer: Self._Sp

    @staticmethod
    fn _parse_num(
        inout iterator: _StringSliceIter[origin],
    ) -> (Int8, UInt8, Int):
        constrained[
            maximum_int_bitwidth < bitwidthof[Int](),
            "more than bitwidth[Int]() not supported",
        ]()
        alias `0` = Byte(ord("0"))
        alias `9` = Byte(ord("9"))
        alias `-` = Byte(ord("-"))
        debug_assert(iterator.__hasmore__(), "iterator has no more values")
        b0_char = iterator.__next__().unsafe_ptr()[0]
        sign = Int8(1)
        if b0_char == `-`:
            sign = -1
            debug_assert(iterator.__hasmore__(), "iterator has no more values")
            b0_char = iterator.__next__().unsafe_ptr()[0]

        alias w = bit_ceil(log(2**maximum_int_bitwidth))
        alias base_10_multipliers = _get_base_10_multipliers[DType.uint8, w]()
        values = SIMD[DType.uint8, w](0x30)
        idx = UInt8(0)
        while iterator.__hasmore__():
            debug_assert(`0` <= b0_char <= `9`, "value is not a  digit")
            values[idx] = b0_char
            idx += 1
            b0_char = iterator.__next__().unsafe_ptr()[0]

        v = _align_base_10[w](values ^ 0x30, idx)
        result = (v * base_10_multipliers).cast[DType.uint64]().reduce_add()
        return sign, idx, int(sign) * int(result)

    @staticmethod
    fn parse_int(span: Self._Sp) -> Int:
        """Parse an Int from the start of the span **with no leading
        whitespace and assuming it was validated previously**.

        Args:
            span: The span from beginning to the end of the value.

        Returns:
            The result.
        """
        iterator = StringSlice(unsafe_from_utf8=span).__iter__()
        return Self._parse_num(iterator)[2]

    @staticmethod
    fn parse_float_dot(span: Self._Sp) -> Float64:
        """Parse a Float64 from the start of the span **with no leading
        whitespace and assuming it was validated previously**.

        Args:
            span: The span from beginning to the end of the value.

        Returns:
            The result.
        """

        iterator = StringSlice(unsafe_from_utf8=span).__iter__()
        sign, _, whole = Self._parse_num(iterator)
        debug_assert(iterator.__hasmore__(), "iterator has no more values")
        _ = iterator.__next__()  # dot
        _, idx, decimal = Self._parse_num(iterator)
        return Float64(whole) + Float64(sign) * Float64(decimal) / 10**idx

    @staticmethod
    fn parse_float_exp(span: Self._Sp) -> Float64:
        """Parse a Float64 from the start of the span **with no leading
        whitespace and assuming it was validated previously**.

        Args:
            span: The span from beginning to the end of the value.

        Returns:
            The result.
        """

        alias `0` = Byte(ord("0"))
        alias `9` = Byte(ord("9"))
        iterator = StringSlice(unsafe_from_utf8=span).__iter__()
        whole = Self._parse_num(iterator)[2]
        debug_assert(iterator.__hasmore__(), "iterator has no more values")
        _ = iterator.__next__()  # e or E
        exponent = Self._parse_num(iterator)[2]
        return Float64(whole) * Float64(10) ** Float64(exponent)


fn _get_base_10_multipliers[D: DType, width: Int]() -> SIMD[D, width]:
    values = SIMD[D, width](0)

    @parameter
    for i in reversed(range(width)):
        values[i] = 10**i


fn _align_base_10[
    w: Int
](v: SIMD[DType.uint8, w], idx: Int) -> SIMD[DType.uint8, w]:
    @parameter
    for i in range(w):
        if idx == i:
            return v.rotate_left[i]()
