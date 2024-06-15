# RUN: %mojo %s

from testing import assert_equal, assert_false, assert_raises, assert_true

from forge_tools.datetime.calendar import (
    CalendarHashes,
    Calendar,
    Gregorian,
    UTCFast,
    PythonCalendar,
    UTCCalendar,
    _date,
)


fn _get_dates_as_lists(t1: _date, t2: _date) -> (List[Int], List[Int]):
    var l1 = List[Int](
        int(t1[0]),
        int(t1[1]),
        int(t1[2]),
        int(t1[3]),
        int(t1[4]),
        int(t1[5]),
        int(t1[6]),
        int(t1[7]),
    )
    var l2 = List[Int](
        int(t2[0]),
        int(t2[1]),
        int(t2[2]),
        int(t2[3]),
        int(t2[4]),
        int(t2[5]),
        int(t2[6]),
        int(t2[7]),
    )
    return l1^, l2^


fn test_calendar_hashes() raises:
    alias calh64 = CalendarHashes(CalendarHashes.UINT64)
    alias calh32 = CalendarHashes(CalendarHashes.UINT32)
    alias calh16 = CalendarHashes(CalendarHashes.UINT16)
    alias calh8 = CalendarHashes(CalendarHashes.UINT8)
    var d = _date(2024, 6, 15, 15, 13, 30, 30, 30)

    var greg = Gregorian()
    var h = greg.hash[calh64](d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7])
    var result = _get_dates_as_lists(d, greg.from_hash[calh64](h))
    assert_equal(result[0].__str__(), result[1].__str__())
    h = greg.hash[calh32](d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7])
    d = _date(2024, 6, 15, 0, 0, 0, 0, 0)
    result = _get_dates_as_lists(d, greg.from_hash[calh32](h))
    assert_equal(result[0].__str__(), result[1].__str__())

    var utcfast = UTCFast()
    d = _date(2024, 6, 15, 15, 13, 30, 30, 0)
    h = utcfast.hash[calh64](d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7])
    result = _get_dates_as_lists(d, utcfast.from_hash[calh64](h))
    assert_equal(result[0].__str__(), result[1].__str__())
    d = _date(2024, 6, 15, 15, 13, 0, 0, 0)
    h = utcfast.hash[calh32](d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7])
    result = _get_dates_as_lists(d, utcfast.from_hash[calh32](h))
    assert_equal(result[0].__str__(), result[1].__str__())
    d = _date(3, 0, 15, 15, 0, 0, 0, 0)
    h = utcfast.hash[calh16](d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7])
    result = _get_dates_as_lists(d, utcfast.from_hash[calh16](h))
    assert_equal(result[0].__str__(), result[1].__str__())
    d = _date(0, 0, 15, 15, 0, 0, 0, 0)
    h = utcfast.hash[calh8](d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7])
    result = _get_dates_as_lists(d, utcfast.from_hash[calh8](h))
    assert_equal(result[0].__str__(), result[1].__str__())


fn test_gregorian_calendar() raises:
    # TODO
    pass


fn test_utcfast_calendar() raises:
    # TODO
    pass


fn test_python_calendar() raises:
    # TODO
    pass


fn test_gregorian_utc_calendar() raises:
    # TODO
    pass


fn main() raises:
    test_calendar_hashes()
    test_gregorian_calendar()
    test_utcfast_calendar()
    test_python_calendar()
    test_gregorian_utc_calendar()
