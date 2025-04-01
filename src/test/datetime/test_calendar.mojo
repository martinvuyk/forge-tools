# RUN: %mojo %s

from testing import assert_equal, assert_false, assert_raises, assert_true

from forge_tools.datetime.calendar import (
    CalendarHashes,
    Calendar,
    Gregorian,
    UTCFast,
    PythonCalendar,
    UTCCalendar,
    UTCFastCal,
    _date,
)


def _get_dates_as_lists(t1: _date, t2: _date) -> (List[Int], List[Int]):
    l1 = List[Int](
        Int(t1[0]),
        Int(t1[1]),
        Int(t1[2]),
        Int(t1[3]),
        Int(t1[4]),
        Int(t1[5]),
        Int(t1[6]),
        Int(t1[7]),
    )
    l2 = List[Int](
        Int(t2[0]),
        Int(t2[1]),
        Int(t2[2]),
        Int(t2[3]),
        Int(t2[4]),
        Int(t2[5]),
        Int(t2[6]),
        Int(t2[7]),
    )
    return l1^, l2^


def test_calendar_hashes():
    alias calh64 = CalendarHashes(CalendarHashes.UINT64)
    alias calh32 = CalendarHashes(CalendarHashes.UINT32)
    alias calh16 = CalendarHashes(CalendarHashes.UINT16)
    alias calh8 = CalendarHashes(CalendarHashes.UINT8)

    greg = Gregorian()
    d = _date(9999, 12, 31, 23, 59, 59, 999, 999)
    h = greg.hash[calh64](d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7])
    result = _get_dates_as_lists(d, greg.from_hash[calh64](h))
    assert_equal(result[0].__str__(), result[1].__str__())
    d = _date(4095, 12, 31, 0, 0, 0, 0, 0)
    h = greg.hash[calh32](d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7])
    result = _get_dates_as_lists(d, greg.from_hash[calh32](h))
    assert_equal(result[0].__str__(), result[1].__str__())

    utcfast = UTCFast()
    d = _date(9999, 12, 31, 23, 59, 59, 999, 0)
    h = utcfast.hash[calh64](d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7])
    result = _get_dates_as_lists(d, utcfast.from_hash[calh64](h))
    assert_equal(result[0].__str__(), result[1].__str__())
    d = _date(4095, 12, 31, 23, 59, 0, 0, 0)
    h = utcfast.hash[calh32](d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7])
    result = _get_dates_as_lists(d, utcfast.from_hash[calh32](h))
    assert_equal(result[0].__str__(), result[1].__str__())
    d = _date(3, 12, 31, 23, 0, 0, 0, 0)
    h = utcfast.hash[calh16](d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7])
    result = _get_dates_as_lists(d, utcfast.from_hash[calh16](h))
    assert_equal(result[0].__str__(), result[1].__str__())
    d = _date(0, 0, 6, 23, 0, 0, 0, 0)
    h = utcfast.hash[calh8](d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7])
    result = _get_dates_as_lists(d, utcfast.from_hash[calh8](h))
    assert_equal(result[0].__str__(), result[1].__str__())


def test_python_calendar():
    alias cal = PythonCalendar
    assert_equal(3, cal.day_of_week(2023, 6, 15))
    assert_equal(5, cal.day_of_week(2024, 6, 15))
    assert_equal(166, cal.day_of_year(2023, 6, 15))
    assert_equal(167, cal.day_of_year(2024, 6, 15))
    assert_equal(365, cal.day_of_year(2023, 12, 31))
    assert_equal(366, cal.day_of_year(2024, 12, 31))

    for i in range(1, 3_000):
        if i % 4 == 0 and (i % 100 != 0 or i % 400 == 0):
            assert_true(cal.is_leapyear(i))
            assert_equal(29, cal.max_days_in_month(i, 2))
        else:
            assert_false(cal.is_leapyear(i))
            assert_equal(28, cal.max_days_in_month(i, 2))

    assert_equal(27, cal.leapsecs_since_epoch(2017, 1, 2))
    res = cal.monthrange(2023, 2)
    assert_equal(2, res[0])
    assert_equal(28, res[1])
    res = cal.monthrange(2024, 2)
    assert_equal(3, res[0])
    assert_equal(29, res[1])
    assert_equal(60, cal.max_second(1972, 6, 30, 23, 59))
    assert_equal(60, cal.max_second(1972, 12, 31, 23, 59))
    assert_equal(60, cal.max_second(1973, 12, 31, 23, 59))
    assert_equal(60, cal.max_second(1974, 12, 31, 23, 59))
    assert_equal(60, cal.max_second(1975, 12, 31, 23, 59))
    assert_equal(60, cal.max_second(1976, 12, 31, 23, 59))
    assert_equal(60, cal.max_second(1977, 12, 31, 23, 59))
    assert_equal(60, cal.max_second(1978, 12, 31, 23, 59))
    assert_equal(60, cal.max_second(1979, 12, 31, 23, 59))
    assert_equal(60, cal.max_second(1981, 6, 30, 23, 59))
    assert_equal(60, cal.max_second(1982, 6, 30, 23, 59))
    assert_equal(60, cal.max_second(1983, 6, 30, 23, 59))
    assert_equal(60, cal.max_second(1985, 6, 30, 23, 59))
    assert_equal(60, cal.max_second(1987, 12, 31, 23, 59))
    assert_equal(60, cal.max_second(1989, 12, 31, 23, 59))
    assert_equal(60, cal.max_second(1990, 12, 31, 23, 59))
    assert_equal(60, cal.max_second(1992, 6, 30, 23, 59))
    assert_equal(60, cal.max_second(1993, 6, 30, 23, 59))
    assert_equal(60, cal.max_second(1994, 6, 30, 23, 59))
    assert_equal(60, cal.max_second(1995, 12, 31, 23, 59))
    assert_equal(60, cal.max_second(1997, 6, 30, 23, 59))
    assert_equal(60, cal.max_second(1998, 12, 31, 23, 59))
    assert_equal(60, cal.max_second(2005, 12, 31, 23, 59))
    assert_equal(60, cal.max_second(2008, 12, 31, 23, 59))
    assert_equal(60, cal.max_second(2012, 6, 30, 23, 59))
    assert_equal(60, cal.max_second(2015, 6, 30, 23, 59))
    assert_equal(60, cal.max_second(2016, 12, 31, 23, 59))
    assert_equal(120, cal.seconds_since_epoch(1, 1, 1, 0, 2, 0))
    assert_equal(120 * 1_000, cal.m_seconds_since_epoch(1, 1, 1, 0, 2, 0, 0))
    assert_equal(
        Int(120 * 1e9), cal.n_seconds_since_epoch(1, 1, 1, 0, 2, 0, 0, 0, 0)
    )
    d1 = cal.seconds_since_epoch(2024, 1, 1, 0, 2, 0)
    d2 = cal.seconds_since_epoch(2024, 1, 1, 0, 0, 0)
    assert_equal(120, d1 - d2)
    d1 = cal.m_seconds_since_epoch(2024, 1, 1, 0, 2, 0, 0)
    d2 = cal.m_seconds_since_epoch(2024, 1, 1, 0, 0, 0, 0)
    assert_equal(120 * 1_000, d1 - d2)
    d1 = cal.n_seconds_since_epoch(500, 1, 1, 0, 2, 0, 0, 0, 0)
    d2 = cal.n_seconds_since_epoch(500, 1, 1, 0, 0, 0, 0, 0, 0)
    assert_equal(Int(120 * 1e9), d1 - d2)

    alias day_to_sec = 24 * 60 * 60
    alias sec_to_nano = 1_000_000_000
    d1 = cal.seconds_since_epoch(2024, 12, 31, 3, 4, 5)
    d2 = cal.seconds_since_epoch(2025, 1, 1, 3, 4, 5)
    assert_equal(1 * day_to_sec, d2 - d1)
    d1 = cal.m_seconds_since_epoch(2024, 12, 31, 3, 4, 5, 6)
    d2 = cal.m_seconds_since_epoch(2025, 1, 1, 3, 4, 5, 6)
    assert_equal(1 * day_to_sec * 1_000, d2 - d1)
    d1 = cal.n_seconds_since_epoch(500, 12, 31, 3, 4, 5, 6, 7, 8)
    d2 = cal.n_seconds_since_epoch(501, 1, 1, 3, 4, 5, 6, 7, 8)
    assert_equal(1 * day_to_sec * sec_to_nano, d2 - d1)


def test_gregorian_utc_calendar():
    alias cal = UTCCalendar
    assert_equal(3, cal.day_of_week(2023, 6, 15))
    assert_equal(5, cal.day_of_week(2024, 6, 15))
    assert_equal(166, cal.day_of_year(2023, 6, 15))
    assert_equal(167, cal.day_of_year(2024, 6, 15))
    assert_equal(27, cal.leapsecs_since_epoch(2017, 1, 2))
    res = cal.monthrange(2023, 2)
    assert_equal(2, res[0])
    assert_equal(28, res[1])
    res = cal.monthrange(2024, 2)
    assert_equal(3, res[0])
    assert_equal(29, res[1])
    assert_equal(120, cal.seconds_since_epoch(1970, 1, 1, 0, 2, 0))
    assert_equal(120 * 1_000, cal.m_seconds_since_epoch(1970, 1, 1, 0, 2, 0, 0))
    assert_equal(
        Int(120 * 1e9), cal.n_seconds_since_epoch(1970, 1, 1, 0, 2, 0, 0, 0, 0)
    )
    d1 = cal.seconds_since_epoch(2024, 1, 1, 0, 2, 0)
    d2 = cal.seconds_since_epoch(2024, 1, 1, 0, 0, 0)
    assert_equal(120, d1 - d2)
    d1 = cal.m_seconds_since_epoch(2024, 1, 1, 0, 2, 0, 0)
    d2 = cal.m_seconds_since_epoch(2024, 1, 1, 0, 0, 0, 0)
    assert_equal(120 * 1_000, d1 - d2)
    d1 = cal.n_seconds_since_epoch(2024, 1, 1, 0, 2, 0, 0, 0, 0)
    d2 = cal.n_seconds_since_epoch(2024, 1, 1, 0, 0, 0, 0, 0, 0)
    assert_equal(Int(120 * 1e9), d1 - d2)

    alias day_to_sec = 24 * 60 * 60
    alias sec_to_nano = 1_000_000_000
    d1 = cal.seconds_since_epoch(2024, 12, 31, 3, 4, 5)
    d2 = cal.seconds_since_epoch(2025, 1, 1, 3, 4, 5)
    assert_equal(1 * day_to_sec, d2 - d1)
    d1 = cal.m_seconds_since_epoch(2024, 12, 31, 3, 4, 5, 6)
    d2 = cal.m_seconds_since_epoch(2025, 1, 1, 3, 4, 5, 6)
    assert_equal(1 * day_to_sec * 1_000, d2 - d1)
    d1 = cal.n_seconds_since_epoch(2024, 12, 31, 3, 4, 5, 6, 7, 8)
    d2 = cal.n_seconds_since_epoch(2025, 1, 1, 3, 4, 5, 6, 7, 8)
    assert_equal(1 * day_to_sec * sec_to_nano, d2 - d1)


def test_utcfast_calendar():
    alias cal = UTCFastCal
    assert_equal(3, cal.day_of_week(2023, 6, 15))
    assert_equal(5, cal.day_of_week(2024, 6, 15))
    assert_equal(166, cal.day_of_year(2023, 6, 15))
    assert_equal(167, cal.day_of_year(2024, 6, 15))
    assert_equal(365, cal.day_of_year(2023, 12, 31))
    assert_equal(366, cal.day_of_year(2024, 12, 31))

    assert_equal(0, cal.leapsecs_since_epoch(2017, 1, 2))
    res = cal.monthrange(2023, 2)
    assert_equal(2, res[0])
    assert_equal(28, res[1])
    res = cal.monthrange(2024, 2)
    assert_equal(3, res[0])
    assert_equal(29, res[1])
    assert_equal(120, cal.seconds_since_epoch(1970, 1, 1, 0, 2, 0))
    assert_equal(120 * 1_000, cal.m_seconds_since_epoch(1970, 1, 1, 0, 2, 0, 0))
    assert_equal(
        Int(120 * 1e9), cal.n_seconds_since_epoch(1970, 1, 1, 0, 2, 0, 0, 0, 0)
    )
    d1 = cal.seconds_since_epoch(2024, 1, 1, 0, 2, 0)
    d2 = cal.seconds_since_epoch(2024, 1, 1, 0, 0, 0)
    assert_equal(120, d1 - d2)
    d1 = cal.m_seconds_since_epoch(2024, 1, 1, 0, 2, 0, 0)
    d2 = cal.m_seconds_since_epoch(2024, 1, 1, 0, 0, 0, 0)
    assert_equal(120 * 1_000, d1 - d2)
    d1 = cal.n_seconds_since_epoch(2024, 1, 1, 0, 2, 0, 0, 0, 0)
    d2 = cal.n_seconds_since_epoch(2024, 1, 1, 0, 0, 0, 0, 0, 0)
    assert_equal(Int(120 * 1e9), d1 - d2)

    alias day_to_sec = 24 * 60 * 60
    alias sec_to_nano = 1_000_000_000
    d1 = cal.seconds_since_epoch(2024, 12, 31, 3, 4, 5)
    d2 = cal.seconds_since_epoch(2025, 1, 1, 3, 4, 5)
    assert_equal(1 * day_to_sec, d2 - d1)
    d1 = cal.m_seconds_since_epoch(2024, 12, 31, 3, 4, 5, 6)
    d2 = cal.m_seconds_since_epoch(2025, 1, 1, 3, 4, 5, 6)
    assert_equal(1 * day_to_sec * 1_000, d2 - d1)
    d1 = cal.n_seconds_since_epoch(2024, 12, 31, 3, 4, 5, 6, 7, 8)
    d2 = cal.n_seconds_since_epoch(2025, 1, 1, 3, 4, 5, 6, 7, 8)
    assert_equal(1 * day_to_sec * sec_to_nano, d2 - d1)


def main():
    test_calendar_hashes()
    test_python_calendar()
    test_gregorian_utc_calendar()
    test_utcfast_calendar()
