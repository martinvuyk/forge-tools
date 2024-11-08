"""Json module."""

from utils import Span

# TODO: write tests with https://github.com/miloyip/nativejson-benchmark/tree/master/data/jsonchecker
# TODO: read python impl https://github.com/python/cpython/blob/main/Lib/json/scanner.py


# TODO: enum
@value
struct JsonType:
    """A JSON pseudotype alias."""

    alias invalid = "INVALID"
    """Invalid."""
    alias whitespace = "WHITESPACE"
    """Whitespace."""
    alias object = "OBJECT"
    """Object."""
    alias array = "ARRAY"
    """Array."""
    alias int = "INT"
    """Integer."""
    alias float_dot = "FLOAT_DOT"
    """Float with a dot."""
    alias float_exp = "FLOAT_EXP"
    """Float with exponent."""
    alias true = "TRUE"
    """Json true."""
    alias false = "FALSE"
    """Json false."""
    alias null = "NULL"
    """Json null."""
    alias NaN = "NAN"
    """Json NaN."""
    alias Inf = "INFINITY"
    """Infinity, can be positive or negative."""
    alias string = "STRING"
    """String."""
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
                Self.object,
                Self.array,
                Self.int,
                Self.float_dot,
                Self.float_exp,
                Self.string,
                Self.null,
                Self.NaN,
                Self.Inf,
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
    """A JsonInstance.

    Parameters:
        origin: The immutable origin of the data.
    """

    var type: JsonType
    """The type."""
    var buffer: Span[Byte, origin]
    """The data."""
