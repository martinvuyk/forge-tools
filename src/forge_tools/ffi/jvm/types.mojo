"""Java Native Interface types."""


# ===----------------------------------------------------------------------=== #
# Base Types
# ===----------------------------------------------------------------------=== #


struct J:
    """Java types."""

    alias boolean = UInt8
    """Type: `boolean`. Type signature: `Z`."""
    alias byte = Int8
    """Type: `byte`. Type signature: `B`."""
    alias char = UInt16
    """Type: `char`. Type signature: `C`."""
    alias short = Int16
    """Type: `short`. Type signature: `S`."""
    alias int = Int32
    """Type: `int`. Type signature: `I`."""
    alias long = Int64
    """Type: `long`. Type signature: `J`."""
    alias float = Float32
    """Type: `float`. Type signature: `F`."""
    alias double = Float64
    """Type: `double`. Type signature: `D`."""
    alias null = None
    """Type: `null`. Type signature: `V`."""
    alias ptr_addr = Int
    """Type: A Pointer Address."""


# ===----------------------------------------------------------------------=== #
# Utils
# ===----------------------------------------------------------------------=== #
