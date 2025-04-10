# RUN: %mojo %s

from testing import assert_equal, assert_false, assert_raises, assert_true

from forge_tools.datetime.timezone import (
    TimeZone,
    ZoneInfo,
    ZoneInfoMem32,
    ZoneInfoMem8,
)


def test_tz_no_iana():
    alias TZ = TimeZone[iana=False, pyzoneinfo=False, native=False]
    tz0 = TZ("Etc/UTC", 0, 0)
    tz_1 = TZ("Etc/UTC-1", 1, 0)
    tz_2 = TZ("Etc/UTC-2", 2, 30)
    tz_3 = TZ("Etc/UTC-3", 3, 45)
    tz1_ = TZ("Etc/UTC+1", 1, 0, -1)
    tz2_ = TZ("Etc/UTC+2", 2, 30, -1)
    tz3_ = TZ("Etc/UTC+3", 3, 45, -1)
    assert_true(tz0 == TZ())
    assert_true(tz1_ != tz_1 and tz2_ != tz_2 and tz3_ != tz_3)
    d = (1970, 1, 1, 0, 0, 0)
    tz0_of = tz0.offset_at(d[0], d[1], d[2], d[3], d[4], d[5])
    tz_1_of = tz_1.offset_at(d[0], d[1], d[2], d[3], d[4], d[5])
    tz_2_of = tz_2.offset_at(d[0], d[1], d[2], d[3], d[4], d[5])
    tz_3_of = tz_3.offset_at(d[0], d[1], d[2], d[3], d[4], d[5])
    tz1__of = tz1_.offset_at(d[0], d[1], d[2], d[3], d[4], d[5])
    tz2__of = tz2_.offset_at(d[0], d[1], d[2], d[3], d[4], d[5])
    tz3__of = tz3_.offset_at(d[0], d[1], d[2], d[3], d[4], d[5])
    assert_equal(tz0_of.hour, 0)
    assert_equal(tz0_of.minute, 0)
    assert_equal(tz0_of.sign, 1)
    assert_equal(tz_1_of.hour, 1)
    assert_equal(tz_1_of.minute, 0)
    assert_equal(tz_1_of.sign, 1)
    assert_equal(tz_2_of.hour, 2)
    assert_equal(tz_2_of.minute, 30)
    assert_equal(tz_2_of.sign, 1)
    assert_equal(tz_3_of.hour, 3)
    assert_equal(tz_3_of.minute, 45)
    assert_equal(tz_3_of.sign, 1)
    assert_equal(tz1__of.hour, 1)
    assert_equal(tz1__of.minute, 0)
    assert_equal(tz1__of.sign, -1)
    assert_equal(tz2__of.hour, 2)
    assert_equal(tz2__of.minute, 30)
    assert_equal(tz2__of.sign, -1)
    assert_equal(tz3__of.hour, 3)
    assert_equal(tz3__of.minute, 45)
    assert_equal(tz3__of.sign, -1)


def test_tz_iana_dst():
    # TODO: test from positive and negative UTC
    # TODO: test transitions to and from DST
    # TODO: test for Australia/Lord_Howe and Antarctica/Troll base
    pass


def test_tz_iana_no_dst():
    # TODO: test from positive and negative UTC
    pass


def main():
    test_tz_no_iana()
    test_tz_iana_dst()
    test_tz_iana_no_dst()
