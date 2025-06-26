# RUN: %mojo %s

from testing import assert_equal, assert_false, assert_raises, assert_true

from time import time

from forge_tools.datetime.datetime import DateTime
from forge_tools.datetime.calendar import (
    Calendar,
    PythonCalendar,
    UTCCalendar,
    Gregorian,
)
from forge_tools.datetime.dt_str import IsoFormat


def test_add():
    # using python and unix calendar should have no difference in results
    alias pycal = PythonCalendar
    alias unixcal = UTCCalendar
    alias dt = DateTime[iana=False, pyzoneinfo=False, native=False]
    alias TZ = dt._tz
    tz_0_ = TZ("Etc/UTC", 0, 0)
    tz_1 = TZ("Etc/UTC-1", 1, 0)
    tz1_ = TZ("Etc/UTC+1", 1, 0, -1)

    # test february leapyear
    result = dt(2024, 2, 29, tz=tz_0_, calendar=pycal) + dt(
        0, 0, 1, tz=tz_0_, calendar=pycal
    )
    offset_0 = dt(2024, 3, 1, tz=tz_0_, calendar=unixcal)
    offset_p_1 = dt(2024, 3, 1, hour=1, tz=tz_1, calendar=unixcal)
    offset_n_1 = dt(2024, 2, 29, hour=23, tz=tz1_, calendar=unixcal)
    add_seconds = dt(2024, 2, 29, tz=tz_0_, calendar=unixcal).add(
        seconds=24 * 3600
    )
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, add_seconds)

    # test february not leapyear
    result = dt(2023, 2, 28, tz=tz_0_, calendar=pycal) + dt(
        0, 0, 1, tz=tz_0_, calendar=pycal
    )
    offset_0 = dt(2023, 3, 1, tz=tz_0_, calendar=unixcal)
    offset_p_1 = dt(2023, 3, 1, hour=1, tz=tz_1, calendar=unixcal)
    offset_n_1 = dt(2023, 2, 28, hour=23, tz=tz1_, calendar=unixcal)
    add_seconds = dt(2023, 2, 28, tz=tz_0_, calendar=unixcal).add(
        seconds=24 * 3600
    )
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, add_seconds)

    # test normal month
    result = dt(2024, 5, 31, tz=tz_0_, calendar=pycal) + dt(
        0, 0, 1, tz=tz_0_, calendar=pycal
    )
    offset_0 = dt(2024, 6, 1, tz=tz_0_, calendar=unixcal)
    offset_p_1 = dt(2024, 6, 1, hour=1, tz=tz_1, calendar=unixcal)
    offset_n_1 = dt(2024, 5, 31, hour=23, tz=tz1_, calendar=unixcal)
    add_seconds = dt(2024, 5, 31, tz=tz_0_, calendar=unixcal).add(
        seconds=24 * 3600
    )
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, add_seconds)

    # test december
    result = dt(2024, 12, 31, tz=tz_0_, calendar=pycal) + dt(
        0, 0, 1, tz=tz_0_, calendar=pycal
    )
    offset_0 = dt(2025, 1, 1, tz=tz_0_, calendar=unixcal)
    offset_p_1 = dt(2025, 1, 1, hour=1, tz=tz_1, calendar=unixcal)
    offset_n_1 = dt(2024, 12, 31, hour=23, tz=tz1_, calendar=unixcal)
    add_seconds = dt(2024, 12, 31, tz=tz_0_, calendar=unixcal).add(
        seconds=24 * 3600
    )
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, add_seconds)

    # test year and month add
    result = dt(2022, 6, 1, tz=tz_0_, calendar=pycal) + dt(
        2, 6, 31, tz=tz_0_, calendar=pycal
    )
    offset_0 = dt(2025, 1, 1, tz=tz_0_, calendar=unixcal)
    offset_p_1 = dt(2025, 1, 1, hour=1, tz=tz_1, calendar=unixcal)
    offset_n_1 = dt(2024, 12, 31, hour=23, tz=tz1_, calendar=unixcal)
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)

    # test positive overflow pycal
    result = dt(9999, 12, 31, tz=tz_0_, calendar=pycal) + dt(
        0, 0, 1, tz=tz_0_, calendar=pycal
    )
    offset_0 = dt(1, 1, 1, tz=tz_0_, calendar=pycal)
    offset_p_1 = dt(1, 1, 1, hour=1, tz=tz_1, calendar=pycal)
    offset_n_1 = dt(9999, 12, 31, hour=23, tz=tz1_, calendar=pycal)
    add_seconds = dt(9999, 12, 31, tz=tz_0_, calendar=pycal).add(
        seconds=24 * 3600
    )
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, add_seconds)

    # test positive overflow unixcal
    result = dt(9999, 12, 31, tz=tz_0_, calendar=unixcal) + dt(
        0, 0, 1, tz=tz_0_, calendar=unixcal
    )
    offset_0 = dt(1970, 1, 1, tz=tz_0_, calendar=unixcal)
    offset_p_1 = dt(1970, 1, 1, hour=1, tz=tz_1, calendar=unixcal)
    offset_n_1 = dt(9999, 12, 31, hour=23, tz=tz1_, calendar=unixcal)
    add_seconds = dt(9999, 12, 31, tz=tz_0_, calendar=unixcal).add(
        seconds=24 * 3600
    )
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, add_seconds)


def test_subtract():
    # using python and unix calendar should have no difference in results
    alias pycal = PythonCalendar
    alias unixcal = UTCCalendar
    alias dt = DateTime[iana=False, pyzoneinfo=False, native=False]
    alias TZ = dt._tz
    tz_0_ = TZ("Etc/UTC", 0, 0)
    tz_1 = TZ("Etc/UTC-1", 1, 0)
    tz1_ = TZ("Etc/UTC+1", 1, 0, -1)

    # test february leapyear
    result = dt(2024, 3, 1, tz=tz_0_, calendar=pycal) - dt(
        0, 0, 1, tz=tz_0_, calendar=pycal
    )
    offset_0 = dt(2024, 2, 29, tz=tz_0_, calendar=unixcal)
    offset_p_1 = dt(2024, 2, 29, hour=1, tz=tz_1, calendar=unixcal)
    offset_n_1 = dt(2024, 2, 28, hour=23, tz=tz1_, calendar=unixcal)
    sub_seconds = dt(2024, 3, 1, tz=tz_0_, calendar=unixcal).subtract(days=1)
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, sub_seconds)

    # test february not leapyear
    result = dt(2023, 3, 1, tz=tz_0_, calendar=pycal) - dt(
        0, 0, 1, tz=tz_0_, calendar=pycal
    )
    offset_0 = dt(2023, 2, 28, tz=tz_0_, calendar=unixcal)
    offset_p_1 = dt(2023, 2, 28, hour=1, tz=tz_1, calendar=unixcal)
    offset_n_1 = dt(2023, 2, 27, hour=23, tz=tz1_, calendar=unixcal)
    sub_seconds = dt(2023, 3, 1, tz=tz_0_, calendar=unixcal).subtract(days=1)
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, sub_seconds)

    # test normal month
    result = dt(2024, 6, 1, tz=tz_0_, calendar=pycal) - dt(
        0, 0, 1, tz=tz_0_, calendar=pycal
    )
    offset_0 = dt(2024, 5, 31, tz=tz_0_, calendar=unixcal)
    offset_p_1 = dt(2024, 5, 31, hour=1, tz=tz_1, calendar=unixcal)
    offset_n_1 = dt(2024, 5, 30, hour=23, tz=tz1_, calendar=unixcal)
    sub_seconds = dt(2024, 6, 1, tz=tz_0_, calendar=unixcal).subtract(days=1)
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, sub_seconds)

    # test december
    result = dt(2025, 1, 1, tz=tz_0_, calendar=pycal) - dt(
        0, 0, 1, tz=tz_0_, calendar=pycal
    )
    offset_0 = dt(2024, 12, 31, tz=tz_0_, calendar=unixcal)
    offset_p_1 = dt(2024, 12, 31, hour=1, tz=tz_1, calendar=unixcal)
    offset_n_1 = dt(2024, 12, 30, hour=23, tz=tz1_, calendar=unixcal)
    sub_seconds = dt(2025, 1, 1, tz=tz_0_, calendar=unixcal).subtract(days=1)
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, sub_seconds)

    # test year and month subtract
    result = dt(2025, 1, 1, tz=tz_0_, calendar=pycal) - dt(
        2, 6, 31, tz=tz_0_, calendar=pycal
    )
    offset_0 = dt(2022, 6, 1, tz=tz_0_, calendar=unixcal)
    offset_p_1 = dt(2022, 6, 1, hour=1, tz=tz_1, calendar=unixcal)
    offset_n_1 = dt(2022, 5, 31, hour=23, tz=tz1_, calendar=unixcal)
    sub_seconds = dt(2025, 1, 1, tz=tz_0_, calendar=unixcal).subtract(
        years=2, months=6, days=31
    )
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, sub_seconds)

    # test negative overflow pycal
    result = dt(1, 1, 1, tz=tz_0_, calendar=pycal) - dt(
        0, 0, 1, tz=tz_0_, calendar=pycal
    )
    offset_0 = dt(9999, 12, 31, tz=tz_0_, calendar=pycal)
    offset_p_1 = dt(9999, 12, 31, hour=1, tz=tz_1, calendar=pycal)
    offset_n_1 = dt(9999, 12, 30, hour=23, tz=tz1_, calendar=pycal)
    sub_seconds = dt(1, 1, 1, tz=tz_0_, calendar=pycal).subtract(days=1)
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, sub_seconds)

    # test negative overflow unixcal
    result = dt(1970, 1, 1, tz=tz_0_, calendar=unixcal) - dt(
        0, 0, 1, tz=tz_0_, calendar=unixcal
    )
    offset_0 = dt(9999, 12, 31, tz=tz_0_, calendar=unixcal)
    offset_p_1 = dt(9999, 12, 31, hour=1, tz=tz_1, calendar=unixcal)
    offset_n_1 = dt(9999, 12, 30, hour=23, tz=tz1_, calendar=unixcal)
    sub_seconds = dt(1970, 1, 1, tz=tz_0_, calendar=unixcal).subtract(days=1)
    assert_equal(result, offset_0)
    assert_equal(result, offset_p_1)
    assert_equal(result, offset_n_1)
    assert_equal(result, sub_seconds)


def test_logic():
    # using python and unix calendar should have no difference in results
    alias pycal = PythonCalendar
    alias unixcal = UTCCalendar
    alias dt = DateTime[iana=False, pyzoneinfo=False, native=False]
    alias TZ = dt._tz
    tz_0_ = TZ("Etc/UTC", 0, 0)
    tz_1 = TZ("Etc/UTC-1", 1, 0)
    tz1_ = TZ("Etc/UTC+1", 1, 0, -1)

    ref1 = dt(1970, 1, 1, tz=tz_0_, calendar=pycal)
    assert_true(ref1 == dt(1970, 1, 1, tz=tz_0_, calendar=unixcal))
    assert_true(ref1 == dt(1970, 1, 1, 1, tz=tz_1, calendar=unixcal))
    assert_true(ref1 == dt(1969, 12, 31, 23, tz=tz1_, calendar=pycal))
    assert_true(ref1 < dt(1970, 1, 2, tz=tz_0_, calendar=unixcal))
    assert_true(ref1 <= dt(1970, 1, 2, tz=tz_0_, calendar=unixcal))
    assert_true(ref1 > dt(1969, 12, 31, tz=tz_0_, calendar=pycal))
    assert_true(ref1 >= dt(1969, 12, 31, tz=tz_0_, calendar=pycal))


def test_bitwise():
    # using python and unix calendar should have no difference in results
    alias pycal = PythonCalendar
    alias unixcal = UTCCalendar
    alias dt = DateTime[iana=False, pyzoneinfo=False, native=False]
    alias TZ = dt._tz
    tz_0_ = TZ("Etc/UTC", 0, 0)
    tz_1 = TZ("Etc/UTC-1", 1, 0)
    tz1_ = TZ("Etc/UTC+1", 1, 0, -1)

    ref1 = dt(1970, 1, 1, tz=tz_0_, calendar=pycal)
    assert_true(ref1 ^ dt(1970, 1, 1, tz=tz_0_, calendar=unixcal) == 0)
    assert_true(ref1 ^ dt(1970, 1, 1, tz=tz_1, calendar=unixcal) == 0)
    assert_true(ref1 ^ dt(1969, 12, 31, tz=tz1_, calendar=pycal) != 0)
    assert_true((ref1 ^ dt(1970, 1, 2, tz=tz_0_, calendar=pycal)) != 0)
    assert_true(
        (ref1 | (dt(1970, 1, 2, tz=tz_0_, calendar=pycal) & 0)) == hash(ref1)
    )
    # assert_true((hash(ref1) & ~hash(ref1)) == 0) # FIXME: uint has no ~ yet
    # assert_true(~(hash(ref1) ^ ~hash(ref1)) == 0)


def test_iso():
    alias pycal = PythonCalendar
    alias dt = DateTime[iana=False, pyzoneinfo=False, native=False]
    alias TZ = dt._tz
    tz_0_ = TZ("Etc/UTC", 0, 0)

    ref1 = dt(2024, 6, 16, 18, 51, 20, tz=tz_0_, calendar=pycal)
    iso_str: StaticString = "2024-06-16T18:51:20+00:00"
    alias fmt1 = IsoFormat(IsoFormat.YYYY_MM_DD_T_HH_MM_SS_TZD)
    assert_equal(ref1, dt.from_iso[fmt1](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt1]())

    iso_str = "2024-06-16 18:51:20"
    alias fmt2 = IsoFormat(IsoFormat.YYYY_MM_DD___HH_MM_SS)
    assert_equal(ref1, dt.from_iso[fmt2](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt2]())

    iso_str = "2024-06-16T18:51:20"
    alias fmt3 = IsoFormat(IsoFormat.YYYY_MM_DD_T_HH_MM_SS)
    assert_equal(ref1, dt.from_iso[fmt3](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt3]())

    iso_str = "20240616185120"
    alias fmt4 = IsoFormat(IsoFormat.YYYYMMDDHHMMSS)
    assert_equal(ref1, dt.from_iso[fmt4](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt4]())

    alias customcal = Calendar(Gregorian(min_year=2024))
    ref1 = dt(2024, 1, 1, 18, 51, 20, tz=tz_0_, calendar=pycal)
    iso_str = "18:51:20"
    alias fmt5 = IsoFormat(IsoFormat.HH_MM_SS)
    assert_equal(ref1, dt.from_iso[fmt5](iso_str, calendar=customcal).value())
    assert_equal(iso_str, ref1.to_iso[fmt5]())

    iso_str = "185120"
    alias fmt6 = IsoFormat(IsoFormat.HHMMSS)
    assert_equal(ref1, dt.from_iso[fmt6](iso_str, calendar=customcal).value())
    assert_equal(iso_str, ref1.to_iso[fmt6]())


def test_time():
    alias dt = DateTime[iana=False, pyzoneinfo=False, native=False]

    start = dt.now()
    time.sleep(1e-9)  # nanosecond resolution
    end = dt.now()
    assert_true(start.n_second != end.n_second)


def test_hash():
    alias pycal = PythonCalendar
    alias unixcal = UTCCalendar
    alias dt = DateTime[iana=False, pyzoneinfo=False, native=False]
    alias TZ = dt._tz
    tz_0_ = TZ("Etc/UTC", 0, 0)
    ref1 = dt(1970, 1, 1, tz=tz_0_, calendar=pycal)
    assert_equal(ref1, dt.from_hash(hash(ref1)))
    ref2 = dt(1970, 1, 1, tz=tz_0_, calendar=unixcal)
    assert_equal(ref2, dt.from_hash(hash(ref2)))
    assert_equal(ref1, ref2)


def test_strftime():
    alias dt = DateTime[iana=False, pyzoneinfo=False, native=False]
    fstr: StaticString = "mojo: %Y🔥%m🤯%d"
    assert_equal("mojo: 0009🔥06🤯01", dt(9, 6, 1).strftime(fstr))
    fstr = "%Y-%m-%d %H:%M:%S.%f"
    ref1 = dt(2024, 9, 9, 9, 9, 9, 9, 9)
    assert_equal("2024-09-09 09:09:09.009009", ref1.strftime(fstr))


def test_strptime():
    fstr: StaticString = "mojo: %Y🔥%m🤯%d"
    vstr: StaticString = "mojo: 0009🔥06🤯01"
    alias dt = DateTime[iana=False, pyzoneinfo=False, native=False]
    ref1 = dt(9, 6, 1)
    parsed = dt.strptime(vstr, fstr)
    assert_true(parsed)
    assert_equal(ref1, parsed.value())
    fstr = "%Y-%m-%d %H:%M:%S.%f"
    vstr = "2024-09-09 09:09:09.009009"
    ref1 = dt(2024, 9, 9, 9, 9, 9, 9, 9)
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
