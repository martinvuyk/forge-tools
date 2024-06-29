# ===----------------------------------------------------------------------=== #
# Copyright (c) 2024, Modular Inc. All rights reserved.
#
# Licensed under the Apache License v2.0 with LLVM Exceptions:
# https://llvm.org/LICENSE.txt
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ===----------------------------------------------------------------------=== #
"""Implements the Error class.

These are Mojo built-ins, so you don't need to import them.
"""

from sys import alignof, sizeof

from memory.memory import _free
from memory import memcmp, memcpy, UnsafePointer

# ===----------------------------------------------------------------------===#
# Error
# ===----------------------------------------------------------------------===#


@register_passable("trivial")
struct ErrorReg(Stringable, Boolable):
    """This type represents a register-passable Error."""

    var data: StringLiteral
    """The string data."""

    @always_inline("nodebug")
    fn __init__(inout self):
        """Default constructor."""
        self.data = ""

    @always_inline("nodebug")
    fn __init__(inout self, value: StringLiteral):
        """Construct an ErrorReg object with a given string literal.

        Args:
            value: The ErrorReg message.
        """
        self.data = value

    fn __bool__(self) -> Bool:
        """Returns True if the ErrorReg is set and false otherwise.

        Returns:
          True if the ErrorReg object contains a value and False otherwise.
        """
        return bool(self.data)

    fn __str__(self) -> String:
        """Converts the ErrorReg to string representation.

        Returns:
            A String of the ErrorReg message.
        """
        return self.data

    fn __repr__(self) -> String:
        """Converts the ErrorReg to printable representation.

        Returns:
            A printable representation of the ErrorReg message.
        """
        return str(self)

    fn __eq__(self, other: String) -> Bool:
        """Whether the Error message is equal to the string.

        Args:
            other: The String to compare to.

        Returns:
            The comparison.
        """
        return str(self) == other


@value
struct Error2[T: StringLiteral = "AnyError"](Stringable, Boolable):
    """This type represents a parametric Error."""

    alias kind = T
    """The kind of Error."""
    var message: String
    """The Error message."""

    @always_inline("nodebug")
    fn __bool__(self) -> Bool:
        """Returns True if the Error is set and false otherwise.

        Returns:
          True if the Error object contains a message and False otherwise.
        """
        return bool(self.message)

    @always_inline("nodebug")
    fn __str__(self) -> String:
        """Converts the Error to string representation.

        Returns:
            A String of the Error kind and message.
        """
        return self.kind + ": " + self.message

    @always_inline("nodebug")
    fn __repr__(self) -> String:
        """Converts the Error to printable representation.

        Returns:
            A printable representation of the Error message.
        """
        return str(self)

    fn __eq__[A: StringLiteral](self, other: Error2[A]) -> Bool:
        """Whether the Errors have the same message.

        Args:
            other: The Error to compare to.

        Returns:
            The comparison.
        """

        return self.message == other.message

    fn __eq__(self, value: StringLiteral) -> Bool:
        """Whether the Error message is set and self.kind is equal to the
        StringLiteral. Error kind "AnyError" matches with all errors.

        Args:
            value: The StringLiteral to compare to.

        Returns:
            The Result.
        """

        return bool(self) and (self.kind == value or value == "AnyError")
