# RUN: %mojo %s

from testing import assert_equal, assert_false, assert_raises, assert_true
from forge_tools.ffi.c.libc import Libc, TryLibc
from forge_tools.ffi.c.types import C, char_ptr
from forge_tools.ffi.c.constants import *


def _test_htonl(libc: Libc):
    ...


def test_dynamic_htonl():
    ...


def test_static_htonl():
    ...


def _test_htons(libc: Libc):
    ...


def test_dynamic_htons():
    ...


def test_static_htons():
    ...


def _test_ntohl(libc: Libc):
    ...


def test_dynamic_ntohl():
    ...


def test_static_ntohl():
    ...


def _test_ntohs(libc: Libc):
    ...


def test_dynamic_ntohs():
    ...


def test_static_ntohs():
    ...


def _test_inet_ntop(libc: Libc):
    ...


def test_dynamic_inet_ntop():
    ...


def test_static_inet_ntop():
    ...


def _test_inet_pton(libc: Libc):
    ...


def test_dynamic_inet_pton():
    ...


def test_static_inet_pton():
    ...


def _test_inet_addr(libc: Libc):
    ...


def test_dynamic_inet_addr():
    ...


def test_static_inet_addr():
    ...


def _test_inet_aton(libc: Libc):
    ...


def test_dynamic_inet_aton():
    ...


def test_static_inet_aton():
    ...


def _test_inet_ntoa(libc: Libc):
    ...


def test_dynamic_inet_ntoa():
    ...


def test_static_inet_ntoa():
    ...


def _test_socket(libc: Libc):
    ...


def test_dynamic_socket():
    ...


def test_static_socket():
    ...


def _test_socketpair(libc: Libc):
    ...


def test_dynamic_socketpair():
    ...


def test_static_socketpair():
    ...


def _test_setsockopt(libc: Libc):
    ...


def test_dynamic_setsockopt():
    ...


def test_static_setsockopt():
    ...


def _test_bind(libc: Libc):
    ...


def test_dynamic_bind():
    ...


def test_static_bind():
    ...


def _test_listen(libc: Libc):
    ...


def test_dynamic_listen():
    ...


def test_static_listen():
    ...


def _test_accept(libc: Libc):
    ...


def test_dynamic_accept():
    ...


def test_static_accept():
    ...


def _test_connect(libc: Libc):
    ...


def test_dynamic_connect():
    ...


def test_static_connect():
    ...


def _test_recv(libc: Libc):
    ...


def test_dynamic_recv():
    ...


def test_static_recv():
    ...


def _test_recvfrom(libc: Libc):
    ...


def test_dynamic_recvfrom():
    ...


def test_static_recvfrom():
    ...


def _test_send(libc: Libc):
    ...


def test_dynamic_send():
    ...


def test_static_send():
    ...


def _test_sendto(libc: Libc):
    ...


def test_dynamic_sendto():
    ...


def test_static_sendto():
    ...


def _test_shutdown(libc: Libc):
    ...


def test_dynamic_shutdown():
    ...


def test_static_shutdown():
    ...


def _test_getaddrinfo(libc: Libc):
    ...


def test_dynamic_getaddrinfo():
    ...


def test_static_getaddrinfo():
    ...


def _test_gai_strerror(libc: Libc):
    ...


def test_dynamic_gai_strerror():
    ...


def test_static_gai_strerror():
    ...


def main():
    test_dynamic_htonl()
    test_static_htonl()
    test_dynamic_htons()
    test_static_htons()
    test_dynamic_ntohl()
    test_static_ntohl()
    test_dynamic_ntohs()
    test_static_ntohs()
    test_dynamic_inet_ntop()
    test_static_inet_ntop()
    test_dynamic_inet_pton()
    test_static_inet_pton()
    test_dynamic_inet_addr()
    test_static_inet_addr()
    test_dynamic_inet_aton()
    test_static_inet_aton()
    test_dynamic_inet_ntoa()
    test_static_inet_ntoa()
    test_dynamic_socket()
    test_static_socket()
    test_dynamic_socketpair()
    test_static_socketpair()
    test_dynamic_setsockopt()
    test_static_setsockopt()
    test_dynamic_bind()
    test_static_bind()
    test_dynamic_listen()
    test_static_listen()
    test_dynamic_accept()
    test_static_accept()
    test_dynamic_connect()
    test_static_connect()
    test_dynamic_recv()
    test_static_recv()
    test_dynamic_recvfrom()
    test_static_recvfrom()
    test_dynamic_send()
    test_static_send()
    test_dynamic_sendto()
    test_static_sendto()
    test_dynamic_shutdown()
    test_static_shutdown()
    test_dynamic_getaddrinfo()
    test_static_getaddrinfo()
    test_dynamic_gai_strerror()
    test_static_gai_strerror()
