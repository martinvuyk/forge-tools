# Forge Tools
Tools to extend the functionality of the Mojo standard library. Hopefully they will all someday be available in the stdlib. The main focus is to only include things that would make sense in such a library.

## How to Install
```bash
source ./scripts/package-lib.sh
```
The semi-compiled package will be under `./build/forge_tools.mojopkg`
## How to run tests
test an entire directory or subdirectories or specific file
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
### calendar.mojo
```mojo
alias PythonCalendar = Calendar()
"""The default Python proleptic Gregorian calendar, goes from [0001-01-01, 9999-12-31]."""
alias UTCCalendar = Calendar(Gregorian(min_year=1970))
"""The leap day and leap second aware UTC calendar, goes from [1970-01-01, 9999-12-31]."""
alias UTCFastCal = Calendar(UTCFast())
"""UTC calendar for the fast module. Leap day aware, goes from [1970-01-01, 9999-12-31]."""
```
#### CalendarHashes
```mojo
struct CalendarHashes:
    """Hashing definitions. Up to microsecond resolution for
    the 64bit hash. Each calendar implementation can still
    override with its own definitions."""
    ...
```
#### Calendar
```mojo
struct Calendar:
    """`Calendar` interface."""

    var max_year: UInt16
    """Maximum value of years."""
    var max_typical_days_in_year: UInt16
    """Maximum typical value of days in a year (no leaps)."""
    var max_possible_days_in_year: UInt16
    """Maximum possible value of days in a year (with leaps)."""
    var max_month: UInt8
    """Maximum value of months in a year."""
    var max_hour: UInt8
    """Maximum value of hours in a day."""
    var max_minute: UInt8
    """Maximum value of minutes in an hour."""
    var max_typical_second: UInt8
    """Maximum typical value of seconds in a minute (no leaps)."""
    var max_possible_second: UInt8
    """Maximum possible value of seconds in a minute (with leaps)."""
    var max_milisecond: UInt16
    """Maximum value of miliseconds in a second."""
    var max_microsecond: UInt16
    """Maximum value of microseconds in a second."""
    var max_nanosecond: UInt16
    """Maximum value of nanoseconds in a second."""
    var min_year: UInt16
    """Default minimum year in the calendar."""
    var min_month: UInt8
    """Default minimum month."""
    var min_day: UInt8
    """Default minimum day."""
    var min_hour: UInt8
    """Default minimum hour."""
    var min_minute: UInt8
    """Default minimum minute."""
    var min_second: UInt8
    """Default minimum second."""
    var min_milisecond: UInt16
    """Default minimum milisecond."""
    var min_microsecond: UInt16
    """Default minimum microsecond."""
    var min_nanosecond: UInt16
    """Default minimum nanosecond."""
    alias _monthdays = List[UInt8]()
    """An array with the amount of days each month contains without 
    leap values. It's assumed that `len(monthdays) == max_month`."""
    var _implementation: Variant[Gregorian, UTCFast]
    ...
```

### date.mojo
#### Date
Custom `Calendar` and `TimeZone` may be passed in.
By default uses `PythonCalendar` which is a proleptic
Gregorian calendar with its given epoch and max years:
from [0001-01-01, 9999-12-31]. Default `TimeZone`
is UTC.

- Max Resolution:
    - year: Up to year 65_536.
    - month: Up to month 256.
    - day: Up to day 256.
    - hash: 32 bits.



### datetime.mojo
#### DateTime
Custom `Calendar` and `TimeZone` may be passed in.
By default, it uses `PythonCalendar` which is a Gregorian
calendar with its given epoch and max year:
[0001-01-01, 9999-12-31]. Default `TimeZone` is UTC.

- Max Resolution:
    - year: Up to year 65_536.
    - month: Up to month 256.
    - day: Up to day 256.
    - hour: Up to hour 256.
    - minute: Up to minute 256.
    - second: Up to second 256.
    - m_second: Up to m_second 65_536.
    - u_second: Up to u_second 65_536.
    - n_second: Up to n_second 65_536.
    - hash: 64 bits.


### dt_str.mojo
`DateTime` and `Date` String parsing module.
#### IsoFormat
Available formats to parse from and to [ISO 8601](https://es.wikipedia.org/wiki/ISO_8601).
### fast.mojo
Fast implementations of `DateTime` module. All assume no leap seconds.

- `DateTime64`:
    - This is a "normal" `DateTime` with milisecond resolution.
- `DateTime32`:
    - This is a "normal" `DateTime` with minute resolution.
- `DateTime16`:
    - This is a `DateTime` with hour resolution, it can be used as a 
    year, dayofyear, hour representation.
- `DateTime8`:
    - This is a `DateTime` with hour resolution, it can be used as a 
    dayofweek, hour representation.
- Notes:
    - The caveats of each implementation are better explained in 
    each struct's docstrings.

### timezone.mojo
#### TimeZone
```mojo
struct TimeZone[
    dst_storage: ZoneStorageDST = ZoneInfoMem32,
    no_dst_storage: ZoneStorageNoDST = ZoneInfoMem8,
    iana: Bool = True,
    pyzoneinfo: Bool = True,
    native: Bool = False,
]:
    """`TimeZone` struct. Because of a POSIX standard, if you set
    the tz_str e.g. Etc/UTC-4 it means 4 hours east of UTC
    which is UTC + 4 in numbers. That is:
    `TimeZone("Etc/UTC-4", offset_h=4, offset_m=0, sign=1)`. If
    `TimeZone[iana=True]("Etc/UTC-4")`, the correct offsets are
    returned for the calculations, but the attributes offset_h,
    offset_m and sign will remain the default 0, 0, 1 respectively.

    Parameters:
        dst_storage: The type of storage to use for ZoneInfo
            for zones with Dailight Saving Time. Default Memory.
        no_dst_storage: The type of storage to use for ZoneInfo
            for zones with no Dailight Saving Time. Default Memory.
        iana: Whether timezones from the [IANA database](
            http://www.iana.org/time-zones/repository/tz-link.html)
            are used. It defaults to using all available timezones,
            if getting them fails at compile time, it tries using
            python's zoneinfo if pyzoneinfo is set to True, otherwise
            it uses the offsets as is, no daylight saving or
            special exceptions. [List of TZ identifiers](
            https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
        pyzoneinfo: Whether to use python's zoneinfo and
            datetime to get full IANA support.
        native: (fast, partial IANA support) Whether to use a native Dict
            with the current timezones from the [List of TZ identifiers](
            https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
            at the time of compilation (for now they're hardcoded
            at stdlib release time, in the future it should get them
            from the OS). If it fails at compile time, it defaults to
            using the given offsets when the timezone was constructed.
    """
    ...
```

### zoneinfo.mojo
#### Offset
```mojo
struct Offset:
    """Only supports hour offsets: [0, 15] and minute offsets
    that are: {0, 30, 45}. Offset sign and minute are assumed
    to be equal in DST and STD and DST adds 1 hour to STD hour,
    unless 2 reserved bits are set which means the offset jumps 30
    minutes or 2 hours from its STD time (this was added because
    of literally [one small island](
        https://en.wikipedia.org/wiki/Lord_Howe_Island)
    and an [Antarctica research station](
        https://es.wikipedia.org/wiki/Base_Troll ))."""

    var hour: UInt8
    """Hour: [0, 15]."""
    var minute: UInt8
    """Minute: {0, 30, 45}."""
    var sign: UInt8
    """Sign: {1, -1}. Positive means east of UTC."""
    var buf: UInt8
    """Buffer."""
    ...
```
#### TzDT
```mojo
struct TzDT:
    """`TzDT` stores the rules for DST start/end."""

    var month: UInt8
    """Month: Month: [1, 12]."""
    var dow: UInt8
    """Dow: Day of week: [0, 6] (monday - sunday)."""
    var eomon: UInt8
    """Eomon: End of month: {0, 1} Whether to count from the
    beginning of the month or the end."""
    var week: UInt8
    """Week: {0, 1} If week=0 -> first week of the month,
    if it's week=1 -> second week. In the case that
    eomon=1, fw=0 -> last week of the month
    and fw=1 -> second to last."""
    var hour: UInt8
    """Hour: {20, 21, 22, 23, 0, 1, 2, 3} Hour at which DST starts/ends."""
    var buf: UInt16
    """Buffer."""
```
#### ZoneStorageDST
```mojo
trait ZoneStorageDST(CollectionElement):
    """Trait that defines ZoneInfo storage structs."""

    fn __init__(inout self):
        """Construct a `ZoneInfo`."""
        ...

    fn add(inout self, key: StringLiteral, value: ZoneDST):
        """Add a value to `ZoneInfo`.

        Args:
            key: The tz_str.
            value: ZoneDST.
        """
        ...

    fn get(self, key: StringLiteral) -> OptionalReg[ZoneDST]:
        """Get value from `ZoneInfo`.

        Args:
            key: The tz_str.

        Returns:
            An Optional `ZoneDST`.
        """
        ...
```
#### ZoneStorageNoDST
```mojo
trait ZoneStorageNoDST(CollectionElement):
    """Trait that defines ZoneInfo storage structs."""

    fn __init__(inout self):
        """Construct a `ZoneInfo`."""
        ...

    fn add(inout self, key: StringLiteral, value: Offset):
        """Add a value to `ZoneInfo`.

        Args:
            key: The tz_str.
            value: Offset.
        """
        ...

    fn get(self, key: StringLiteral) -> OptionalReg[Offset]:
        """Get value from `ZoneInfo`.

        Args:
            key: The tz_str.

        Returns:
            An Optional `Offset`.
        """
        ...
```
#### ZoneInfo
```mojo
struct ZoneInfo[T: ZoneStorageDST, A: ZoneStorageNoDST]:
    """ZoneInfo.

    Parameters:
        T: The type of storage for timezones with
            Daylight Saving Time.
        A: The type of storage for timezones with
            no Daylight Saving Time.
    """

    var with_dst: T
    """Zoneinfo for Zones with Daylight Saving Time."""
    var with_no_dst: A
    """Zoneinfo for Zones with no Daylight Saving Time."""
```