from testing import assert_equal, assert_false, assert_true, assert_almost_equal
from sys import is_big_endian
from bit import bit_reverse
from memory import UnsafePointer, stack_allocation
from utils import StringSlice, Span

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


async def test_server_client_ipv4():
    var server = Socket.create_server(("0.0.0.0", 8000))
    var client = Socket.create_connection(("0.0.0.0", 8000))

    var client_msg = String("123456789")
    var bytes_sent = client.send(client_msg.as_bytes_span())

    var conn = (await server.accept())[0]
    assert_equal(10, await bytes_sent^)
    var server_msg = String("987654321")
    var server_ptr = UnsafePointer[UInt8](stack_allocation[10, UInt8]())

    alias Life = ImmutableAnyLifetime
    var server_buf = Span[UInt8, Life](unsafe_ptr=server_ptr, len=10)
    var server_bytes_recv = await conn.recv(server_buf)
    assert_equal(10, server_bytes_recv)

    alias S = StringSlice[Life]
    assert_equal(String(S(unsafe_from_utf8=server_buf)), client_msg)
    var server_sent = await conn.send(server_msg.as_bytes_span())
    assert_equal(10, server_sent)

    var client_ptr = UnsafePointer[UInt8](stack_allocation[10, UInt8]())
    var client_buf = Span[UInt8, Life](unsafe_ptr=client_ptr, len=10)
    var client_bytes_recv = await client.recv(client_buf)
    assert_equal(10, client_bytes_recv)
    assert_equal(String(S(unsafe_from_utf8=client_buf)), server_msg)
    server_ptr.free()
    client_ptr.free()


async def main():
    test_ntohs()
    test_ntohl()
    test_htons()
    test_htonl()
    test_inet_aton()
    test_inet_ntoa()
    await test_server_client_ipv4()
