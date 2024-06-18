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


fn test_offset() raises:
    var minutes = List[UInt8](0, 30, 45)
    for k in range(2):
        var sign = 1 if k == 0 else -1
        for j in range(3):
            for i in range(16):
                var of = Offset(i, minutes[j], sign)
                assert_equal(of.hour, i)
                assert_equal(of.minute, minutes[j])
                assert_equal(of.sign, sign)


fn test_tzdst() raises:
    # TODO
    pass


fn test_zonedst() raises:
    # TODO
    pass


fn test_zoneinfomem32() raises:
    var storage = ZoneInfoMem32()
    var tz0 = "tz0"
    var tz1 = "tz1"
    var tz2 = "tz2"
    var tz30 = "tz30"
    var tz45 = "tz45"
    var tz0_of = Offset(0, 0, 1)
    var tz1_of = Offset(1, 0, 1)
    var tz2_of = Offset(2, 0, 1)
    var tz30_of = Offset(0, 30, 1)
    var tz45_of = Offset(0, 45, 1)
    storage.add(tz0, ZoneDST(TzDT(), TzDT(), tz0_of))
    storage.add(tz1, ZoneDST(TzDT(), TzDT(), tz1_of))
    storage.add(tz2, ZoneDST(TzDT(), TzDT(), tz2_of))
    storage.add(tz30, ZoneDST(TzDT(), TzDT(), tz30_of))
    storage.add(tz45, ZoneDST(TzDT(), TzDT(), tz45_of))
    var tz0_read = storage.get(tz0).value().from_hash()[2]
    var tz1_read = storage.get(tz1).value().from_hash()[2]
    var tz2_read = storage.get(tz2).value().from_hash()[2]
    var tz30_read = storage.get(tz30).value().from_hash()[2]
    var tz45_read = storage.get(tz45).value().from_hash()[2]
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


fn test_zoneinfomem8() raises:
    var storage = ZoneInfoMem8()
    var tz0 = "tz0"
    var tz1 = "tz1"
    var tz2 = "tz2"
    var tz30 = "tz30"
    var tz45 = "tz45"
    var tz0_of = Offset(0, 0, 1)
    var tz1_of = Offset(1, 0, 1)
    var tz2_of = Offset(2, 0, 1)
    var tz30_of = Offset(0, 30, 1)
    var tz45_of = Offset(0, 45, 1)
    storage.add(tz0, tz0_of)
    storage.add(tz1, tz1_of)
    storage.add(tz2, tz2_of)
    storage.add(tz30, tz30_of)
    storage.add(tz45, tz45_of)
    var tz0_read = storage.get(tz0).value()
    var tz1_read = storage.get(tz1).value()
    var tz2_read = storage.get(tz2).value()
    var tz30_read = storage.get(tz30).value()
    var tz45_read = storage.get(tz45).value()
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
# fn test_zoneinfofile32() raises:
#     var storage = ZoneInfoFile32()
#     var tz0 = "tz0"
#     var tz1 = "tz1"
#     var tz2 = "tz2"
#     var tz30 = "tz30"
#     var tz45 = "tz45"
#     var tz0_of = Offset(0, 0, 1)
#     var tz1_of = Offset(1, 0, 1)
#     var tz2_of = Offset(2, 0, 1)
#     var tz30_of = Offset(0, 30, 1)
#     var tz45_of = Offset(0, 45, 1)
#     storage.add(tz0, ZoneDST(TzDT(), TzDT(), tz0_of))
#     storage.add(tz1, ZoneDST(TzDT(), TzDT(), tz1_of))
#     storage.add(tz2, ZoneDST(TzDT(), TzDT(), tz2_of))
#     storage.add(tz30, ZoneDST(TzDT(), TzDT(), tz30_of))
#     storage.add(tz45, ZoneDST(TzDT(), TzDT(), tz45_of))
#     var tz0_read = storage.get(tz0).value().from_hash()[2]
#     var tz1_read = storage.get(tz1).value().from_hash()[2]
#     var tz2_read = storage.get(tz2).value().from_hash()[2]
#     var tz30_read = storage.get(tz30).value().from_hash()[2]
#     var tz45_read = storage.get(tz45).value().from_hash()[2]
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
# fn test_zoneinfofile8() raises:
#     var storage = ZoneInfoFile8()
#     var tz0 = "tz0"
#     var tz1 = "tz1"
#     var tz2 = "tz2"
#     var tz30 = "tz30"
#     var tz45 = "tz45"
#     var tz0_of = Offset(0, 0, 1)
#     var tz1_of = Offset(1, 0, 1)
#     var tz2_of = Offset(2, 0, 1)
#     var tz30_of = Offset(0, 30, 1)
#     var tz45_of = Offset(0, 45, 1)
#     storage.add(tz0, tz0_of)
#     storage.add(tz1, tz1_of)
#     storage.add(tz2, tz2_of)
#     storage.add(tz30, tz30_of)
#     storage.add(tz45, tz45_of)
#     var tz0_read = storage.get(tz0).value()
#     var tz1_read = storage.get(tz1).value()
#     var tz2_read = storage.get(tz2).value()
#     var tz30_read = storage.get(tz30).value()
#     var tz45_read = storage.get(tz45).value()
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


fn test_get_zoneinfo() raises:
    # TODO
    pass


fn test_get_leapsecs() raises:
    # TODO
    pass


fn test_parse_iana_leapsecs() raises:
    # TODO
    pass


fn test_parse_iana_zonenow() raises:
    # TODO
    pass


fn test_parse_iana_dst_transitions() raises:
    # TODO
    pass


fn main() raises:
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
