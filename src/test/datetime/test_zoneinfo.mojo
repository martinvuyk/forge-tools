# RUN: %mojo %s

from testing import assert_equal, assert_false, assert_raises, assert_true

from forge_tools.datetime.zoneinfo import (
    Offset,
    TzDT,
    ZoneDST,
    ZoneInfoFile32,
    ZoneInfoFile8,
    ZoneInfoMem32,
    ZoneInfoMem8,
    get_zoneinfo,
    get_leapsecs,
    # _parse_iana_leapsecs,
    # _parse_iana_zonenow,
    # _parse_iana_dst_transitions,
)


def test_offset():
    alias minutes = SIMD[DType.uint8, 4](0, 30, 45, 0)
    for k in range(2):
        sign = 1 if k == 0 else -1
        for j in range(3):
            for i in range(16):
                of = Offset(i, minutes[j], sign)
                assert_equal(of.hour, i)
                assert_equal(of.minute, minutes[j])
                assert_equal(of.sign, sign)
                of = Offset(buf=of.buf)
                assert_equal(of.hour, i)
                assert_equal(of.minute, minutes[j])
                assert_equal(of.sign, sign)


def test_tzdst():
    alias hours = SIMD[DType.uint8, 8](20, 21, 22, 23, 0, 1, 2, 3)
    for month in range(1, 13):
        for dow in range(2):
            for eomon in range(2):
                for week in range(2):
                    for hour in range(8):
                        tzdt = TzDT(month, dow, eomon, week, hours[hour])
                        assert_equal(tzdt.month, month)
                        assert_equal(tzdt.dow, dow)
                        assert_equal(tzdt.eomon, eomon)
                        assert_equal(tzdt.week, week)
                        assert_equal(tzdt.hour, hours[hour])
                        tzdt = TzDT(buf=tzdt.buf)
                        assert_equal(tzdt.month, month)
                        assert_equal(tzdt.dow, dow)
                        assert_equal(tzdt.eomon, eomon)
                        assert_equal(tzdt.week, week)
                        assert_equal(tzdt.hour, hours[hour])


def test_zonedst():
    alias hours = SIMD[DType.uint8, 8](20, 21, 22, 23, 0, 1, 2, 3)
    alias minutes = SIMD[DType.uint8, 4](0, 30, 45, 0)
    for month in range(1, 13):
        for dow in range(2):
            for eomon in range(2):
                for week in range(2):
                    for hour in range(8):
                        for k in range(2):
                            sign = 1 if k == 0 else -1
                            for j in range(3):
                                for i in range(16):
                                    tzdt = TzDT(
                                        month, dow, eomon, week, hours[hour]
                                    )
                                    of = Offset(i, minutes[j], sign)
                                    parsed = ZoneDST(tzdt, tzdt, of).from_hash()
                                    assert_equal(tzdt.buf, parsed[0].buf)
                                    assert_equal(tzdt.buf, parsed[1].buf)
                                    assert_equal(of.buf, parsed[2].buf)


def test_zoneinfomem32():
    storage = ZoneInfoMem32()
    tz0 = "tz0"
    tz1 = "tz1"
    tz2 = "tz2"
    tz30 = "tz30"
    tz45 = "tz45"
    tz0_of = Offset(0, 0, 1)
    tz1_of = Offset(1, 0, 1)
    tz2_of = Offset(2, 0, 1)
    tz30_of = Offset(0, 30, 1)
    tz45_of = Offset(0, 45, 1)
    storage.add(tz0, ZoneDST(TzDT(), TzDT(), tz0_of))
    storage.add(tz1, ZoneDST(TzDT(), TzDT(), tz1_of))
    storage.add(tz2, ZoneDST(TzDT(), TzDT(), tz2_of))
    storage.add(tz30, ZoneDST(TzDT(), TzDT(), tz30_of))
    storage.add(tz45, ZoneDST(TzDT(), TzDT(), tz45_of))
    tz0_read = storage.get(tz0).value().from_hash()[2]
    tz1_read = storage.get(tz1).value().from_hash()[2]
    tz2_read = storage.get(tz2).value().from_hash()[2]
    tz30_read = storage.get(tz30).value().from_hash()[2]
    tz45_read = storage.get(tz45).value().from_hash()[2]
    assert_equal(tz0_read.hour, tz0_of.hour)
    assert_equal(tz1_read.hour, tz1_of.hour)
    assert_equal(tz2_read.hour, tz2_of.hour)
    assert_equal(tz30_read.hour, tz30_of.hour)
    assert_equal(tz45_read.hour, tz45_of.hour)
    assert_equal(tz0_read.minute, tz0_of.minute)
    assert_equal(tz1_read.minute, tz1_of.minute)
    assert_equal(tz2_read.minute, tz2_of.minute)
    assert_equal(tz30_read.minute, tz30_of.minute)
    assert_equal(tz45_read.minute, tz45_of.minute)
    assert_equal(tz0_read.sign, tz0_of.sign)
    assert_equal(tz1_read.sign, tz1_of.sign)
    assert_equal(tz2_read.sign, tz2_of.sign)
    assert_equal(tz30_read.sign, tz30_of.sign)
    assert_equal(tz45_read.sign, tz45_of.sign)
    assert_equal(tz0_read.buf, tz0_of.buf)
    assert_equal(tz1_read.buf, tz1_of.buf)
    assert_equal(tz2_read.buf, tz2_of.buf)
    assert_equal(tz30_read.buf, tz30_of.buf)
    assert_equal(tz45_read.buf, tz45_of.buf)


def test_zoneinfomem8():
    storage = ZoneInfoMem8()
    tz0 = "tz0"
    tz1 = "tz1"
    tz2 = "tz2"
    tz30 = "tz30"
    tz45 = "tz45"
    tz0_of = Offset(0, 0, 1)
    tz1_of = Offset(1, 0, 1)
    tz2_of = Offset(2, 0, 1)
    tz30_of = Offset(0, 30, 1)
    tz45_of = Offset(0, 45, 1)
    storage.add(tz0, tz0_of)
    storage.add(tz1, tz1_of)
    storage.add(tz2, tz2_of)
    storage.add(tz30, tz30_of)
    storage.add(tz45, tz45_of)
    tz0_read = storage.get(tz0).value()
    tz1_read = storage.get(tz1).value()
    tz2_read = storage.get(tz2).value()
    tz30_read = storage.get(tz30).value()
    tz45_read = storage.get(tz45).value()
    assert_equal(tz0_read.hour, tz0_of.hour)
    assert_equal(tz1_read.hour, tz1_of.hour)
    assert_equal(tz2_read.hour, tz2_of.hour)
    assert_equal(tz30_read.hour, tz30_of.hour)
    assert_equal(tz45_read.hour, tz45_of.hour)
    assert_equal(tz0_read.minute, tz0_of.minute)
    assert_equal(tz1_read.minute, tz1_of.minute)
    assert_equal(tz2_read.minute, tz2_of.minute)
    assert_equal(tz30_read.minute, tz30_of.minute)
    assert_equal(tz45_read.minute, tz45_of.minute)
    assert_equal(tz0_read.sign, tz0_of.sign)
    assert_equal(tz1_read.sign, tz1_of.sign)
    assert_equal(tz2_read.sign, tz2_of.sign)
    assert_equal(tz30_read.sign, tz30_of.sign)
    assert_equal(tz45_read.sign, tz45_of.sign)
    assert_equal(tz0_read.buf, tz0_of.buf)
    assert_equal(tz1_read.buf, tz1_of.buf)
    assert_equal(tz2_read.buf, tz2_of.buf)
    assert_equal(tz30_read.buf, tz30_of.buf)
    assert_equal(tz45_read.buf, tz45_of.buf)


# FIXME
# def test_zoneinfofile32():
#     storage = ZoneInfoFile32()
#     tz0 = "tz0"
#     tz1 = "tz1"
#     tz2 = "tz2"
#     tz30 = "tz30"
#     tz45 = "tz45"
#     tz0_of = Offset(0, 0, 1)
#     tz1_of = Offset(1, 0, 1)
#     tz2_of = Offset(2, 0, 1)
#     tz30_of = Offset(0, 30, 1)
#     tz45_of = Offset(0, 45, 1)
#     storage.add(tz0, ZoneDST(TzDT(), TzDT(), tz0_of))
#     storage.add(tz1, ZoneDST(TzDT(), TzDT(), tz1_of))
#     storage.add(tz2, ZoneDST(TzDT(), TzDT(), tz2_of))
#     storage.add(tz30, ZoneDST(TzDT(), TzDT(), tz30_of))
#     storage.add(tz45, ZoneDST(TzDT(), TzDT(), tz45_of))
#     tz0_read = storage.get(tz0).value().from_hash()[2]
#     tz1_read = storage.get(tz1).value().from_hash()[2]
#     tz2_read = storage.get(tz2).value().from_hash()[2]
#     tz30_read = storage.get(tz30).value().from_hash()[2]
#     tz45_read = storage.get(tz45).value().from_hash()[2]
#     assert_equal(tz0_read.hour, tz0_of.hour)
#     assert_equal(tz1_read.hour, tz1_of.hour)
#     assert_equal(tz2_read.hour, tz2_of.hour)
#     assert_equal(tz30_read.hour, tz30_of.hour)
#     assert_equal(tz45_read.hour, tz45_of.hour)
#     assert_equal(tz0_read.minute, tz0_of.minute)
#     assert_equal(tz1_read.minute, tz1_of.minute)
#     assert_equal(tz2_read.minute, tz2_of.minute)
#     assert_equal(tz30_read.minute, tz30_of.minute)
#     assert_equal(tz45_read.minute, tz45_of.minute)
#     assert_equal(tz0_read.sign, tz0_of.sign)
#     assert_equal(tz1_read.sign, tz1_of.sign)
#     assert_equal(tz2_read.sign, tz2_of.sign)
#     assert_equal(tz30_read.sign, tz30_of.sign)
#     assert_equal(tz45_read.sign, tz45_of.sign)
#     assert_equal(tz0_read.buf, tz0_of.buf)
#     assert_equal(tz1_read.buf, tz1_of.buf)
#     assert_equal(tz2_read.buf, tz2_of.buf)
#     assert_equal(tz30_read.buf, tz30_of.buf)
#     assert_equal(tz45_read.buf, tz45_of.buf)


# FIXME
# def test_zoneinfofile8():
#     storage = ZoneInfoFile8()
#     tz0 = "tz0"
#     tz1 = "tz1"
#     tz2 = "tz2"
#     tz30 = "tz30"
#     tz45 = "tz45"
#     tz0_of = Offset(0, 0, 1)
#     tz1_of = Offset(1, 0, 1)
#     tz2_of = Offset(2, 0, 1)
#     tz30_of = Offset(0, 30, 1)
#     tz45_of = Offset(0, 45, 1)
#     storage.add(tz0, tz0_of)
#     storage.add(tz1, tz1_of)
#     storage.add(tz2, tz2_of)
#     storage.add(tz30, tz30_of)
#     storage.add(tz45, tz45_of)
#     tz0_read = storage.get(tz0).value()
#     tz1_read = storage.get(tz1).value()
#     tz2_read = storage.get(tz2).value()
#     tz30_read = storage.get(tz30).value()
#     tz45_read = storage.get(tz45).value()
#     # print("tz0_of: ", tz0_of.hour, tz0_of.minute, tz0_of.sign)
#     # print("tz0_read: ", tz0_read.hour, tz0_read.minute, tz0_read.sign)
#     # print("tz1_of: ", tz1_of.hour, tz1_of.minute, tz1_of.sign)
#     # print("tz1_read: ", tz1_read.hour, tz1_read.minute, tz1_read.sign)
#     # print("tz2_of: ", tz2_of.hour, tz2_of.minute, tz2_of.sign)
#     # print("tz2_read: ", tz2_read.hour, tz2_read.minute, tz2_read.sign)
#     # print("tz30_of: ", tz30_of.hour, tz30_of.minute, tz30_of.sign)
#     # print("tz30_read: ", tz30_read.hour, tz30_read.minute, tz30_read.sign)
#     # print("tz45_of: ", tz45_of.hour, tz45_of.minute, tz45_of.sign)
#     # print("tz45_read: ", tz45_read.hour, tz45_read.minute, tz45_read.sign)
#     assert_equal(tz0_read.hour, tz0_of.hour)
#     assert_equal(tz1_read.hour, tz1_of.hour)
#     assert_equal(tz2_read.hour, tz2_of.hour)
#     assert_equal(tz30_read.hour, tz30_of.hour)
#     assert_equal(tz45_read.hour, tz45_of.hour)
#     assert_equal(tz0_read.minute, tz0_of.minute)
#     assert_equal(tz1_read.minute, tz1_of.minute)
#     assert_equal(tz2_read.minute, tz2_of.minute)
#     assert_equal(tz30_read.minute, tz30_of.minute)
#     assert_equal(tz45_read.minute, tz45_of.minute)
#     assert_equal(tz0_read.sign, tz0_of.sign)
#     assert_equal(tz1_read.sign, tz1_of.sign)
#     assert_equal(tz2_read.sign, tz2_of.sign)
#     assert_equal(tz30_read.sign, tz30_of.sign)
#     assert_equal(tz45_read.sign, tz45_of.sign)
#     assert_equal(tz0_read.buf, tz0_of.buf)
#     assert_equal(tz1_read.buf, tz1_of.buf)
#     assert_equal(tz2_read.buf, tz2_of.buf)
#     assert_equal(tz30_read.buf, tz30_of.buf)
#     assert_equal(tz45_read.buf, tz45_of.buf)


def test_get_zoneinfo():
    # TODO
    pass


def test_get_leapsecs():
    # TODO
    pass


def test_parse_iana_leapsecs():
    # TODO
    pass


def test_parse_iana_zonenow():
    # TODO
    pass


def test_parse_iana_dst_transitions():
    # TODO
    pass


def main():
    test_offset()
    test_tzdst()
    test_zonedst()
    test_zoneinfomem32()
    test_zoneinfomem8()
    # test_zoneinfofile32()
    # test_zoneinfofile8()
    test_get_zoneinfo()
    test_get_leapsecs()
    test_parse_iana_leapsecs()
    test_parse_iana_zonenow()
    test_parse_iana_dst_transitions()
