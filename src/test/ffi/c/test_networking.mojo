# RUN: %mojo %s

from testing import assert_equal, assert_false, assert_raises, assert_true
from forge_tools.ffi.c.networking import *


def test_htonl():
    ...


def test_htons():
    ...


def test_ntohl():
    ...


def test_ntohs():
    ...


def test_inet_ntop():
    ...


def test_inet_pton():
    ...


def test_inet_addr():
    ...


def test_inet_aton():
    ...


def test_inet_ntoa():
    ...


def test_socket():
    ...


def test_socketpair():
    ...


def test_setsockopt():
    ...


def test_bind():
    ...


def test_listen():
    ...


def test_accept():
    ...


def test_connect():
    ...


def test_recv():
    ...


def test_recvfrom():
    ...


def test_send():
    ...


def test_sendto():
    ...


def test_shutdown():
    ...


def test_getaddrinfo():
    ...


def test_gai_strerror():
    ...


def main():
    test_htonl()
    test_htons()
    test_ntohl()
    test_ntohs()
    test_inet_ntop()
    test_inet_pton()
    test_inet_addr()
    test_inet_aton()
    test_inet_ntoa()
    test_socket()
    test_socketpair()
    test_setsockopt()
    test_bind()
    test_listen()
    test_accept()
    test_connect()
    test_recv()
    test_recvfrom()
    test_send()
    test_sendto()
    test_shutdown()
    test_getaddrinfo()
    test_gai_strerror()
