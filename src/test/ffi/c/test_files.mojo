# RUN: %mojo %s


from testing import assert_equal, assert_false, assert_raises, assert_true

from pathlib import _dir_of_current_file
from time import sleep

from forge_tools.ffi.c.files import *
from forge_tools.ffi.c.constants import *
from forge_tools.ffi.c.types import C, char_ptr, FILE
from forge_tools.ffi.c.logging import TryLibc


def test_open_close():
    file = str(_dir_of_current_file() / "dummy_test_open_close")
    ptr = char_ptr(file)
    with TryLibc():
        filedes = libc_open(ptr, O_WRONLY | O_CREAT | O_TRUNC, 744)
        assert_true(filedes != -1)
        sleep(0.05)
        assert_true(libc_close(filedes) != -1)
        filedes = libc_open(ptr, O_RDONLY)
        assert_true(filedes != -1)
        sleep(0.05)
        assert_true(libc_close(filedes) != -1)
        filedes = libc_open(ptr, O_WRONLY)
        assert_true(filedes != -1)
        sleep(0.05)
        assert_true(libc_close(filedes) != -1)
        filedes = libc_open(ptr, O_RDWR)
        assert_true(filedes != -1)
        sleep(0.05)
        assert_true(libc_close(filedes) != -1)

        assert_true(remove(ptr) != -1)
    _ = file^


def test_openat():
    ...


def test_fcntl():
    ...


def test_fopen_fclose():
    file = str(_dir_of_current_file() / "dummy_test_fopen_fclose")
    ptr = char_ptr(file)
    with TryLibc():
        filedes = creat(ptr, 744)
        assert_true(filedes != -1)
        for s in List(
            FM_WRITE,
            FM_WRITE_READ_CREATE,
            FM_READ,
            FM_READ_WRITE,
            FM_APPEND,
            FM_APPEND_READ,
        ):
            stream = fopen(ptr, char_ptr(s[]))
            assert_true(stream != C.NULL.bitcast[FILE]())
            sleep(0.05)
            assert_true(fclose(stream) != EOF)
            filedes = libc_open(ptr, O_RDONLY)
            assert_true(filedes != -1)

        assert_true(remove(ptr) != -1)
    _ = file^


def test_fdopen_fclose():
    file = str(_dir_of_current_file() / "dummy_test_fdopen_fclose")
    ptr = char_ptr(file)
    with TryLibc():
        filedes = creat(ptr, 744)
        assert_true(filedes != -1)
        for s in List(
            FM_WRITE,
            FM_WRITE_READ_CREATE,
            FM_READ,
            FM_READ_WRITE,
            FM_APPEND,
            FM_APPEND_READ,
        ):
            stream = fdopen(filedes, char_ptr(s[]))
            assert_true(stream != C.NULL.bitcast[FILE]())
            sleep(0.05)
            assert_true(fclose(stream) != EOF)
            filedes = libc_open(ptr, O_RDONLY)
            assert_true(filedes != -1)

        assert_true(remove(ptr) != -1)
    _ = file^


def test_freopen():
    ...


def test_fmemopen():
    ...


def test_creat():
    ...


def test_fseek():
    ...


def test_fseeko():
    ...


def test_lseek():
    ...


def test_fputc():
    ...


def test_fputs():
    ...


def test_fgetc():
    ...


def test_fgets():
    ...


def test_dprintf():
    ...


def test_fprintf():
    ...


def test_printf():
    ...


def test_snprintf():
    ...


def test_sprintf():
    ...


def test_fscanf():
    ...


def test_scanf():
    ...


def test_sscanf():
    ...


def test_fread():
    ...


def test_rewind():
    ...


def test_getline():
    ...


def test_getdelim():
    ...


def test_pread():
    ...


def test_read():
    ...


def test_pwrite():
    ...


def test_write():
    ...


def test_ftell():
    ...


def test_ftello():
    ...


def test_fflush():
    ...


def test_clearerr():
    ...


def test_feof():
    ...


def test_ferror():
    ...


def test_ioctl():
    ...


def main():
    test_open_close()
    test_fopen_fclose()
    test_fdopen_fclose()
    test_fcntl()
    test_openat()
    test_freopen()
    test_fmemopen()
    test_creat()
    test_fseek()
    test_fseeko()
    test_lseek()
    test_fputc()
    test_fputs()
    test_fgetc()
    test_fgets()
    test_dprintf()
    test_fprintf()
    test_printf()
    test_printf()
    test_snprintf()
    test_sprintf()
    test_fscanf()
    test_scanf()
    test_sscanf()
    test_fread()
    test_rewind()
    test_getline()
    test_getdelim()
    test_pread()
    test_read()
    test_pwrite()
    test_write()
    test_ftell()
    test_ftello()
    test_fflush()
    test_clearerr()
    test_feof()
    test_ferror()
    test_ioctl()
