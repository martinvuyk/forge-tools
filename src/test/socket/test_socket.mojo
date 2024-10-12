from testing import assert_equal, assert_false, assert_true, assert_almost_equal
from sys import is_big_endian
from bit import bit_reverse
from memory import UnsafePointer, stack_allocation
from utils import StringSlice, Span

from forge_tools.socket import Socket


def test_ntohs():
    value = UInt16(1 << 15)
    res = Socket.ntohs(value)

    @parameter
    if is_big_endian():
        assert_equal(value, res)
    else:
        assert_equal(1 << 7, res)


def test_ntohl():
    value = UInt32(1 << 31)
    res = Socket.ntohl(value)

    @parameter
    if is_big_endian():
        assert_equal(value, res)
    else:
        assert_equal(1 << 7, res)


def test_htons():
    value = UInt16(1 << 15)
    res = Socket.htons(value)

    @parameter
    if is_big_endian():
        assert_equal(value, res)
    else:
        assert_equal(1 << 7, res)


def test_htonl():
    value = UInt32(1 << 31)
    res = Socket.htonl(value)

    @parameter
    if is_big_endian():
        assert_equal(value, res)
    else:
        assert_equal(1 << 7, res)


def test_inet_aton():
    res = Socket.inet_aton(String("123.45.67.89"))
    assert_true(res)
    value: UInt32 = 0b01111011001011010100001101011001

    @parameter
    if not is_big_endian():
        b0 = value << 24
        b1 = (value << 8) & 0xFF_00_00
        b2 = (value >> 8) & 0xFF_00
        b3 = value >> 24
        value = b0 | b1 | b2 | b3
    assert_equal(value, res.value())


def test_inet_ntoa():
    value: UInt32 = 0b01111011001011010100001101011001

    @parameter
    if not is_big_endian():
        b0 = value << 24
        b1 = (value << 8) & 0xFF_00_00
        b2 = (value >> 8) & 0xFF_00
        b3 = value >> 24
        value = b0 | b1 | b2 | b3
    res = Socket.inet_ntoa(value)
    assert_equal(String("123.45.67.89"), res)


def test_server_sync_ipv4():
    socket = Socket()
    socket.bind(("0.0.0.0", 8001))
    socket.listen()


# def test_client_sync_ipv4():
#     socket = Socket()
#     await socket.connect(("0.0.0.0", 8000))
#     client_msg = String("123456789")
#     bytes_sent = await socket.send(client_msg.as_bytes_span())
#     _ = socket


def test_create_server_sync_ipv4():
    server = Socket.create_server(("0.0.0.0", 8002))
    _ = server


# def test_create_connection_sync_ipv4():
#     client = Socket.create_connection(("0.0.0.0", 8000))
#     _ = client

# async def test_client_server_ipv4():
#     server = Socket.create_server(("0.0.0.0", 8000))
#     client = Socket.create_connection(("0.0.0.0", 8000))

#     client_msg = String("123456789")
#     bytes_sent = client.send(client_msg.as_bytes_span())
#     conn = (await server.accept())[0]
#     assert_equal(9, await bytes_sent^)

#     alias Life = ImmutableAnyLifetime
#     server_ptr = UnsafePointer[UInt8](stack_allocation[10, UInt8]())
#     server_buf = Span[UInt8, Life](unsafe_ptr=server_ptr, len=10)
#     server_bytes_recv = await conn.recv(server_buf)
#     assert_equal(9, server_bytes_recv)
#     assert_equal(client_msg, String(ptr=server_ptr, len=10))

#     server_msg = String("987654321")
#     server_sent = await conn.send(server_msg.as_bytes_span())
#     assert_equal(9, server_sent)

#     client_ptr = UnsafePointer[UInt8](stack_allocation[10, UInt8]())
#     client_buf = Span[UInt8, Life](unsafe_ptr=client_ptr, len=10)
#     client_bytes_recv = await client.recv(client_buf)
#     assert_equal(9, client_bytes_recv)
#     assert_equal(server_msg, String(ptr=client_ptr, len=10))


def main():
    test_ntohs()
    test_ntohl()
    test_htons()
    test_htonl()
    test_inet_aton()
    test_inet_ntoa()
    test_server_sync_ipv4()
    # test_client_sync_ipv4()
    test_create_server_sync_ipv4()
    # test_create_connection_sync_ipv4()
    # await test_client_server_ipv4()
