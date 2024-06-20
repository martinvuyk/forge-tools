# Forge Tools
Tools to extend the functionality of the Mojo standard library. Hopefully they will all someday be available in the stdlib. The main focus is to only include things that would make sense in such a library.

## How to Install
```bash
source ./scripts/package-lib.sh
```
The semi-compiled package will be under `./build/forge_tools.mojopkg`
## How to run tests
test an entire directory or subdirectory or specific file
```bash
source ./scripts/run-tests.sh test/
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
alias Arr = Array[DType.uint8, 3]
var a = Arr(1, 2, 3)
var b = Arr(1, 2, 3)
print((a - b).sum()) # prints 0
print(a.avg()) # prints 2
print(a * b) # dot product: 14
print(a.cross(b)) # cross product: Array(0, 0, 0)
print(2 in a) # prints True
print(a.index(2).value() if a.index(2) else -1) # prints 1
print((Arr(2, 2, 2) % 2).sum()) # 0
print((Arr(2, 2, 2) // 2).sum()) # 3
print((Arr(2, 2, 2) ** 2).sum()) # 12
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
    ...

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

## complex
### quaternion.mojo
#### Quaternion
Quaternion, a structure often used to represent rotations.
Allocated on the stack with very efficient vectorized operations.
#### DualQuaternion
DualQuaternion, a structure nascently used to represent 3D
transformations and rigid body kinematics. Allocated on the
stack with very efficient vectorized operations.

## datetime

- `DateTime`
    - A structure aware of TimeZone, Calendar, and leap days and seconds.
    - Nanosecond resolution, though when using dunder methods (e.g. dt1 == dt2) 
        it has only Microsecond resolution.
- `Date`
    - A structure aware of TimeZone, Calendar, and leap days and seconds.
- `TimeZone`
    - By default UTC, highly customizable and options for full or partial
        IANA timezones support.
- `DateTime64`, `DateTime32`, `DateTime16`, `DateTime8`
    - Fast implementations of DateTime, no leap seconds, and some have much
        lower resolutions but better performance.
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
var customcal = Calendar(2024)
dt = DateT.from_iso[fstr](iso_str, calendar=customcal)
print(dt) # 2024-01-01T22:14:07+00:00 


# TODO: current mojo limitation. Parametrized structs need to be bound to an
# alias and used for interoperability
# var customtz = TimeZone("my_str", 1, 0) 
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
