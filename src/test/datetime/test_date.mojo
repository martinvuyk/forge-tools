# RUN: %mojo %s

from testing import assert_equal, assert_false, assert_raises, assert_true

from time import time

from forge_tools.datetime.date import Date
from forge_tools.datetime.calendar import Calendar, PythonCalendar, UTCCalendar
from forge_tools.datetime.dt_str import IsoFormat


fn test_add() raises:
    # using python and unix calendar should have no difference in results
    alias pycal = PythonCalendar
    alias unixcal = UTCCalendar
    alias date = Date[iana=False, pyzoneinfo=False, native=False]
    alias TZ = date._tz
    var tz_0_ = TZ("Etc/UTC", 0, 0)
    var tz_1 = TZ("Etc/UTC-1", 1, 0)
    var tz1_ = TZ("Etc/UTC+1", 1, 0, -1)

    # test february leapyear
    var result = date(2024, 2, 28, tz_0_, pycal) + date(0, 0, 1, tz_0_, pycal)
    var offset_0 = date(2024, 2, 29, tz_0_, unixcal)
    var offset_p_1 = date(2024, 2, 29, tz_1, unixcal)
    var offset_n_1 = date(2024, 2, 29, tz1_, unixcal)
    var add_seconds = date(2024, 2, 28, tz_0_, unixcal).add(seconds=24 * 3600)
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, add_seconds)

    # test february not leapyear
    result = date(2023, 2, 28, tz_0_, pycal) + date(0, 0, 1, tz_0_, pycal)
    offset_0 = date(2023, 3, 1, tz_0_, unixcal)
    offset_p_1 = date(2023, 3, 1, tz_1, unixcal)
    offset_n_1 = date(2023, 3, 1, tz1_, unixcal)
    add_seconds = date(2023, 2, 28, tz_0_, unixcal).add(seconds=24 * 3600)
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, add_seconds)

    # test normal month
    result = date(2024, 5, 31, tz_0_, pycal) + date(0, 0, 1, tz_0_, pycal)
    offset_0 = date(2024, 6, 1, tz_0_, unixcal)
    offset_p_1 = date(2024, 6, 1, tz_1, unixcal)
    offset_n_1 = date(2024, 6, 1, tz1_, unixcal)
    add_seconds = date(2024, 5, 31, tz_0_, unixcal).add(seconds=24 * 3600)
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, add_seconds)

    # test december
    result = date(2024, 12, 31, tz_0_, pycal) + date(0, 0, 1, tz_0_, pycal)
    offset_0 = date(2025, 1, 1, tz_0_, unixcal)
    offset_p_1 = date(2025, 1, 1, tz_1, unixcal)
    offset_n_1 = date(2025, 1, 1, tz1_, unixcal)
    add_seconds = date(2024, 12, 31, tz_0_, unixcal).add(seconds=24 * 3600)
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, add_seconds)

    # test year and month add
    result = date(2022, 6, 1, tz_0_, pycal) + date(2, 6, 31, tz_0_, pycal)
    offset_0 = date(2025, 1, 1, tz_0_, unixcal)
    offset_p_1 = date(2025, 1, 1, tz_1, unixcal)
    offset_n_1 = date(2025, 1, 1, tz1_, unixcal)
    add_seconds = date(2022, 6, 1, tz_0_, unixcal).add(
        years=2, months=6, days=31
    )
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, add_seconds)

    # test positive overflow pycal
    result = date(9999, 12, 31, tz_0_, pycal) + date(0, 0, 1, tz_0_, pycal)
    offset_0 = date(1, 1, 1, tz_0_, pycal)
    offset_p_1 = date(1, 1, 1, tz_1, pycal)
    offset_n_1 = date(1, 1, 1, tz1_, pycal)
    add_seconds = date(9999, 12, 31, tz_0_, pycal).add(seconds=24 * 3600)
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, add_seconds)

    # test positive overflow unixcal
    result = date(9999, 12, 31, tz_0_, unixcal) + date(0, 0, 1, tz_0_, unixcal)
    offset_0 = date(1970, 1, 1, tz_0_, unixcal)
    offset_p_1 = date(1970, 1, 1, tz_1, unixcal)
    offset_n_1 = date(1970, 1, 1, tz1_, unixcal)
    add_seconds = date(9999, 12, 31, tz_0_, unixcal).add(seconds=24 * 3600)
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, add_seconds)


fn test_subtract() raises:
    # using python and unix calendar should have no difference in results
    alias pycal = PythonCalendar
    alias unixcal = UTCCalendar
    alias date = Date[iana=False, pyzoneinfo=False, native=False]
    alias TZ = date._tz
    var tz_0_ = TZ("Etc/UTC", 0, 0)
    var tz_1 = TZ("Etc/UTC-1", 1, 0)
    var tz1_ = TZ("Etc/UTC+1", 1, 0, -1)

    # test february leapyear
    var result = date(2024, 3, 1, tz_0_, pycal) - date(0, 0, 1, tz_0_, pycal)
    var offset_0 = date(2024, 2, 29, tz_0_, unixcal)
    var offset_p_1 = date(2024, 2, 29, tz_1, unixcal)
    var offset_n_1 = date(2024, 2, 29, tz1_, unixcal)
    var sub_seconds = date(2024, 3, 1, tz_0_, unixcal).subtract(days=1)
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, sub_seconds)

    # test february not leapyear
    result = date(2023, 3, 1, tz_0_, pycal) - date(0, 0, 1, tz_0_, pycal)
    offset_0 = date(2023, 2, 28, tz_0_, unixcal)
    offset_p_1 = date(2023, 2, 28, tz_1, unixcal)
    offset_n_1 = date(2023, 2, 28, tz1_, unixcal)
    sub_seconds = date(2023, 3, 1, tz_0_, unixcal).subtract(days=1)
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, sub_seconds)

    # test normal month
    result = date(2024, 6, 1, tz_0_, pycal) - date(0, 0, 1, tz_0_, pycal)
    offset_0 = date(2024, 5, 31, tz_0_, unixcal)
    offset_p_1 = date(2024, 5, 31, tz_1, unixcal)
    offset_n_1 = date(2024, 5, 31, tz1_, unixcal)
    sub_seconds = date(2024, 6, 1, tz_0_, unixcal).subtract(days=1)
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, sub_seconds)

    # test december
    result = date(2025, 1, 1, tz_0_, pycal) - date(0, 0, 1, tz_0_, pycal)
    offset_0 = date(2024, 12, 31, tz_0_, unixcal)
    offset_p_1 = date(2024, 12, 31, tz_1, unixcal)
    offset_n_1 = date(2024, 12, 31, tz1_, unixcal)
    sub_seconds = date(2025, 1, 1, tz_0_, unixcal).subtract(days=1)
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, sub_seconds)

    # test year and month subtract
    result = date(2025, 1, 1, tz_0_, pycal) - date(2, 6, 31, tz_0_, pycal)
    offset_0 = date(2022, 6, 1, tz_0_, unixcal)
    offset_p_1 = date(2022, 6, 1, tz_1, unixcal)
    offset_n_1 = date(2022, 6, 1, tz1_, unixcal)
    sub_seconds = date(2025, 1, 1, tz_0_, unixcal).subtract(
        years=2, months=6, days=31
    )
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, sub_seconds)

    # test negative overflow pycal
    result = date(1, 1, 1, tz_0_, pycal) - date(0, 0, 1, tz_0_, pycal)
    offset_0 = date(9999, 12, 31, tz_0_, pycal)
    offset_p_1 = date(9999, 12, 31, tz_1, pycal)
    offset_n_1 = date(9999, 12, 31, tz1_, pycal)
    sub_seconds = date(1, 1, 1, tz_0_, pycal).subtract(days=1)
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, sub_seconds)

    # test negative overflow unixcal
    result = date(1970, 1, 1, tz_0_, unixcal) - date(0, 0, 1, tz_0_, unixcal)
    offset_0 = date(9999, 12, 31, tz_0_, unixcal)
    offset_p_1 = date(9999, 12, 31, tz_1, unixcal)
    offset_n_1 = date(9999, 12, 31, tz1_, unixcal)
    sub_seconds = date(1970, 1, 1, tz_0_, unixcal).subtract(days=1)
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, sub_seconds)


fn test_logic() raises:
    # using python and unix calendar should have no difference in results
    alias pycal = PythonCalendar
    alias unixcal = UTCCalendar
    alias date = Date[iana=False, pyzoneinfo=False, native=False]
    alias TZ = date._tz
    var tz_0_ = TZ("Etc/UTC", 0, 0)
    var tz_1 = TZ("Etc/UTC-1", 1, 0)
    var tz1_ = TZ("Etc/UTC+1", 1, 0, -1)

    var ref1 = date(1970, 1, 1, tz_0_, pycal)
    assert_true(ref1 == date(1970, 1, 1, tz_0_, unixcal))
    assert_true(ref1 != date(1970, 1, 2, tz_0_, unixcal))
    assert_true(ref1 == date(1970, 1, 1, tz_1, unixcal))
    assert_true(ref1 == date(1970, 1, 1, tz1_, pycal))
    assert_true(ref1 < date(1970, 1, 2, tz_0_, pycal))
    assert_true(ref1 <= date(1970, 1, 2, tz_0_, pycal))
    assert_true(ref1 > date(1969, 12, 31, tz_0_, pycal))
    assert_true(ref1 >= date(1969, 12, 31, tz_0_, pycal))


fn test_bitwise() raises:
    # using python and unix calendar should have no difference in results
    alias pycal = PythonCalendar
    alias unixcal = UTCCalendar
    alias date = Date[iana=False, pyzoneinfo=False, native=False]
    alias TZ = date._tz
    var tz_0_ = TZ("Etc/UTC", 0, 0)
    var tz_1 = TZ("Etc/UTC-1", 1, 0)
    var tz1_ = TZ("Etc/UTC+1", 1, 0, -1)

    var ref1 = date(1970, 1, 1, tz_0_, pycal)
    assert_true((ref1 ^ date(1970, 1, 1, tz_0_, unixcal)) == 0)
    assert_true((ref1 ^ date(1970, 1, 1, tz_1, unixcal)) == 0)
    assert_true((ref1 ^ date(1969, 12, 31, tz1_, pycal)) != 0)
    assert_true((ref1 ^ date(1970, 1, 2, tz_0_, pycal)) != 0)
    assert_true((ref1 | (date(1970, 1, 2, tz_0_, pycal) & 0)) == hash(ref1))
    # assert_true((hash(ref1) & ~hash(ref1)) == 0) # FIXME: uint has no ~ yet
    # assert_true(~(hash(ref1) ^ ~hash(ref1)) == 0)


fn test_iso() raises:
    # using python and unix calendar should have no difference in results
    alias pycal = PythonCalendar
    alias unixcal = UTCCalendar
    alias date = Date[iana=False, pyzoneinfo=False, native=False]
    alias TZ = date._tz
    var tz_0_ = TZ("Etc/UTC", 0, 0)

    var ref1 = date(1970, 1, 1, tz_0_, unixcal)
    var iso_str = "1970-01-01T00:00:00+00:00"
    alias fmt1 = IsoFormat(IsoFormat.YYYY_MM_DD_T_HH_MM_SS_TZD)
    assert_equal(ref1, date.from_iso[fmt1](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt1]())

    iso_str = "1970-01-01 00:00:00"
    alias fmt2 = IsoFormat(IsoFormat.YYYY_MM_DD___HH_MM_SS)
    assert_equal(ref1, date.from_iso[fmt2](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt2]())

    iso_str = "1970-01-01T00:00:00"
    alias fmt3 = IsoFormat(IsoFormat.YYYY_MM_DD_T_HH_MM_SS)
    assert_equal(ref1, date.from_iso[fmt3](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt3]())

    iso_str = "19700101000000"
    alias fmt4 = IsoFormat(IsoFormat.YYYYMMDDHHMMSS)
    assert_equal(ref1, date.from_iso[fmt4](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt4]())

    iso_str = "00:00:00"
    alias fmt5 = IsoFormat(IsoFormat.HH_MM_SS)
    assert_equal(ref1, date.from_iso[fmt5](iso_str, calendar=unixcal).value())
    assert_equal(iso_str, ref1.to_iso[fmt5]())

    iso_str = "000000"
    alias fmt6 = IsoFormat(IsoFormat.HHMMSS)
    assert_equal(ref1, date.from_iso[fmt6](iso_str, calendar=unixcal).value())
    assert_equal(iso_str, ref1.to_iso[fmt6]())


fn test_time() raises:
    alias date = Date[iana=False, pyzoneinfo=False, native=False]
    var start = date.now()
    time.sleep(0.1)
    var end = date.now()
    assert_equal(start, end)


fn test_hash() raises:
    alias pycal = PythonCalendar
    alias unixcal = UTCCalendar
    alias dt = Date[iana=False, pyzoneinfo=False, native=False]
    alias TZ = dt._tz
    var tz_0_ = TZ("Etc/UTC", 0, 0)
    var ref1 = dt(1970, 1, 1, tz_0_, pycal)
    var data = hash(ref1)
    var parsed = dt.from_hash(data, tz_0_)
    assert_true(ref1 == parsed)
    var ref2 = dt(1970, 1, 1, tz_0_, unixcal)
    var data2 = hash(ref2)
    var parsed2 = dt.from_hash(data2, tz_0_)
    assert_true(ref2 == parsed2)
    # both should be the same
    assert_true(ref1 == ref2)


fn test_strftime() raises:
    var fstr = "mojo: %Y🔥%m🤯%d"
    alias dt = Date[iana=False, pyzoneinfo=False, native=False]
    assert_equal("mojo: 0009🔥06🤯01", dt(9, 6, 1).strftime(fstr))
    fstr = "%Y-%m-%d %H:%M:%S.%f"
    assert_equal("2024-06-07 00:00:00.000000", dt(2024, 6, 7).strftime(fstr))


fn test_strptime() raises:
    var fstr = "mojo: %Y🔥%m🤯%d"
    var vstr = "mojo: 0009🔥06🤯01"
    alias dt = Date[iana=False, pyzoneinfo=False, native=False]
    var ref1 = dt(9, 6, 1)
    var parsed = dt.strptime(vstr, fstr)
    assert_true(parsed)
    assert_equal(ref1, parsed.value())
    fstr = "%Y-%m-%d %H:%M:%S.%f"
    vstr = "2024-06-07 09:09:09.009009"
    ref1 = dt(2024, 6, 7)
    parsed = dt.strptime(vstr, fstr)
    assert_true(parsed)
    assert_equal(ref1, parsed.value())


fn main() raises:
    test_add()
    test_subtract()
    test_logic()
    test_bitwise()
    test_iso()
    test_time()
    test_hash()
    test_strftime()
