from testing import assert_equal, assert_false, assert_true, assert_almost_equal
from sys import is_big_endian

from forge_tools.socket import Socket


def test_ntohs():
    var value = UInt16(1 << 16)
    var res = Socket.ntohs(value)
    @parameter
    if is_big_endian():
        assert_equal(value, res)
    else:
        assert_equal(1, res)

def test_ntohl():
    var value = UInt32(1 << 32)
    var res = Socket.ntohl(value)
    @parameter
    if is_big_endian():
        assert_equal(value, res)
    else:
        assert_equal(1, res)

def test_htons():
    var value = UInt16(1 << 16)
    var res = Socket.htons(value)
    @parameter
    if is_big_endian():
        assert_equal(value, res)
    else:
        assert_equal(1, res)

def test_htonl():
    var value = UInt32(1 << 32)
    var res = Socket.htonl(value)
    @parameter
    if is_big_endian():
        assert_equal(value, res)
    else:
        assert_equal(1, res)

def test_inet_aton():
    var res = Socket.inet_aton()
    assert_equal(0, res)

def test_inet_ntoa():
    var res = Socket.inet_ntoa()
    assert_equal(0, res)



def main():
    test_ntohs()
    test_ntohl()
    test_htons()
    test_htonl()
    test_inet_aton()
    test_inet_ntoa()