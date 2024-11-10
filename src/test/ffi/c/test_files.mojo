# RUN: %mojo %s


from testing import assert_equal, assert_false, assert_raises, assert_true

from pathlib import _dir_of_current_file
from time import sleep
from memory import UnsafePointer, memset, memcpy, memcmp
from random import random_ui64

from forge_tools.ffi.c.types import C, char_ptr, FILE
from forge_tools.ffi.c.libc import TryLibc, Libc
from forge_tools.ffi.c.constants import *


def _test_open_close(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_open_close" + suffix))
    ptr = char_ptr(file)
    with TryLibc(libc):
        filedes = libc.open(ptr, O_WRONLY | O_CREAT | O_TRUNC, 0o666)
        assert_true(filedes != -1)
        sleep(0.05)
        assert_true(libc.close(filedes) != -1)
        for s in List(O_RDONLY, O_WRONLY, O_RDWR):
            filedes = libc.open(ptr, s[])
            assert_true(filedes != -1)
            sleep(0.05)
            assert_true(libc.close(filedes) != -1)

        assert_true(libc.remove(ptr) != -1)
    _ = file^


def test_dynamic_open_close():
    _test_open_close(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_open_close():
    _test_open_close(Libc[static=True](), "_static")


def _test_fopen_fclose(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_fopen_fclose" + suffix))
    ptr = char_ptr(file)
    with TryLibc(libc):
        filedes = libc.creat(ptr, 0o666)
        assert_true(filedes != -1)
        for s in List(
            FM_WRITE,
            FM_WRITE_READ_CREATE,
            FM_READ,
            FM_READ_WRITE,
            FM_APPEND,
            FM_APPEND_READ,
        ):
            stream = libc.fopen(ptr, char_ptr(s[]))
            assert_true(stream != C.NULL.bitcast[FILE]())
            sleep(0.05)
            assert_true(libc.fclose(stream) != EOF)

        assert_true(libc.remove(ptr) != -1)
    _ = file^


def test_dynamic_fopen_fclose():
    _test_fopen_fclose(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_fopen_fclose():
    _test_fopen_fclose(Libc[static=True](), "_static")


def _test_fdopen_fclose(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_fdopen_fclose" + suffix))
    ptr = char_ptr(file)
    with TryLibc(libc):
        filedes = libc.creat(ptr, 0o666)
        assert_true(filedes != -1)
        for s in List(
            FM_WRITE,
            FM_WRITE_READ_CREATE,
            FM_READ,
            FM_READ_WRITE,
            FM_APPEND,
            FM_APPEND_READ,
        ):
            stream = libc.fdopen(filedes, char_ptr(s[]))
            assert_true(stream != C.NULL.bitcast[FILE]())
            sleep(0.05)
            assert_true(libc.fclose(stream) != EOF)
            filedes = libc.open(ptr, O_RDWR)
            assert_true(filedes != -1)

        assert_true(libc.remove(ptr) != -1)
    _ = file^


def test_dynamic_fdopen_fclose():
    _test_fdopen_fclose(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_fdopen_fclose():
    _test_fdopen_fclose(Libc[static=True](), "_static")


def _test_creat_openat(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_creat_openat" + suffix))
    ptr = char_ptr(file)
    with TryLibc(libc):
        filedes = libc.creat(ptr, 0o666)
        assert_true(filedes != -1)
        filedes = libc.openat(filedes, ptr, O_RDWR)
        assert_true(filedes != -1)
        sleep(0.05)
        assert_true(libc.close(filedes) != -1)
        assert_true(libc.remove(ptr) != -1)
    _ = file^


def test_dynamic_creat_openat():
    _test_creat_openat(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_creat_openat():
    _test_creat_openat(Libc[static=True](), "_static")


def _test_freopen(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_freopen" + suffix))
    ptr = char_ptr(file)
    with TryLibc(libc):
        filedes = libc.creat(ptr, 0o666)
        assert_true(filedes != -1)
        stream = libc.fopen(ptr, char_ptr(FM_READ_WRITE))
        assert_true(stream != C.NULL.bitcast[FILE]())
        sleep(0.05)
        stream = libc.freopen(ptr, char_ptr(FM_READ_WRITE), stream)
        assert_true(stream != C.NULL.bitcast[FILE]())
        sleep(0.05)
        assert_true(libc.close(filedes) != -1)
        assert_true(libc.remove(ptr) != -1)
    _ = file^


def test_dynamic_freopen():
    _test_freopen(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_freopen():
    _test_freopen(Libc[static=True](), "_static")


def _test_fmemopen_fprintf(libc: Libc, suffix: String):
    file = str(
        _dir_of_current_file() / ("dummy_test_fmemopen_fprintf" + suffix)
    )
    ptr = char_ptr(file)
    with TryLibc(libc):
        filedes = libc.creat(ptr, 0o666)
        assert_true(filedes != -1)

        # test print to file
        stream = libc.fopen(ptr, char_ptr(FM_WRITE))
        assert_true(stream != C.NULL.bitcast[FILE]())
        size = 1000
        a = UnsafePointer[Byte].alloc(size)
        memset(a, ord("a"), size - 1)
        a[size - 1] = 0
        num_bytes = libc.fprintf(stream, char_ptr(a))
        assert_equal(num_bytes, size - 1)
        assert_true(libc.fclose(stream) != EOF)

        # test print to buffer
        p = UnsafePointer[Byte].alloc(size)
        memset(p, 0, size)
        stream = libc.fmemopen(p.bitcast[C.void](), size, char_ptr(FM_WRITE))
        assert_true(stream != C.NULL.bitcast[FILE]())
        num_bytes = libc.fprintf(stream, char_ptr(a))
        assert_equal(num_bytes, size - 1)

        assert_true(libc.fclose(stream) != EOF)  # flush stream
        assert_true(libc.remove(ptr) != -1)
        assert_equal(0, memcmp(p, a, size - 1))  # compare buffer
        a.free()
        p.free()
    _ = file^


def test_dynamic_fmemopen_fprintf():
    _test_fmemopen_fprintf(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_fmemopen_fprintf():
    _test_fmemopen_fprintf(Libc[static=True](), "_static")


def _test_fseek_ftell(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_fseek_ftell" + suffix))
    ptr = char_ptr(file)
    with TryLibc(libc):
        filedes = libc.creat(ptr, 0o666)
        assert_true(filedes != -1)

        # print to file
        filedes = libc.open(ptr, O_RDWR)
        assert_true(filedes != -1)
        stream = libc.fdopen(filedes, char_ptr(FM_WRITE))
        assert_true(stream != C.NULL.bitcast[FILE]())
        size = 255
        a = UnsafePointer[Byte].alloc(size)
        for i in range(size - 1):
            a[i] = i + 1
        a[size - 1] = 0
        num_bytes = libc.fprintf(stream, char_ptr(a))
        assert_equal(num_bytes, size - 1)

        assert_true(libc.fflush(stream) != EOF)  # flush stream

        # test seek
        stream = libc.fopen(ptr, char_ptr(FM_WRITE))
        assert_true(stream != C.NULL.bitcast[FILE]())
        assert_equal(libc.fseek(stream, 10, SEEK_SET), 0)
        assert_equal(libc.ftell(stream), 10)
        assert_equal(libc.fseeko(stream, 10, SEEK_CUR), 0)
        assert_equal(libc.ftello(stream), 20)

        assert_true(libc.fclose(stream) != EOF)
        assert_true(libc.remove(ptr) != -1)
        a.free()
    _ = file^


def test_dynamic_fseek_ftell():
    _test_fseek_ftell(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_fseek_ftell():
    _test_fseek_ftell(Libc[static=True](), "_static")


def _test_fput_fget(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_fput_fget" + suffix))
    ptr = char_ptr(file)
    with TryLibc(libc):
        filedes = libc.creat(ptr, 0o666)
        assert_true(filedes != -1)

        # print to file
        filedes = libc.open(ptr, O_RDWR)
        assert_true(filedes != -1)
        stream = libc.fdopen(filedes, char_ptr(FM_READ_WRITE))
        assert_true(stream != C.NULL.bitcast[FILE]())
        size = 255
        for i in range(size - 1):
            assert_equal(libc.fputc(i + 1, stream), i + 1)

        assert_true(libc.fflush(stream) != EOF)  # flush stream
        stream = libc.fopen(ptr, char_ptr(FM_READ_WRITE))

        for i in range(size - 1):
            assert_equal(libc.fgetc(stream), i + 1)

        a = UnsafePointer[C.char].alloc(size)
        memset(a, ord("a"), size - 1)
        a[size - 1] = 0

        stream = libc.fopen(ptr, char_ptr(FM_READ_WRITE))
        assert_true(libc.fputs(a, stream) != EOF)
        assert_true(libc.fclose(stream) != EOF)

        stream = libc.fopen(ptr, char_ptr(FM_READ_WRITE))
        b = UnsafePointer[C.char].alloc(size)
        p = libc.fgets(b, size, stream)
        assert_equal(b, p)
        assert_true(libc.fflush(stream) != EOF)  # flush stream
        assert_equal(0, memcmp(p, a, size))

        assert_true(libc.fclose(stream) != EOF)
        assert_true(libc.remove(ptr) != -1)
        a.free()
        b.free()
    _ = file^


def test_dynamic_fput_fget():
    _test_fput_fget(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_fput_fget():
    _test_fput_fget(Libc[static=True](), "_static")


def _test_dprintf(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_dprintf" + suffix))


def test_dynamic_dprintf():
    _test_dprintf(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_dprintf():
    _test_dprintf(Libc[static=True](), "_static")


def _test_printf(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_printf" + suffix))


def test_dynamic_printf():
    _test_printf(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_printf():
    _test_printf(Libc[static=True](), "_static")


def _test_snprintf(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_snprintf" + suffix))


def test_dynamic_snprintf():
    _test_snprintf(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_snprintf():
    _test_snprintf(Libc[static=True](), "_static")


def _test_sprintf(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_sprintf" + suffix))


def test_dynamic_sprintf():
    _test_sprintf(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_sprintf():
    _test_sprintf(Libc[static=True](), "_static")


def _test_fscanf(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_fscanf" + suffix))


def test_dynamic_fscanf():
    _test_fscanf(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_fscanf():
    _test_fscanf(Libc[static=True](), "_static")


def _test_scanf(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_scanf" + suffix))


def test_dynamic_scanf():
    _test_scanf(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_scanf():
    _test_scanf(Libc[static=True](), "_static")


def _test_sscanf(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_sscanf" + suffix))


def test_dynamic_sscanf():
    _test_sscanf(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_sscanf():
    _test_sscanf(Libc[static=True](), "_static")


def _test_fread(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_fread" + suffix))


def test_dynamic_fread():
    _test_fread(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_fread():
    _test_fread(Libc[static=True](), "_static")


def _test_rewind(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_rewind" + suffix))


def test_dynamic_rewind():
    _test_rewind(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_rewind():
    _test_rewind(Libc[static=True](), "_static")


def _test_getline(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_getline" + suffix))


def test_dynamic_getline():
    _test_getline(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_getline():
    _test_getline(Libc[static=True](), "_static")


def _test_getdelim(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_getdelim" + suffix))


def test_dynamic_getdelim():
    _test_getdelim(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_getdelim():
    _test_getdelim(Libc[static=True](), "_static")


def _test_pread(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_pread" + suffix))


def test_dynamic_pread():
    _test_pread(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_pread():
    _test_pread(Libc[static=True](), "_static")


def _test_read(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_read" + suffix))


def test_dynamic_read():
    _test_read(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_read():
    _test_read(Libc[static=True](), "_static")


def _test_pwrite(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_pwrite" + suffix))


def test_dynamic_pwrite():
    _test_pwrite(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_pwrite():
    _test_pwrite(Libc[static=True](), "_static")


def _test_write(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_write" + suffix))


def test_dynamic_write():
    _test_write(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_write():
    _test_write(Libc[static=True](), "_static")


def _test_clearerr(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_clearerr" + suffix))


def test_dynamic_clearerr():
    _test_clearerr(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_clearerr():
    _test_clearerr(Libc[static=True](), "_static")


def _test_ferror(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_ferror" + suffix))


def test_dynamic_ferror():
    _test_ferror(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_ferror():
    _test_ferror(Libc[static=True](), "_static")


def _test_fcntl(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_fcntl" + suffix))
    ptr = char_ptr(file)
    with TryLibc(libc):
        filedes = libc.creat(ptr, 0o666)
        assert_true(filedes != -1)
        filedes = libc.fcntl(filedes, F_DUPFD)
        assert_true(filedes != -1)
        filedes = libc.openat(filedes, ptr, O_RDWR)
        assert_true(filedes != -1)
        sleep(0.05)
        assert_true(libc.close(filedes) != -1)
        assert_true(libc.remove(ptr) != -1)
    _ = file^


def test_dynamic_fcntl():
    _test_fcntl(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_fcntl():
    _test_fcntl(Libc[static=True](), "_static")


def _test_ioctl(libc: Libc, suffix: String):
    file = str(_dir_of_current_file() / ("dummy_test_ioctl" + suffix))


def test_dynamic_ioctl():
    _test_ioctl(Libc[static=False]("libc.so.6"), "_dynamic")


def test_static_ioctl():
    _test_ioctl(Libc[static=True](), "_static")


def main():
    test_static_open_close()
    test_dynamic_open_close()
    test_static_fopen_fclose()
    test_dynamic_fopen_fclose()
    test_static_fdopen_fclose()
    test_dynamic_fdopen_fclose()
    test_static_creat_openat()
    test_dynamic_creat_openat()
    test_static_freopen()
    test_dynamic_freopen()
    test_static_fmemopen_fprintf()
    test_dynamic_fmemopen_fprintf()
    test_static_fseek_ftell()
    test_dynamic_fseek_ftell()
    test_static_fput_fget()
    test_dynamic_fput_fget()
    test_static_dprintf()
    test_dynamic_dprintf()
    test_static_printf()
    test_dynamic_printf()
    test_static_printf()
    test_dynamic_printf()
    test_static_snprintf()
    test_dynamic_snprintf()
    test_static_sprintf()
    test_dynamic_sprintf()
    test_static_fscanf()
    test_dynamic_fscanf()
    test_static_scanf()
    test_dynamic_scanf()
    test_static_sscanf()
    test_dynamic_sscanf()
    test_static_fread()
    test_dynamic_fread()
    test_static_rewind()
    test_dynamic_rewind()
    test_static_getline()
    test_dynamic_getline()
    test_static_getdelim()
    test_dynamic_getdelim()
    test_static_pread()
    test_dynamic_pread()
    test_static_read()
    test_dynamic_read()
    test_static_pwrite()
    test_dynamic_pwrite()
    test_static_write()
    test_dynamic_write()
    test_static_clearerr()
    test_dynamic_clearerr()
    test_static_ferror()
    test_dynamic_ferror()
    test_static_fcntl()
    test_dynamic_fcntl()
    test_static_ioctl()
    test_dynamic_ioctl()
