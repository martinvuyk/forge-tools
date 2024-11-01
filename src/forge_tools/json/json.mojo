"""Python-like JSON implementation.

### JSON specification:

(unescaped values are used to indicate sets)

Collection types have commas between content. Trailing commas are
dissallowed.

| Pseudotype    | Pseudocode set description |
|:--------------|:---------------------------|
|whitespace     | { SPACE, \\n, \\r, \\t }
|value          | { `Optional[whitespace]`, `Variant[string, number, object\
, array, true, false, null]`, `Optional[whitespace]` } |
|key_value      | { `string`, `Optional[whitespace]` , `:`, `value` } |
|object_content | { `Optional[whitespace]`, `Optional[key_value]` } |
|object         | { `{`, `Optional[object_content]`, `}` } |
|array_content  | { `Optional[whitespace]`, `value`,\
`Optional[whitespace]` } |
|array          | { `[`, `Optional[array_content]`, `]` } |
|string         | { `"`, `Optional[Variant[escaped_values, values]]`, `"` }|
|escaped_values | { `\\`, `Variant['"', '\\', '/', backspace, '\\f',\
'\\n', '\\r', '\\t', 'uHHHH']` } * |
|number         | { `Variant[int, float]` } |
|int            | { `Optional['-']`, `Optional['0']`, `Optional[digits]` } |
|float          | { `Optional['-']`, `Optional['0']`, `Optional[digits]`,\
Optional['.'], `Optional[digits]`, `Optional[ [ Variant['E', 'e'],\
Optional[Variant['+', '-']], digit, Optional[digits] ] ]` } |

*: note that `\\ANYTHING` is a single value, they are double only in
docstrings to escape them. 'uHHHH' is meant to be a u followed by 4
hexadecimal byte encoded values from unicode.
"""

from utils.span import Span
from utils.string_slice import StringSlice, _StringSliceIter
from memory import UnsafePointer

# TODO: write tests with https://github.com/miloyip/nativejson-benchmark/tree/master/data/jsonchecker
# TODO: read python impl https://github.com/python/cpython/blob/main/Lib/json/scanner.py


# TODO: enum
@value
struct JsonType:
    """A JSON type alias.

    ### JSON specification:

    (unescaped values are used to indicate sets)

    Collection types have commas between content. Trailing commas are
    dissallowed.

    | Pseudotype    | Pseudocode set description |
    |:--------------|:---------------------------|
    |whitespace     | { SPACE, \\n, \\r, \\t }
    |value          | { `Optional[whitespace]`, `Variant[string, number, object\
    , array, true, false, null]`, `Optional[whitespace]` } |
    |key_value      | { `string`, `Optional[whitespace]` , `:`, `value` } |
    |object_content | { `Optional[whitespace]`, `Optional[key_value]` } |
    |object         | { `{`, `Optional[object_content]`, `}` } |
    |array_content  | { `Optional[whitespace]`, `value`,\
    `Optional[whitespace]` } |
    |array          | { `[`, `Optional[array_content]`, `]` } |
    |string         | { `"`, `Optional[Variant[escaped_values, values]]`, `"` }|
    |escaped_values | { `\\`, `Variant['"', '\\', '/', backspace, '\\f',\
    '\\n', '\\r', '\\t', 'uHHHH']` } * |
    |number         | { `Variant[int, float]` } |
    |int            | { `Optional['-']`, `Optional['0']`, `Optional[digits]` } |
    |float          | { `Optional['-']`, `Optional['0']`, `Optional[digits]`,\
    Optional['.'], `Optional[digits]`, `Optional[ [ Variant['E', 'e'],\
    Optional[Variant['+', '-']], digit, Optional[digits] ] ]` } |

    *: note that `\\ANYTHING` is a single value, they are double only in
    docstrings to escape them. 'uHHHH' is meant to be a u followed by 4
    hexadecimal byte encoded values from unicode.
    """

    alias invalid = "INVALID"
    alias whitespace = "WHITESPACE"
    alias value = "VALUE"
    alias object = "OBJECT"
    alias array = "ARRAY"
    alias int = "INT"
    alias float = "FLOAT"
    alias null = "NULL"
    alias NaN = "NAN"
    alias Inf = "INFINITY"
    alias neg_Inf = "-INFINITY"
    alias string = "STRING"
    alias escaped_value = "ESCAPED_VALUE"
    var _selected: StringLiteral

    fn __init__(inout self, value: StringLiteral):
        """Construct a JsonType instance.

        Args:
            value: The `StringLiteral` value.
        """
        debug_assert(
            value
            in (
                Self.invalid,
                Self.whitespace,
                Self.value,
                Self.object,
                Self.array,
                Self.int,
                Self.float,
                Self.string,
                Self.escaped_value,
                Self.null,
                Self.NaN,
                Self.Inf,
                Self.neg_Inf,
            ),
            "Value given to JsonType does not exist",
        )
        self._selected = value

    fn __is__(self, value: JsonType) -> Bool:
        """Whether the self is the given `JsonType`.

        Returns:
            Whether the self is the given `JsonType`.
        """
        return self._selected == value._selected

    fn __is_not__(self, value: JsonType) -> Bool:
        """Whether the self is not the given `JsonType`.

        Returns:
            Whether the self is not the given `JsonType`.
        """
        return self._selected != value._selected


@value
struct JsonInstance[origin: Origin[False].type]:
    var type: JsonType
    var buffer: Span[Byte, origin]


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

    ### JSON specification:

    (unescaped values are used to indicate sets)

    Collection types have commas between content. Trailing commas are
    dissallowed.

    | Pseudotype    | Pseudocode set description |
    |:--------------|:---------------------------|
    |whitespace     | { SPACE, \\n, \\r, \\t }
    |value          | { `Optional[whitespace]`, `Variant[string, number, object\
    , array, true, false, null]`, `Optional[whitespace]` } |
    |key_value      | { `string`, `Optional[whitespace]` , `:`, `value` } |
    |object_content | { `Optional[whitespace]`, `Optional[key_value]` } |
    |object         | { `{`, `Optional[object_content]`, `}` } |
    |array_content  | { `Optional[whitespace]`, `value`,\
    `Optional[whitespace]` } |
    |array          | { `[`, `Optional[array_content]`, `]` } |
    |string         | { `"`, `Optional[Variant[escaped_values, values]]`, `"` }|
    |escaped_value | { `\\`, `Variant['"', '\\', '/', backspace, '\\f',\
    '\\n', '\\r', '\\t', 'uHHHH']` } * |
    |number         | { `Variant[int, float]` } |
    |int            | { `Optional['-']`, `Optional['0']`, `Optional[digits]` } |
    |float          | { `Optional['-']`, `Optional['0']`, `Optional[digits]`,\
    Optional['.'], `Optional[digits]`, `Optional[ [ Variant['E', 'e'],\
    Optional[Variant['+', '-']], digit, Optional[digits] ] ]` } |

    *: note that `\\ANYTHING` is a single value, they are double only in
    docstrings to escape them. 'uHHHH' is meant to be a u followed by 4
    hexadecimal byte encoded values from unicode.
    """

    alias _Sp = Span[Byte, origin]
    var _buffer: Self._Sp

    fn __init__(inout self, buffer: Self._Sp):
        """Construct an immutable Reader from a buffer.

        Args:
            buffer: The buffer to read from.
        """
        self._buffer = buffer

    fn get_json_instance(
        self, start: UInt = 0
    ) -> JsonInstance[origin] as output:
        """Get the `JsonInstance` starting at start without its start and end
        characters.

        Args:
            start: The absolute offset in bytes to start reading a valid
                `JsonType`.

        Returns:
            The `JsonInstance` beginning at the start character **after skipping
            all the whitespace** until its end without its start and end
            characters.

        Notes:
            This only validates the content of the instance, not if it has a
            trailing whitespace, comma, etc.
        """

        alias `{` = Byte(ord("{"))
        alias `}` = Byte(ord("}"))
        alias `[` = Byte(ord("["))
        alias `]` = Byte(ord("]"))
        alias `"` = Byte(ord('"'))
        alias `0` = Byte(ord("0"))
        alias `9` = Byte(ord("9"))
        alias `n` = Byte(ord("n"))
        alias `N` = Byte(ord("N"))
        alias `I` = Byte(ord("I"))
        alias `-` = Byte(ord("-"))
        alias `.` = Byte(ord("."))
        alias `e` = Byte(ord("e"))
        alias `E` = Byte(ord("E"))
        alias float_starters = SIMD[DType.uint8, 4](`.`, `.`, `e`, `E`)

        invalid = JsonInstance(
            JsonType.invalid, Self._sp(self._buffer.unsafe_ptr() + start, 0)
        )

        @always_inline
        fn _loop_is_valid[
            byte: Byte
        ](
            inout iterator: _StringSliceIter,
            inout char: StringSlice[origin],
            inout char_p: UnsafePointer[Byte],
            inout b0_char: Byte,
            inout offset: UInt,
        ) -> Bool:
            while b0_char != byte:
                if not iterator.__hasmore__():
                    return False
                char = rebind[StringSlice[origin]](iterator.__next__())
                b0_char = char.unsafe_ptr()[0]
                offset += char.byte_length()
            return True

        ptr = self._buffer.unsafe_ptr()
        debug_assert(start < len(self._buffer), "start is `>=` buffer length")
        iterator = StringSlice[origin](
            unsafe_from_utf8_ptr=ptr + start, len=len(self._buffer) - start
        ).__iter__()
        if not iterator.__hasmore__():
            output = invalid
            return
        char = iterator.__next__()
        offset = UInt(0)
        while (
            char.byte_length() == 1
            and Self.isspace(char.unsafe_ptr()[0])
            and iterator.__hasmore__()
        ):
            char = iterator.__next__()
            offset += 1
        if not char:
            output = invalid
            return
        char_p = char.unsafe_ptr()
        start_ptr = char_p
        b0_char = char_p[0]
        if b0_char == `{`:
            if _loop_is_valid[`}`](iterator, char, char_p, b0_char, offset):
                output = JsonInstance(
                    JsonType.object, Self._sp(start_ptr, offset)
                )
                return
        elif b0_char == `[`:
            if _loop_is_valid[`]`](iterator, char, char_p, b0_char, offset):
                output = JsonInstance(
                    JsonType.array, Self._sp(start_ptr, offset)
                )
                return
        elif b0_char == `"`:
            b0_char = 0
            if _loop_is_valid[`"`](iterator, char, char_p, b0_char, offset):
                output = JsonInstance(
                    JsonType.string, Self._sp(start_ptr, offset)
                )
                return
        elif `0` <= b0_char <= `9`:
            while `0` <= b0_char <= `9`:
                if not iterator.__hasmore__():
                    break
                char = rebind[StringSlice[origin]](iterator.__next__())
                b0_char = char.unsafe_ptr()[0]
                offset += 1
            offset += 1
            if b0_char in float_starters:
                # NOTE: this technically allows a trailing character, but... meh
                output = JsonInstance(
                    JsonType.float, Self._sp(start_ptr, offset)
                )
                return
            output = JsonInstance(JsonType.int, Self._sp(start_ptr, offset))
            return
        elif b0_char == `n`:
            alias `u` = Byte(ord("u"))
            alias `l` = Byte(ord("l"))
            if Self._is_valid[3, `u`, `l`, `l`](iterator):
                output = JsonInstance(JsonType.null, Self._sp(start_ptr, 3))
                return
        elif b0_char == `N`:
            alias `a` = Byte(ord("a"))
            if Self._is_valid[2, `a`, `N`](iterator):
                output = JsonInstance(JsonType.NaN, Self._sp(start_ptr, 3))
                return
        elif b0_char == `-`:
            if not iterator.__hasmore__():
                output = invalid
                return
            b0_char = iterator.__next__().unsafe_ptr()[0]

            if `0` <= b0_char <= `9`:
                while `0` <= b0_char <= `9`:
                    if not iterator.__hasmore__():
                        break
                    char = rebind[StringSlice[origin]](iterator.__next__())
                    b0_char = char.unsafe_ptr()[0]
                    offset += 1
                offset += 1
                if b0_char in float_starters:
                    # NOTE: this technically allows a trailing character, but... meh
                    output = JsonInstance(
                        JsonType.float, Self._sp(start_ptr, offset)
                    )
                    return
                output = JsonInstance(JsonType.int, Self._sp(start_ptr, offset))
                return
            start_ptr -= 1

        if b0_char == `I`:
            alias `f` = Byte(ord("f"))
            alias `i` = Byte(ord("i"))
            alias `t` = Byte(ord("t"))
            alias `y` = Byte(ord("y"))
            if Self._is_valid[7, `n`, `f`, `i`, `n`, `i`, `t`, `y`](iterator):
                output = JsonInstance(JsonType.Inf, Self._sp(start_ptr, 8))
                return
        output = invalid

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
        if not iterator.__hasmore__():
            return False

        alias items = (b0, b1, b2, b3, b4, b5, b6, b7)

        @parameter
        for i in range(amount):
            b0_char = iterator.__next__().unsafe_ptr()[0]
            if not iterator.__hasmore__() or b0_char != items.get[i, Byte]():
                return False
        return True

    @always_inline
    @staticmethod
    fn _parse_int(span: Self._Sp) -> Int:
        alias `0` = UInt8(ord("0"))
        alias `9` = UInt8(ord("9"))
        iterator = StringSlice[origin](
            unsafe_from_utf8_ptr=span.unsafe_ptr(), len=len(span)
        ).__iter__()
        char = iterator.__next__()
        char_p = char.unsafe_ptr()
        b0_char = char_p[0]
        value = 0
        while `0` <= b0_char <= `9`:
            value = value * 10 + int(b0_char ^ 0x30)
            b0_char = iterator.__next__().unsafe_ptr()[0]
            if not iterator.__hasmore__():
                break
        return value

    @always_inline
    @staticmethod
    fn _parse_float(span: Self._Sp) -> Float64:
        alias `0` = UInt8(ord("0"))
        alias `9` = UInt8(ord("9"))
        iterator = StringSlice[origin](
            unsafe_from_utf8_ptr=span.unsafe_ptr(), len=len(span)
        ).__iter__()
        char = iterator.__next__()
        char_p = char.unsafe_ptr()
        b0_char = char_p[0]
        value = 0
        while `0` <= b0_char <= `9`:
            value = value * 10 + int(b0_char ^ 0x30)
            b0_char = iterator.__next__().unsafe_ptr()[0]
            if not iterator.__hasmore__():
                break
        # TODO: after decimal
        return value

    @always_inline
    @staticmethod
    fn isspace(char: Byte) -> Bool:
        """Whether the given character byte is whitespace.

        Args:
            char: The given character byte.

        Returns:
            Whether the given character byte is whitespace.
        """

        alias ` ` = UInt8(ord(" "))
        alias `\n` = UInt8(ord("\n"))
        alias `\t` = UInt8(ord("\t"))
        alias `\r` = UInt8(ord("\r"))

        @parameter
        if allow_c_whitespace:
            return (`\n` <= char <= `\r`) or char == ` `
        else:
            return char == ` ` or char == `\n` or char == `\t` or char == `\r`

    @staticmethod
    fn _sp(ptr: UnsafePointer[Byte], length: Int) -> Span[Byte, origin]:
        return Span[Byte, origin](unsafe_ptr=ptr, len=length)

    fn find(self, key: StringSlice) -> JsonInstance[origin]:
        """Find a json value by key. Be sure to pass `"` + `name` + `"`."""
        idx = -1  # self._buffer.find(key)
        if idx == -1:
            return JsonInstance(
                JsonType.invalid, Self._sp(self._buffer.unsafe_ptr(), 0)
            )
        return self.get_json_instance(idx)
