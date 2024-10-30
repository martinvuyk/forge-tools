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
# TODO: read all python impl https://github.com/python/cpython/blob/main/Lib/json/scanner.py


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
                Self.whitespace,
                Self.value,
                Self.object,
                Self.array,
                Self.int,
                Self.float,
                Self.string,
                Self.escaped_value,
                Self.invalid,
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


# TODO: UTF-16
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
        """Get the `JsonInstance` starting at start **skipping over
        whitespace**.

        Args:
            start: The absolute offset in bytes to start reading a valid
                `JsonType`.

        Returns:
            The `JsonInstance` beginning at the start character.
        """

        alias `{` = UInt8(ord("{"))
        alias `}` = UInt8(ord("}"))
        alias `[` = UInt8(ord("["))
        alias `]` = UInt8(ord("]"))
        alias `,` = UInt8(ord(","))
        alias `"` = UInt8(ord('"'))
        alias ` ` = UInt8(ord(" "))
        alias `\n` = UInt8(ord("\n"))
        alias `\t` = UInt8(ord("\t"))
        alias `\r` = UInt8(ord("\r"))
        alias Sp = Span[Byte, origin]

        fn _sp(ptr: UnsafePointer[Byte], length: Int) -> Sp:
            return Sp(unsafe_ptr=ptr, len=length)

        invalid = JsonInstance(
            JsonType.invalid, _sp(self._buffer.unsafe_ptr() + start, 0)
        )

        @always_inline
        fn _loop_until_break[
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
                    return True
                char = rebind[StringSlice[origin]](iterator.__next__())
                char_p = char.unsafe_ptr()
                b0_char = char_p[0]
                offset = char.byte_length()
            return False

        ptr = self._buffer.unsafe_ptr()
        debug_assert(
            start <= len(self._buffer), "start is bigger than buffer length"
        )
        iterator = StringSlice[origin](
            unsafe_from_utf8_ptr=ptr + start, len=len(self._buffer) - start
        ).__iter__()
        if not iterator.__hasmore__():
            output = invalid
            return
        char = iterator.__next__()
        offset = UInt(0)
        while (
            char.byte_length() > 0
            and Self.isspace(char.unsafe_ptr()[0])
            and iterator.__hasmore__()
        ):
            char = iterator.__next__()
            offset += char.byte_length()
        if not char:
            output = invalid
            return
        char_p = char.unsafe_ptr()
        start_ptr = char_p
        b0_char = char_p[0]
        if b0_char == `{`:
            if _loop_until_break[`}`](iterator, char, char_p, b0_char, offset):
                output = invalid
                return
            output = JsonInstance(JsonType.object, _sp(start_ptr, offset))
            return
        elif b0_char == `[`:
            if _loop_until_break[`]`](iterator, char, char_p, b0_char, offset):
                output = invalid
                return
            output = JsonInstance(JsonType.array, _sp(start_ptr, offset))
            return
        elif b0_char == `"`:
            b0_char = 0
            if _loop_until_break[`"`](iterator, char, char_p, b0_char, offset):
                output = invalid
                return
            output = JsonInstance(JsonType.string, _sp(start_ptr, offset))
            return
        # TODO: value
        # TODO: escaped_value
        # TODO: parametrized support for NaN
        # TODO: parametrized support for Infinity
        # TODO: parametrized support for -Infinity
        output = invalid

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
            return `\n` <= char <= `\r` or char == ` `
        else:
            return char == ` ` or char == `\n` or char == `\t` or char == `\r`


# TODO: json should be indexed by keys, not necesarilly using a Dict
# TODO: The json should be parsed as lazily as possible
# TODO: Everything should use StringSlice or Span
