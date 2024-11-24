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
"""`Date` module.

- Notes:
    - IANA is supported: [`TimeZone` and DST data sources](
        http://www.iana.org/time-zones/repository/tz-link.html).
        [List of TZ identifiers (`tz_str`)](
        https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
"""
from time import time
from collections.optional import Optional

from .timezone import (
    TimeZone,
    ZoneInfo,
    ZoneInfoMem32,
    ZoneInfoMem8,
    ZoneStorageDST,
    ZoneStorageNoDST,
)
from .calendar import (
    Calendar,
    UTCCalendar,
    Gregorian,
    CalendarHashes,
    _Calendarized,
)

import .dt_str


alias _cal_hash = CalendarHashes(32)


trait _IntCollect(Intable):
    ...


@value
# @register_passable("trivial")
struct Date[
    dst_storage: ZoneStorageDST = ZoneInfoMem32,
    no_dst_storage: ZoneStorageNoDST = ZoneInfoMem8,
    iana: Bool = True,
    pyzoneinfo: Bool = True,
    native: Bool = False,
    C: _Calendarized = Gregorian[],
](Hashable, Stringable):
    """Custom `Calendar` and `TimeZone` may be passed in.
    By default uses `PythonCalendar` which is a proleptic
    Gregorian calendar with its given epoch and max years:
    from [0001-01-01, 9999-12-31]. Default `TimeZone`
    is UTC.

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
        C: The type of implementation for Calendar.

    - Max Resolution:
        - year: Up to year 65_536.
        - month: Up to month 256.
        - day: Up to day 256.
        - hash: 32 bits.

    - Notes:
        - By default, PythonCalendar has min_hour set to 0,
            that means if you have timezones that have one or more
            hours less than UTC they will be set a day before
            in most calculations. If that is a problem, a custom
            Gregorian calendar with min_hour=12 can be passed
            in the constructor and most timezones will be inside
            the same day.
    """

    var year: UInt16
    """Year."""
    var month: UInt8
    """Month."""
    var day: UInt8
    """Day."""
    # TODO: tz and calendar should be references
    alias _tz = TimeZone[dst_storage, no_dst_storage, iana, pyzoneinfo, native]
    var tz: Self._tz
    """Tz."""
    var calendar: Calendar[C]
    """Calendar."""
    alias _UnboundCal = Date[
        dst_storage, no_dst_storage, iana, pyzoneinfo, native, _
    ]

    fn __init__[
        T1: _IntCollect = Int, T2: _IntCollect = Int, T3: _IntCollect = Int
    ](
        out self,
        year: Optional[T1] = None,
        month: Optional[T2] = None,
        day: Optional[T3] = None,
        tz: Optional[Self._tz] = None,
        calendar: Calendar[C] = Calendar[C](),
    ):
        """Construct a `DateTime` from valid values.

        Parameters:
            T1: Any type that is Intable and CollectionElement.
            T2: Any type that is Intable and CollectionElement.
            T3: Any type that is Intable and CollectionElement.

        Args:
            year: Year.
            month: Month.
            day: Day.
            tz: Tz.
            calendar: Calendar.
        """

        self.year = int(year.value()) if year else int(calendar.min_year)
        self.month = int(month.value()) if month else int(calendar.min_month)
        self.day = int(day.value()) if day else int(calendar.min_day)
        self.tz = tz.value() if tz else Self._tz()
        self.calendar = calendar

    fn __init__(out self, *, other: Self):
        """Construct self with other.

        Args:
            other: The other.
        """
        self.year = other.year
        self.month = other.month
        self.day = other.day
        self.tz = other.tz
        self.calendar = other.calendar

    fn __init__(out self, *, other: Self._UnboundCal, calendar: Calendar[C]):
        """Construct self with other.

        Args:
            other: The other.
            calendar: The calendar for self.
        """
        self.year = other.year
        self.month = other.month
        self.day = other.day
        self.tz = other.tz
        self.calendar = calendar

    fn replace[
        T: _Calendarized = C
    ](
        owned self,
        *,
        year: Optional[UInt16] = None,
        month: Optional[UInt8] = None,
        day: Optional[UInt8] = None,
        tz: Optional[Self._tz] = None,
        calendar: Optional[Calendar[T]] = None,
    ) -> Self._UnboundCal[T]:
        """Replace with given value/s.

        Args:
            year: Year.
            month: Month.
            day: Day.
            tz: Tz.
            calendar: Calendar to change to, distance from epoch
                is calculated and the new Self has that same
                distance from the new Calendar's epoch.

        Returns:
            Self.
        """

        self.year = year.or_else(self.year)
        self.month = month.or_else(self.month)
        self.day = day.or_else(self.day)
        self.tz = tz.or_else(self.tz)
        if not calendar:
            return Self._UnboundCal(
                other=self, calendar=rebind[Calendar[T]](self.calendar)
            )
        return Self._UnboundCal(other=self, calendar=calendar.value())

    fn to_calendar(
        owned self, calendar: Calendar
    ) -> Self._UnboundCal[__type_of(calendar).T]:
        """Translates the `Date`'s values to be on the same offset since its
        current calendar's epoch to the new calendar's epoch.

        Args:
            calendar: The new calendar.

        Returns:
            Self.
        """

        if self.calendar == calendar:
            return self.replace(calendar=calendar)
        s = self.seconds_since_epoch()
        return Self._UnboundCal(calendar=calendar).add(seconds=int(s))

    fn to_utc(owned self) -> Self:
        """Returns a new instance of `Self` transformed to UTC. If
        `self.tz` is UTC it returns early. All dates are assumed to be at
        midday with respect to UTC (UTC is at 12:00 and add/subtract offset).

        Returns:
            Self with tz casted to UTC.
        """

        TZ_UTC = Self._tz()
        if self.tz == TZ_UTC:
            return self^
        offset = self.tz.offset_at(self.year, self.month, self.day, 0, 0, 0)
        beyond_day = 12 + offset.hour + offset.minute / 60 > 24
        if beyond_day and offset.sign == -1:
            self = self.add(days=1)
        elif beyond_day and offset.sign == 1:
            self = self.subtract(days=1)

        self.tz = TZ_UTC
        return self^

    fn from_utc(owned self, tz: Self._tz) -> Self:
        """Translate `TimeZone` from UTC. If `self.tz` is UTC
        it returns early.

        Args:
            tz: `TimeZone` to cast to.

        Returns:
            Self with tz casted to given tz.
        """
        TZ_UTC = Self._tz()
        if tz == TZ_UTC:
            return self^
        maxmin = self.calendar.max_minute
        maxsec = self.calendar.max_typical_second
        offset = tz.offset_at(self.year, self.month, self.day, 0, 0, 0)
        of_h = int(offset.hour)
        of_m = int(offset.minute)
        amnt = int(of_h * maxmin * maxsec + of_m * maxsec)
        if offset.sign == 1:
            self = self.add(seconds=amnt)
        else:
            self = self.subtract(seconds=amnt)
        leapsecs = int(
            self.calendar.leapsecs_since_epoch(self.year, self.month, self.day)
        )
        return self.add(seconds=leapsecs).replace(tz=tz)

    @always_inline
    fn seconds_since_epoch(self) -> UInt64:
        """Seconds since the begining of the calendar's epoch.

        Returns:
            The amount.
        """
        y, m, d = self.year, self.month, self.day
        return self.calendar.seconds_since_epoch(y, m, d, 0, 0, 0)

    fn delta_s(self, other: Self._UnboundCal) -> UInt64:
        """Calculates the difference in seconds between `self` and other.

        Args:
            other: Other.

        Returns:
            `self.seconds_since_epoch() - other.seconds_since_epoch()`.
        """

        s = self
        o = other.replace(calendar=self.calendar)

        if s.tz != o.tz:
            s = s.to_utc()
            o = o.to_utc()
        return s.seconds_since_epoch() - o.seconds_since_epoch()

    fn add(
        owned self,
        *,
        years: UInt = 0,
        months: UInt = 0,
        days: UInt = 0,
        seconds: UInt = 0,
    ) -> Self:
        """Recursively evaluated function to build a valid `Date`
        according to its calendar. Values are added in BigEndian order i.e.
        `years, months, ...` .

        Args:
            years: Amount of years to add.
            months: Amount of months to add.
            days: Amount of days to add.
            seconds: Amount of seconds to add.

        Returns:
            Self.

        Notes:
            On overflow, the `Date` starts from the beginning of the
            calendar's epoch and keeps evaluating until valid.
        """

        max_year = int(self.calendar.max_year)
        y = int(self.year) + int(years)
        if y > max_year:
            self.year = self.calendar.min_year
            self = self.add(years=y - (max_year + 1))
        else:
            self.year = y

        max_mon = int(self.calendar.max_month)
        mon = int(self.month) + int(months)
        if mon > max_mon:
            self.month = self.calendar.min_month
            self = self.add(years=1, months=mon - (max_mon + 1))
        else:
            self.month = mon

        max_day = self.calendar.max_days_in_month(self.year, self.month)
        s_to_day = (
            int(self.calendar.max_hour + 1)
            * int(self.calendar.max_minute + 1)
            * int(self.calendar.max_typical_second + 1)
        )
        d = int(self.day) + int(days) + int(seconds) // s_to_day
        if d > int(max_day):
            self.day = self.calendar.min_day
            self = self^.add(months=1, days=d - (int(max_day) + 1))
        else:
            self.day = d
        return self^

    fn subtract(
        owned self,
        *,
        years: UInt = 0,
        months: UInt = 0,
        days: UInt = 0,
        seconds: UInt = 0,
    ) -> Self:
        """Recursively evaluated function to build a valid `Date`
        according to its calendar. Values are subtracted in LittleEndian order
        i.e. `seconds, days, ...` .

        Args:
            years: Amount of years to add.
            months: Amount of months to add.
            days: Amount of days to add.
            seconds: Amount of seconds to add.

        Returns:
            Self.

        Notes:
            On overflow, the `Date` goes to the end of the
            calendar's epoch and keeps evaluating until valid.
        """

        min_day = self.calendar.min_day
        s_to_day = (
            int(self.calendar.max_hour + 1)
            * int(self.calendar.max_minute + 1)
            * int(self.calendar.max_typical_second + 1)
        )
        d = int(self.day) - int(days) - int(seconds) // s_to_day
        if d < int(min_day):
            self.day = min_day
            self = self.subtract(months=1)
            self.day = self.calendar.max_days_in_month(self.year, self.month)
            self = self.subtract(days=(int(min_day) - 1) - d)
        else:
            self.day = d

        min_month = int(self.calendar.min_month)
        mon = int(self.month) - int(months)
        if mon < min_month:
            self.month = self.calendar.max_month
            self = self.subtract(years=1, months=(min_month - 1) - mon)
        else:
            self.month = mon

        min_year = int(self.calendar.min_year)
        y = int(self.year) - int(years)
        if y < min_year:
            self.year = self.calendar.max_year
            self = self.subtract(years=(min_year - 1) - y)
        else:
            self.year = y
        return self^.add(days=0)  #  to correct days and months

    @always_inline
    fn add(self, other: Self._UnboundCal) -> Self:
        """Adds another `Date`.

        Args:
            other: Other.

        Returns:
            A `Date` with the `TimeZone` and `Calendar` of `self`.
        """
        return self.add(
            years=int(other.year), months=int(other.month), days=int(other.day)
        )

    @always_inline
    fn subtract(self, other: Self._UnboundCal) -> Self:
        """Subtracts another `Date`.

        Args:
            other: Other.

        Returns:
            A `Date` with the `TimeZone` and `Calendar` of `self`.
        """
        return self.subtract(
            years=int(other.year), months=int(other.month), days=int(other.day)
        )

    @always_inline
    fn __add__(self, other: Self._UnboundCal) -> Self:
        """Add.

        Args:
            other: Other.

        Returns:
            Result.
        """
        return self.add(other)

    @always_inline
    fn __add__(self, other: Self) -> Self:
        """Add.

        Args:
            other: Other.

        Returns:
            Result.
        """
        return self.add(other)

    @always_inline
    fn __sub__(self, other: Self._UnboundCal) -> Self:
        """Subtract.

        Args:
            other: Other.

        Returns:
            Result.
        """
        return self.subtract(other)

    @always_inline
    fn __sub__(self, other: Self) -> Self:
        """Subtract.

        Args:
            other: Other.

        Returns:
            Result.
        """
        return self.subtract(other)

    @always_inline
    fn __iadd__(inout self, owned other: Self._UnboundCal):
        """Add Immediate.

        Args:
            other: Other.
        """
        self = self.add(other)

    @always_inline
    fn __isub__(inout self, owned other: Self._UnboundCal):
        """Subtract Immediate.

        Args:
            other: Other.
        """
        self = self.subtract(other)

    @always_inline
    fn day_of_week(self) -> UInt8:
        """Calculates the day of the week for a `Date`.

        Returns:
            Day of the week [monday, sunday]: [0, 6] (Gregorian) [1, 7]
            (ISOCalendar).
        """
        return self.calendar.day_of_week(self.year, self.month, self.day)

    @always_inline
    fn day_of_year(self) -> UInt16:
        """Calculates the day of the year for a `Date`.

        Returns:
            Day of the year: [1, 366] (for Gregorian calendar).
        """
        return self.calendar.day_of_year(self.year, self.month, self.day)

    @always_inline
    fn day_of_month(self, day_of_year: Int) -> (UInt8, UInt8):
        """Calculates the month, day of the month for a given day of the year.

        Args:
            day_of_year: The day of the year.

        Returns:
            - month: Month of the year: [1, 12] (for Gregorian calendar).
            - day: Day of the month: [1, 31] (for Gregorian calendar).
        """
        return self.calendar.day_of_month(self.year, day_of_year)

    @always_inline
    fn week_of_year(self) -> UInt8:
        """Calculates the week of the year for a given date.

        Returns:
            Week of the year: [0, 52] (Gregorian), [1, 53] (ISOCalendar).

        Notes:
            Gregorian takes the first day of the year as starting week 0,
            ISOCalendar follows [ISO 8601](\
            https://en.wikipedia.org/wiki/ISO_week_date) which takes the first
            thursday of the year as starting week 1.
        """
        return self.calendar.week_of_year(self.year, self.month, self.day)

    fn leapsecs_since_epoch(self) -> UInt32:
        """Cumulative leap seconds since the calendar's epoch start.

        Returns:
            The amount.
        """

        dt = self.to_utc()
        return dt.calendar.leapsecs_since_epoch(dt.year, dt.month, dt.day)

    @always_inline
    fn __hash__(self) -> UInt:
        """Hash.

        Returns:
            The hash.
        """
        return self.calendar.hash[_cal_hash](self.year, self.month, self.day)

    @always_inline
    fn _compare[op: StringLiteral](self, other: Self._UnboundCal) -> Bool:
        var s: UInt
        var o: UInt
        if self.tz != other.tz:
            s, o = hash(self.to_utc()), hash(other.to_utc())
        else:
            s, o = hash(self), hash(other)

        @parameter
        if op == "==":
            return s == o
        elif op == "!=":
            return s != o
        elif op == ">":
            return s > o
        elif op == ">=":
            return s >= o
        elif op == "<":
            return s < o
        elif op == "<=":
            return s <= o
        else:
            constrained[False, "nonexistent op."]()
            return False

    @always_inline
    fn __eq__(self, other: Self._UnboundCal) -> Bool:
        """Eq.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self._compare["=="](other)

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        """Eq.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self._compare["=="](other)

    @always_inline
    fn __ne__(self, other: Self._UnboundCal) -> Bool:
        """Ne.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self._compare["!="](other)

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        """Ne.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self._compare["!="](other)

    @always_inline
    fn __gt__(self, other: Self._UnboundCal) -> Bool:
        """Gt.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self._compare[">"](other)

    @always_inline
    fn __gt__(self, other: Self) -> Bool:
        """Gt.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self._compare[">"](other)

    @always_inline
    fn __ge__(self, other: Self._UnboundCal) -> Bool:
        """Ge.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self._compare[">="](other)

    @always_inline
    fn __ge__(self, other: Self) -> Bool:
        """Ge.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self._compare[">="](other)

    @always_inline
    fn __lt__(self, other: Self._UnboundCal) -> Bool:
        """Lt.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self._compare["<"](other)

    @always_inline
    fn __lt__(self, other: Self) -> Bool:
        """Lt.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self._compare["<"](other)

    @always_inline
    fn __le__(self, other: Self._UnboundCal) -> Bool:
        """Le.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self._compare["<="](other)

    @always_inline
    fn __le__(self, other: Self) -> Bool:
        """Le.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self._compare["<="](other)

    @always_inline
    fn __and__[T: Hashable](self, other: T) -> UInt32:
        """And.

        Parameters:
            T: Any Hashable type.

        Args:
            other: Other.

        Returns:
            Result.
        """
        return hash(self) & hash(other)

    @always_inline
    fn __or__[T: Hashable](self, other: T) -> UInt32:
        """Or.

        Parameters:
            T: Any Hashable type.

        Args:
            other: Other.

        Returns:
            Result.
        """
        return hash(self) | hash(other)

    @always_inline
    fn __xor__[T: Hashable](self, other: T) -> UInt32:
        """Xor.

        Parameters:
            T: Any Hashable type.

        Args:
            other: Other.

        Returns:
            Result.
        """
        return hash(self) ^ hash(other)

    @always_inline
    fn __int__(self) -> Int:
        """Int.

        Returns:
            Int.
        """
        return hash(self)

    @always_inline
    fn __str__(self) -> String:
        """Str.

        Returns:
            String.
        """
        return self.to_iso()

    @staticmethod
    fn from_unix_epoch[
        add_leap: Bool = False
    ](seconds: Int, tz: Optional[Self._tz] = None) -> Self:
        """Construct a `Date` from the seconds since the Unix Epoch
        1970-01-01. Adding the cumulative leap seconds since 1972
        to the given date.

        Parameters:
            add_leap: Whether to add the leap seconds and leap days
                since the start of the calendar's epoch.

        Args:
            seconds: Seconds.
            tz: Tz.

        Returns:
            Self.
        """

        zone = tz.value() if tz else Self._tz()
        dt = Self._UnboundCal(tz=zone, calendar=UTCCalendar).add(
            seconds=seconds
        )

        @parameter
        if add_leap:
            dt = dt.add(seconds=int(dt.leapsecs_since_epoch()))
        # FIXME: this is horrible
        return rebind[Self](
            dt.replace(
                calendar=Calendar(
                    Self.C(
                        min_year=Self.C._get_default_min_year(),
                        min_month=Self.C._get_default_min_month(),
                        min_day=Self.C._get_default_min_day(),
                        max_year=Self.C._get_default_max_year(),
                    )
                )
            )
        )

    @staticmethod
    fn now(
        tz: Optional[Self._tz] = None,
        calendar: Calendar[C] = Calendar[C](),
    ) -> Self:
        """Construct a date from `time.now()`.

        Args:
            tz: The tz to cast the result to.
            calendar: The Calendar to cast the result to.

        Returns:
            Self.
        """

        zone = tz.value() if tz else Self._tz()
        s = time.now() // 1_000_000_000
        return Self.from_unix_epoch(s, zone).replace(calendar=calendar)

    @always_inline
    fn strftime(self, fmt: String) -> String:
        """Formats time into a `String`.

        Args:
            fmt: The chosen format.

        Returns:
            String.
        """
        return dt_str.strftime(
            fmt, self.year, self.month, self.day, 0, 0, 0, 0, 0
        )

    @always_inline
    fn to_iso[iso: dt_str.IsoFormat = dt_str.IsoFormat()](self) -> String:
        """Return an [ISO 8601](https://es.wikipedia.org/wiki/ISO_8601)
        compliant formatted`String` e.g. `IsoFormat.YYYY_MM_DD` ->
         `1970-01-01` .

        Parameters:
            iso: The IsoFormat.

        Returns:
            String.
        """
        y, m, d = self.year, self.month, self.day
        offset = self.tz.offset_at(y, m, d)
        return dt_str.to_iso[iso](y, m, d, 0, 0, 0, offset.to_iso())

    @always_inline
    fn timestamp(self) -> Float64:
        """Return the POSIX timestamp (time since unix epoch).

        Returns:
            The POSIX timestamp.

        Notes:
            This is done by directly replacing the calendar with UTCCalendar,
            if the date in the current calendar is before the unix epoch
            (1970, 1, 1) this will return a very big number since it will
            overflow to the end of the calendar.
        """
        alias C = UTCCalendar
        if self.calendar == C:
            return self.seconds_since_epoch().cast[DType.float64]()
        new_s = self.replace(calendar=C).subtract(years=0).add(years=0)
        return new_s.seconds_since_epoch().cast[DType.float64]()

    @staticmethod
    fn strptime(
        s: String,
        format_str: StringLiteral,
        tz: Optional[Self._tz] = None,
        calendar: Calendar[C] = Calendar[C](),
    ) -> Optional[Self]:
        """Parse a `Date` from a  `String`.

        Args:
            s: The string.
            format_str: The format string.
            tz: The `TimeZone` to cast the result to.
            calendar: The Calendar to cast the result to.

        Returns:
            An Optional Self.
        """

        zone = tz.value() if tz else Self._tz()
        parsed = dt_str.strptime(s, format_str)
        if not parsed:
            return None
        p = parsed.value()
        dt = Self(p.year, p.month, p.day, zone, calendar)
        return dt^

    @staticmethod
    fn from_iso[
        iso: dt_str.IsoFormat = dt_str.IsoFormat(),
    ](
        s: String,
        tz: Optional[Self._tz] = None,
        calendar: Calendar[C] = Calendar[C](),
    ) -> Optional[Self]:
        """Construct a date from an
        [ISO 8601](https://es.wikipedia.org/wiki/ISO_8601) compliant
        `String`.

        Parameters:
            iso: The IsoFormat to parse.

        Args:
            s: The `String` to parse; it's assumed that it is properly formatted
                i.e. no leading whitespaces or anything different to the
                selected IsoFormat.
            tz: Optional timezone to transform the result into (taking into
                account that the format may return with a `TimeZone`).
            calendar: The calendar to which the result will belong.

        Returns:
            An Optional Self.
        """

        try:
            p = dt_str.from_iso[
                iso, dst_storage, no_dst_storage, iana, pyzoneinfo, native
            ](s)
            year, month, day = p[0], p[1], p[2]

            @parameter
            if iso.selected in (iso.HHMMSS, iso.HH_MM_SS):
                year = calendar.min_year
                month = calendar.min_month
                day = calendar.min_day

            dt = Self(year, month, day, tz=p[6], calendar=calendar)
            if tz:
                t = tz.value()
                if t != dt.tz:
                    return dt.to_utc().from_utc(t)
            return dt
        except:
            return None

    @staticmethod
    fn from_hash(
        value: UInt32,
        tz: Optional[Self._tz] = None,
        calendar: Calendar[C] = Calendar[C](),
    ) -> Self:
        """Construct a `Date` from a hash made by it.

        Args:
            value: The value to parse.
            tz: The `TimeZone` to designate to the result.
            calendar: The Calendar to designate to the result.

        Returns:
            Self.
        """

        zone = tz.value() if tz else Self._tz()
        d = calendar.from_hash[_cal_hash](int(value))
        return Self(d[0], d[1], d[2], zone, calendar)
