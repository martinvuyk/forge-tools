"""JSON Parser module."""

from math import log10, nan
from bit import next_power_of_two
from collections import Dict
from memory import Span
from utils.string_slice import StringSlice, _StringSliceIter
from sys.info import bitwidthof

from .json import JsonInstance, JsonType


# TODO: UTF-16
struct Parser[
    origin: Origin[False],
    allow_trailing_comma: Bool = True,
    allow_c_whitespace: Bool = True,
    maximum_int_bitwidth: UInt = bitwidthof[Int](),
]:
    """A JSON Parser.

    Parameters:
        origin: The immutable origin of the data.
        allow_trailing_comma: Whether to allow (ignore) trailing comma or
            set the instance type as empty (array/object).
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
            name = String(
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
    fn _parse_num(mut iterator: _StringSliceIter[origin]) -> (Int8, Int, Int):
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
        alias w = Int(next_power_of_two(log10(Si(2**maximum_int_bitwidth))))
        alias base_10_multipliers = _get_base_10_multipliers[DType.uint8, w]()
        values = SIMD[DType.uint8, w](`0`)
        idx = 0
        while iterator.__has_next__():
            debug_assert(`0` <= b0_char <= `9`, "value is not a  digit")
            values[idx] = b0_char
            idx += 1
            b0_char = iterator.__next__().unsafe_ptr()[0]

        v = _align_base_10[w](values ^ `0`, idx)
        result = (v * base_10_multipliers).cast[DType.index]().reduce_add()
        return sign, idx, Int(result)

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
        sign, _, num = Self._parse_num(iterator)
        return Int(sign) * num

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
        dot = iterator.__next__()
        debug_assert(dot == ".", "expected a dot")
        exp_sign, idx, decimal = Self._parse_num(iterator)
        return sign.cast[DType.float64]() * (
            Float64(whole) + Float64(decimal) * 10 ** (Int(exp_sign) * idx)
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
        sign, _, whole = Self._parse_num(iterator)
        debug_assert(iterator.__has_next__(), "iterator has no more values")
        exp_letter = iterator.__next__()
        debug_assert(
            exp_letter in ("e", "E"),
            "expected 'e' or 'E' as exponent start.",
        )
        exp_sign, _, exponent = Self._parse_num(iterator)
        return sign.cast[DType.float64]() * (
            Float64(whole) * 10 ** (Int(exp_sign) * exponent)
        )

    fn loads(self) raises -> object:
        """Parse Json from the start of the span. Evaluate arrays and objects
        recursively until everything is parsed.

        Returns:
            The result.

        Notes:
            If allow_trailing_comma is False and any object or array contains
            one, the item is set as empty.

            - `JsonType.object` -> `Dict[String, object]`.
            - `JsonType.array` -> `List[object]`.
            - `JsonType.string` -> `StringSlice[origin]`.
            - `JsonType.true`/`JsonType.false` -> `Bool`.
            - `JsonType.null` -> `None`.
            - `JsonType.invalid` -> `None`.
            - `JsonType.float_exp`/`JsonType.float_dot` -> `Float64`.
            - `JsonType.Inf` -> `Float64.MAX`/`Float64.MAX`.
            - `JsonType.NaN` -> `nan[DType.float64]()`.
            - `JsonType.int` -> `Int`.
            - `JsonType.whitespace` -> `" "`.
        """
        return Self.parse_instance(Self._R.get_json_instance(self._buffer))

    @staticmethod
    fn parse_instance(instance: Self._J) -> object as output:
        """Parse a JsonInstance from the start of the span **with no leading
        whitespace and assuming the start and end were validated previously**.

        Args:
            instance: The JsonInstance.

        Returns:
            The result.

        Notes:

            - `JsonType.object` -> `Dict[String, Self._J]`.
            - `JsonType.array` -> `List[Self._J]`.
            - `JsonType.string` -> `StringSlice[origin]`.
            - `JsonType.true`/`JsonType.false` -> `Bool`.
            - `JsonType.null` -> `None`.
            - `JsonType.invalid` -> `None`.
            - `JsonType.float_exp`/`JsonType.float_dot` -> `Float64`.
            - `JsonType.Inf` -> `Float64.MAX`/`Float64.MAX`.
            - `JsonType.NaN` -> `nan[DType.float64]()`.
            - `JsonType.int` -> `Int`.
            - `JsonType.whitespace` -> `" "`.
        """

        if instance.type is JsonType.object:
            obj = Dict[String, object]()
            for item in Self.parse_object(instance).items():
                obj[item[].key] = Self.parse_instance(item[].value)
            output = object(obj)
            return
        elif instance.type is JsonType.array:
            arr = List[object]()
            for item in Self.parse_array(instance):
                arr.append(Self.parse_instance(item[]))
            output = object(arr)
            return
        elif instance.type is JsonType.int:
            output = Self.parse_int(instance)
            return
        elif instance.type is JsonType.float_dot:
            output = Self.parse_float_dot(instance)
            return
        elif instance.type is JsonType.float_exp:
            output = Self.parse_float_exp(instance)
            return
        elif instance.type is JsonType.string:
            output = object(
                StringSlice[origin](
                    ptr=instance.buffer.unsafe_ptr() + 1,
                    length=len(instance.buffer) - 1,
                )
            )
            return
        elif instance.type is JsonType.true:
            output = True
            return
        elif instance.type is JsonType.false:
            output = False
            return
        elif instance.type is JsonType.Inf:
            output = Float64.MAX if len(instance.buffer) == 7 else Float64.MIN
            return
        elif instance.type is JsonType.NaN:
            output = nan[DType.float64]()
            return
        elif instance.type is JsonType.whitespace:
            output = " "
            return

        output = None

    fn find(self, key: String) -> object:
        """Find a json value by key.

        Args:
            key: The key.

        Returns:
            The JsonInstance on the right side of the key.

        Notes:
            This looks for the first occurrence of the key. Any invalid value is
            set to None.

            - `JsonType.object` -> `Dict[String, Self._J]`.
            - `JsonType.array` -> `List[Self._J]`.
            - `JsonType.string` -> `StringSlice[origin]`.
            - `JsonType.true`/`JsonType.false` -> `Bool`.
            - `JsonType.null` -> `None`.
            - `JsonType.invalid` -> `None`.
            - `JsonType.float_exp`/`JsonType.float_dot` -> `Float64`.
            - `JsonType.Inf` -> `Float64.MAX`/`Float64.MAX`.
            - `JsonType.NaN` -> `nan[DType.float64]()`.
            - `JsonType.int` -> `Int`.
            - `JsonType.whitespace` -> `" "`.
        """
        var full_key = '"' + key + '"'
        instance = self._R.find(self._buffer, full_key)
        return Self.parse_instance(instance)


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
