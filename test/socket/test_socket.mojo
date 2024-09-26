from testing import assert_equal, assert_false, assert_true, assert_almost_equal
from sys import is_big_endian
from bit import bit_reverse

from forge_tools.socket import Socket


def test_ntohs():
    var value = UInt16(1 << 15)
    var res = Socket.ntohs(value)
    @parameter
    if is_big_endian():
        assert_equal(value, res)
    else:
        assert_equal(1 << 7, res)

def test_ntohl():
    var value = UInt32(1 << 31)
    var res = Socket.ntohl(value)
    @parameter
    if is_big_endian():
        assert_equal(value, res)
    else:
        assert_equal(1 << 7, res)

def test_htons():
    var value = UInt16(1 << 15)
    var res = Socket.htons(value)
    @parameter
    if is_big_endian():
        assert_equal(value, res)
    else:
        assert_equal(1 << 7, res)

def test_htonl():
    var value = UInt32(1 << 31)
    var res = Socket.htonl(value)
    @parameter
    if is_big_endian():
        assert_equal(value, res)
    else:
        assert_equal(1 << 7, res)

def test_inet_aton():
    var res = Socket.inet_aton(String("123.45.67.89"))
    assert_true(res)
    var value: UInt32 = 0b01111011001011010100001101011001

    @parameter
    if not is_big_endian():
        var b0 = (value << 24)
        var b1 = ((value << 8) & 0xFF_00_00)
        var b2 = ((value >> 8) & 0xFF_00)
        var b3 = (value >> 24)
        value = b0 | b1 | b2 | b3
    assert_equal(value, res.value())

def test_inet_ntoa():
    var value: UInt32 = 0b01111011001011010100001101011001

    @parameter
    if not is_big_endian():
        var b0 = (value << 24)
        var b1 = ((value << 8) & 0xFF_00_00)
        var b2 = ((value >> 8) & 0xFF_00)
        var b3 = (value >> 24)
        value = b0 | b1 | b2 | b3
    var res = Socket.inet_ntoa(value)
    assert_equal(String("123.45.67.89"), res)



def main():
    test_ntohs()
    test_ntohl()
    test_htons()
    test_htonl()
    test_inet_aton()
    test_inet_ntoa()