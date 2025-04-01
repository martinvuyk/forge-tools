# ===----------------------------------------------------------------------=== #
# Copyright (c) 2024, Martin Vuyk Loperena
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
"""Defines Result, a type modeling a value which may or may not be present.
With an Error in the case of failure.

Result values can be thought of as a type-safe nullable pattern.
Your value can take on a value or `None`, and you need to check
and explicitly extract the value to get it out.

Examples:

```mojo
from forge_tools.collections import Result
a = Result(1)
b = Result[Int]()
if a:
    print(a.value())  # prints 1
if b:  # Bool(b) is False, so no print
    print(b.value())
c = a.or_else(2)
d = b.or_else(2)
print(c)  # prints 1
print(d)  # prints 2
```

And if more information about the returned Error is wanted it is available.

```mojo
from forge_tools.collections import Result
a = Result(1)
b = Result[Int](err=Error("something went wrong"))
c = Result[Int](None, Error("error 1"))
d = Result[Int](err=Error("error 2"))
if a:
    print(a.err)  # prints ""
if not b:
    print(b.err) # prints "something went wrong"

if c.err:
    print("c had an error")

# TODO: pattern matching
if String(d.err) == "error 1":
    print("d had error 1")
elif String(d.err) == "error 2":
    print("d had error 2")
```

A Result with an Error can also be retuned early:

```mojo
fn func_that_can_err[A: CollectionElement]() -> Result[A]:
    ...

fn return_early_if_err[T: CollectionElement, A: CollectionElement]() -> Result[T]:
    result: Result[A] = func_that_can_err[A]()
    if not result:
        # the internal err gets transferred to a Result[T]
        return result
        # its also possible to do:
        # return None, Error("func_that_can_err failed")
    val = result.value()
    final_result: T
    ...
    return final_result
```
.
"""

from os import abort
from utils import Variant


# ===----------------------------------------------------------------------===#
# Result
# ===----------------------------------------------------------------------===#


@value
struct Result[T: CollectionElement](CollectionElement, Boolable):
    """A type modeling a value which may or may not be present.
    With an Error in the case of failure.

    Result values can be thought of as a type-safe nullable pattern.
    Your value can take on a value or `None`, and you need to check
    and explicitly extract the value to get it out.

    Currently T is required to be a `CollectionElement` so we can implement
    copy/move for Result and allow it to be used in collections itself.

    Parameters:
        T: The type of value stored in the `Result`.

    Examples:

    ```mojo
    from forge_tools.collections import Result
    a = Result(1)
    b = Result[Int]()
    if a:
        print(a.value())  # prints 1
    if b:  # Bool(b) is False, so no print
        print(b.value())
    c = a.or_else(2)
    d = b.or_else(2)
    print(c)  # prints 1
    print(d)  # prints 2
    ```

    And if more information about the returned Error is wanted it is available.

    ```mojo
    from forge_tools.collections import Result
    a = Result(1)
    b = Result[Int](err=Error("something went wrong"))
    c = Result[Int](None, Error("error 1"))
    d = Result[Int](err=Error("error 2"))
    if a:
        print(a.err)  # prints ""
    if not b:
        print(b.err) # prints "something went wrong"

    if c.err:
        print("c had an error")

    # TODO: pattern matching
    if String(d.err) == "error 1":
        print("d had error 1")
    elif String(d.err) == "error 2":
        print("d had error 2")
    ```

    A Result with an Error can also be retuned early:

    ```mojo
    fn func_that_can_err[A: CollectionElement]() -> Result[A]:
        return Error("failed")

    fn return_early_if_err[T: CollectionElement, A: CollectionElement]() -> Result[T]:
        result: Result[A] = func_that_can_err[A]()
        if not result:
            # the internal err gets transferred to a Result[T]
            return result
            # its also possible to do:
            # return None, Error("func_that_can_err failed")
        val = result.value()
        final_result: T
        ...
        return final_result
    ```
    .
    """

    # NoneType comes first so its index is 0.
    # This means that Results that are 0-initialized will be None.
    alias _type = Variant[NoneType, T]
    var _value: Self._type
    var err: Error
    """The Error inside the `Result`."""

    @always_inline("nodebug")
    fn __init__(
        out self,
        value: NoneType = None,
        err: Error = Error("Result value was not set"),
        /,
    ):
        """Create an empty `Result` with an `Error`.

        Args:
            value: Must be exactly `None`.
            err: The `Error`.
        """
        self = Self(err=err)

    @always_inline("nodebug")
    fn __init__(out self, value: Tuple[NoneType, Error], /):
        """Create an empty `Result` with an `Error`.

        Args:
            value: Must be exactly (`None`, `Error`).
        """
        if len(value) < 2:
            self = Self()
        else:
            self = Self(err=value[1])

    @always_inline("nodebug")
    fn __init__[A: CollectionElement](out self, owned other: Result[A]):
        """Create a `Result` by transferring another `Result`'s Error.

        Parameters:
            A: The type of the value contained in other.

        Args:
            other: The other `Result`.
        """
        self = Self(err=other.err)

    @always_inline("nodebug")
    fn __init__(out self, owned value: T):
        """Create a `Result` containing a value.

        Args:
            value: The value to store in the `Result`.
        """
        self._value = Self._type(value^)
        self.err = Error()

    @always_inline("nodebug")
    fn __init__(out self, *, err: Error):
        """Create an empty `Result`.

        Args:
            err: Must be an `Error`.
        """
        self._value = Self._type(None)
        self.err = err

    @always_inline
    fn value(ref [_]self) -> ref [__origin_of(self._value)] T:
        """Retrieve a reference to the value of the `Result`.

        This check to see if the `Result` contains a value.
        If you call this without first verifying the `Result` with __bool__()
        eg. by `if my_result:` or without otherwise knowing that it contains a
        value (for instance with `or_else`), the program will abort

        Returns:
            A reference to the contained data of the `Result` as a Reference[T].
        """
        if not self:
            abort(".value() on empty `Result`")

        return self.unsafe_value()

    @always_inline
    fn unsafe_value(
        ref [_]self,
    ) -> ref [__origin_of(self._value)] T:
        """Unsafely retrieve a reference to the value of the `Result`.

        This doesn't check to see if the `Result` contains a value.
        If you call this without first verifying the `Result` with __bool__()
        eg. by `if my_result:` or without otherwise knowing that it contains a
        value (for instance with `or_else`), you'll get garbage unsafe data out.

        Returns:
            A reference to the contained data of the `Result` as a Reference[T].
        """
        debug_assert(Bool(self), ".value() on empty Result")
        return self._value.unsafe_get[T]()

    fn take(mut self) -> T:
        """Move the value out of the `Result`.

        The caller takes ownership over the new value, which is moved
        out of the `Result`, and the `Result` is left in an empty state.

        This check to see if the `Result` contains a value.
        If you call this without first verifying the `Result` with __bool__()
        eg. by `if my_result:` or without otherwise knowing that it contains a
        value (for instance with `or_else`), you'll get garbage unsafe data out.

        Returns:
            The contained data of the `Result` as an owned T value.
        """
        if not self:
            abort(".take() on empty `Result`")
        return self.unsafe_take()

    fn unsafe_take(mut self) -> T:
        """Unsafely move the value out of the `Result`.

        The caller takes ownership over the new value, which is moved
        out of the `Result`, and the `Result` is left in an empty state.

        This check to see if the `Result` contains a value.
        If you call this without first verifying the `Result` with __bool__()
        eg. by `if my_option:` or without otherwise knowing that it contains a
        value (for instance with `or_else`), the program will abort!

        Returns:
            The contained data of the option as an owned T value.
        """
        debug_assert(Bool(self), ".unsafe_take() on empty Result")
        return self._value.unsafe_take[T]()

    fn or_else(self, default: T) -> T:
        """Return the underlying value contained in the `Result` or a default
        value if the `Result`'s underlying value is not present.

        Args:
            default: The new value to use if no value was present.

        Returns:
            The underlying value contained in the Result or a default value.
        """
        if self:
            return self._value[T]
        return default

    @always_inline("nodebug")
    fn __is__(self, other: NoneType) -> Bool:
        """Return `True` if the `Result` has no value.

        It allows you to use the following syntax: `if my_result is None:`

        Args:
            other: The value to compare to (None).

        Returns:
            True if the `Result` has no value and False otherwise.
        """
        return not self

    @always_inline("nodebug")
    fn __isnot__(self, other: NoneType) -> Bool:
        """Return `True` if the `Result` has a value.

        It allows you to use the following syntax: `if my_result is not None:`.

        Args:
            other: The value to compare to (None).

        Returns:
            True if the `Result` has a value and False otherwise.
        """
        return Bool(self)

    @always_inline("nodebug")
    fn __bool__(self) -> Bool:
        """Return true if the `Result` has a value.

        Returns:
            True if the `Result` has a value and False otherwise.
        """
        return not self._value.isa[NoneType]()

    @always_inline("nodebug")
    fn __invert__(self) -> Bool:
        """Return False if the `Result` has a value.

        Returns:
            False if the `Result` has a value and True otherwise.
        """
        return not self


# ===----------------------------------------------------------------------===#
# Result2
# ===----------------------------------------------------------------------===#

from forge_tools.builtin.error import Error2


@value
struct Result2[T: CollectionElement, E: StringLiteral](Boolable):
    """A parametric `Result2` type. A type modeling a value which may or may not
    be present. With an Error in the case of failure.

    Parameters:
        T: The type of value stored in the `Result2`.
        E: The type of Error stored in the `Result2`.

    Examples:

    ```mojo
    from forge_tools.collections.result import Result2
    from forge_tools.builtin.error import Error2

    fn do_something(i: Int) -> Result2[Int, "IndexError"]:
        if i < 0:
            return None, Error2["IndexError"]("index out of bounds: " + String(i))
        return 1

    fn do_some_other_thing() -> Result2[String, "OtherError"]:
        a = do_something(-1)
        if a.err:
            print(a.err) # IndexError: index out of bounds: -1
            return a # error message ("index out of bounds: -1") gets transferred
        return "success"
    ```
    .
    """

    alias _type = Variant[NoneType, T]
    var _value: Self._type
    alias _err_type = Error2[E]
    var err: Self._err_type
    """The Error inside the `Result`."""

    @always_inline("nodebug")
    fn __init__(
        out self,
        value: NoneType = None,
        err: Self._err_type = Self._err_type("Result value was not set"),
        /,
    ):
        """Create an empty `Result` with an `Error`.

        Args:
            value: Must be exactly `None`.
            err: The `Error`.
        """
        self = Self(err=err)

    @always_inline("nodebug")
    fn __init__(out self, value: Tuple[NoneType, Self._err_type], /):
        """Create an empty `Result` with an `Error`.

        Args:
            value: Must be exactly (`None`, `Error`).
        """
        self = Self(err=value[1])

    @always_inline("nodebug")
    fn __init__[A: CollectionElement](out self, owned other: Result2[A, E]):
        """Create a `Result` by transferring another `Result`'s Error.

        Parameters:
            A: The type of the value contained in other.

        Args:
            other: The other `Result`.
        """
        self = Self(err=other.err)

    @always_inline("nodebug")
    fn __init__[
        A: CollectionElement, B: StringLiteral
    ](out self, owned other: Result2[A, B]):
        """Create a `Result` by transferring another `Result`'s Error message.

        Parameters:
            A: The type of the value contained in other.
            B: The type of the Error contained in other.

        Args:
            other: The other `Result`.
        """
        self = Self(err=Self._err_type(other.err.message))

    @always_inline("nodebug")
    fn __init__(out self, owned value: T):
        """Create a `Result` containing a value.

        Args:
            value: The value to store in the `Result`.
        """
        self._value = Self._type(value^)
        self.err = Self._err_type("")

    @always_inline("nodebug")
    fn __init__(out self, *, err: Self._err_type):
        """Create an empty `Result`.

        Args:
            err: Must be an `Error`.
        """
        self._value = Self._type(None)
        self.err = err

    @always_inline
    fn value(ref [_]self) -> ref [__origin_of(self._value)] T:
        """Retrieve a reference to the value of the `Result`.

        This check to see if the `Result` contains a value.
        If you call this without first verifying the `Result` with __bool__()
        eg. by `if my_result:` or without otherwise knowing that it contains a
        value (for instance with `or_else`), the program will abort

        Returns:
            A reference to the contained data of the `Result` as a Reference[T].
        """
        if not self:
            abort(".value() on empty `Result`")

        return self.unsafe_value()

    @always_inline
    fn unsafe_value(
        ref [_]self,
    ) -> ref [__origin_of(self._value)] T:
        """Unsafely retrieve a reference to the value of the `Result`.

        This doesn't check to see if the `Result` contains a value.
        If you call this without first verifying the `Result` with __bool__()
        eg. by `if my_result:` or without otherwise knowing that it contains a
        value (for instance with `or_else`), you'll get garbage unsafe data out.

        Returns:
            A reference to the contained data of the `Result` as a Reference[T].
        """
        debug_assert(Bool(self), ".value() on empty Result")
        return self._value.unsafe_get[T]()

    fn take(mut self) -> T:
        """Move the value out of the `Result`.

        The caller takes ownership over the new value, which is moved
        out of the `Result`, and the `Result` is left in an empty state.

        This check to see if the `Result` contains a value.
        If you call this without first verifying the `Result` with __bool__()
        eg. by `if my_result:` or without otherwise knowing that it contains a
        value (for instance with `or_else`), you'll get garbage unsafe data out.

        Returns:
            The contained data of the `Result` as an owned T value.
        """
        if not self:
            abort(".take() on empty `Result`")
        return self.unsafe_take()

    fn unsafe_take(mut self) -> T:
        """Unsafely move the value out of the `Result`.

        The caller takes ownership over the new value, which is moved
        out of the `Result`, and the `Result` is left in an empty state.

        This check to see if the `Result` contains a value.
        If you call this without first verifying the `Result` with __bool__()
        eg. by `if my_option:` or without otherwise knowing that it contains a
        value (for instance with `or_else`), the program will abort!

        Returns:
            The contained data of the option as an owned T value.
        """
        debug_assert(Bool(self), ".unsafe_take() on empty Result")
        return self._value.unsafe_take[T]()

    fn or_else(self, default: T) -> T:
        """Return the underlying value contained in the `Result` or a default
        value if the `Result`'s underlying value is not present.

        Args:
            default: The new value to use if no value was present.

        Returns:
            The underlying value contained in the Result or a default value.
        """
        if self:
            return self._value[T]
        return default

    @always_inline("nodebug")
    fn __is__(self, other: NoneType) -> Bool:
        """Return `True` if the `Result` has no value.

        It allows you to use the following syntax: `if my_result is None:`

        Args:
            other: The value to compare to (None).

        Returns:
            True if the `Result` has no value and False otherwise.
        """
        return not self

    @always_inline("nodebug")
    fn __isnot__(self, other: NoneType) -> Bool:
        """Return `True` if the `Result` has a value.

        It allows you to use the following syntax: `if my_result is not None:`.

        Args:
            other: The value to compare to (None).

        Returns:
            True if the `Result` has a value and False otherwise.
        """
        return Bool(self)

    @always_inline("nodebug")
    fn __bool__(self) -> Bool:
        """Return true if the `Result` has a value.

        Returns:
            True if the `Result` has a value and False otherwise.
        """
        return not self._value.isa[NoneType]()

    @always_inline("nodebug")
    fn __invert__(self) -> Bool:
        """Return False if the `Result` has a value.

        Returns:
            False if the `Result` has a value and True otherwise.
        """
        return not self
