"""JSON Reader module."""

from memory import UnsafePointer
from sys.intrinsics import unlikely
from utils.string_slice import StringSlice, _StringSliceIter
from utils.span import Span
from .json import JsonInstance, JsonType


# TODO: UTF-16. _StringSliceIter should actually support it, then this code stays unchanged
struct Reader[
    origin: Origin[False].type,
    allow_trailing_comma: Bool = True,
    allow_c_whitespace: Bool = True,
]:
    """A JSON reader.

    Parameters:
        origin: The immutable origin of the data.
        allow_trailing_comma: Whether to allow (ignore) trailing comma or fail.
        allow_c_whitespace: Whether to allow c whitespace, since it is faster.
    """

    alias _Sp = Span[Byte, origin]
    var _buffer: Self._Sp

    fn __init__(inout self, buffer: Self._Sp):
        """Construct an immutable Reader from a buffer.

        Args:
            buffer: The buffer to read from.
        """
        self._buffer = buffer

    @staticmethod
    fn get_json_instance(
        span: Self._Sp, start: UInt = 0
    ) -> JsonInstance[origin] as output:
        """Get the `JsonInstance` starting at start **skipping over starting
        whitespace**.

        Args:
            span: The span to look into.
            start: The absolute offset in bytes to start reading a valid
                `JsonType`.

        Returns:
            The `JsonInstance` beginning at the start character until its end
            character.

        Notes:
            This only validates the content of the instance, not if it has a
            trailing whitespace, comma, etc.
        """

        # object
        alias `{` = Byte(ord("{"))
        alias `}` = Byte(ord("}"))
        # array
        alias `[` = Byte(ord("["))
        alias `]` = Byte(ord("]"))
        # string
        alias `"` = Byte(ord('"'))
        # digit
        alias `0` = Byte(ord("0"))
        alias `9` = Byte(ord("9"))
        alias `-` = Byte(ord("-"))
        # bool
        alias `t` = Byte(ord("t"))
        alias `f` = Byte(ord("f"))
        # null, NaN, Inf
        alias `n` = Byte(ord("n"))
        alias `N` = Byte(ord("N"))
        alias `I` = Byte(ord("I"))

        ptr = span.unsafe_ptr()
        alias J = JsonInstance
        var invalid = J(JsonType.invalid, Self._sp(ptr + start, 0))

        debug_assert(start < len(span), "start is `>=` buffer length")
        iterator = StringSlice[origin](
            ptr=ptr + start, length=len(span) - start
        ).__iter__()
        if not iterator.__has_next__():
            output = invalid
            return
        char = iterator.__next__()
        length = UInt(0)
        while (
            char.byte_length() == 1
            and Self.isspace(char.unsafe_ptr()[0])
            and iterator.__has_next__()
        ):
            char = iterator.__next__()
            length += 1
        if not char:
            output = invalid
            return
        start_ptr = char.unsafe_ptr()
        b0_char = start_ptr[0]
        if b0_char == `{`:
            if Self._is_closed[`}`](iterator, b0_char, length):
                output = J(JsonType.object, Self._sp(start_ptr, length))
                return
        elif b0_char == `[`:
            if Self._is_closed[`]`](iterator, b0_char, length):
                output = J(JsonType.array, Self._sp(start_ptr, length))
                return
        elif b0_char == `"`:
            b0_char = 0
            if Self._is_closed[`"`](iterator, b0_char, length):
                output = J(JsonType.string, Self._sp(start_ptr, length))
                return
        elif b0_char == `t`:
            alias `r` = Byte(ord("r"))
            alias `u` = Byte(ord("u"))
            alias `e` = Byte(ord("e"))
            if Self._is_valid[3, `r`, `u`, `e`](iterator):
                output = J(JsonType.true, Self._sp(start_ptr, 3))
                return
        elif b0_char == `f`:
            alias `a` = Byte(ord("a"))
            alias `l` = Byte(ord("l"))
            alias `s` = Byte(ord("s"))
            alias `e` = Byte(ord("e"))
            if Self._is_valid[4, `a`, `l`, `s`, `e`](iterator):
                output = J(JsonType.false, Self._sp(start_ptr, 4))
                return
        elif `0` <= b0_char <= `9`:
            return Self._validate_int_float(
                iterator, start_ptr, b0_char, length
            )
        elif b0_char == `n`:
            alias `u` = Byte(ord("u"))
            alias `l` = Byte(ord("l"))
            if Self._is_valid[3, `u`, `l`, `l`](iterator):
                output = J(JsonType.null, Self._sp(start_ptr, 3))
                return
        elif b0_char == `N`:
            alias `a` = Byte(ord("a"))
            if Self._is_valid[2, `a`, `N`](iterator):
                output = J(JsonType.NaN, Self._sp(start_ptr, 3))
                return
        elif b0_char == `-`:
            if not iterator.__has_next__():
                output = invalid
                return
            b0_char = iterator.__next__().unsafe_ptr()[0]

            if `0` <= b0_char <= `9`:
                return Self._validate_int_float(
                    iterator, start_ptr, b0_char, length
                )
            start_ptr -= 1
            length += 1

        if b0_char == `I`:
            alias `f` = Byte(ord("f"))
            alias `i` = Byte(ord("i"))
            alias `t` = Byte(ord("t"))
            alias `y` = Byte(ord("y"))
            if Self._is_valid[7, `n`, `f`, `i`, `n`, `i`, `t`, `y`](iterator):
                output = J(JsonType.Inf, Self._sp(start_ptr, length + 8))
                return
        output = invalid

    @always_inline
    @staticmethod
    fn _is_valid[
        amount: Int,
        b0: Byte,
        b1: Byte,
        b2: Byte = 0,
        b3: Byte = 0,
        b4: Byte = 0,
        b5: Byte = 0,
        b6: Byte = 0,
        b7: Byte = 0,
    ](inout iterator: _StringSliceIter) -> Bool:
        if not iterator.__has_next__():
            return False

        alias items = (b0, b1, b2, b3, b4, b5, b6, b7)

        @parameter
        for i in range(amount):
            b0_char = iterator.__next__().unsafe_ptr()[0]
            if not iterator.__has_next__() or b0_char != items.get[i, Byte]():
                return False
        return True

    @always_inline
    @staticmethod
    fn _is_closed[
        closing_byte: Byte
    ](
        inout iterator: _StringSliceIter,
        inout b0_char: Byte,
        inout length: UInt,
    ) -> Bool:
        while b0_char != closing_byte:
            if not iterator.__has_next__():
                return False
            char = rebind[StringSlice[origin]](iterator.__next__())
            b0_char = char.unsafe_ptr()[0]
            length += char.byte_length()
        return True

    @always_inline
    @staticmethod
    fn _validate_int_float(
        inout iterator: _StringSliceIter[origin],
        start_ptr: UnsafePointer[Byte],
        owned b0_char: Byte,
        owned length: UInt,
    ) -> JsonInstance[origin] as output:
        # digit
        alias `0` = Byte(ord("0"))
        alias `9` = Byte(ord("9"))
        alias `-` = Byte(ord("-"))
        # float
        alias `.` = Byte(ord("."))
        alias `e` = Byte(ord("e"))
        alias `E` = Byte(ord("E"))
        alias `+` = Byte(ord("+"))
        alias exponents = SIMD[DType.uint8, 2](`e`, `E`)
        invalid = JsonInstance(JsonType.invalid, Self._sp(start_ptr, 0))

        while `0` <= b0_char <= `9`:
            if not iterator.__has_next__():
                break
            b0_char = iterator.__next__().unsafe_ptr()[0]
            length += 1
        length += 1
        if b0_char == `.`:
            b0_char = `0`
            while `0` <= b0_char <= `9`:
                if not iterator.__has_next__():
                    break
                b0_char = iterator.__next__().unsafe_ptr()[0]
                length += 1
            output = JsonInstance(
                JsonType.float_dot, Self._sp(start_ptr, length)
            )
            return
        elif b0_char in exponents:
            if not iterator.__has_next__():
                output = invalid
                return
            b0_char = iterator.__next__().unsafe_ptr()[0]
            alias num_signs = SIMD[DType.int8, 2](1, -1)
            alias str_signs = SIMD[DType.uint8, 2](`+`, `-`)
            comparison = (str_signs == b0_char).cast[DType.int8]()
            sign = (comparison * num_signs).reduce_or()
            if sign * int(iterator.__has_next__()) == 0:
                output = invalid
                return
            length += 1
            b0_char = iterator.__next__().unsafe_ptr()[0]

            while `0` <= b0_char <= `9`:
                if not iterator.__has_next__():
                    break
                b0_char = iterator.__next__().unsafe_ptr()[0]
                length += 1
            output = JsonInstance(
                JsonType.float_exp, Self._sp(start_ptr, length)
            )
            return
        output = JsonInstance(JsonType.int, Self._sp(start_ptr, length))
        return

    @always_inline
    @staticmethod
    fn isspace(char: Byte) -> Bool:
        """Whether the given character byte is whitespace.

        Args:
            char: The given character byte.

        Returns:
            Whether the given character byte is whitespace.
        """

        alias ` ` = Byte(ord(" "))
        alias `\n` = Byte(ord("\n"))
        alias `\t` = Byte(ord("\t"))
        alias `\r` = Byte(ord("\r"))

        @parameter
        if allow_c_whitespace:
            return (`\n` <= char <= `\r`) or char == ` `
        else:
            return char == ` ` or char == `\n` or char == `\t` or char == `\r`

    @always_inline
    @staticmethod
    fn _sp(ptr: UnsafePointer[Byte], length: Int) -> Span[Byte, origin]:
        return Span[Byte, origin](unsafe_ptr=ptr, len=length)

    @staticmethod
    fn find(span: Self._Sp, key: StringSlice) -> JsonInstance[origin] as output:
        """Find a json value by key: `"` + `name` + `"`.

        Args:
            span: The buffer.
            key: The key.

        Returns:
            The JsonInstance on the right side of the key.

        Notes:
            This looks for the first occurrence of the key.
        """
        alias `:` = Byte(ord(":"))
        # key_idx =  self._buffer.find[unsafe_dont_normalize=True](key)
        key_idx = -1
        p = span.unsafe_ptr()
        invalid = JsonInstance(JsonType.invalid, Self._sp(p, 0))
        if key_idx == -1:
            output = invalid
            return
        colon_idx = key_idx + key.byte_length()
        iterator = StringSlice[origin](
            ptr=p, length=len(span) - key_idx
        ).__iter__()
        if not iterator.__has_next__():
            output = invalid
            return
        colon_idx += 1
        char = iterator.__next__()
        if unlikely(Self.isspace(char.unsafe_ptr()[0])):
            if not iterator.__has_next__():
                output = invalid
                return
            char = iterator.__next__()
            colon_idx += 1
        if unlikely(not char.unsafe_ptr()[0] == `:`):
            output = invalid
            return
        output = Self.get_json_instance(span, colon_idx + 1)
