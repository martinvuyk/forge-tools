# RUN: %mojo %s

from testing import assert_equal, assert_false, assert_raises, assert_true

from time import time

from forge_tools.datetime.date import Date
from forge_tools.datetime.calendar import Calendar, PythonCalendar, UTCCalendar
from forge_tools.datetime.dt_str import IsoFormat


def test_add():
    # using python and unix calendar should have no difference in results
    alias pycal = PythonCalendar
    alias unixcal = UTCCalendar
    alias date = Date[iana=False, pyzoneinfo=False, native=False]
    alias TZ = date._tz
    tz_0_ = TZ("Etc/UTC", 0, 0)
    tz_1 = TZ("Etc/UTC-1", 1, 0)
    tz1_ = TZ("Etc/UTC+1", 1, 0, -1)

    # test february leapyear
    result = date(2024, 2, 28, tz_0_, pycal) + date(0, 0, 1, tz_0_, pycal)
    offset_0 = date(2024, 2, 29, tz_0_, unixcal)
    offset_p_1 = date(2024, 2, 29, tz_1, unixcal)
    offset_n_1 = date(2024, 2, 29, tz1_, unixcal)
    add_seconds = date(2024, 2, 28, tz_0_, unixcal).add(seconds=24 * 3600)
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


def test_subtract():
    # using python and unix calendar should have no difference in results
    alias pycal = PythonCalendar
    alias unixcal = UTCCalendar
    alias date = Date[iana=False, pyzoneinfo=False, native=False]
    alias TZ = date._tz
    tz_0_ = TZ("Etc/UTC", 0, 0)
    tz_1 = TZ("Etc/UTC-1", 1, 0)
    tz1_ = TZ("Etc/UTC+1", 1, 0, -1)

    # test february leapyear
    result = date(2024, 3, 1, tz_0_, pycal) - date(0, 0, 1, tz_0_, pycal)
    offset_0 = date(2024, 2, 29, tz_0_, unixcal)
    offset_p_1 = date(2024, 2, 29, tz_1, unixcal)
    offset_n_1 = date(2024, 2, 29, tz1_, unixcal)
    sub_seconds = date(2024, 3, 1, tz_0_, unixcal).subtract(days=1)
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


def test_logic():
    # using python and unix calendar should have no difference in results
    alias pycal = PythonCalendar
    alias unixcal = UTCCalendar
    alias date = Date[iana=False, pyzoneinfo=False, native=False]
    alias TZ = date._tz
    tz_0_ = TZ("Etc/UTC", 0, 0)
    tz_1 = TZ("Etc/UTC-1", 1, 0)
    tz1_ = TZ("Etc/UTC+1", 1, 0, -1)

    ref1 = date(1970, 1, 1, tz_0_, pycal)
    assert_true(ref1 == date(1970, 1, 1, tz_0_, unixcal))
    assert_true(ref1 != date(1970, 1, 2, tz_0_, unixcal))
    assert_true(ref1 == date(1970, 1, 1, tz_1, unixcal))
    assert_true(ref1 == date(1970, 1, 1, tz1_, pycal))
    assert_true(ref1 < date(1970, 1, 2, tz_0_, pycal))
    assert_true(ref1 <= date(1970, 1, 2, tz_0_, pycal))
    assert_true(ref1 > date(1969, 12, 31, tz_0_, pycal))
    assert_true(ref1 >= date(1969, 12, 31, tz_0_, pycal))


def test_bitwise():
    # using python and unix calendar should have no difference in results
    alias pycal = PythonCalendar
    alias unixcal = UTCCalendar
    alias date = Date[iana=False, pyzoneinfo=False, native=False]
    alias TZ = date._tz
    tz_0_ = TZ("Etc/UTC", 0, 0)
    tz_1 = TZ("Etc/UTC-1", 1, 0)
    tz1_ = TZ("Etc/UTC+1", 1, 0, -1)

    ref1 = date(1970, 1, 1, tz_0_, pycal)
    assert_true((ref1 ^ date(1970, 1, 1, tz_0_, unixcal)) == 0)
    assert_true((ref1 ^ date(1970, 1, 1, tz_1, unixcal)) == 0)
    assert_true((ref1 ^ date(1969, 12, 31, tz1_, pycal)) != 0)
    assert_true((ref1 ^ date(1970, 1, 2, tz_0_, pycal)) != 0)
    assert_true(
        (ref1.hash() | (date(1970, 1, 2, tz_0_, pycal).hash() & 0))
        == ref1.hash()
    )
    # assert_true((ref1.hash() & ~ref1.hash()) == 0) # FIXME: uint has no ~ yet
    # assert_true(~(ref1.hash() ^ ~ref1.hash()) == 0)


def test_iso():
    # using python and unix calendar should have no difference in results
    alias pycal = PythonCalendar
    alias unixcal = UTCCalendar
    alias date = Date[iana=False, pyzoneinfo=False, native=False]
    alias TZ = date._tz
    tz_0_ = TZ("Etc/UTC", 0, 0)

    ref1 = date(1970, 1, 1, tz_0_, unixcal)
    iso_str: StaticString = "1970-01-01T00:00:00+00:00"
    alias fmt1 = IsoFormat.YYYY_MM_DD_T_HH_MM_SS_TZD
    assert_equal(ref1, date.from_iso[fmt1](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt1]())

    iso_str = "1970-01-01 00:00:00"
    alias fmt2 = IsoFormat.YYYY_MM_DD___HH_MM_SS
    assert_equal(ref1, date.from_iso[fmt2](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt2]())

    iso_str = "1970-01-01T00:00:00"
    alias fmt3 = IsoFormat.YYYY_MM_DD_T_HH_MM_SS
    assert_equal(ref1, date.from_iso[fmt3](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt3]())

    iso_str = "19700101000000"
    alias fmt4 = IsoFormat.YYYYMMDDHHMMSS
    assert_equal(ref1, date.from_iso[fmt4](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt4]())

    iso_str = "00:00:00"
    alias fmt5 = IsoFormat.HH_MM_SS
    assert_equal(ref1, date.from_iso[fmt5](iso_str, calendar=unixcal).value())
    assert_equal(iso_str, ref1.to_iso[fmt5]())

    iso_str = "000000"
    alias fmt6 = IsoFormat.HHMMSS
    assert_equal(ref1, date.from_iso[fmt6](iso_str, calendar=unixcal).value())
    assert_equal(iso_str, ref1.to_iso[fmt6]())


def test_time():
    alias date = Date[iana=False, pyzoneinfo=False, native=False]
    start = date.now()
    time.sleep(0.1)
    end = date.now()
    assert_equal(start, end)


def test_hash():
    alias pycal = PythonCalendar
    alias unixcal = UTCCalendar
    alias dt = Date[iana=False, pyzoneinfo=False, native=False]
    alias TZ = dt._tz
    tz_0_ = TZ("Etc/UTC", 0, 0)
    ref1 = dt(1970, 1, 1, tz_0_, pycal)
    data = ref1.hash()
    parsed = dt.from_hash(data, tz_0_)
    assert_true(ref1 == parsed)
    ref2 = dt(1970, 1, 1, tz_0_, unixcal)
    data2 = ref2.hash()
    parsed2 = dt.from_hash(data2, tz_0_)
    assert_true(ref2 == parsed2)
    # both should be the same
    assert_true(ref1 == ref2)


def test_strftime():
    fstr: StaticString = "mojo: %Y🔥%m🤯%d"
    alias dt = Date[iana=False, pyzoneinfo=False, native=False]
    assert_equal("mojo: 0009🔥06🤯01", dt(9, 6, 1).strftime(fstr))
    fstr = "%Y-%m-%d %H:%M:%S.%f"
    assert_equal("2024-06-07 00:00:00.000000", dt(2024, 6, 7).strftime(fstr))


def test_strptime():
    fstr: StaticString = "mojo: %Y🔥%m🤯%d"
    vstr: StaticString = "mojo: 0009🔥06🤯01"
    alias dt = Date[iana=False, pyzoneinfo=False, native=False]
    ref1 = dt(9, 6, 1)
    parsed = dt.strptime(vstr, fstr)
    assert_true(parsed)
    assert_equal(ref1, parsed.value())
    fstr = "%Y-%m-%d %H:%M:%S.%f"
    vstr = "2024-06-07 09:09:09.009009"
    ref1 = dt(2024, 6, 7)
    parsed = dt.strptime(vstr, fstr)
    assert_true(parsed)
    assert_equal(ref1, parsed.value())


def main():
    test_add()
    test_subtract()
    test_logic()
    test_bitwise()
    test_iso()
    test_time()
    test_hash()
    test_strftime()
