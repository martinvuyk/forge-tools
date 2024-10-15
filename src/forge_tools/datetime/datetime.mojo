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
"""Nanosecond resolution `DateTime` module.

Notes:
    - IANA is supported: [`TimeZone` and DST data sources](
        http://www.iana.org/time-zones/repository/tz-link.html).
        [List of TZ identifiers (`tz_str`)](
        https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
"""
from time import time
from utils import Variant
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

alias _cal_hash = CalendarHashes(64)
alias _max_delta = (~UInt64(0) // (365 * 24 * 60 * 60 * 1_000_000_000)).cast[
    DType.uint16
]()
"""Maximum year delta that fits in a UInt64 for a 
Gregorian calendar with year = 365 d * 24 h, 60 min, 60 s, 10^9 ns"""


trait _IntCollect(Intable, CollectionElement):
    ...


@value
# @register_passable("trivial")
struct DateTime[
    dst_storage: ZoneStorageDST = ZoneInfoMem32,
    no_dst_storage: ZoneStorageNoDST = ZoneInfoMem8,
    iana: Bool = True,
    pyzoneinfo: Bool = True,
    native: Bool = False,
    C: _Calendarized = Gregorian[],
](Hashable, Stringable):
    """Custom `Calendar` and `TimeZone` may be passed in.
    By default, it uses `PythonCalendar` which is a Gregorian
    calendar with its given epoch and max year:
    [0001-01-01, 9999-12-31]. Default `TimeZone` is UTC.

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
        - hour: Up to hour 256.
        - minute: Up to minute 256.
        - second: Up to second 256.
        - m_second: Up to m_second 65_536.
        - u_second: Up to u_second 65_536.
        - n_second: Up to n_second 65_536.
        - hash: 64 bits.

    - Notes:
        - The default hash that is used for logical and bitwise
            operations has only microsecond resolution.
        - The Default `DateTime` hash has only Microsecond resolution.
    """

    var year: UInt16
    """Year."""
    var month: UInt8
    """Month."""
    var day: UInt8
    """Day."""
    var hour: UInt8
    """Hour."""
    var minute: UInt8
    """Minute."""
    var second: UInt8
    """Second."""
    var m_second: UInt16
    """M_second."""
    var u_second: UInt16
    """U_second."""
    var n_second: UInt16
    """N_second."""
    # TODO: tz and calendar should be references
    alias _tz = TimeZone[dst_storage, no_dst_storage, iana, pyzoneinfo, native]
    var tz: Self._tz
    """Tz."""
    var calendar: Calendar[C]
    """Calendar."""
    alias _UnboundCal = DateTime[
        dst_storage, no_dst_storage, iana, pyzoneinfo, native, _
    ]

    fn __init__[
        T1: _IntCollect = Int,
        T2: _IntCollect = Int,
        T3: _IntCollect = Int,
        T4: _IntCollect = Int,
        T5: _IntCollect = Int,
        T6: _IntCollect = Int,
        T7: _IntCollect = Int,
        T8: _IntCollect = Int,
        T9: _IntCollect = Int,
    ](
        inout self,
        year: Optional[T1] = None,
        month: Optional[T2] = None,
        day: Optional[T3] = None,
        hour: Optional[T4] = None,
        minute: Optional[T5] = None,
        second: Optional[T6] = None,
        m_second: Optional[T7] = None,
        u_second: Optional[T8] = None,
        n_second: Optional[T9] = None,
        tz: Optional[Self._tz] = None,
        calendar: Calendar[C] = Calendar[C](),
    ):
        """Construct a `DateTime` from valid values.

        Parameters:
            T1: Any type that is Intable and CollectionElement.
            T2: Any type that is Intable and CollectionElement.
            T3: Any type that is Intable and CollectionElement.
            T4: Any type that is Intable and CollectionElement.
            T5: Any type that is Intable and CollectionElement.
            T6: Any type that is Intable and CollectionElement.
            T7: Any type that is Intable and CollectionElement.
            T8: Any type that is Intable and CollectionElement.
            T9: Any type that is Intable and CollectionElement.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.
            m_second: M_second.
            u_second: U_second.
            n_second: N_second.
            tz: Tz.
            calendar: Calendar.
        """

        self.year = int(year.value()) if year else int(calendar.min_year)
        self.month = int(month.value()) if month else int(calendar.min_month)
        self.day = int(day.value()) if day else int(calendar.min_day)
        self.hour = int(hour.value()) if hour else int(calendar.min_hour)
        self.minute = int(minute.value()) if minute else int(
            calendar.min_minute
        )
        self.second = int(second.value()) if second else int(
            calendar.min_second
        )
        self.m_second = int(m_second.value()) if m_second else int(
            calendar.min_milisecond
        )
        self.u_second = int(u_second.value()) if u_second else int(
            calendar.min_microsecond
        )
        self.n_second = int(n_second.value()) if n_second else int(
            calendar.min_nanosecond
        )
        self.tz = tz.value() if tz else Self._tz()
        self.calendar = calendar

    fn __init__(inout self, *, other: Self):
        """Construct self with other.

        Args:
            other: The other.
        """
        self.year = other.year
        self.month = other.month
        self.day = other.day
        self.hour = other.hour
        self.minute = other.minute
        self.second = other.second
        self.m_second = other.m_second
        self.u_second = other.u_second
        self.n_second = other.n_second
        self.tz = other.tz
        self.calendar = other.calendar

    fn __init__(inout self, *, other: Self._UnboundCal, calendar: Calendar[C]):
        """Construct self with other.

        Args:
            other: The other.
            calendar: The calendar for self.
        """
        self.year = other.year
        self.month = other.month
        self.day = other.day
        self.hour = other.hour
        self.minute = other.minute
        self.second = other.second
        self.m_second = other.m_second
        self.u_second = other.u_second
        self.n_second = other.n_second
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
        hour: Optional[UInt8] = None,
        minute: Optional[UInt8] = None,
        second: Optional[UInt8] = None,
        m_second: Optional[UInt16] = None,
        u_second: Optional[UInt16] = None,
        n_second: Optional[UInt16] = None,
        tz: Optional[Self._tz] = None,
        calendar: Optional[Calendar[T]] = None,
    ) -> Self._UnboundCal:
        """Replace with given value/s.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.
            m_second: Milisecond.
            u_second: Microsecond.
            n_second: Nanosecond.
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
        self.hour = hour.or_else(self.hour)
        self.minute = minute.or_else(self.minute)
        self.second = second.or_else(self.second)
        self.m_second = m_second.or_else(self.m_second)
        self.u_second = u_second.or_else(self.u_second)
        self.n_second = n_second.or_else(self.n_second)
        self.tz = tz.or_else(self.tz)
        if not calendar:
            return Self._UnboundCal(other=self, calendar=self.calendar)
        return Self._UnboundCal(other=self, calendar=calendar.value())

    fn to_calendar(owned self, calendar: Calendar) -> Self._UnboundCal:
        """Translates the `DateTime`'s values to be on the same offset since
        its current calendar's epoch to the new calendar's epoch.

        Args:
            calendar: The new calendar.

        Returns:
            Self.
        """

        if self.calendar == calendar:
            return self^.replace(calendar=calendar)
        year = self.year
        tmp = self.replace(calendar=self.calendar.from_year(year))
        ns = tmp.n_seconds_since_epoch()
        return Self._UnboundCal(calendar=calendar).add(
            years=int(year), n_seconds=int(ns)
        )

    fn to_utc(owned self) -> Self:
        """Returns a new instance of `Self` transformed to UTC. If
        `self.tz` is UTC it returns early.

        Returns:
            Self.
        """

        TZ_UTC = Self._tz()
        if self.tz == TZ_UTC:
            return self
        offset = self.tz.offset_at(
            self.year, self.month, self.day, self.hour, self.minute, self.second
        )
        of_h = int(offset.hour)
        of_m = int(offset.minute)
        if offset.sign == -1:
            self = self.add(hours=of_h, minutes=of_m)
        else:
            self = self.subtract(hours=of_h, minutes=of_m)
        self.tz = TZ_UTC
        return self^

    fn from_utc(owned self, tz: Self._tz) -> Self:
        """Translate `TimeZone` from UTC. If `self.tz` is UTC
        it returns early.

        Args:
            tz: Timezone to cast to.

        Returns:
            Self.
        """

        TZ_UTC = Self._tz()
        if tz == TZ_UTC:
            return self
        offset = tz.offset_at(
            self.year, self.month, self.day, self.hour, self.minute, self.second
        )
        h, m = int(offset.hour), int(offset.minute)
        var new_self: Self
        if offset.sign == 1:
            new_self = self.add(hours=h, minutes=m)
        else:
            new_self = self.subtract(hours=h, minutes=m)
        leapsecs = int(
            new_self.calendar.leapsecs_since_epoch(
                new_self.year, new_self.month, new_self.day
            )
        )
        return new_self.add(seconds=leapsecs).replace(tz=tz)

    @always_inline
    fn n_seconds_since_epoch(self) -> UInt64:
        """Nanoseconds since the begining of the calendar's epoch.
        Can only represent up to ~ 580 years since epoch start.

        Returns:
            The amount.
        """
        return self.calendar.n_seconds_since_epoch(
            self.year,
            self.month,
            self.day,
            self.hour,
            self.minute,
            self.second,
            self.m_second,
            self.u_second,
            self.n_second,
        )

    @always_inline
    fn seconds_since_epoch(self) -> UInt64:
        """Seconds since the begining of the calendar's epoch.

        Returns:
            The amount.
        """
        return self.calendar.seconds_since_epoch(
            self.year, self.month, self.day, self.hour, self.minute, self.second
        )

    fn delta_s(self, other: Self._UnboundCal) -> UInt64:
        """Calculates the difference in seconds between `self` and other.

        Args:
            other: Other.

        Returns:
            `self.seconds_since_epoch() - other.seconds_since_epoch()`.
        """

        s, o = self, other.replace(calendar=self.calendar)

        if s.tz != o.tz:
            s, o = s.to_utc(), o.to_utc()
        return s.seconds_since_epoch() - o.seconds_since_epoch()

    fn delta_ns(
        self, other: Self._UnboundCal
    ) -> (UInt64, UInt64, UInt16, UInt8):
        """Calculates the nanoseconds for `self` and other, creating
        a reference calendar to keep nanosecond resolution.

        Args:
            other: Other.

        Returns:
            - self_ns: Nanoseconds from `self` to created temp calendar.
            - other_ns: Nanoseconds from other to created temp calendar.
            - overflow: the amount of years added / subtracted from `self`
                to make the temp calendar. This occurs if the difference
                in years is bigger than ~ 580 (Gregorian years).
            - sign: {1, -1} if the overflow was added or subtracted.
        """

        s, o = self, other
        if self.tz != other.tz:
            s, o = self.to_utc(), other.to_utc()

        overflow, sign, year = UInt16(0), UInt8(1), s.year
        if s.year < o.year:
            sign = -1
            while o.year - year > _max_delta:
                year -= _max_delta
                overflow += _max_delta
        else:
            while year - o.year > _max_delta:
                year -= _max_delta
                overflow += _max_delta

        cal = self.calendar.from_year(year)
        self_ns = s.replace(calendar=cal).n_seconds_since_epoch()
        other_ns = o.replace(calendar=cal).n_seconds_since_epoch()
        return self_ns, other_ns, overflow, sign

    fn add(
        owned self,
        *,
        years: UInt = 0,
        months: UInt = 0,
        days: UInt = 0,
        hours: UInt = 0,
        minutes: UInt = 0,
        seconds: UInt = 0,
        m_seconds: UInt = 0,
        u_seconds: UInt = 0,
        n_seconds: UInt = 0,
    ) -> Self:
        """Recursively evaluated function to build a valid `DateTime`
        according to its calendar. Values are added in BigEndian order i.e.
        `years, months, ...` .

        Args:
            years: Years.
            months: Months.
            days: Days.
            hours: Hours.
            minutes: Minutes.
            seconds: Seconds.
            m_seconds: Miliseconds.
            u_seconds: Microseconds.
            n_seconds: Nanoseconds.

        Returns:
            Self.

        Notes:
            On overflow, the `DateTime` starts from the beginning of the
            calendar's epoch and keeps evaluating until valid.
        """

        max_year = int(self.calendar.max_year)
        y = int(self.year) + years
        if y > max_year:
            self.year = self.calendar.min_year
            self = self.add(years=y - (max_year + 1))
        else:
            self.year = y

        max_mon = int(self.calendar.max_month)
        mon = int(self.month) + months
        if mon > max_mon:
            self.month = self.calendar.min_month
            self = self.add(years=1, months=mon - (max_mon + 1))
        else:
            self.month = mon

        max_day = int(self.calendar.max_days_in_month(self.year, self.month))
        d = int(self.day) + days
        if d > max_day:
            self.day = self.calendar.min_day
            self = self.add(months=1, days=d - (max_day + 1))
        else:
            self.day = d

        max_hour = int(self.calendar.max_hour)
        h = int(self.hour) + hours
        if h > max_hour:
            self.hour = self.calendar.min_hour
            self = self.add(days=1, hours=h - (max_hour + 1))
        else:
            self.hour = h

        max_min = int(self.calendar.max_minute)
        mi = int(self.minute) + minutes
        if mi > max_min:
            self.minute = self.calendar.min_minute
            self = self.add(hours=1, minutes=mi - (max_min + 1))
        else:
            self.minute = mi

        max_sec = self.calendar.max_second(
            self.year, self.month, self.day, self.hour, self.minute
        )
        s = int(self.second) + seconds
        if s > int(max_sec):
            self.second = self.calendar.min_second
            self = self.add(minutes=1, seconds=s - (int(max_sec) + 1))
        else:
            self.second = s

        max_msec = int(self.calendar.max_milisecond)
        ms = int(self.m_second) + m_seconds
        if ms > max_msec:
            self.m_second = self.calendar.min_milisecond
            self = self.add(seconds=1, m_seconds=ms - (max_msec + 1))
        else:
            self.m_second = ms

        max_usec = int(self.calendar.max_microsecond)
        us = int(self.u_second) + u_seconds
        if us > max_usec:
            self.u_second = self.calendar.min_microsecond
            self = self.add(m_seconds=1, u_seconds=us - (max_usec + 1))
        else:
            self.u_second = us

        max_nsec = int(self.calendar.max_nanosecond)
        ns = int(self.n_second) + n_seconds
        if ns > max_nsec:
            self.n_second = self.calendar.min_nanosecond
            self = self.add(u_seconds=1, n_seconds=ns - (max_nsec + 1))
        else:
            self.n_second = ns
        return self^

    fn subtract(
        owned self,
        *,
        years: UInt = 0,
        months: UInt = 0,
        days: UInt = 0,
        hours: UInt = 0,
        minutes: UInt = 0,
        seconds: UInt = 0,
        m_seconds: UInt = 0,
        u_seconds: UInt = 0,
        n_seconds: UInt = 0,
    ) -> Self:
        """Recursively evaluated function to build a valid `DateTime`
        according to its calendar. Values are subtracted in LittleEndian order
        i.e. `n_seconds, u_seconds, ...` .

        Args:
            years: Years.
            months: Months.
            days: Days.
            hours: Hours.
            minutes: Minutes.
            seconds: Seconds.
            m_seconds: Miliseconds.
            u_seconds: Microseconds.
            n_seconds: Nanoseconds.

        Returns:
            Self.

        Notes:
            On overflow, the `DateTime` goes to the end of the calendar's epoch
            and keeps evaluating until valid.
        """

        min_nsec = int(self.calendar.min_nanosecond)
        ns = int(self.n_second) - n_seconds
        if ns < min_nsec:
            self.n_second = self.calendar.max_nanosecond
            self = self.subtract(
                u_seconds=1, n_seconds=(int(min_nsec) - 1) - ns
            )
        else:
            self.n_second = ns

        min_usec = int(self.calendar.min_microsecond)
        us = int(self.u_second) - u_seconds
        if us < min_usec:
            self.u_second = self.calendar.max_microsecond
            self = self.subtract(
                m_seconds=1, u_seconds=(int(min_usec) - 1) - us
            )
        else:
            self.u_second = us

        min_msec = int(self.calendar.min_milisecond)
        ms = int(self.m_second) - m_seconds
        if ms < min_msec:
            self.m_second = self.calendar.max_milisecond
            self = self.subtract(seconds=1, m_seconds=(int(min_msec) - 1) - ms)
        else:
            self.m_second = ms

        min_sec = int(self.calendar.min_second)
        s = int(self.second) - seconds
        if s < min_sec:
            sec = self.calendar.max_second(
                self.year, self.month, self.day, self.hour, self.minute
            )
            self.second = sec
            self = self.subtract(minutes=1, seconds=(int(min_sec) - 1) - s)
        else:
            self.second = s

        min_min = int(self.calendar.min_minute)
        mi = int(self.minute) - minutes
        if mi < min_min:
            self.minute = self.calendar.max_minute
            self = self.subtract(hours=1, minutes=(int(min_min) - 1) - mi)
        else:
            self.minute = mi

        min_hour = int(self.calendar.min_hour)
        h = int(self.hour) - hours
        if h < min_hour:
            self.hour = self.calendar.max_hour
            self = self.subtract(days=1, hours=(int(min_hour) - 1) - h)
        else:
            self.hour = h

        min_day = int(self.calendar.min_day)
        d = int(self.day) - days
        if d < min_day:
            self.day = 1
            self = self.subtract(months=1)
            self.day = self.calendar.max_days_in_month(self.year, self.month)
            self = self.subtract(days=(int(min_day) - 1) - d)
        else:
            self.day = d

        min_month = int(self.calendar.min_month)
        mon = int(self.month) - months
        if mon < min_month:
            self.month = self.calendar.max_month
            self = self.subtract(years=1, months=(int(min_month) - 1) - mon)
        else:
            self.month = mon

        min_year = int(self.calendar.min_year)
        y = int(self.year) - years
        if y < min_year:
            self.year = self.calendar.max_year
            self = self.subtract(years=(min_year - 1) - y)
        else:
            self.year = y
        return self^.add(days=0)  #  to correct days and months

    @always_inline
    fn add(owned self, other: Self._UnboundCal) -> Self:
        """Adds another `DateTime`.

        Args:
            other: Other.

        Returns:
            A `DateTime` with the `TimeZone` and `Calendar` of `self`.
        """
        return self.add(
            years=int(other.year),
            months=int(other.month),
            days=int(other.day),
            hours=int(other.hour),
            minutes=int(other.minute),
            seconds=int(other.second),
            m_seconds=int(other.m_second),
            u_seconds=int(other.u_second),
            n_seconds=int(other.n_second),
        )

    @always_inline
    fn subtract(owned self, other: Self._UnboundCal) -> Self:
        """Subtracts another `DateTime`.

        Args:
            other: Other.

        Returns:
            A `DateTime` with the `TimeZone` and `Calendar` of `self`.
        """
        return self.subtract(
            years=int(other.year),
            months=int(other.month),
            days=int(other.day),
            hours=int(other.hour),
            minutes=int(other.minute),
            seconds=int(other.second),
            m_seconds=int(other.m_second),
            u_seconds=int(other.u_second),
            n_seconds=int(other.n_second),
        )

    @always_inline
    fn __add__(owned self, other: Self._UnboundCal) -> Self:
        """Add.

        Args:
            other: Other.

        Returns:
            Result.
        """
        return self.add(other)

    @always_inline
    fn __sub__(owned self, other: Self._UnboundCal) -> Self:
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
        """Calculates the day of the week for a `DateTime`.

        Returns:
            Day of the week [monday, sunday]: [0, 6] (Gregorian) [1, 7]
            (ISOCalendar).
        """
        return self.calendar.day_of_week(self.year, self.month, self.day)

    @always_inline
    fn day_of_year(self) -> UInt16:
        """Calculates the day of the year for a `DateTime`.

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
            Result.
        """
        return self.calendar.hash[_cal_hash](
            self.year,
            self.month,
            self.day,
            self.hour,
            self.minute,
            self.second,
            self.m_second,
            self.u_second,
            self.n_second,
        )

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
    fn __and__[T: Hashable](self, other: T) -> UInt64:
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
    fn __or__[T: Hashable](self, other: T) -> UInt64:
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
    fn __xor__[T: Hashable](self, other: T) -> UInt64:
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
            Result.
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
        """Construct a `DateTime` from the seconds since the Unix Epoch
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
        return dt^

    @staticmethod
    fn now(
        tz: Optional[Self._tz] = None, calendar: Calendar[C] = Calendar[C]()
    ) -> Self:
        """Construct a datetime from `time.now()`.

        Args:
            tz: `TimeZone` to replace UTC.
            calendar: Calendar to replace the UTCCalendar with.

        Returns:
            Self.
        """

        zone = tz.or_else(Self._tz())
        ns = UInt16(time.now())
        dt = Self.from_unix_epoch(int(ns // 1_000_000_000), zone)
        dt.m_second, dt.u_second, dt.n_second = ns // 1_000_000, ns // 1_000, ns
        return dt^

    @always_inline
    fn strftime(self, fmt: String) -> String:
        """Formats time into a `String`.

        Args:
            fmt: Format string.

        Returns:
            The formatted string.
        """

        return dt_str.strftime(
            fmt,
            self.year,
            self.month,
            self.day,
            self.hour,
            self.minute,
            self.second,
            self.m_second,
            self.u_second,
        )

    @always_inline
    fn __format__(self, fmt: String) -> String:
        """Format.

        Args:
            fmt: Format string.

        Returns:
            String.
        """
        return self.strftime(fmt)

    @always_inline
    fn to_iso[iso: dt_str.IsoFormat = dt_str.IsoFormat()](self) -> String:
        """Return an [ISO 8601](https://es.wikipedia.org/wiki/ISO_8601)
        compliant formatted `String` e.g. `IsoFormat.YYYY_MM_DD_T_MM_HH_TZD`
        -> `1970-01-01T00:00:00+00:00` .

        Parameters:
            iso: The IsoFormat.

        Returns:
            String.
        """

        offset = self.tz.offset_at(
            self.year, self.month, self.day, self.hour, self.minute, self.second
        )
        return dt_str.to_iso[iso](
            self.year,
            self.month,
            self.day,
            self.hour,
            self.minute,
            self.second,
            offset.to_iso(),
        )

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
        """Parse a `DateTime` from a  `String`.

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
        return Self(
            p.year,
            p.month,
            p.day,
            p.hour,
            p.minute,
            p.second,
            p.m_second,
            p.u_second,
            p.n_second,
            zone,
            calendar,
        )

    @staticmethod
    fn from_iso[
        iso: dt_str.IsoFormat = dt_str.IsoFormat()
    ](
        s: String,
        tz: Optional[Self._tz] = None,
        calendar: Calendar[C] = Calendar[C](),
    ) -> Optional[Self]:
        """Construct a datetime from an
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

            year = p[0]
            month = p[1]
            day = p[2]

            @parameter
            if iso.selected in (iso.HHMMSS, iso.HH_MM_SS):
                year = calendar.min_year
                month = calendar.min_month
                day = calendar.min_day

            dt = Self(
                year, month, day, p[3], p[4], p[5], tz=p[6], calendar=calendar
            )
            if tz:
                t = tz.value()
                if t != dt.tz:
                    return dt.to_utc().from_utc(t)
            return dt
        except:
            return None

    @staticmethod
    fn from_hash(
        value: Int,
        tz: Optional[Self._tz] = None,
        calendar: Calendar[C] = Calendar[C](),
    ) -> Self:
        """Construct a `DateTime` from a hash made by it.
        Nanoseconds are set to the calendar's minimum.

        Args:
            value: The value to parse.
            tz: The `TimeZone` to designate to the result.
            calendar: The Calendar to designate to the result.

        Returns:
            Self.
        """

        zone = tz.value() if tz else Self._tz()
        d = calendar.from_hash(value)
        ns = calendar.min_nanosecond
        return Self(
            d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7], ns, zone, calendar
        )


fn timedelta[
    dst_storage: ZoneStorageDST = ZoneInfoMem32,
    no_dst_storage: ZoneStorageNoDST = ZoneInfoMem8,
    iana: Bool = True,
    pyzoneinfo: Bool = True,
    native: Bool = False,
](
    years: UInt = 0,
    months: UInt = 0,
    days: UInt = 0,
    hours: UInt = 0,
    minutes: UInt = 0,
    seconds: UInt = 0,
    m_seconds: UInt = 0,
    u_seconds: UInt = 0,
    n_seconds: UInt = 0,
    tz: Optional[
        DateTime[
            dst_storage=dst_storage,
            no_dst_storage=no_dst_storage,
            iana=iana,
            pyzoneinfo=pyzoneinfo,
            native=native,
        ]._tz
    ] = None,
) -> DateTime[
    dst_storage=dst_storage,
    no_dst_storage=no_dst_storage,
    iana=iana,
    pyzoneinfo=pyzoneinfo,
    native=native,
] as output:
    """Return a `DateTime` with `ZeroCalendar`.

    Args:
        years: The years.
        months: The months.
        days: The days.
        hours: The hours.
        minutes: The minutes.
        seconds: The seconds.
        m_seconds: The miliseconds.
        u_seconds: The microseconds.
        n_seconds: The nanoseconds.
        tz: The TimeZone for the timedelta object.

    Returns:
        A `DateTime` with a calendar set to using 0000-00-00 as epoch start.
        Beware this `DateTime` kind should only be used for adding/subtracting
        for instances in the same timezone.
    """
    output = __type_of(output)(
        int(years),
        int(months),
        int(days),
        int(hours),
        int(minutes),
        int(seconds),
        int(m_seconds),
        int(u_seconds),
        int(n_seconds),
        tz,
        ZeroCalendar,
    )
