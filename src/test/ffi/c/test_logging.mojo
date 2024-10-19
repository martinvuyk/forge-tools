# RUN: %mojo %s

from testing import assert_equal, assert_false, assert_raises, assert_true
from forge_tools.ffi.c.logging import *


def test_get_errno():
    ...


def test_set_errno():
    ...


def test_strerror():
    ...


def test_perror():
    ...


def test_openlog():
    ...


def test_syslog():
    ...


def test_setlogmask():
    ...


def test_closelog():
    ...


def main():
    test_get_errno()
    test_set_errno()
    test_strerror()
    test_perror()
    test_openlog()
    test_syslog()
    test_setlogmask()
    test_closelog()
