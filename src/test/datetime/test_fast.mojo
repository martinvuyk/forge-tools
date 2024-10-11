# RUN: %mojo %s

from testing import assert_equal, assert_false, assert_raises, assert_true

from time import time

from forge_tools.datetime.fast import (
    DateTime64,
    DateTime32,
    DateTime16,
    DateTime8,
)
from forge_tools.datetime.dt_str import IsoFormat


fn test_add64() raises:
    # test february leapyear
    result = DateTime64(2024, 2, 28).add(days=1)
    offset_0 = DateTime64(2024, 2, 29)
    assert_equal(result, offset_0)
    add_seconds = DateTime64(2024, 2, 28).add(seconds=24 * 3600)
    assert_equal(result, add_seconds)

    # test february not leapyear
    result = DateTime64(2023, 2, 28).add(days=1)
    offset_0 = DateTime64(2023, 3, 1)
    assert_equal(result, offset_0)
    add_seconds = DateTime64(2023, 2, 28).add(seconds=24 * 3600)
    assert_equal(result, add_seconds)

    # test normal month
    result = DateTime64(2024, 5, 31).add(days=1)
    offset_0 = DateTime64(2024, 6, 1)
    assert_equal(result, offset_0)
    add_seconds = DateTime64(2024, 5, 31).add(seconds=24 * 3600)
    assert_equal(result, add_seconds)

    # test december
    result = DateTime64(2024, 12, 31).add(days=1)
    offset_0 = DateTime64(2025, 1, 1)
    assert_equal(result, offset_0)
    add_seconds = DateTime64(2024, 12, 31).add(seconds=24 * 3600)
    assert_equal(result, add_seconds)

    # test year and month add
    result = DateTime64(2022, 12, 1).add(years=1, days=31)
    offset_0 = DateTime64(2024, 1, 1)
    assert_equal(result.m_seconds, offset_0.m_seconds)


fn test_add32() raises:
    # test february leapyear
    result = DateTime32(2024, 2, 28).add(days=1)
    offset_0 = DateTime32(2024, 2, 29)
    assert_equal(result.minutes, offset_0.minutes)
    add_seconds = DateTime32(2024, 2, 28).add(seconds=24 * 3600)
    assert_equal(result, add_seconds)

    # test february not leapyear
    result = DateTime32(2023, 2, 28).add(days=1)
    offset_0 = DateTime32(2023, 3, 1)
    assert_equal(result, offset_0)
    add_seconds = DateTime32(2023, 2, 28).add(seconds=24 * 3600)
    assert_equal(result, add_seconds)

    # test normal month
    result = DateTime32(2024, 5, 31).add(days=1)
    offset_0 = DateTime32(2024, 6, 1)
    assert_equal(result, offset_0)
    add_seconds = DateTime32(2024, 5, 31).add(seconds=24 * 3600)
    assert_equal(result, add_seconds)

    # test december
    result = DateTime32(2024, 12, 31).add(days=1)
    offset_0 = DateTime32(2025, 1, 1)
    assert_equal(result, offset_0)
    add_seconds = DateTime32(2024, 12, 31).add(seconds=24 * 3600)
    assert_equal(result, add_seconds)

    # test year and month add
    result = DateTime32(2022, 12, 1).add(years=1, days=31)
    offset_0 = DateTime32(2024, 1, 1)
    assert_equal(result, offset_0)


fn test_subtract64() raises:
    # test february leapyear
    result = DateTime64(2024, 3, 1).subtract(days=1)
    offset_0 = DateTime64(2024, 2, 29)
    assert_equal(result, offset_0)
    sub_seconds = DateTime64(2024, 3, 1).subtract(seconds=1 * 24 * 60 * 60)
    assert_equal(result, sub_seconds)

    # test february not leapyear
    result = DateTime64(2023, 3, 1).subtract(days=1)
    offset_0 = DateTime64(2023, 2, 28)
    assert_equal(result, offset_0)
    sub_seconds = DateTime64(2023, 3, 1).subtract(seconds=1 * 24 * 60 * 60)
    assert_equal(result, sub_seconds)

    # test normal month
    result = DateTime64(2024, 6, 1).subtract(days=1)
    offset_0 = DateTime64(2024, 5, 31)
    assert_equal(result, offset_0)
    sub_seconds = DateTime64(2024, 6, 1).subtract(seconds=1 * 24 * 60 * 60)
    assert_equal(result, sub_seconds)

    # test december
    result = DateTime64(2025, 1, 1).subtract(days=1)
    offset_0 = DateTime64(2024, 12, 31)
    assert_equal(result, offset_0)
    sub_seconds = DateTime64(2025, 1, 1).subtract(seconds=1 * 24 * 60 * 60)
    assert_equal(result, sub_seconds)

    # test year and month subtract
    result = DateTime64(2023, 7, 1).subtract(years=1, days=30)
    offset_0 = DateTime64(2022, 6, 1)
    assert_equal(result, offset_0)


fn test_subtract32() raises:
    # test february leapyear
    result = DateTime32(2024, 3, 1).subtract(days=1)
    offset_0 = DateTime32(2024, 2, 29)
    assert_equal(result, offset_0)
    sub_seconds = DateTime32(2024, 3, 1).subtract(seconds=1 * 24 * 60 * 60)
    assert_equal(result, sub_seconds)

    # test february not leapyear
    result = DateTime32(2023, 3, 1).subtract(days=1)
    offset_0 = DateTime32(2023, 2, 28)
    assert_equal(result, offset_0)
    sub_seconds = DateTime32(2023, 3, 1).subtract(seconds=1 * 24 * 60 * 60)
    assert_equal(result, sub_seconds)

    # test normal month
    result = DateTime32(2024, 6, 1).subtract(days=1)
    offset_0 = DateTime32(2024, 5, 31)
    assert_equal(result, offset_0)
    sub_seconds = DateTime32(2024, 6, 1).subtract(seconds=1 * 24 * 60 * 60)
    assert_equal(result, sub_seconds)

    # test december
    result = DateTime32(2025, 1, 1).subtract(days=1)
    offset_0 = DateTime32(2024, 12, 31)
    assert_equal(result, offset_0)
    sub_seconds = DateTime32(2025, 1, 1).subtract(seconds=1 * 24 * 60 * 60)
    assert_equal(result, sub_seconds)

    # test year and month subtract
    result = DateTime32(2023, 7, 1).subtract(years=1, days=30)
    offset_0 = DateTime32(2022, 6, 1)
    assert_equal(result, offset_0)


fn test_logic64() raises:
    ref1 = DateTime64(2000, 1, 1)
    assert_true(ref1 == DateTime64(2000, 1, 1))
    assert_true(ref1 != DateTime64(1999, 12, 31))
    assert_true(ref1 < DateTime64(2000, 1, 2))
    assert_true(ref1 <= DateTime64(2000, 1, 2))
    assert_true(ref1 > DateTime64(1999, 12, 31))
    assert_true(ref1 >= DateTime64(1999, 12, 31))


fn test_logic32() raises:
    ref1 = DateTime32(2000, 1, 1)
    assert_true(ref1 == DateTime32(2000, 1, 1))
    assert_true(ref1 != DateTime32(1999, 12, 31))
    assert_true(ref1 < DateTime32(2000, 1, 2))
    assert_true(ref1 <= DateTime32(2000, 1, 2))
    assert_true(ref1 > DateTime32(1999, 12, 31))
    assert_true(ref1 >= DateTime32(1999, 12, 31))


fn test_logic16() raises:
    ref1 = DateTime16(2000, 1, 1)
    assert_true(ref1 == DateTime16(2000, 1, 1))
    assert_true(ref1 != DateTime16(1999, 12, 31))
    assert_true(ref1 < DateTime16(2000, 1, 2))
    assert_true(ref1 <= DateTime16(2000, 1, 2))
    assert_true(ref1 > DateTime16(1999, 12, 31))
    assert_true(ref1 >= DateTime16(1999, 12, 31))


fn test_logic8() raises:
    ref1 = DateTime8(2000, 1, 1)
    assert_true(ref1 == DateTime8(2000, 1, 1))
    assert_true(ref1 != DateTime8(1999, 12, 31))
    assert_true(ref1 < DateTime8(2000, 1, 2))
    assert_true(ref1 <= DateTime8(2000, 1, 2))
    assert_true(ref1 > DateTime8(1999, 12, 31))
    assert_true(ref1 >= DateTime8(1999, 12, 31))


fn test_bitwise64() raises:
    ref1 = DateTime64(2000, 1, 1)
    assert_true((ref1 ^ DateTime64(2000, 1, 2)) != 0)
    assert_true((ref1 | (DateTime64(2000, 1, 2) & 0)) == hash(ref1))
    assert_true((ref1 & ~ref1) == 0)
    assert_true(~(ref1 ^ ~ref1) == 0)


fn test_bitwise32() raises:
    ref1 = DateTime32(2000, 1, 1)
    assert_true((ref1 ^ DateTime32(2000, 1, 2)) != 0)
    assert_true((ref1 | (DateTime32(2000, 1, 2) & 0)) == hash(ref1))
    assert_true((ref1 & ~ref1) == 0)
    assert_true(~(ref1 ^ ~ref1) == 0)


fn test_bitwise16() raises:
    ref1 = DateTime16(2000, 1, 1)
    assert_true((ref1 ^ DateTime16(2000, 1, 2)) != 0)
    assert_true((ref1 | (DateTime16(2000, 1, 2) & 0)) == hash(ref1))
    assert_true((ref1 & ~ref1) == 0)
    assert_true(~(ref1 ^ ~ref1) == 0)


fn test_bitwise8() raises:
    ref1 = DateTime8(2000, 1, 1)
    assert_true((ref1 ^ DateTime8(2000, 1, 2)) != 0)
    assert_true((ref1 | (DateTime8(2000, 1, 2) & 0)) == hash(ref1))
    assert_true((ref1 & ~ref1) == 0)
    assert_true(~(ref1 ^ ~ref1) == 0)


fn test_iso64() raises:
    ref1 = DateTime64(2024, 6, 16, 18, 51, 20)
    iso_str = "2024-06-16T18:51:20+00:00"
    alias fmt1 = IsoFormat(IsoFormat.YYYY_MM_DD_T_HH_MM_SS_TZD)
    assert_equal(ref1, DateTime64.from_iso[fmt1](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt1]())

    iso_str = "2024-06-16 18:51:20"
    alias fmt2 = IsoFormat(IsoFormat.YYYY_MM_DD___HH_MM_SS)
    assert_equal(ref1, DateTime64.from_iso[fmt2](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt2]())

    iso_str = "2024-06-16T18:51:20"
    alias fmt3 = IsoFormat(IsoFormat.YYYY_MM_DD_T_HH_MM_SS)
    assert_equal(ref1, DateTime64.from_iso[fmt3](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt3]())

    iso_str = "20240616185120"
    alias fmt4 = IsoFormat(IsoFormat.YYYYMMDDHHMMSS)
    assert_equal(ref1, DateTime64.from_iso[fmt4](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt4]())

    iso_str = "18:51:20"
    alias fmt5 = IsoFormat(IsoFormat.HH_MM_SS)
    parsed = DateTime64.from_iso[fmt5](iso_str).value()
    assert_equal(ref1.hour, parsed.hour)
    assert_equal(ref1.minute, parsed.minute)
    assert_equal(ref1.second, parsed.second)
    assert_equal(iso_str, ref1.to_iso[fmt5]())

    iso_str = "185120"
    alias fmt6 = IsoFormat(IsoFormat.HHMMSS)
    parsed = DateTime64.from_iso[fmt6](iso_str).value()
    assert_equal(ref1.hour, parsed.hour)
    assert_equal(ref1.minute, parsed.minute)
    assert_equal(ref1.second, parsed.second)
    assert_equal(iso_str, ref1.to_iso[fmt6]())


fn test_iso32() raises:
    ref1 = DateTime32(2024, 6, 16, 18, 51)
    iso_str = "2024-06-16T18:51:00+00:00"
    alias fmt1 = IsoFormat(IsoFormat.YYYY_MM_DD_T_HH_MM_SS_TZD)
    assert_equal(ref1, DateTime32.from_iso[fmt1](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt1]())

    iso_str = "2024-06-16 18:51:00"
    alias fmt2 = IsoFormat(IsoFormat.YYYY_MM_DD___HH_MM_SS)
    assert_equal(ref1, DateTime32.from_iso[fmt2](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt2]())

    iso_str = "2024-06-16T18:51:00"
    alias fmt3 = IsoFormat(IsoFormat.YYYY_MM_DD_T_HH_MM_SS)
    assert_equal(ref1, DateTime32.from_iso[fmt3](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt3]())

    iso_str = "20240616185100"
    alias fmt4 = IsoFormat(IsoFormat.YYYYMMDDHHMMSS)
    assert_equal(ref1, DateTime32.from_iso[fmt4](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt4]())

    iso_str = "18:51:00"
    alias fmt5 = IsoFormat(IsoFormat.HH_MM_SS)
    parsed = DateTime32.from_iso[fmt5](iso_str).value()
    assert_equal(ref1.hour, parsed.hour)
    assert_equal(ref1.minute, parsed.minute)
    assert_equal(iso_str, ref1.to_iso[fmt5]())

    iso_str = "185100"
    alias fmt6 = IsoFormat(IsoFormat.HHMMSS)
    parsed = DateTime32.from_iso[fmt6](iso_str).value()
    assert_equal(ref1.hour, parsed.hour)
    assert_equal(ref1.minute, parsed.minute)
    assert_equal(iso_str, ref1.to_iso[fmt6]())


fn test_iso16() raises:
    ref1 = DateTime16(1973, 6, 16, 18)
    iso_str = "1973-06-16T18:00:00+00:00"
    alias fmt1 = IsoFormat(IsoFormat.YYYY_MM_DD_T_HH_MM_SS_TZD)
    assert_equal(ref1, DateTime16.from_iso[fmt1](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt1]())

    iso_str = "1973-06-16 18:00:00"
    alias fmt2 = IsoFormat(IsoFormat.YYYY_MM_DD___HH_MM_SS)
    assert_equal(ref1, DateTime16.from_iso[fmt2](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt2]())

    iso_str = "1973-06-16T18:00:00"
    alias fmt3 = IsoFormat(IsoFormat.YYYY_MM_DD_T_HH_MM_SS)
    assert_equal(ref1, DateTime16.from_iso[fmt3](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt3]())

    iso_str = "19730616180000"
    alias fmt4 = IsoFormat(IsoFormat.YYYYMMDDHHMMSS)
    assert_equal(ref1, DateTime16.from_iso[fmt4](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt4]())

    iso_str = "18:00:00"
    alias fmt5 = IsoFormat(IsoFormat.HH_MM_SS)
    parsed = DateTime16.from_iso[fmt5](iso_str).value()
    assert_equal(ref1.hour, parsed.hour)
    assert_equal(iso_str, ref1.to_iso[fmt5]())

    iso_str = "180000"
    alias fmt6 = IsoFormat(IsoFormat.HHMMSS)
    parsed = DateTime16.from_iso[fmt6](iso_str).value()
    assert_equal(ref1.hour, parsed.hour)
    assert_equal(iso_str, ref1.to_iso[fmt6]())


fn test_iso8() raises:
    ref1 = DateTime8(1970, 1, 6, 18)
    iso_str = "1970-01-06T18:00:00+00:00"
    alias fmt1 = IsoFormat(IsoFormat.YYYY_MM_DD_T_HH_MM_SS_TZD)
    assert_equal(ref1, DateTime8.from_iso[fmt1](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt1]())

    iso_str = "1970-01-06 18:00:00"
    alias fmt2 = IsoFormat(IsoFormat.YYYY_MM_DD___HH_MM_SS)
    assert_equal(ref1, DateTime8.from_iso[fmt2](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt2]())

    iso_str = "1970-01-06T18:00:00"
    alias fmt3 = IsoFormat(IsoFormat.YYYY_MM_DD_T_HH_MM_SS)
    assert_equal(ref1, DateTime8.from_iso[fmt3](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt3]())

    iso_str = "19700106180000"
    alias fmt4 = IsoFormat(IsoFormat.YYYYMMDDHHMMSS)
    assert_equal(ref1, DateTime8.from_iso[fmt4](iso_str).value())
    assert_equal(iso_str, ref1.to_iso[fmt4]())

    iso_str = "18:00:00"
    alias fmt5 = IsoFormat(IsoFormat.HH_MM_SS)
    parsed = DateTime8.from_iso[fmt5](iso_str).value()
    assert_equal(ref1.hour, parsed.hour)
    assert_equal(iso_str, ref1.to_iso[fmt5]())

    iso_str = "180000"
    alias fmt6 = IsoFormat(IsoFormat.HHMMSS)
    parsed = DateTime8.from_iso[fmt6](iso_str).value()
    assert_equal(ref1.hour, parsed.hour)
    assert_equal(iso_str, ref1.to_iso[fmt6]())


fn test_time64() raises:
    start = DateTime64.now()
    time.sleep(1e-3)  # milisecond resolution
    end = DateTime64.now()
    assert_true(start != end)


fn test_hash64() raises:
    ref1 = DateTime64(9999, 12, 31, 23, 59, 59, 999)
    assert_equal(ref1.m_seconds, DateTime64.from_hash(hash(ref1)).m_seconds)


fn test_hash32() raises:
    ref1 = DateTime32(4095, 12, 31, 23, 59)
    assert_equal(ref1.minutes, DateTime32.from_hash(hash(ref1)).minutes)


fn test_hash16() raises:
    ref1 = DateTime16(1973, 12, 31, 23)
    assert_equal(ref1.hours, DateTime16.from_hash(hash(ref1)).hours)


fn test_hash8() raises:
    ref1 = DateTime8(1970, 1, 6, 23)
    assert_equal(ref1.hours, DateTime8.from_hash(hash(ref1)).hours)


fn main() raises:
    test_add64()
    test_subtract64()
    test_logic64()
    test_bitwise64()
    test_iso64()
    test_hash64()
    test_time64()
    test_add32()
    test_subtract32()
    test_logic32()
    test_bitwise32()
    test_iso32()
    test_hash32()
    test_logic16()
    test_bitwise16()
    test_iso16()
    test_hash16()
    test_logic8()
    test_bitwise8()
    test_iso8()
    test_hash8()
