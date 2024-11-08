"""JSON Parser module."""

from math import log10
from bit import bit_ceil
from collections import Dict
from utils import Span
from utils.string_slice import StringSlice, _StringSliceIter
from sys.info import bitwidthof

from .json import JsonInstance, JsonType


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
    alias _J = JsonInstance[origin]
    alias _R = Reader[origin, allow_trailing_comma, allow_c_whitespace]
    var _buffer: Self._Sp

    @staticmethod
    fn parse_object(instance: Self._J) -> Dict[String, Self._J] as output:
        """Parse an object from the start of the span **with no leading
        whitespace and assuming the start and end were validated previously**.

        Args:
            instance: The JsonInstance.

        Returns:
            The result.

        Notes:
            If allow_trailing_comma is False and the object contains one, the
            return is an empty `Dict[String, JsonInstance]`.
        """

        alias `}` = Byte(ord("}"))
        alias `,` = Byte(ord(","))
        alias `"` = Byte(ord('"'))
        alias `\\` = Byte(ord("\\"))
        debug_assert(
            instance.type is JsonType.object, "instance type is not object"
        )
        items = __type_of(output)()
        iterator = StringSlice(unsafe_from_utf8=instance.buffer).__iter__()
        b0_char = iterator.__next__().unsafe_ptr()[0]
        start_ptr = instance.buffer.unsafe_ptr()
        total_length = len(instance.buffer)
        offset = 1
        while offset < total_length:
            length = 0
            is_escaped = False
            while not (b0_char == `"` and not is_escaped):
                if not iterator.__has_next__():
                    break
                char = iterator.__next__()
                b0_char = char.unsafe_ptr()[0]
                is_escaped = not is_escaped and b0_char == `\\`
                length += char.byte_length()
            name = str(
                StringSlice[origin](ptr=start_ptr + offset, length=length)
            )
            offset += length
            item = Reader[
                origin, allow_trailing_comma, allow_c_whitespace
            ].get_json_instance(instance.buffer, offset)
            items[name] = item
            offset += len(item.buffer)
            iterator = StringSlice[origin](
                ptr=start_ptr + offset, length=total_length - offset
            ).__iter__()

            # skip whitespace and find next comma
            if not iterator.__has_next__():
                break
            char = iterator.__next__()
            b0_char = char.unsafe_ptr()[0]
            while (
                char.byte_length() == 1
                and Self._R.isspace(b0_char)
                and iterator.__has_next__()
            ):
                char = iterator.__next__()
                b0_char = char.unsafe_ptr()[0]
                offset += 1
            if not b0_char == `,`:
                break

        @parameter
        if not allow_trailing_comma:
            if b0_char == `,`:
                return __type_of(output)()

        return items^

    @staticmethod
    fn parse_array(instance: Self._J) -> List[Self._J] as output:
        """Parse an array from the start of the span **with no leading
        whitespace and assuming the start and end were validated previously**.

        Args:
            instance: The JsonInstance.

        Returns:
            The result.

        Notes:
            If allow_trailing_comma is False and the array contains one, the
            return is an empty `List[JsonInstance]`.
        """

        alias `}` = Byte(ord("}"))
        alias `,` = Byte(ord(","))
        alias `"` = Byte(ord('"'))
        alias `\\` = Byte(ord("\\"))
        debug_assert(
            instance.type is JsonType.array, "instance type is not array"
        )
        items = __type_of(output)()
        iterator = StringSlice(unsafe_from_utf8=instance.buffer).__iter__()
        b0_char = iterator.__next__().unsafe_ptr()[0]
        start_ptr = instance.buffer.unsafe_ptr()
        total_length = len(instance.buffer)
        offset = 1
        while offset < total_length:
            item = Reader[
                origin, allow_trailing_comma, allow_c_whitespace
            ].get_json_instance(instance.buffer, offset)
            items.append(item)
            offset += len(item.buffer)
            iterator = StringSlice[origin](
                ptr=start_ptr + offset, length=total_length - offset
            ).__iter__()

            # skip whitespace and find next comma
            if not iterator.__has_next__():
                break
            char = iterator.__next__()
            b0_char = char.unsafe_ptr()[0]
            while (
                char.byte_length() == 1
                and Self._R.isspace(b0_char)
                and iterator.__has_next__()
            ):
                char = iterator.__next__()
                b0_char = char.unsafe_ptr()[0]
                offset += 1
            if not b0_char == `,`:
                break

        @parameter
        if not allow_trailing_comma:
            if b0_char == `,`:
                return __type_of(output)()

        return items^

    @staticmethod
    fn _parse_num(inout iterator: _StringSliceIter[origin]) -> (Int8, Int, Int):
        constrained[
            maximum_int_bitwidth <= bitwidthof[Int](),
            "can't parse an Int bigger than bitwidth[Int]()",
        ]()
        alias `0` = Byte(ord("0"))
        alias `9` = Byte(ord("9"))
        alias `-` = Byte(ord("-"))
        debug_assert(iterator.__has_next__(), "iterator has no more values")
        b0_char = iterator.__next__().unsafe_ptr()[0]
        sign = Int8(1)
        if b0_char == `-`:
            sign = -1
            debug_assert(iterator.__has_next__(), "iterator has no more values")
            b0_char = iterator.__next__().unsafe_ptr()[0]

        alias Si = Scalar[DType.index]
        alias w = int(bit_ceil(log10(Si(2**maximum_int_bitwidth))))
        alias base_10_multipliers = _get_base_10_multipliers[DType.uint8, w]()
        values = SIMD[DType.uint8, w](0x30)
        idx = 0
        while iterator.__has_next__():
            debug_assert(`0` <= b0_char <= `9`, "value is not a  digit")
            values[idx] = b0_char
            idx += 1
            b0_char = iterator.__next__().unsafe_ptr()[0]

        v = _align_base_10[w](values ^ 0x30, idx)
        result = (v * base_10_multipliers).cast[DType.uint64]().reduce_add()
        return sign, idx, int(sign) * int(result)

    @staticmethod
    fn parse_int(instance: Self._J) -> Int:
        """Parse an Int from the start of the span **with no leading
        whitespace and assuming the start and end were validated previously**.

        Args:
            instance: The JsonInstance.

        Returns:
            The result.
        """

        debug_assert(instance.type is JsonType.int, "instance type is not int")
        iterator = StringSlice(unsafe_from_utf8=instance.buffer).__iter__()
        return Self._parse_num(iterator)[2]

    @staticmethod
    fn parse_float_dot(instance: Self._J) -> Float64:
        """Parse a Float64 from the start of the span **with no leading
        whitespace and assuming the start and end were validated previously**.

        Args:
            instance: The JsonInstance.

        Returns:
            The result.
        """

        debug_assert(
            instance.type is JsonType.float_dot,
            "instance type is not float_dot",
        )
        iterator = StringSlice(unsafe_from_utf8=instance.buffer).__iter__()
        sign, _, whole = Self._parse_num(iterator)
        debug_assert(iterator.__has_next__(), "iterator has no more values")
        _ = iterator.__next__()  # dot
        _, idx, decimal = Self._parse_num(iterator)
        return (
            Float64(whole)
            + sign.cast[DType.float64]() * Float64(decimal) / 10**idx
        )

    @staticmethod
    fn parse_float_exp(instance: Self._J) -> Float64:
        """Parse a Float64 from the start of the span **with no leading
        whitespace and assuming the start and end were validated previously**.

        Args:
            instance: The JsonInstance.

        Returns:
            The result.
        """

        alias `0` = Byte(ord("0"))
        alias `9` = Byte(ord("9"))
        debug_assert(
            instance.type is JsonType.float_exp,
            "instance type is not float_exp",
        )
        iterator = StringSlice(unsafe_from_utf8=instance.buffer).__iter__()
        whole = Self._parse_num(iterator)[2]
        debug_assert(iterator.__has_next__(), "iterator has no more values")
        _ = iterator.__next__()  # e or E
        exponent = Self._parse_num(iterator)[2]
        return Float64(whole) * Float64(10) ** Float64(exponent)


fn _get_base_10_multipliers[D: DType, width: Int]() -> SIMD[D, width]:
    values = SIMD[D, width](0)

    @parameter
    for i in reversed(range(width)):
        values[i] = 10**i
    return values


fn _align_base_10[
    w: Int
](v: SIMD[DType.uint8, w], idx: Int) -> SIMD[DType.uint8, w]:
    @parameter
    for i in range(w):
        if idx == i:
            return v.rotate_left[i]()
    return SIMD[DType.uint8, w](0)