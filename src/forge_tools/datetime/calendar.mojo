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
"""`Calendar` module."""

from os import abort
from utils import Variant
from sys.intrinsics import likely, unlikely

from ._lists import leapsecs

alias PythonCalendar = Calendar()
"""The default Python proleptic Gregorian calendar, goes from [0001-01-01,
9999-12-31]."""
alias UTCCalendar = Calendar(Gregorian(min_year=1970))
"""The leap year and leap second aware UTC calendar, goes from [1970-01-01,
9999-12-31]."""
alias UTCFastCal = Calendar(UTCFast())
"""UTC calendar for the fast module. Leap day aware, goes from [1970-01-01,
9999-12-31]."""
alias ZeroCalendar = Calendar(min_year=0, min_month=0, min_day=0)
"""Calendar for working with timedelta-like logic."""
alias _date = (UInt16, UInt8, UInt8, UInt8, UInt8, UInt8, UInt16, UInt16)
"""Alias for the date type. Up to microsecond resolution."""


@register_passable("trivial")
struct CalendarHashes:
    """Hashing definitions. Up to microsecond resolution for
    the 64bit hash. Each calendar implementation can still
    override with its own definitions."""

    alias UINT8 = 8
    """Hash width UINT8."""
    alias UINT16 = 16
    """Hash width UINT16."""
    alias UINT32 = 32
    """Hash width UINT32."""
    alias UINT64 = 64
    """Hash width UINT64."""
    var selected: Int
    """What hash width was selected."""

    alias _17b = 0b1_1111_1111_1111_1111
    alias _12b = 0b0_0000_1111_1111_1111
    alias _10b = 0b0_0000_0011_1111_1111
    alias _9b = 0b0_0000_0001_1111_1111
    alias _6b = 0b0_0000_0000_0011_1111
    alias _5b = 0b0_0000_0000_0001_1111
    alias _4b = 0b0_0000_0000_0000_1111
    alias _3b = 0b0_0000_0000_0000_0111
    alias _2b = 0b0_0000_0000_0000_0011

    alias shift_64_y = (5 + 5 + 5 + 6 + 6 + 10 + 10)
    """Up to 131_072 years in total (-1 numeric)."""
    alias shift_64_mon = (5 + 5 + 6 + 6 + 10 + 10)
    """Up to 32 months in total (-1 numeric)."""
    alias shift_64_d = (5 + 6 + 6 + 10 + 10)
    """Up to 32 days in total (-1 numeric)."""
    alias shift_64_h = (6 + 6 + 10 + 10)
    """Up to 32 hours in total (-1 numeric)."""
    alias shift_64_m = (6 + 10 + 10)
    """Up to 64 minutes in total (-1 numeric)."""
    alias shift_64_s = (10 + 10)
    """Up to 64 seconds in total (-1 numeric)."""
    alias shift_64_ms = 10
    """Up to 1024 m_seconds in total (-1 numeric)."""
    alias shift_64_us = 0
    """Up to 1024 u_seconds in total (-1 numeric)."""
    alias mask_64_y: UInt64 = CalendarHashes._17b
    alias mask_64_mon: UInt64 = CalendarHashes._5b
    alias mask_64_d: UInt64 = CalendarHashes._5b
    alias mask_64_h: UInt64 = CalendarHashes._5b
    alias mask_64_m: UInt64 = CalendarHashes._6b
    alias mask_64_s: UInt64 = CalendarHashes._6b
    alias mask_64_ms: UInt64 = CalendarHashes._10b
    alias mask_64_us: UInt64 = CalendarHashes._10b

    alias shift_32_y = (4 + 5 + 5 + 6)
    """Up to 4096 years in total (-1 numeric)."""
    alias shift_32_mon = (5 + 5 + 6)
    """Up to 16 months in total (-1 numeric)."""
    alias shift_32_d = (5 + 6)
    """Up to 32 days in total (-1 numeric)."""
    alias shift_32_h = 6
    """Up to 32 hours in total (-1 numeric)."""
    alias shift_32_m = 0
    """Up to 64 minutes in total (-1 numeric)."""
    alias mask_32_y: UInt32 = CalendarHashes._12b
    alias mask_32_mon: UInt32 = CalendarHashes._4b
    alias mask_32_d: UInt32 = CalendarHashes._5b
    alias mask_32_h: UInt32 = CalendarHashes._5b
    alias mask_32_m: UInt32 = CalendarHashes._6b

    alias shift_16_y = (9 + 5)
    """Up to 4 years in total (-1 numeric)."""
    alias shift_16_d = 5
    """Up to 512 days in total (-1 numeric)."""
    alias shift_16_h = 0
    """Up to 32 hours in total (-1 numeric)."""
    alias mask_16_y: UInt16 = CalendarHashes._2b
    alias mask_16_d: UInt16 = CalendarHashes._9b
    alias mask_16_h: UInt16 = CalendarHashes._5b

    alias shift_8_d = 5
    """Up to 8 days in total (-1 numeric)."""
    alias shift_8_h = 0
    """Up to 32 hours in total (-1 numeric)."""
    alias mask_8_d: UInt8 = CalendarHashes._3b
    alias mask_8_h: UInt8 = CalendarHashes._5b

    @implicit
    fn __init__(out self, selected: Int = 64):
        """Construct a `CalendarHashes`.

        Args:
            selected: The selected hash bit width.
        """
        debug_assert(
            selected == self.UINT8
            or selected == self.UINT16
            or selected == self.UINT32
            or selected == self.UINT64,
            "there is no such hash size",
        )
        self.selected = selected


trait _Calendarized(CollectionElement):
    @staticmethod
    fn _get_default_max_year() -> UInt16:
        ...

    fn _get_max_year(self) -> UInt16:
        ...

    @staticmethod
    fn _get_max_typical_days_in_year() -> UInt16:
        ...

    @staticmethod
    fn _get_max_possible_days_in_year() -> UInt16:
        ...

    @staticmethod
    fn _get_max_month() -> UInt8:
        ...

    @staticmethod
    fn _get_max_hour() -> UInt8:
        ...

    @staticmethod
    fn _get_max_minute() -> UInt8:
        ...

    @staticmethod
    fn _get_max_typical_second() -> UInt8:
        ...

    @staticmethod
    fn _get_max_possible_second() -> UInt8:
        ...

    @staticmethod
    fn _get_max_milisecond() -> UInt16:
        ...

    @staticmethod
    fn _get_max_microsecond() -> UInt16:
        ...

    @staticmethod
    fn _get_max_nanosecond() -> UInt16:
        ...

    @staticmethod
    fn _get_default_min_year() -> UInt16:
        ...

    fn _get_min_year(self) -> UInt16:
        ...

    @staticmethod
    fn _get_default_min_month() -> UInt8:
        ...

    fn _get_min_month(self) -> UInt8:
        ...

    @staticmethod
    fn _get_default_min_day() -> UInt8:
        ...

    fn _get_min_day(self) -> UInt8:
        ...

    @staticmethod
    fn _get_min_hour() -> UInt8:
        ...

    @staticmethod
    fn _get_min_minute() -> UInt8:
        ...

    @staticmethod
    fn _get_min_second() -> UInt8:
        ...

    @staticmethod
    fn _get_min_milisecond() -> UInt16:
        ...

    @staticmethod
    fn _get_min_microsecond() -> UInt16:
        ...

    @staticmethod
    fn _get_min_nanosecond() -> UInt16:
        ...

    fn __init__(
        out self,
        *,
        min_year: UInt16,
        min_month: UInt8,
        min_day: UInt8,
        max_year: UInt16,
    ):
        ...

    @staticmethod
    fn is_leapyear(year: UInt16) -> Bool:
        ...

    fn is_leapsec(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
    ) -> Bool:
        ...

    fn day_of_week(self, year: UInt16, month: UInt8, day: UInt8) -> UInt8:
        ...

    fn day_of_year(self, year: UInt16, month: UInt8, day: UInt8) -> UInt16:
        ...

    fn day_of_month(self, year: UInt16, day_of_year: UInt16) -> (UInt8, UInt8):
        ...

    fn week_of_year(self, year: UInt16, month: UInt8, day: UInt8) -> UInt8:
        ...

    fn max_second(
        self, year: UInt16, month: UInt8, day: UInt8, hour: UInt8, minute: UInt8
    ) -> UInt8:
        ...

    fn max_days_in_month(self, year: UInt16, month: UInt8) -> UInt8:
        ...

    fn monthrange(self, year: UInt16, month: UInt8) -> (UInt8, UInt8):
        ...

    fn leapsecs_since_epoch(
        self, year: UInt16, month: UInt8, day: UInt8
    ) -> UInt32:
        ...

    fn leapdays_since_epoch(
        self, year: UInt16, month: UInt8, day: UInt8
    ) -> UInt32:
        ...

    fn seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
    ) -> UInt64:
        ...

    fn m_seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
        m_second: UInt16,
    ) -> UInt64:
        ...

    fn n_seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
        m_second: UInt16,
        u_second: UInt16,
        n_second: UInt16,
    ) -> UInt64:
        ...

    fn hash[
        cal_hash: CalendarHashes
    ](
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
        m_second: UInt16,
        u_second: UInt16,
        n_second: UInt16,
    ) -> Int:
        ...

    fn from_hash[cal_hash: CalendarHashes](self, value: Int) -> _date:
        ...


@value
struct Calendar[T: _Calendarized = Gregorian[]]:
    """`Calendar` struct.

    Parameters:
        T: The type of Calendar.
    """

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
    var impl: T
    """The Calendar implementation."""

    fn __init__(
        out self, min_year: UInt16, min_month: UInt8 = 1, min_day: UInt8 = 1
    ):
        """Get a Calendar with certain values.

        Args:
            min_year: Calendar year start.
            min_month: Calendar month start.
            min_day: Calendar day start.
        """

        self = Self(
            T(
                min_year=min_year,
                min_month=min_month,
                min_day=min_day,
                max_year=T._get_default_max_year(),
            )
        )

    @implicit
    fn __init__(
        out self,
        owned impl: T = T(
            min_year=T._get_default_min_year(),
            min_month=T._get_default_min_month(),
            min_day=T._get_default_min_day(),
            max_year=T._get_default_max_year(),
        ),
    ):
        """Construct a `Calendar`.

        Args:
            impl: Calendar implementation.
        """

        self.max_year = impl._get_max_year()
        self.max_typical_days_in_year = impl._get_max_typical_days_in_year()
        self.max_possible_days_in_year = impl._get_max_possible_days_in_year()
        self.max_month = impl._get_max_month()
        self.max_hour = impl._get_max_hour()
        self.max_minute = impl._get_max_minute()
        self.max_typical_second = impl._get_max_typical_second()
        self.max_possible_second = impl._get_max_possible_second()
        self.max_milisecond = impl._get_max_milisecond()
        self.max_microsecond = impl._get_max_microsecond()
        self.max_nanosecond = impl._get_max_nanosecond()
        self.min_year = impl._get_min_year()
        self.min_month = impl._get_min_month()
        self.min_day = impl._get_min_day()
        self.min_hour = impl._get_min_hour()
        self.min_minute = impl._get_min_minute()
        self.min_second = impl._get_min_second()
        self.min_milisecond = impl._get_min_milisecond()
        self.min_microsecond = impl._get_min_microsecond()
        self.min_nanosecond = impl._get_min_nanosecond()
        self.impl = impl

    fn from_year(self, year: UInt16) -> Self:
        """Build a Calendar using the given year as min_year.

        Args:
            year: The year to start the calendar.

        Returns:
            The new Calendar.
        """
        return Self(min_year=year)

    fn day_of_week(self, year: UInt16, month: UInt8, day: UInt8) -> UInt8:
        """Calculates the day of the week for a given date.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            Day of the week [monday, sunday]: [0, 6] (Gregorian) [1, 7]
            (ISOCalendar).
        """
        return self.impl.day_of_week(year, month, day)

    fn day_of_year(self, year: UInt16, month: UInt8, day: UInt8) -> UInt16:
        """Calculates the day of the year for a given date.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            Day of the year: [1, 366] (for Gregorian calendar).
        """
        return self.impl.day_of_year(year, month, day)

    fn day_of_month(self, year: UInt16, day_of_year: UInt16) -> (UInt8, UInt8):
        """Calculates the month, day of the month for a given day of the year.

        Args:
            year: Year.
            day_of_year: The day of the year.

        Returns:
            - month: Month of the year: [1, 12] (for Gregorian calendar).
            - day: Day of the month: [1, 31] (for Gregorian calendar).
        """
        return self.impl.day_of_month(year, day_of_year)

    fn week_of_year(self, year: UInt16, month: UInt8, day: UInt8) -> UInt8:
        """Calculates the week of the year for a given date.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            Week of the year: [0, 52] (Gregorian), [1, 53] (ISOCalendar).
        
        Notes:
            Gregorian takes the first day of the year as starting week 0,
            ISOCalendar follows [ISO 8601](\
            https://en.wikipedia.org/wiki/ISO_week_date) which takes the first
            thursday of the year as starting week 1.
        """
        return self.impl.week_of_year(year, month, day)

    fn max_days_in_month(self, year: UInt16, month: UInt8) -> UInt8:
        """The maximum amount of days in a given month.

        Args:
            year: Year.
            month: Month.

        Returns:
            The amount of days.
        """
        return self.impl.max_days_in_month(year, month)

    fn monthrange(self, year: UInt16, month: UInt8) -> (UInt8, UInt8):
        """Returns day of the week for the first day of the month and number of
        days in month, for the specified year and month.

        Args:
            year: Year.
            month: Month.

        Returns:
            - day_of_week: Day of the week.
            - day_of_month: Day of the month.
        """
        return self.impl.monthrange(year, month)

    fn max_second(
        self, year: UInt16, month: UInt8, day: UInt8, hour: UInt8, minute: UInt8
    ) -> UInt8:
        """The maximum amount of seconds in a minute (usually 59).

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.

        Returns:
            The amount.
        """
        return self.impl.max_second(year, month, day, hour, minute)

    fn is_leapsec(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
    ) -> Bool:
        """Whether the second is a leap second.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.

        Returns:
            Bool.
        """
        return self.impl.is_leapsec(year, month, day, hour, minute, second)

    fn leapsecs_since_epoch(
        self, year: UInt16, month: UInt8, day: UInt8
    ) -> UInt32:
        """Cumulative leap seconds since the calendar's epoch start.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            The amount.
        """
        return self.impl.leapsecs_since_epoch(year, month, day)

    fn leapdays_since_epoch(
        self, year: UInt16, month: UInt8, day: UInt8
    ) -> UInt32:
        """Cumulative leap days since the calendar's epoch start.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            The amount.
        """
        return self.impl.leapdays_since_epoch(year, month, day)

    fn seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
    ) -> UInt64:
        """Seconds since the begining of the calendar's epoch.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.

        Returns:
            The amount.
        """
        return self.impl.seconds_since_epoch(
            year, month, day, hour, minute, second
        )

    fn m_seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
        m_second: UInt16,
    ) -> UInt64:
        """Miliseconds since the begining of the calendar's epoch.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.
            m_second: Milisecond.

        Returns:
            The amount.
        """
        return self.impl.m_seconds_since_epoch(
            year, month, day, hour, minute, second, m_second
        )

    fn n_seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
        m_second: UInt16,
        u_second: UInt16,
        n_second: UInt16,
    ) -> UInt64:
        """Nanoseconds since the begining of the calendar's epoch.
        Can only represent up to ~ 580 years since epoch start.

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

        Returns:
            The amount.
        """
        return self.impl.n_seconds_since_epoch(
            year, month, day, hour, minute, second, m_second, u_second, n_second
        )

    fn hash[
        cal_hash: CalendarHashes = CalendarHashes()
    ](
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8 = 0,
        minute: UInt8 = 0,
        second: UInt8 = 0,
        m_second: UInt16 = 0,
        u_second: UInt16 = 0,
        n_second: UInt16 = 0,
    ) -> Int:
        """Hash the given values according to the calendar's bitshifted
        component lengths, BigEndian (i.e. yyyymmdd...).

        Parameters:
            cal_hash: The hashing schema (CalendarHashes).

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

        Returns:
            The hash.
        """
        return self.impl.hash[cal_hash](
            year, month, day, hour, minute, second, m_second, u_second, n_second
        )

    fn from_hash[
        cal_hash: CalendarHashes = CalendarHashes()
    ](self, value: Int) -> _date:
        """Build a date from a hashed value.

        Parameters:
            cal_hash: The hashing schema (CalendarHashes).

        Args:
            value: The Hash.

        Returns:
            Tuple containing date data.
        """
        return self.impl.from_hash[cal_hash](value)

    fn is_leapyear(self, year: UInt16) -> Bool:
        """Whether the year is a leap year.

        Args:
            year: Year.

        Returns:
            Bool.
        """
        return self.impl.is_leapyear(year)

    fn __eq__(self, other: Calendar) -> Bool:
        """Compare self with other.

        Args:
            other: The other.

        Returns:
            The result.
        """
        return (
            self.max_year == other.max_year
            and self.max_typical_days_in_year == other.max_typical_days_in_year
            and self.max_possible_days_in_year
            == other.max_possible_days_in_year
            and self.max_month == other.max_month
            and self.max_hour == other.max_hour
            and self.max_minute == other.max_minute
            and self.max_typical_second == other.max_typical_second
            and self.max_possible_second == other.max_possible_second
            and self.max_milisecond == other.max_milisecond
            and self.max_microsecond == other.max_microsecond
            and self.max_nanosecond == other.max_nanosecond
            and self.min_year == other.min_year
            and self.min_month == other.min_month
            and self.min_day == other.min_day
            and self.min_hour == other.min_hour
            and self.min_minute == other.min_minute
            and self.min_second == other.min_second
            and self.min_milisecond == other.min_milisecond
            and self.min_microsecond == other.min_microsecond
            and self.min_nanosecond == other.min_nanosecond
        )

    fn __ne__(self, other: Calendar) -> Bool:
        """Compare self with other.

        Args:
            other: The other.

        Returns:
            The result.
        """
        return not (self == other)


alias _m: UInt16 = 2**16 - 1


@value
struct Gregorian[include_leapsecs: Bool = True](_Calendarized):
    """`Gregorian` Calendar.

    Parameters:
        include_leapsecs: Whether to include leap seconds in calculations.
    """

    alias _default_max_year: UInt16 = 9999
    var _max_year: UInt16
    alias _max_typical_days_in_year: UInt16 = 365
    alias _max_possible_days_in_year: UInt16 = 366
    alias _max_month: UInt8 = 12
    alias _max_hour: UInt8 = 23
    alias _max_minute: UInt8 = 59
    alias _max_typical_second: UInt8 = 59
    alias _max_possible_second: UInt8 = 60
    alias _max_milisecond: UInt16 = 999
    alias _max_microsecond: UInt16 = 999
    alias _max_nanosecond: UInt16 = 999
    alias _default_min_year: UInt16 = 1
    var _min_year: UInt16
    alias _default_min_month: UInt8 = 1
    var _min_month: UInt8
    alias _default_min_day: UInt8 = 1
    var _min_day: UInt8
    alias _min_hour: UInt8 = 0
    alias _min_minute: UInt8 = 0
    alias _min_second: UInt8 = 0
    alias _min_milisecond: UInt16 = 0
    alias _min_microsecond: UInt16 = 0
    alias _min_nanosecond: UInt16 = 0
    alias _monthdays = List[UInt8](
        0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
    )
    alias _days_before_month = SIMD[DType.uint16, 16](
        0, 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, _m, _m, _m
    )

    fn __init__(
        out self,
        min_year: UInt16 = Self._default_min_year,
        min_month: UInt8 = Self._default_min_month,
        min_day: UInt8 = Self._default_min_day,
        *,
        max_year: UInt16 = Self._default_max_year,
    ):
        """Construct a `Gregorian` Calendar from values.

        Args:
            min_year: Min year (epoch start).
            min_month: Min month (epoch start).
            min_day: Min day (epoch start).
            max_year: Max year (epoch end).
        """
        self._max_year = max_year
        self._min_month = min_month
        self._min_day = min_day
        self._min_year = min_year

    @staticmethod
    fn _get_default_max_year() -> UInt16:
        return Self._default_max_year

    fn _get_max_year(self) -> UInt16:
        return self._max_year

    @staticmethod
    fn _get_max_typical_days_in_year() -> UInt16:
        return Self._max_typical_days_in_year

    @staticmethod
    fn _get_max_possible_days_in_year() -> UInt16:
        return Self._max_possible_days_in_year

    @staticmethod
    fn _get_max_month() -> UInt8:
        return Self._max_month

    @staticmethod
    fn _get_max_hour() -> UInt8:
        return Self._max_hour

    @staticmethod
    fn _get_max_minute() -> UInt8:
        return Self._max_minute

    @staticmethod
    fn _get_max_typical_second() -> UInt8:
        return Self._max_typical_second

    @staticmethod
    fn _get_max_possible_second() -> UInt8:
        return Self._max_possible_second

    @staticmethod
    fn _get_max_milisecond() -> UInt16:
        return Self._max_milisecond

    @staticmethod
    fn _get_max_microsecond() -> UInt16:
        return Self._max_microsecond

    @staticmethod
    fn _get_max_nanosecond() -> UInt16:
        return Self._max_nanosecond

    @staticmethod
    fn _get_default_min_year() -> UInt16:
        return Self._default_min_year

    fn _get_min_year(self) -> UInt16:
        return self._min_year

    @staticmethod
    fn _get_default_min_month() -> UInt8:
        return Self._default_min_month

    fn _get_min_month(self) -> UInt8:
        return self._min_month

    @staticmethod
    fn _get_default_min_day() -> UInt8:
        return Self._default_min_day

    fn _get_min_day(self) -> UInt8:
        return self._min_day

    @staticmethod
    fn _get_min_hour() -> UInt8:
        return Self._min_hour

    @staticmethod
    fn _get_min_minute() -> UInt8:
        return Self._min_minute

    @staticmethod
    fn _get_min_second() -> UInt8:
        return Self._min_second

    @staticmethod
    fn _get_min_milisecond() -> UInt16:
        return Self._min_milisecond

    @staticmethod
    fn _get_min_microsecond() -> UInt16:
        return Self._min_microsecond

    @staticmethod
    fn _get_min_nanosecond() -> UInt16:
        return Self._min_nanosecond

    fn monthrange(self, year: UInt16, month: UInt8) -> (UInt8, UInt8):
        """Returns day of the week for the first day of the month and number of
        days in month, for the specified year and month.

        Args:
            year: Year.
            month: Month.

        Returns:
            - day_of_week: Day of the week.
            - day_of_month: Day of the month.
        """

        return self.day_of_week(year, month, 1), self.max_days_in_month(
            year, month
        )

    fn max_second(
        self, year: UInt16, month: UInt8, day: UInt8, hour: UInt8, minute: UInt8
    ) -> UInt8:
        """The maximum amount of seconds that a minute lasts (usually 59).
        Some years its 60 when a leap second is added. The spec also lists
        the posibility of 58 seconds but it stil hasn't ben done.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.

        Returns:
            The amount.
        """

        @parameter
        if include_leapsecs:
            if self.is_leapsec(year, month, day, hour, minute, 59):
                return 60
        return 59

    fn max_days_in_month(self, year: UInt16, month: UInt8) -> UInt8:
        """The maximum amount of days in a given month.

        Args:
            year: Year.
            month: Month.

        Returns:
            The amount of days.
        """

        days = Self._monthdays[Int(month)]
        return days + Int(unlikely(month == 2 and Self.is_leapyear(year)))

    @always_inline
    fn day_of_week(self, year: UInt16, month: UInt8, day: UInt8) -> UInt8:
        """Calculates the day of the week for a given date.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            Day of the week [monday, sunday]: [0, 6] (Gregorian) [1, 7]
            (ISOCalendar).
        """
        return (Self.days_since_epoch(year, month, day) % 7).cast[DType.uint8]()

    @always_inline
    @staticmethod
    fn day_of_year(year: UInt16, month: UInt8, day: UInt8) -> UInt16:
        """Calculates the day of the year for a given date.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            Day of the year: [1, 366] (for Gregorian calendar).
        """
        total = UInt16(Int(month > 2 and Self.is_leapyear(year)))
        total += Self._days_before_month[Int(month)].cast[DType.uint16]()
        return total + day.cast[DType.uint16]()

    fn day_of_year(self, year: UInt16, month: UInt8, day: UInt8) -> UInt16:
        """Calculates the day of the year for a given date.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            Day of the year: [1, 366] (for Gregorian calendar).
        """
        return Self.day_of_year(year, month, day)

    fn day_of_month(self, year: UInt16, day_of_year: UInt16) -> (UInt8, UInt8):
        """Calculates the month, day of the month for a given day of the year.

        Args:
            year: Year.
            day_of_year: The day of the year.

        Returns:
            - month: Month of the year: [1, 12] (for Gregorian calendar).
            - day: Day of the month: [1, 31] (for Gregorian calendar).
        """

        c = (Self._days_before_month < day_of_year).cast[DType.uint8]()
        idx = c.reduce_add() - 1
        rest = day_of_year - Self._days_before_month[Int(idx)]
        rest -= Int(idx > 2 and Self.is_leapyear(year))
        return idx, rest.cast[DType.uint8]()

    @always_inline
    fn week_of_year(self, year: UInt16, month: UInt8, day: UInt8) -> UInt8:
        """Calculates the week of the year for a given date.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            Week of the year: [0, 52] (Gregorian), [1, 53] (ISOCalendar).
        
        Notes:
            Gregorian takes the first day of the year as starting week 0,
            ISOCalendar follows [ISO 8601](\
            https://en.wikipedia.org/wiki/ISO_week_date) which takes the first
            thursday of the year as starting week 1.
        """
        return (self.day_of_year(year, month, day) // 7).cast[DType.uint8]()

    @always_inline
    fn is_leapyear(self, year: UInt16) -> Bool:
        """Whether the year is a leap year.

        Args:
            year: Year.

        Returns:
            Bool.
        """
        return Self.is_leapyear(year)

    fn is_leapsec(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
    ) -> Bool:
        """Whether the second is a leap second.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.

        Returns:
            Bool.
        """

        @parameter
        if not include_leapsecs:
            return False

        if unlikely(
            hour == 23
            and minute == 59
            and second == 59
            and (month == 6 or month == 12)
            and (day == 30 or day == 31)
        ):
            alias calh32 = CalendarHashes(CalendarHashes.UINT32)
            h = UInt32(self.hash[calh32](year, month, day))
            for i in range(len(leapsecs)):
                if h == leapsecs[i]:
                    return True
            return False
        return False

    fn leapsecs_since_epoch(
        self, year: UInt16, month: UInt8, day: UInt8
    ) -> UInt32:
        """Cumulative leap seconds since the calendar's epoch start.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            The amount.
        """

        @parameter
        if not include_leapsecs:
            return 0

        if unlikely(year < 1972):
            return 0
        size = len(leapsecs)
        alias calh32 = CalendarHashes(CalendarHashes.UINT32)
        h = UInt32(self.hash[calh32](year, month, day))
        last = leapsecs[size - 1]
        if h > last:
            if not self.is_default_calendar() and last < self.hash[calh32](
                self._min_year, self._min_month, self._min_day
            ):
                return 0
            return size
        amnt = 0
        for i in range(size):
            if h < leapsecs[i]:
                return amnt
            amnt += 1
        return amnt

    @always_inline
    @staticmethod
    fn leapdays_since_epoch(year: UInt16, month: UInt8, day: UInt8) -> UInt32:
        """Cumulative leap days since the calendar's default epoch start.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            The amount.
        """
        y = Int(year - 1)
        l = Self.is_leapyear(year) and (month > 2 or (month == 2 and day == 29))
        return y // 4 - y // 100 + y // 400 + Int(l)

    @always_inline("nodebug")
    fn is_default_calendar(self) -> Bool:
        return likely(
            self._min_year == Self._default_min_year
            and self._min_month == Self._default_min_month
            and self._min_day == Self._default_min_day
        )

    @always_inline
    fn leapdays_since_epoch(
        self, year: UInt16, month: UInt8, day: UInt8
    ) -> UInt32:
        """Cumulative leap days since the calendar's epoch start.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            The amount.
        """
        l1 = Self.leapdays_since_epoch(year, month, day)
        if self.is_default_calendar():
            return l1
        y, m, d = self._min_year, self._min_month, self._min_day
        return l1 - Self.leapdays_since_epoch(y, m, d)

    @always_inline
    @staticmethod
    fn days_since_epoch(year: UInt16, month: UInt8, day: UInt8) -> UInt32:
        """Cumulative days since the calendar's default epoch start.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            The amount: [0, 9998].
        """
        leapdays1 = Self.leapdays_since_epoch(year, 1, 1)
        y_d1 = (year.cast[DType.uint32]() - 1) * 365 + leapdays1
        doy = Self.day_of_year(year, month, day).cast[DType.uint32]()
        return y_d1 + doy - 1

    @always_inline
    fn days_since_epoch(self, year: UInt16, month: UInt8, day: UInt8) -> UInt32:
        """Cumulative days since the calendar's epoch start.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            The amount: [0, 9998].
        """
        d1 = Self.days_since_epoch(year, month, day)

        if self.is_default_calendar():
            return d1
        y, m, d = self._min_year, self._min_month, self._min_day
        return d1 - Self.days_since_epoch(y, m, d)

    fn seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
    ) -> UInt64:
        """Seconds since the begining of the calendar's epoch.
        Takes leap seconds added to UTC up to the given datetime into
        account.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.

        Returns:
            The amount.
        """
        alias min_to_sec: UInt64 = 60
        alias hours_to_sec: UInt64 = 60 * min_to_sec
        alias days_to_sec: UInt64 = 24 * hours_to_sec

        d = self.days_since_epoch(year, month, day).cast[DType.uint64]()
        h = (hour - self._min_hour).cast[DType.uint64]() * hours_to_sec
        m = (minute - self._min_minute).cast[DType.uint64]() * min_to_sec
        s = (second - self._min_second).cast[DType.uint64]()
        leaps = self.leapsecs_since_epoch(year, month, day)
        return (d * days_to_sec + h + m + s) - leaps.cast[DType.uint64]()

    fn m_seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
        m_second: UInt16,
    ) -> UInt64:
        """Miliseconds since the begining of the calendar's epoch.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.
            m_second: Milisecond.

        Returns:
            The amount.
        """
        secs = (
            self.seconds_since_epoch(year, month, day, hour, minute, second)
            * 1000
        )
        return secs + (m_second - self._min_milisecond).cast[DType.uint64]()

    fn n_seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
        m_second: UInt16,
        u_second: UInt16,
        n_second: UInt16,
    ) -> UInt64:
        """Nanoseconds since the begining of the calendar's epoch. Takes leap
        seconds added to UTC up to the given datetime into account. Can only
        represent up to ~ 580 years since epoch start.

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

        Returns:
            The amount.
        """
        ms = (
            self.m_seconds_since_epoch(
                year, month, day, hour, minute, second, m_second
            )
            * 1_000_000
        )
        min_u_sec = UInt16(self._min_microsecond)
        us = (u_second - min_u_sec).cast[DType.uint64]() * 1_000
        ns_d = (n_second - UInt16(self._min_nanosecond)).cast[DType.uint64]()
        return ms + us + ns_d

    fn hash[
        cal_h: CalendarHashes = CalendarHashes()
    ](
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8 = 0,
        minute: UInt8 = 0,
        second: UInt8 = 0,
        m_second: UInt16 = 0,
        u_second: UInt16 = 0,
        n_second: UInt16 = 0,
    ) -> Int:
        """Hash the given values according to the calendar's bitshifted
        component lengths, BigEndian (i.e. yyyymmdd...).

        Parameters:
            cal_h: The hashing schema (CalendarHashes).

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

        Returns:
            The hash.
        """

        _ = self, n_second
        result = 0

        @parameter
        if cal_h.selected == cal_h.UINT8:
            pass
        elif cal_h.selected == cal_h.UINT16:
            pass
        elif cal_h.selected == cal_h.UINT32:  # hash for `Date`
            result = (Int(year) << (5 + 5)) | (Int(month) << 5) | Int(day)
        elif cal_h.selected == cal_h.UINT64:  # hash for `DateTime`
            result = (
                (Int(year) << cal_h.shift_64_y)
                | (Int(month) << cal_h.shift_64_mon)
                | (Int(day) << cal_h.shift_64_d)
                | (Int(hour) << cal_h.shift_64_h)
                | (Int(minute) << cal_h.shift_64_m)
                | (Int(second) << cal_h.shift_64_s)
                | (Int(m_second) << cal_h.shift_64_ms)
                | (Int(u_second) << cal_h.shift_64_us)
            )
        return result

    fn from_hash[
        cal_h: CalendarHashes = CalendarHashes()
    ](self, value: Int) -> _date:
        """Build a date from a hashed value.

        Parameters:
            cal_h: The hashing schema (CalendarHashes).

        Args:
            value: The Hash.

        Returns:
            Tuple containing date data.
        """
        _ = self
        num8 = UInt8(0)
        num16 = UInt16(0)
        result = (num16, num8, num8, num8, num8, num8, num16, num16)

        @parameter
        if cal_h.selected == cal_h.UINT8:
            pass
        elif cal_h.selected == cal_h.UINT16:
            pass
        elif cal_h.selected == cal_h.UINT32:  # hash for `Date`
            result[0] = Int(value >> (5 + 5))
            result[1] = Int((value >> 5) & 0b1_1111)
            result[2] = Int(value & 0b1_1111)
        elif cal_h.selected == cal_h.UINT64:  # hash for `DateTime`
            result[0] = Int((value >> cal_h.shift_64_y) & cal_h.mask_64_y)
            result[1] = Int((value >> cal_h.shift_64_mon) & cal_h.mask_64_mon)
            result[2] = Int((value >> cal_h.shift_64_d) & cal_h.mask_64_d)
            result[3] = Int((value >> cal_h.shift_64_h) & cal_h.mask_64_h)
            result[4] = Int((value >> cal_h.shift_64_m) & cal_h.mask_64_m)
            result[5] = Int((value >> cal_h.shift_64_s) & cal_h.mask_64_s)
            result[6] = Int((value >> cal_h.shift_64_ms) & cal_h.mask_64_ms)
            result[7] = Int((value >> cal_h.shift_64_us) & cal_h.mask_64_us)
        return result^

    @staticmethod
    @always_inline
    fn is_leapyear(year: UInt16) -> Bool:
        """Whether the year is a leap year.

        Args:
            year: Year.

        Returns:
            Bool.
        """
        return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)


@value
struct UTCFast(_Calendarized):
    """`UTCFast` Calendar."""

    var _greg: Gregorian[include_leapsecs=False]

    fn __init__(
        out self,
        *,
        min_year: UInt16 = 1970,
        min_month: UInt8 = 1,
        min_day: UInt8 = 1,
        max_year: UInt16 = 9999,
    ):
        """Construct a `UTCFast` Calendar from values.

        Args:
            min_year: Min year (epoch start).
            min_month: Min month (epoch start).
            min_day: Min day (epoch start).
            max_year: Max year (epoch end).
        """
        self._greg = Gregorian[include_leapsecs=False](
            min_year, min_month, min_day, max_year=max_year
        )

    @always_inline
    fn monthrange(self, year: UInt16, month: UInt8) -> (UInt8, UInt8):
        """Returns day of the week for the first day of the month and number of
        days in month, for the specified year and month.

        Args:
            year: Year.
            month: Month.

        Returns:
            - day_of_week: Day of the week.
            - day_of_month: Day of the month.
        """
        return self.day_of_week(year, month, 1), self.max_days_in_month(
            year, month
        )

    @always_inline
    fn max_second(
        self, year: UInt16, month: UInt8, day: UInt8, hour: UInt8, minute: UInt8
    ) -> UInt8:
        """The maximum amount of seconds that a minute lasts (usually 59).
        Some years its 60 when a leap second is added. The spec also lists
        the posibility of 58 seconds but it stil hasn't ben done.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.

        Returns:
            The amount.
        """
        return self._greg.max_second(year, month, day, hour, minute)

    @always_inline
    fn max_days_in_month(self, year: UInt16, month: UInt8) -> UInt8:
        """The maximum amount of days in a given month.

        Args:
            year: Year.
            month: Month.

        Returns:
            The amount of days.
        """
        return self._greg.max_days_in_month(year, month)

    @always_inline
    fn day_of_week(self, year: UInt16, month: UInt8, day: UInt8) -> UInt8:
        """Calculates the day of the week for a given date.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            Day of the week [monday, sunday]: [0, 6] (Gregorian) [1, 7]
            (ISOCalendar).
        """
        return self._greg.day_of_week(year, month, day)

    @always_inline
    fn day_of_year(self, year: UInt16, month: UInt8, day: UInt8) -> UInt16:
        """Calculates the day of the year for a given date.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            Day of the year: [1, 366] (for Gregorian calendar).
        """
        return self._greg.day_of_year(year, month, day)

    @always_inline
    fn day_of_month(self, year: UInt16, day_of_year: UInt16) -> (UInt8, UInt8):
        """Calculates the month, day of the month for a given day of the year.

        Args:
            year: Year.
            day_of_year: The day of the year.

        Returns:
            - month: Month of the year: [1, 12] (for Gregorian calendar).
            - day: Day of the month: [1, 31] (for Gregorian calendar).
        """
        return self._greg.day_of_month(year, day_of_year)

    @always_inline
    fn week_of_year(self, year: UInt16, month: UInt8, day: UInt8) -> UInt8:
        """Calculates the week of the year for a given date.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            Week of the year: [0, 52] (Gregorian), [1, 53] (ISOCalendar).
        
        Notes:
            Gregorian takes the first day of the year as starting week 0,
            ISOCalendar follows [ISO 8601](\
            https://en.wikipedia.org/wiki/ISO_week_date) which takes the first
            thursday of the year as starting week 1.
        """
        return self._greg.week_of_year(year, month, day)

    @always_inline
    fn is_leapyear(self, year: UInt16) -> Bool:
        """Whether the year is a leap year.

        Args:
            year: Year.

        Returns:
            Bool.
        """
        return Self.is_leapyear(year)

    @always_inline
    fn is_leapsec(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
    ) -> Bool:
        """Whether the second is a leap second.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.

        Returns:
            Bool.
        """
        return self._greg.is_leapsec(year, month, day, hour, minute, second)

    @always_inline
    fn leapsecs_since_epoch(
        self, year: UInt16, month: UInt8, day: UInt8
    ) -> UInt32:
        """Cumulative leap seconds since the calendar's epoch start.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            The amount.
        """
        return self._greg.leapsecs_since_epoch(year, month, day)

    @always_inline
    fn leapdays_since_epoch(
        self, year: UInt16, month: UInt8, day: UInt8
    ) -> UInt32:
        """Cumulative leap days since the calendar's epoch start.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            The amount.
        """
        return self._greg.leapdays_since_epoch(year, month, day)

    @always_inline
    fn days_since_epoch(self, year: UInt16, month: UInt8, day: UInt8) -> UInt32:
        """Cumulative days since the calendar's epoch start.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            The amount: [0, 9998].
        """
        return self._greg.days_since_epoch(year, month, day)

    @always_inline
    fn seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
    ) -> UInt64:
        """Seconds since the begining of the calendar's epoch.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.

        Returns:
            The amount.
        """
        return self._greg.seconds_since_epoch(
            year, month, day, hour, minute, second
        )

    @always_inline
    fn m_seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
        m_second: UInt16,
    ) -> UInt64:
        """Miliseconds since the begining of the calendar's epoch.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.
            m_second: Milisecond.

        Returns:
            The amount.
        """
        return self._greg.m_seconds_since_epoch(
            year, month, day, hour, minute, second, m_second
        )

    @always_inline
    fn n_seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
        m_second: UInt16,
        u_second: UInt16,
        n_second: UInt16,
    ) -> UInt64:
        """Nanoseconds since the begining of the calendar's epoch. Takes leap
        seconds added to UTC up to the given datetime into account. Can only
        represent up to ~ 580 years since epoch start.

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

        Returns:
            The amount.
        """
        return self._greg.n_seconds_since_epoch(
            year, month, day, hour, minute, second, m_second, u_second, n_second
        )

    fn hash[
        cal_h: CalendarHashes = CalendarHashes()
    ](
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8 = 0,
        minute: UInt8 = 0,
        second: UInt8 = 0,
        m_second: UInt16 = 0,
        u_second: UInt16 = 0,
        n_second: UInt16 = 0,
    ) -> Int:
        """Hash the given values according to the calendar's bitshifted
        component lengths, BigEndian (i.e. yyyymmdd...).

        Parameters:
            cal_h: The hashing schema (CalendarHashes).

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

        Returns:
            The hash.
        """

        _ = u_second, n_second
        result = 0

        @parameter
        if cal_h.selected == cal_h.UINT8:
            result = (Int(day) << cal_h.shift_8_d) | (
                Int(hour) << cal_h.shift_8_h
            )
        elif cal_h.selected == cal_h.UINT16:
            result = (
                (Int(year) << cal_h.shift_16_y)
                | (Int(self.day_of_year(year, month, day)) << cal_h.shift_16_d)
                | (Int(hour) << cal_h.shift_16_h)
            )
        elif cal_h.selected == cal_h.UINT32:
            result = (
                (Int(year) << cal_h.shift_32_y)
                | (Int(month) << cal_h.shift_32_mon)
                | (Int(day) << cal_h.shift_32_d)
                | (Int(hour) << cal_h.shift_32_h)
                | (Int(minute) << cal_h.shift_32_m)
            )
        elif cal_h.selected == cal_h.UINT64:
            result = (
                (Int(year) << (cal_h.shift_64_y - cal_h.shift_64_ms))
                | (Int(month) << (cal_h.shift_64_mon - cal_h.shift_64_ms))
                | (Int(day) << (cal_h.shift_64_d - cal_h.shift_64_ms))
                | (Int(hour) << (cal_h.shift_64_h - cal_h.shift_64_ms))
                | (Int(minute) << (cal_h.shift_64_m - cal_h.shift_64_ms))
                | (Int(second) << (cal_h.shift_64_s - cal_h.shift_64_ms))
                | Int(m_second)
            )
        return result

    fn from_hash[
        cal_h: CalendarHashes = CalendarHashes()
    ](self, value: Int) -> _date:
        """Build a date from a hashed value.

        Parameters:
            cal_h: The hashing schema (CalendarHashes).

        Args:
            value: The Hash.

        Returns:
            Tuple containing date data.
        """

        num8 = UInt8(0)
        num16 = UInt16(0)
        result = (num16, num8, num8, num8, num8, num8, num16, num16)

        @parameter
        if cal_h.selected == cal_h.UINT8:
            result[2] = Int((value >> cal_h.shift_8_d) & cal_h.mask_8_d)
            result[3] = Int((value >> cal_h.shift_8_h) & cal_h.mask_8_h)
        elif cal_h.selected == cal_h.UINT16:
            result[0] = Int((value >> cal_h.shift_16_y) & cal_h.mask_16_y)
            doy = Int((value >> cal_h.shift_16_d) & cal_h.mask_16_d)
            res = self.day_of_month(result[0], doy)
            result[1] = res[0]
            result[2] = res[1]
            result[3] = Int((value >> cal_h.shift_16_h) & cal_h.mask_16_h)
        elif cal_h.selected == cal_h.UINT32:
            result[0] = Int((value >> cal_h.shift_32_y) & cal_h.mask_32_y)
            result[1] = Int((value >> cal_h.shift_32_mon) & cal_h.mask_32_mon)
            result[2] = Int((value >> cal_h.shift_32_d) & cal_h.mask_32_d)
            result[3] = Int((value >> cal_h.shift_32_h) & cal_h.mask_32_h)
            result[4] = Int((value >> cal_h.shift_32_m) & cal_h.mask_32_m)
        elif cal_h.selected == cal_h.UINT64:
            result[0] = Int(
                (value >> (cal_h.shift_64_y - cal_h.shift_64_ms))
                & cal_h.mask_64_y
            )
            result[1] = Int(
                (value >> (cal_h.shift_64_mon - cal_h.shift_64_ms))
                & cal_h.mask_64_mon
            )
            result[2] = Int(
                (value >> (cal_h.shift_64_d - cal_h.shift_64_ms))
                & cal_h.mask_64_d
            )
            result[3] = Int(
                (value >> (cal_h.shift_64_h - cal_h.shift_64_ms))
                & cal_h.mask_64_h
            )
            result[4] = Int(
                (value >> (cal_h.shift_64_m - cal_h.shift_64_ms))
                & cal_h.mask_64_m
            )
            result[5] = Int(
                (value >> (cal_h.shift_64_s - cal_h.shift_64_ms))
                & cal_h.mask_64_s
            )
            result[6] = Int(value & cal_h.mask_64_ms)
        return result^

    @staticmethod
    @always_inline
    fn is_leapyear(year: UInt16) -> Bool:
        """Whether the year is a leap year.

        Args:
            year: Year.

        Returns:
            Bool.
        """
        return Gregorian.is_leapyear(year)

    @staticmethod
    fn _get_default_max_year() -> UInt16:
        return Gregorian._get_default_max_year()

    fn _get_max_year(self) -> UInt16:
        return self._greg._get_max_year()

    @staticmethod
    fn _get_max_typical_days_in_year() -> UInt16:
        return Gregorian._get_max_typical_days_in_year()

    @staticmethod
    fn _get_max_possible_days_in_year() -> UInt16:
        return Gregorian._get_max_possible_days_in_year()

    @staticmethod
    fn _get_max_month() -> UInt8:
        return Gregorian._get_max_month()

    @staticmethod
    fn _get_max_hour() -> UInt8:
        return Gregorian._get_max_hour()

    @staticmethod
    fn _get_max_minute() -> UInt8:
        return Gregorian._get_max_minute()

    @staticmethod
    fn _get_max_typical_second() -> UInt8:
        return Gregorian._get_max_typical_second()

    @staticmethod
    fn _get_max_possible_second() -> UInt8:
        return Gregorian._get_max_possible_second()

    @staticmethod
    fn _get_max_milisecond() -> UInt16:
        return Gregorian._get_max_milisecond()

    @staticmethod
    fn _get_max_microsecond() -> UInt16:
        return Gregorian._get_max_microsecond()

    @staticmethod
    fn _get_max_nanosecond() -> UInt16:
        return Gregorian._get_max_nanosecond()

    @staticmethod
    fn _get_default_min_year() -> UInt16:
        return Gregorian._get_default_min_year()

    fn _get_min_year(self) -> UInt16:
        return self._greg._get_min_year()

    @staticmethod
    fn _get_default_min_month() -> UInt8:
        return Gregorian._get_default_min_month()

    fn _get_min_month(self) -> UInt8:
        return self._greg._get_min_month()

    @staticmethod
    fn _get_default_min_day() -> UInt8:
        return Gregorian._get_default_min_day()

    fn _get_min_day(self) -> UInt8:
        return self._greg._get_min_day()

    @staticmethod
    fn _get_min_hour() -> UInt8:
        return Gregorian._get_min_hour()

    @staticmethod
    fn _get_min_minute() -> UInt8:
        return Gregorian._get_min_minute()

    @staticmethod
    fn _get_min_second() -> UInt8:
        return Gregorian._get_min_second()

    @staticmethod
    fn _get_min_milisecond() -> UInt16:
        return Gregorian._get_min_milisecond()

    @staticmethod
    fn _get_min_microsecond() -> UInt16:
        return Gregorian._get_min_microsecond()

    @staticmethod
    fn _get_min_nanosecond() -> UInt16:
        return Gregorian._get_min_nanosecond()


@value
struct ISOCalendar(_Calendarized):
    """`ISOCalendar` Calendar."""

    var _greg: Gregorian

    fn __init__(
        out self,
        *,
        min_year: UInt16 = 1,
        min_month: UInt8 = 1,
        min_day: UInt8 = 1,
        max_year: UInt16 = 9999,
    ):
        """Construct an `ISOCalendar` Calendar from values.

        Args:
            min_year: Min year (epoch start).
            min_month: Min month (epoch start).
            min_day: Min day (epoch start).
            max_year: Max year (epoch end).
        """
        self._greg = Gregorian(min_year, min_month, min_day, max_year=max_year)

    @always_inline
    fn monthrange(self, year: UInt16, month: UInt8) -> (UInt8, UInt8):
        """Returns day of the week for the first day of the month and number of
        days in month, for the specified year and month.

        Args:
            year: Year.
            month: Month.

        Returns:
            - day_of_week: Day of the week.
            - day_of_month: Day of the month.
        """
        return self.day_of_week(year, month, 1), self.max_days_in_month(
            year, month
        )

    @always_inline
    fn max_second(
        self, year: UInt16, month: UInt8, day: UInt8, hour: UInt8, minute: UInt8
    ) -> UInt8:
        """The maximum amount of seconds that a minute lasts (usually 59).
        Some years its 60 when a leap second is added. The spec also lists
        the posibility of 58 seconds but it stil hasn't ben done.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.

        Returns:
            The amount.
        """
        return self._greg.max_second(year, month, day, hour, minute)

    @always_inline
    fn max_days_in_month(self, year: UInt16, month: UInt8) -> UInt8:
        """The maximum amount of days in a given month.

        Args:
            year: Year.
            month: Month.

        Returns:
            The amount of days.
        """
        return self._greg.max_days_in_month(year, month)

    @always_inline
    fn day_of_week(self, year: UInt16, month: UInt8, day: UInt8) -> UInt8:
        """Calculates the day of the week for a given date.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            Day of the week [monday, sunday]: [0, 6] (Gregorian) [1, 7]
            (ISOCalendar).
        """
        return self._greg.day_of_week(year, month, day) + 1

    @always_inline
    fn day_of_year(self, year: UInt16, month: UInt8, day: UInt8) -> UInt16:
        """Calculates the day of the year for a given date.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            Day of the year: [1, 366] (for Gregorian calendar).
        """
        return self._greg.day_of_year(year, month, day)

    @always_inline
    fn day_of_month(self, year: UInt16, day_of_year: UInt16) -> (UInt8, UInt8):
        """Calculates the month, day of the month for a given day of the year.

        Args:
            year: Year.
            day_of_year: The day of the year.

        Returns:
            - month: Month of the year: [1, 12] (for Gregorian calendar).
            - day: Day of the month: [1, 31] (for Gregorian calendar).
        """
        return self._greg.day_of_month(year, day_of_year)

    fn week_of_year(self, year: UInt16, month: UInt8, day: UInt8) -> UInt8:
        """Calculates the week of the year for a given date.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            Week of the year: [0, 52] (Gregorian), [1, 53] (ISOCalendar).
        
        Notes:
            Gregorian takes the first day of the year as starting week 0,
            ISOCalendar follows [ISO 8601](\
            https://en.wikipedia.org/wiki/ISO_week_date) which takes the first
            thursday of the year as starting week 1.
        """

        # Sidenote for posterity: no idea why other algorithms are so
        # complicated since it is literally just doing a coordinate translation.
        # This is why first-principles thinking matters
        alias iso_thursday = 4
        doy = self.day_of_year(year, month, day)  # [1, 366]
        dowday1 = self.day_of_week(year, 1, 1)  # [1, 7]
        delta = iso_thursday - dowday1.cast[DType.uint16]()  # [-3, 3]
        return ((doy - delta) // 7).cast[DType.uint8]()  # [1, 53]

    @always_inline
    fn is_leapyear(self, year: UInt16) -> Bool:
        """Whether the year is a leap year.

        Args:
            year: Year.

        Returns:
            Bool.
        """
        return Self.is_leapyear(year)

    @always_inline
    fn is_leapsec(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
    ) -> Bool:
        """Whether the second is a leap second.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.

        Returns:
            Bool.
        """
        return self._greg.is_leapsec(year, month, day, hour, minute, second)

    @always_inline
    fn leapsecs_since_epoch(
        self, year: UInt16, month: UInt8, day: UInt8
    ) -> UInt32:
        """Cumulative leap seconds since the calendar's epoch start.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            The amount.
        """
        return self._greg.leapsecs_since_epoch(year, month, day)

    @always_inline
    fn leapdays_since_epoch(
        self, year: UInt16, month: UInt8, day: UInt8
    ) -> UInt32:
        """Cumulative leap days since the calendar's epoch start.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            The amount.
        """
        return self._greg.leapdays_since_epoch(year, month, day)

    @always_inline
    fn days_since_epoch(self, year: UInt16, month: UInt8, day: UInt8) -> UInt32:
        """Cumulative days since the calendar's epoch start.

        Args:
            year: Year.
            month: Month.
            day: Day.

        Returns:
            The amount: [0, 9998].
        """
        return self._greg.days_since_epoch(year, month, day)

    @always_inline
    fn seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
    ) -> UInt64:
        """Seconds since the begining of the calendar's epoch.
        Takes leap seconds added to UTC up to the given datetime into
        account.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.

        Returns:
            The amount.
        """
        return self._greg.seconds_since_epoch(
            year, month, day, hour, minute, second
        )

    @always_inline
    fn m_seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
        m_second: UInt16,
    ) -> UInt64:
        """Miliseconds since the begining of the calendar's epoch.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.
            m_second: Milisecond.

        Returns:
            The amount.
        """
        return self._greg.m_seconds_since_epoch(
            year, month, day, hour, minute, second, m_second
        )

    @always_inline
    fn n_seconds_since_epoch(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
        m_second: UInt16,
        u_second: UInt16,
        n_second: UInt16,
    ) -> UInt64:
        """Nanoseconds since the begining of the calendar's epoch. Takes leap
        seconds added to UTC up to the given datetime into account. Can only
        represent up to ~ 580 years since epoch start.

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

        Returns:
            The amount.
        """
        return self._greg.n_seconds_since_epoch(
            year, month, day, hour, minute, second, m_second, u_second, n_second
        )

    @always_inline
    fn hash[
        cal_h: CalendarHashes = CalendarHashes()
    ](
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8 = 0,
        minute: UInt8 = 0,
        second: UInt8 = 0,
        m_second: UInt16 = 0,
        u_second: UInt16 = 0,
        n_second: UInt16 = 0,
    ) -> Int:
        """Hash the given values according to the calendar's bitshifted
        component lengths, BigEndian (i.e. yyyymmdd...).

        Parameters:
            cal_h: The hashing schema (CalendarHashes).

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

        Returns:
            The hash.
        """
        return self._greg.hash[cal_h](
            year, month, day, hour, minute, second, m_second, u_second, n_second
        )

    @always_inline
    fn from_hash[
        cal_h: CalendarHashes = CalendarHashes()
    ](self, value: Int) -> _date:
        """Build a date from a hashed value.

        Parameters:
            cal_h: The hashing schema (CalendarHashes).

        Args:
            value: The Hash.

        Returns:
            Tuple containing date data.
        """
        return self._greg.from_hash[cal_h](value)

    @staticmethod
    @always_inline
    fn is_leapyear(year: UInt16) -> Bool:
        """Whether the year is a leap year.

        Args:
            year: Year.

        Returns:
            Bool.
        """
        return Gregorian.is_leapyear(year)

    @staticmethod
    fn _get_default_max_year() -> UInt16:
        return Gregorian._get_default_max_year()

    fn _get_max_year(self) -> UInt16:
        return self._greg._get_max_year()

    @staticmethod
    fn _get_max_typical_days_in_year() -> UInt16:
        return Gregorian._get_max_typical_days_in_year()

    @staticmethod
    fn _get_max_possible_days_in_year() -> UInt16:
        return Gregorian._get_max_possible_days_in_year()

    @staticmethod
    fn _get_max_month() -> UInt8:
        return Gregorian._get_max_month()

    @staticmethod
    fn _get_max_hour() -> UInt8:
        return Gregorian._get_max_hour()

    @staticmethod
    fn _get_max_minute() -> UInt8:
        return Gregorian._get_max_minute()

    @staticmethod
    fn _get_max_typical_second() -> UInt8:
        return Gregorian._get_max_typical_second()

    @staticmethod
    fn _get_max_possible_second() -> UInt8:
        return Gregorian._get_max_possible_second()

    @staticmethod
    fn _get_max_milisecond() -> UInt16:
        return Gregorian._get_max_milisecond()

    @staticmethod
    fn _get_max_microsecond() -> UInt16:
        return Gregorian._get_max_microsecond()

    @staticmethod
    fn _get_max_nanosecond() -> UInt16:
        return Gregorian._get_max_nanosecond()

    @staticmethod
    fn _get_default_min_year() -> UInt16:
        return Gregorian._get_default_min_year()

    fn _get_min_year(self) -> UInt16:
        return self._greg._get_min_year()

    @staticmethod
    fn _get_default_min_month() -> UInt8:
        return Gregorian._get_default_min_month()

    fn _get_min_month(self) -> UInt8:
        return self._greg._get_min_month()

    @staticmethod
    fn _get_default_min_day() -> UInt8:
        return Gregorian._get_default_min_day()

    fn _get_min_day(self) -> UInt8:
        return self._greg._get_min_day()

    @staticmethod
    fn _get_min_hour() -> UInt8:
        return Gregorian._get_min_hour()

    @staticmethod
    fn _get_min_minute() -> UInt8:
        return Gregorian._get_min_minute()

    @staticmethod
    fn _get_min_second() -> UInt8:
        return Gregorian._get_min_second()

    @staticmethod
    fn _get_min_milisecond() -> UInt16:
        return Gregorian._get_min_milisecond()

    @staticmethod
    fn _get_min_microsecond() -> UInt16:
        return Gregorian._get_min_microsecond()

    @staticmethod
    fn _get_min_nanosecond() -> UInt16:
        return Gregorian._get_min_nanosecond()
