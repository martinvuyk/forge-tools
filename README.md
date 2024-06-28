# Forge Tools
Tools to extend the functionality of the Mojo standard library. Hopefully they will all someday be available in the stdlib. The main focus is to only include things that would make sense in such a library.

## How to Install
```bash
source ./scripts/package-lib.sh
```
The semi-compiled package will be under `./build/forge_tools.mojopkg`
## How to run tests
Test an entire directory or subdirectory or specific file
```bash
source ./scripts/test.sh test/
```
## How to run benchmarks
Run an entire directory or subdirectory or specific file (sequentially)
```bash
source ./scripts/benchmark.sh benchmarks/
```

# Packages

## builtin
### error.mojo
#### ErrorReg
This type represents a register-passable Error.

## collections
### array.mojo
#### Array
An Array allocated on the stack with a capacity known at compile
time.

It is backed by a `SIMD` vector. This struct has the same API
as a regular `Array`.

This is typically faster than Python's `Array` as it is stack-allocated
and does not require any dynamic memory allocation and uses vectorized
operations wherever possible.

Examples:

```mojo
from forge_tools.collections import Array
alias Arr = Array[DType.uint8, 3, True]
var a = Arr(1, 2, 3)
var b = Arr(1, 2, 3)
print(a.max()) # 3
print(a.min()) # 1
print((a - b).sum()) # 0
print(a.avg()) # 2
print(a * b) # [1, 4, 9]
print(2 in a) # True
print(a.index(2).or_else(-1)) # 1
print((Arr(2, 2, 2) % 2).sum()) # 0
print((Arr(2, 2, 2) // 2).sum()) # 3
print((Arr(2, 2, 2) ** 2).sum()) # 12
print(a.dot(b)) # 14
print(a.cross(b)) # [0, 0, 0]
print(a.cos(b)) # 1
print(a.theta(b)) # 0
a.reverse()
print(a) # [3, 2, 1]

fn mapfunc(a: UInt8) -> Scalar[DType.bool]:
    return a < 3
print(a.map(mapfunc)) # [False, True, True]

fn filterfunc(a: UInt8) -> Scalar[DType.bool]:
    return a < 3
print(a.filter(filterfunc)) # [2, 1]

fn applyfunc(a: UInt8) -> UInt8:
    return a * 2
a.apply(applyfunc)
print(a) # [6, 4, 2]

print(a.concat(a.reversed() // 2)) # [6, 4, 2, 1, 2, 3]
```
### result.mojo
### Result
Defines Result, a type modeling a value which may or may not be present.
With an Error in the case of failure.

Result values can be thought of as a type-safe nullable pattern.
Your value can take on a value or `None`, and you need to check
and explicitly extract the value to get it out.

Examples:

```mojo
var a = Result(1)
var b = Result[Int]()
if a:
    print(a.value())  # prints 1
if b:  # bool(b) is False, so no print
    print(b.value())
var c = a.or_else(2)
var d = b.or_else(2)
print(c)  # prints 1
print(d)  # prints 2
```

And if more information about the returned Error is wanted it is available.

```mojo
var a = Result(1)
var b = Result[Int](err=Error("something went wrong"))
var c = Result[Int](None, Error("error 1"))
var d = Result[Int](err=Error("error 2"))
if a:
    print(a.err)  # prints ""
if not b:
    print(b.err) # prints "something went wrong"

if c.err:
    print("c had an error")

# TODO: pattern matching
if str(d.err) == "error 1":
    print("d had error 1")
elif str(d.err) == "error 2":
    print("d had error 2")
```

A Result with an Error can also be retuned early:

```mojo
fn func_that_can_err[A: CollectionElement]() -> Result[A]:
    return Error("failed")

fn return_early_if_err[T: CollectionElement, A: CollectionElement]() -> Result[T]:
    var result: Result[A] = func_that_can_err[A]()
    if not result:
        # the internal err gets transferred to a Result[T]
        return result
        # its also possible to do:
        # return None, Error("func_that_can_err failed")
    var val = result.value()
    var final_result: T
    ...
    return final_result
```
#### ResultReg
A register-passable `ResultReg` type.

#### Result2
A parametric `Result2` type.

uses:
```mojo
struct Error2[T: StringLiteral](Stringable, Boolable):
    """This type represents a parametric Error."""

    alias type = T
    """The type of Error."""
    var message: String
    """The Error message."""
    ...
```

Examples:

```mojo
from forge_tools.collections.result import Result2
from forge_tools.builtin.error import Error2

fn do_something(i: Int) -> Result2[Int, "IndexError"]:
    if i < 0:
        return None, Error2["IndexError"]("index out of bounds: " + str(i))
    return 1

fn do_some_other_thing() -> Result2[String, "OtherError"]:
    var a = do_something(-1)
    if a.err:
        print(a.err) # IndexError: index out of bounds: -1
        return a # error message ("index out of bounds: -1") gets transferred
    return "success"
```

It would be nice to have:
```mojo
struct Result2[T: CollectionElement, *Errs: StringLiteral](Boolable):
    alias _type = Variant[NoneType, T]
    var _value: Self._type
    alias _err_type = Variant[
        VariadicListUnpack[VariadicListEmbed[Error2[_], Errs]]
    ]
    var err: Self._err_type
    """The Error inside the `Result`."""
    ...
```
that way:
```mojo
fn do_something(i: Int) -> Result2[Int, "IndexError", "OtherError"]:
    ...

fn do_some_other_thing() -> Result2[String, "OtherError"]:
    var a = do_something(-1)
    if a.err == "OtherError": # returns bool(err) and err.type == value
        return a # error gets transferred
    elif a.err == "IndexError":
        return a # error message gets transferred
    elif a.err: # some undefined error after an API change
        return a
    return "success"
```


## complex
### quaternion.mojo
#### Quaternion
```mojo
struct Quaternion[T: DType = DType.float64]:
    """Quaternion, a structure often used to represent rotations.
    Allocated on the stack with very efficient vectorized operations.

    Parameters:
        T: The type of the elements in the Quaternion, must be a
            floating point type.
    """

    alias _vec_type = SIMD[T, 4]
    alias _scalar_type = Scalar[T]
    var vec: Self._vec_type
    """The underlying SIMD vector."""

    ...

    fn __mul__(self, other: Self) -> Self:
        """Calculate the Hamilton product of self with other.

        Args:
            other: The other Quaternion.

        Returns:
            The result.
        """

        alias sign0 = Self._vec_type(1, -1, -1, -1)
        alias sign1 = Self._vec_type(1, 1, 1, -1)
        alias sign2 = Self._vec_type(1, -1, 1, 1)
        alias sign3 = Self._vec_type(1, 1, -1, 1)
        var rev = other.vec.shuffle[3, 2, 1, 0]()
        var w = self.dot(other.vec * sign0)
        var i = self.dot(rev.rotate_right[2]() * sign1)
        var j = self.dot(other.vec.rotate_right[2]() * sign2)
        var k = self.dot(rev * sign3)
        return Self(w, i, j, k)
```

#### DualQuaternion
```mojo
struct DualQuaternion[T: DType = DType.float64]:
    """DualQuaternion, a structure nascently used to represent 3D
    transformations and rigid body kinematics. Allocated on the
    stack with very efficient vectorized operations.

    Parameters:
        T: The type of the elements in the DualQuaternion, must be a
            floating point type.
    """

    alias _vec_type = SIMD[T, 8]
    alias _scalar_type = Scalar[T]
    var vec: Self._vec_type
    """The underlying SIMD vector."""

    ...

    fn __mul__(self, other: Self) -> Self:
        """Multiply self with other.

        Args:
            other: The other DualQuaternion.

        Returns:
            The result.
        """

        alias Quat = Quaternion[T]
        var a = Quat(self.vec.slice[4]())
        var b = Quat(self.vec.slice[4, offset=4]())
        var c = Quat(other.vec.slice[4]())
        var d = Quat(other.vec.slice[4, offset=4]())
        return Self((a * c).vec.join((a * d + b * c).vec))
```

## datetime

- `DateTime`
    - A structure aware of TimeZone, Calendar, and leap days and seconds.
    - Nanosecond resolution, though when using dunder methods (e.g.
        `dt1 == dt2`) it has only Microsecond resolution.
- `Date`
    - A structure aware of TimeZone, Calendar, and leap days and seconds.
- `DateTime64`, `DateTime32`, `DateTime16`, `DateTime8`
    - Fast implementations of DateTime, no leap seconds, and some have much
        lower resolutions but better performance.
- `TimeZone`
    - By default UTC, highly customizable and options for full or partial
        IANA timezones support.
- Notes:
    - The caveats of each implementation are better explained in each struct's docstrings.

Examples:

```mojo
from testing import assert_equal, assert_true
from forge_tools.datetime import DateTime, Calendar, IsoFormat
from forge_tools.datetime.calendar import PythonCalendar, UTCCalendar

alias DateT = DateTime[iana=False, pyzoneinfo=False, native=False]
var dt = DateT(2024, 6, 18, 22, 14, 7)
print(dt) # 2024-06-18T22:14:07+00:00
alias fstr = IsoFormat(IsoFormat.HH_MM_SS) 
var iso_str = dt.to_iso[fstr]()
dt = (
    DateT.from_iso[fstr](iso_str, calendar=Calendar(2024, 6, 18))
    .value()
    .replace(calendar=Calendar()) # Calendar() == PythonCalendar
)
print(dt) # 2024-06-18T22:14:07+00:00


# TODO: current mojo limitation. Parametrized structs need to be bound to an
# alias and used for interoperability
# var customtz = TimeZone[False, False, False]("my_str", 1, 0) 
var tz_0 = DateT._tz("my_str", 0, 0)
var tz_1 = DateT._tz("my_str", 1, 0)
assert_equal(DateT(2024, 6, 18, 0, tz=tz_0), DateT(2024, 6, 18, 1, tz=tz_1))


# using python and unix calendar should have no difference in results
alias pycal = PythonCalendar
alias unixcal = UTCCalendar
var tz_0_ = DateT._tz("Etc/UTC", 0, 0)
tz_1 = DateT._tz("Etc/UTC-1", 1, 0)
var tz1_ = DateT._tz("Etc/UTC+1", 1, 0, -1)

dt = DateT(2022, 6, 1, tz=tz_0_, calendar=pycal) + DateT(
    2, 6, 31, tz=tz_0_, calendar=pycal
)
offset_0 = DateT(2025, 1, 1, tz=tz_0_, calendar=unixcal)
offset_p_1 = DateT(2025, 1, 1, hour=1, tz=tz_1, calendar=unixcal)
offset_n_1 = DateT(2024, 12, 31, hour=23, tz=tz1_, calendar=unixcal)
assert_equal(dt, offset_0)
assert_equal(dt, offset_p_1)
assert_equal(dt, offset_n_1)


var fstr = "mojo: %Y🔥%m🤯%d"
assert_equal("mojo: 0009🔥06🤯01", DateT(9, 6, 1).strftime(fstr))
fstr = "%Y-%m-%d %H:%M:%S.%f"
var ref1 = DateT(2024, 9, 9, 9, 9, 9, 9, 9)
assert_equal("2024-09-09 09:09:09.009009", ref1.strftime(fstr))


fstr = "mojo: %Y🔥%m🤯%d"
var vstr = "mojo: 0009🔥06🤯01"
ref1 = DateT(9, 6, 1)
var parsed = DateT.strptime(vstr, fstr)
assert_true(parsed)
assert_equal(ref1, parsed.value())
fstr = "%Y-%m-%d %H:%M:%S.%f"
vstr = "2024-09-09 09:09:09.009009"
ref1 = DateT(2024, 9, 9, 9, 9, 9, 9, 9)
parsed = DateT.strptime(vstr, fstr)
assert_true(parsed)
assert_equal(ref1, parsed.value())
```
