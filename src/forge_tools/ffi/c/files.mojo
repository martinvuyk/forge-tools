"""Libc POSIX file syscalls."""

from sys.ffi import external_call
from sys.info import os_is_windows
from memory import UnsafePointer
from .types import *


# FIXME: this should take in  *args: *T
fn fcntl(fildes: C.int, cmd: C.int) -> C.int:
    """Libc POSIX `fcntl` function.

    Args:
        fildes: A File Descriptor to close.
        cmd: A command to execute.

    Returns:
        Value 0 on success, -1 on error and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/close.3p.html).
        Fn signature: `int fcntl(int fildes, int cmd, ...)`.
    """
    return external_call["fcntl", C.int, C.int, C.int](fildes, cmd)


fn close(fildes: C.int) -> C.int:
    """Libc POSIX `close` function.

    Args:
        fildes: A File Descriptor to close.

    Returns:
        Value 0 on success, -1 on error and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/close.3p.html).
        Fn signature: `int close(int fildes)`.
    """
    return external_call["close", C.int, C.int](fildes)


# FIXME: this should take in  *args: *T
fn open(path: UnsafePointer[C.char], oflag: C.int) -> C.int:
    """Libc POSIX `open` function.

    Args:
        path: A path to a file.
        oflag: A flag to open the file with.

    Returns:
        A File Descriptor. Otherwise -1 and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/open.3p.html).
        Fn signature: `int open(const char *path, int oflag, ...)`.
    """
    return external_call["open", C.int, UnsafePointer[C.char], C.int](
        path, oflag
    )


# FIXME: this should take in  *args: *T
fn openat(fd: C.int, path: UnsafePointer[C.char], oflag: C.int) -> C.int:
    """Libc POSIX `open` function.

    Args:
        fd: A File Descriptor to open the file with.
        path: A path to a file.
        oflag: A flag to open the file with.

    Returns:
        A File Descriptor. Otherwise -1 and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/open.3p.html).
        Fn signature: `int openat(int fd, const char *path, int oflag, ...)`.
    """
    return external_call["openat", C.int, C.int, UnsafePointer[C.char], C.int](
        fd, path, oflag
    )


fn fopen(
    pathname: UnsafePointer[C.char], mode: UnsafePointer[C.char]
) -> UnsafePointer[FILE]:
    """Libc POSIX `fopen` function.

    Args:
        pathname: A path to a file.
        mode: A mode to open the file with.

    Returns:
        A pointer to a File Descriptor. Otherwise `NULL` and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fopen.3p.html).
        Fn signature: `FILE *fopen(const char *restrict pathname,
            const char *restrict mode)`.
    """
    return external_call[
        "fopen",
        UnsafePointer[FILE],
        UnsafePointer[C.char],
        UnsafePointer[C.char],
    ](pathname, mode)


fn fdopen(fildes: C.int, mode: UnsafePointer[C.char]) -> UnsafePointer[FILE]:
    """Libc POSIX `fdopen` function.

    Args:
        fildes: A File Descriptor to open the file with.
        mode: A mode to open the file with.

    Returns:
        A pointer to a File Descriptor. Otherwise `NULL` and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fdopen.3p.html).
        Fn signature: `FILE *fdopen(int fildes, const char *mode)`.
    """
    alias name = "_fdopen" if os_is_windows() else "fdopen"
    return external_call[
        name, UnsafePointer[FILE], C.int, UnsafePointer[C.char]
    ](fildes, mode)


fn freopen(
    pathname: UnsafePointer[C.char],
    mode: UnsafePointer[C.char],
    stream: UnsafePointer[FILE],
) -> UnsafePointer[FILE]:
    """Libc POSIX `freopen` function.

    Args:
        pathname: A path to a file.
        mode: A mode to open the file with.
        stream: A pointer to a stream.

    Returns:
        A pointer to a File Descriptor. Otherwise `NULL` and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/freopen.3p.html).
        Fn signature: `FILE *freopen(const char *restrict pathname,
            const char *restrict mode, FILE *restrict stream)`.
    """
    return external_call[
        "freopen",
        UnsafePointer[FILE],
        UnsafePointer[C.char],
        UnsafePointer[C.char],
        UnsafePointer[FILE],
    ](pathname, mode, stream)


fn fmemopen(
    buf: UnsafePointer[C.void], size: C.u_int, mode: UnsafePointer[C.char]
) -> UnsafePointer[FILE]:
    """Libc POSIX `fmemopen` function.

    Args:
        buf: A pointer to a buffer.
        size: The size of the buffer.
        mode: A mode to open the file with.

    Returns:
        A pointer to a File Descriptor. Otherwise `NULL` and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fmemopen.3p.html).
        Fn signature: `FILE *fmemopen(void *restrict buf, size_t size,
            const char *restrict mode)`.
    """
    return external_call[
        "fmemopen",
        UnsafePointer[FILE],
        UnsafePointer[C.void],
        C.u_int,
        UnsafePointer[C.char],
    ](buf, size, mode)


fn creat(path: UnsafePointer[C.char], mode: mode_t) -> C.int:
    """Libc POSIX `creat` function.

    Args:
        path: A path to a file.
        mode: A mode to open the file with.

    Returns:
        A File Descriptor. Otherwise -1 and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/creat.3p.html).
        Fn signature: `int creat(const char *path, mode_t mode)`.
    """
    return external_call["creat", C.int, UnsafePointer[C.char], mode_t](
        path, mode
    )


fn fseek(stream: UnsafePointer[FILE], offset: C.long, whence: C.int) -> C.int:
    """Libc POSIX `fseek` function.

    Args:
        stream: A pointer to a stream.
        offset: An offset to seek to.
        whence: A pointer to a buffer to store the length of the address of the
            accepted socket.

    Returns:
        Value 0 on success, -1 on error and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fseek.3p.html).
        Fn signature: `int fseek(FILE *stream, long offset, int whence)`.
    """
    return external_call["fseek", C.int, UnsafePointer[FILE], C.long, C.int](
        stream, offset, whence
    )


fn fseeko(stream: UnsafePointer[FILE], offset: off_t, whence: C.int) -> C.int:
    """Libc POSIX `fseeko` function.

    Args:
        stream: A pointer to a stream.
        offset: An offset to seek to.
        whence: A pointer to a buffer to store the length of the address of the
            accepted socket.

    Returns:
        Value 0 on success, -1 on error and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fseek.3p.html).
        Fn signature: `int fseeko(FILE *stream, off_t offset, int whence)`.
    """
    return external_call["fseeko", C.int, UnsafePointer[FILE], off_t, C.int](
        stream, offset, whence
    )


fn lseek(fildes: C.int, offset: off_t, whence: C.int) -> off_t:
    """Libc POSIX `lseek` function.

    Args:
        fildes: A File Descriptor to open the file with.
        offset: An offset to seek to.
        whence: A pointer to a buffer to store the length of the address of the
            accepted socket.

    Returns:
        The resulting offset, as measured in bytes from the beginning of the
        file on success, -1 on error and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/lseek.3p.html).
        Fn signature: `off_t lseek(int fildes, off_t offset, int whence)`.
    """
    return external_call["lseek", off_t, C.int, off_t, C.int](
        fildes, offset, whence
    )


fn fputc(c: C.int, stream: UnsafePointer[FILE]) -> C.int:
    """Libc POSIX `fputc` function.

    Args:
        c: A character to write.
        stream: A pointer to a stream.

    Returns:
        The value it has written. Otherwise `EOF` (usually -1) and `errno` is
        set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fputc.3p.html).
        Fn signature: `int fputc(int c, FILE *stream)`.
    """
    return external_call["fputc", C.int, C.int, UnsafePointer[FILE]](c, stream)


fn fputs(s: UnsafePointer[C.char], stream: UnsafePointer[FILE]) -> C.int:
    """Libc POSIX `fputs` function.

    Args:
        s: A string to write.
        stream: A pointer to a stream.

    Returns:
        The value it has written. Otherwise `EOF` (usually -1) and `errno` is
        set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fputs.3p.html).
        Fn signature: `int fputs(const char *restrict s, FILE *restrict stream
        )`.
    """
    return external_call[
        "fputs", C.int, UnsafePointer[C.char], UnsafePointer[FILE]
    ](s, stream)


fn fgetc(stream: UnsafePointer[FILE]) -> C.int:
    """Libc POSIX `fgetc` function.

    Args:
        stream: A pointer to a stream.

    Returns:
        The next byte from the input stream pointed to by stream. If the
        end-of-file indicator for the stream is set, or if the stream is at
        end-of-file, the end-of-file indicator for the stream shall be set and
        `fgetc()` shall return EOF. If a read error occurs, the error indicator
        for the stream shall be set, fgetc() shall return EOF, and shall set
        `errno` to indicate the error.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fgetc.3p.html).
        Fn signature: `int fgetc(FILE *stream)`.
    """
    return external_call["fgets", C.int, UnsafePointer[FILE]](stream)


fn fgets(
    s: UnsafePointer[C.char], n: C.int, stream: UnsafePointer[FILE]
) -> UnsafePointer[C.char]:
    """Libc POSIX `fgets` function.

    Args:
        s: A pointer to a buffer to store the read string.
        n: The maximum number of characters to read.
        stream: A pointer to a stream.

    Returns:
        Upon successful completion, fgets() shall return s. If the stream is at
        end-of-file, the end-of-file indicator for the stream shall be set and
        `fgets()` shall return a null pointer. If a read error occurs, the error
        indicator for the stream shall be set, `fgets()` shall return a null
        pointer, and shall set `errno` to indicate the error.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fgets.3p.html).
        Fn signature: `char *fgets(char *restrict s, int n,
            FILE *restrict stream)`.
    """
    return external_call[
        "fgets",
        UnsafePointer[C.char],
        UnsafePointer[C.char],
        C.int,
        UnsafePointer[FILE],
    ](s, n, stream)


# FIXME: this should take in  *args: *T
fn dprintf(fildes: C.int, format: UnsafePointer[C.char]) -> C.int:
    """Libc POSIX `dprintf` function.

    Args:
        fildes: A File Descriptor to open the file with.
        format: A format string.

    Returns:
        The number of bytes transmitted. Otherwise a negative value and `errno`
        is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fprintf.3p.html).
        Fn signature: `int dprintf(int fildes,
            const char *restrict format, ...)`.
    """
    return external_call["dprintf", C.int, C.int, UnsafePointer[C.char]](
        fildes, format
    )


# FIXME: this should take in  *args: *T
fn fprintf(stream: UnsafePointer[FILE], format: UnsafePointer[C.char]) -> C.int:
    """Libc POSIX `fprintf` function.

    Args:
        stream: A pointer to a stream.
        format: A format string.

    Returns:
        The number of bytes transmitted. Otherwise a negative value and `errno`
        is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fprintf.3p.html).
        Fn signature: `int fprintf(FILE *restrict stream,
            const char *restrict format, ...)`.
    """
    return external_call[
        "fprintf", C.int, UnsafePointer[FILE], UnsafePointer[C.char]
    ](stream, format)


# FIXME: this should take in  *args: *T
# @always_inline
# fn printf[
#     *T: AnyType
# ](format: UnsafePointer[C.char], *args: *T) -> C.int:
#     """Libc POSIX `printf` function.

#     Args:
#         format: The format string.
#         args: The args to send to the `printf` function.

#     Returns:
#        The number of bytes transmitted. Otherwise a negative value and `errno`
#        is set.

#     Notes:
#         [Reference](https://man7.org/linux/man-pages/man3/printf.3.html).
#     """
#     return external_call["printf", C.int, UnsafePointer[C.char], *T](format, *args)

# FIXME: this should take in  *args: *T
# @always_inline
# fn printf[*T: AnyType](format: String, *args: *T) -> C.int:
#     """Libc POSIX `printf` function.

#     Args:
#         format: The format string.
#         args: The args to send to the `printf` function.

#     Returns:
#        The number of bytes transmitted. Otherwise a negative value and `errno`
#        is set.

#     Notes:
#         [Reference](https://man7.org/linux/man-pages/man3/printf.3.html).
#     """
#     return printf(format.unsafe_ptr().bitcast[C.char](), args)


# printf's family function(s) this is used to implement the rest of the printf's family
fn _printf[callee: StringLiteral](format: UnsafePointer[C.char]) -> C.int:
    return external_call[callee, C.int, UnsafePointer[C.char]](format)


fn _printf[
    callee: StringLiteral, T0: AnyType
](format: UnsafePointer[C.char], arg0: T0) -> C.int:
    return external_call[callee, C.int, UnsafePointer[C.char], T0](format, arg0)


fn _printf[
    callee: StringLiteral, T0: AnyType, T1: AnyType
](format: UnsafePointer[C.char], arg0: T0, arg1: T1) -> C.int:
    return external_call[callee, C.int, UnsafePointer[C.char], T0, T1](
        format, arg0, arg1
    )


fn _printf[
    callee: StringLiteral, T0: AnyType, T1: AnyType, T2: AnyType
](format: UnsafePointer[C.char], arg0: T0, arg1: T1, arg2: T2) -> C.int:
    return external_call[callee, C.int, UnsafePointer[C.char], T0, T1, T2](
        format, arg0, arg1, arg2
    )


fn _printf[
    callee: StringLiteral, T0: AnyType, T1: AnyType, T2: AnyType, T3: AnyType
](
    format: UnsafePointer[C.char], arg0: T0, arg1: T1, arg2: T2, arg3: T3
) -> C.int:
    return external_call[callee, C.int, UnsafePointer[C.char], T0, T1, T2, T3](
        format, arg0, arg1, arg2, arg3
    )


fn _printf[
    callee: StringLiteral,
    T0: AnyTrivialRegType,
    T1: AnyTrivialRegType,
    T2: AnyTrivialRegType,
    T3: AnyTrivialRegType,
    T4: AnyTrivialRegType,
](
    format: UnsafePointer[C.char],
    arg0: T0,
    arg1: T1,
    arg2: T2,
    arg3: T3,
    arg4: T4,
) -> C.int:
    return external_call[
        callee, C.int, UnsafePointer[C.char], T0, T1, T2, T3, T4
    ](format, arg0, arg1, arg2, arg3, arg4)


fn _printf[
    callee: StringLiteral,
    T0: AnyTrivialRegType,
    T1: AnyTrivialRegType,
    T2: AnyTrivialRegType,
    T3: AnyTrivialRegType,
    T4: AnyTrivialRegType,
    T5: AnyTrivialRegType,
](
    format: UnsafePointer[C.char],
    arg0: T0,
    arg1: T1,
    arg2: T2,
    arg3: T3,
    arg4: T4,
    arg5: T5,
) -> C.int:
    return external_call[
        callee, C.int, UnsafePointer[C.char], T0, T1, T2, T3, T4, T5
    ](format, arg0, arg1, arg2, arg3, arg4, arg5)


fn _printf[callee: StringLiteral](format: String) -> C.int:
    return _printf[callee](format.unsafe_ptr().bitcast[C.char]())


fn _printf[
    callee: StringLiteral, T0: AnyType
](format: String, arg0: T0) -> C.int:
    return _printf[callee, T0](format.unsafe_ptr().bitcast[C.char](), arg0)


fn _printf[
    callee: StringLiteral, T0: AnyType, T1: AnyType
](format: String, arg0: T0, arg1: T1) -> C.int:
    return _printf[callee, T0, T1](
        format.unsafe_ptr().bitcast[C.char](), arg0, arg1
    )


fn _printf[
    callee: StringLiteral, T0: AnyType, T1: AnyType, T2: AnyType
](format: String, arg0: T0, arg1: T1, arg2: T2) -> C.int:
    return _printf[callee, T0, T1, T2](
        format.unsafe_ptr().bitcast[C.char](), arg0, arg1, arg2
    )


fn _printf[
    callee: StringLiteral, T0: AnyType, T1: AnyType, T2: AnyType, T3: AnyType
](format: String, arg0: T0, arg1: T1, arg2: T2, arg3: T3) -> C.int:
    return _printf[callee, T0, T1, T2, T3](
        format.unsafe_ptr().bitcast[C.char](), arg0, arg1, arg2, arg3
    )


fn _printf[
    callee: StringLiteral,
    T0: AnyTrivialRegType,
    T1: AnyTrivialRegType,
    T2: AnyTrivialRegType,
    T3: AnyTrivialRegType,
    T4: AnyTrivialRegType,
](format: String, arg0: T0, arg1: T1, arg2: T2, arg3: T3, arg4: T4) -> C.int:
    return _printf[callee, T0, T1, T2, T3, T4](
        format.unsafe_ptr().bitcast[C.char](), arg0, arg1, arg2, arg3, arg4
    )


fn _printf[
    callee: StringLiteral,
    T0: AnyTrivialRegType,
    T1: AnyTrivialRegType,
    T2: AnyTrivialRegType,
    T3: AnyTrivialRegType,
    T4: AnyTrivialRegType,
    T5: AnyTrivialRegType,
](
    format: String, arg0: T0, arg1: T1, arg2: T2, arg3: T3, arg4: T4, arg5: T5
) -> C.int:
    return _printf[callee, T0, T1, T2, T3, T4, T5](
        format.unsafe_ptr().bitcast[C.char](),
        arg0,
        arg1,
        arg2,
        arg3,
        arg4,
        arg5,
    )


fn printf(format: UnsafePointer[C.char]) -> C.int:
    return _printf["printf"](format)


fn printf[T0: AnyType](format: UnsafePointer[C.char], arg0: T0) -> C.int:
    return _printf["printf", T0](format, arg0)


fn printf[
    T0: AnyType, T1: AnyType
](format: UnsafePointer[C.char], arg0: T0, arg1: T1) -> C.int:
    return _printf["printf", T0, T1](format, arg0, arg1)


fn printf[
    T0: AnyType, T1: AnyType, T2: AnyType
](format: UnsafePointer[C.char], arg0: T0, arg1: T1, arg2: T2) -> C.int:
    return _printf["printf", T0, T1, T2](format, arg0, arg1, arg2)


fn printf[
    T0: AnyType, T1: AnyType, T2: AnyType, T3: AnyType
](
    format: UnsafePointer[C.char], arg0: T0, arg1: T1, arg2: T2, arg3: T3
) -> C.int:
    return _printf["printf", T0, T1, T2, T3](format, arg0, arg1, arg2, arg3)


fn printf[
    T0: AnyTrivialRegType,
    T1: AnyTrivialRegType,
    T2: AnyTrivialRegType,
    T3: AnyTrivialRegType,
    T4: AnyTrivialRegType,
](
    format: UnsafePointer[C.char],
    arg0: T0,
    arg1: T1,
    arg2: T2,
    arg3: T3,
    arg4: T4,
) -> C.int:
    return _printf["printf", T0, T1, T2, T3, T4](
        format, arg0, arg1, arg2, arg3, arg4
    )


fn printf[
    T0: AnyTrivialRegType,
    T1: AnyTrivialRegType,
    T2: AnyTrivialRegType,
    T3: AnyTrivialRegType,
    T4: AnyTrivialRegType,
    T5: AnyTrivialRegType,
](
    format: UnsafePointer[C.char],
    arg0: T0,
    arg1: T1,
    arg2: T2,
    arg3: T3,
    arg4: T4,
    arg5: T5,
) -> C.int:
    return _printf["printf", T0, T1, T2, T3, T4, T5](
        format, arg0, arg1, arg2, arg3, arg4, arg5
    )


fn printf(format: String) -> C.int:
    return _printf["printf"](format)


fn printf[T0: AnyType](format: String, arg0: T0) -> C.int:
    return _printf["printf", T0](format, arg0)


fn printf[
    T0: AnyType, T1: AnyType
](format: String, arg0: T0, arg1: T1) -> C.int:
    return _printf["printf", T0, T1](format, arg0, arg1)


fn printf[
    T0: AnyType, T1: AnyType, T2: AnyType
](format: String, arg0: T0, arg1: T1, arg2: T2) -> C.int:
    return _printf["printf", T0, T1, T2](format, arg0, arg1, arg2)


fn printf[
    T0: AnyType, T1: AnyType, T2: AnyType, T3: AnyType
](format: String, arg0: T0, arg1: T1, arg2: T2, arg3: T3) -> C.int:
    return _printf["printf", T0, T1, T2, T3](format, arg0, arg1, arg2, arg3)


fn printf[
    T0: AnyTrivialRegType,
    T1: AnyTrivialRegType,
    T2: AnyTrivialRegType,
    T3: AnyTrivialRegType,
    T4: AnyTrivialRegType,
](format: String, arg0: T0, arg1: T1, arg2: T2, arg3: T3, arg4: T4) -> C.int:
    return _printf["printf", T0, T1, T2, T3, T4](
        format, arg0, arg1, arg2, arg3, arg4
    )


fn printf[
    T0: AnyTrivialRegType,
    T1: AnyTrivialRegType,
    T2: AnyTrivialRegType,
    T3: AnyTrivialRegType,
    T4: AnyTrivialRegType,
    T5: AnyTrivialRegType,
](
    format: String, arg0: T0, arg1: T1, arg2: T2, arg3: T3, arg4: T4, arg5: T5
) -> C.int:
    return _printf["printf", T0, T1, T2, T3, T4, T5](
        format, arg0, arg1, arg2, arg3, arg4, arg5
    )


# FIXME: this should take in  *args: *T
fn snprintf(
    s: UnsafePointer[C.char],
    n: C.u_int,
    format: UnsafePointer[C.char],
) -> C.int:
    """Libc POSIX `snprintf` function.

    Args:
        s: A pointer to a buffer to store the read string.
        n: The maximum number of characters to read.
        format: A format string.

    Returns:
        The number of bytes that would be written to s had n been sufficiently
        large excluding the terminating null byte.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fprintf.3p.html).
        Fn signature: ``int snprintf(char *restrict s, size_t n,`.
            const char *restrict format, ...)`.
    """
    return external_call[
        "snprintf", C.int, UnsafePointer[C.char], C.u_int, UnsafePointer[C.char]
    ](s, n, format)


# FIXME: this should take in  *args: *T
fn sprintf(s: UnsafePointer[C.char], format: UnsafePointer[C.char]) -> C.int:
    """Libc POSIX `sprintf` function.

    Args:
        s: A pointer to a buffer to store the read string.
        format: A format string.

    Returns:
        The number of bytes written to s, excluding the terminating null byte.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fprintf.3p.html).
        Fn signature: ``int sprintf(char *restrict s,`.
            const char *restrict format, ...)`.
    """
    return external_call[
        "sprintf", C.int, UnsafePointer[C.char], UnsafePointer[C.char]
    ](s, format)


# FIXME: this should take in  *args: *T
fn fscanf(stream: UnsafePointer[FILE], format: UnsafePointer[C.char]) -> C.int:
    """Libc POSIX `fscanf` function.

    Args:
        stream: A pointer to a stream.
        format: A format string.

    Returns:
        The number of successfully matched and assigned input items; this number
        can be zero in the event of an early matching failure. If the input ends
        before the first conversion (if any) has completed, and without a
        matching failure having occurred, `EOF` shall be returned. If an error
        occurs before the first conversion (if any) has completed, and without a
        matching failure having occurred, `EOF` shall be returned and `errno`
        shall be set to indicate the error. If a read error occurs, the error
        indicator for the stream shall be set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fscanf.3p.html).
        Fn signature: ``int fscanf(FILE *restrict stream,`.
            const char *restrict format, ...)`.
    """
    return external_call[
        "fscanf", C.int, UnsafePointer[FILE], UnsafePointer[C.char]
    ](stream, format)


# FIXME: this should take in  *args: *T
fn scanf(format: UnsafePointer[C.char]) -> C.int:
    """Libc POSIX `scanf` function.

    Args:
        format: A format string.

    Returns:
        The number of successfully matched and assigned input items; this number
        can be zero in the event of an early matching failure. If the input ends
        before the first conversion (if any) has completed, and without a
        matching failure having occurred, `EOF` shall be returned. If an error
        occurs before the first conversion (if any) has completed, and without a
        matching failure having occurred, `EOF` shall be returned and `errno`
        shall be set to indicate the error. If a read error occurs, the error
        indicator for the stream shall be set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fscanf.3p.html).
        Fn signature: ``int scanf(const char *restrict format, ...)`.`.
    """
    return external_call["scanf", C.int, UnsafePointer[C.char]](format)


fn sscanf(s: UnsafePointer[C.char], format: UnsafePointer[C.char]) -> C.int:
    """Libc POSIX `sscanf` function.

    Args:
        s: A pointer to a buffer to store the read string.
        format: A format string.

    Returns:
        The number of successfully matched and assigned input items; this number
        can be zero in the event of an early matching failure. If the input ends
        before the first conversion (if any) has completed, and without a
        matching failure having occurred, `EOF` shall be returned. If an error
        occurs before the first conversion (if any) has completed, and without a
        matching failure having occurred, `EOF` shall be returned and `errno`
        shall be set to indicate the error. If a read error occurs, the error
        indicator for the stream shall be set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fscanf.3p.html).
        Fn signature: ``int sscanf(const char *restrict s,`.
            const char *restrict format, ...)`.
    """
    return external_call[
        "sscanf", C.int, UnsafePointer[C.char], UnsafePointer[C.char]
    ](s, format)


fn fread(
    ptr: UnsafePointer[C.void],
    size: C.u_int,
    nitems: C.u_int,
    stream: UnsafePointer[FILE],
) -> C.u_int:
    """Libc POSIX `fread` function.

    Args:
        ptr: A pointer to a buffer to store the read string.
        size: The size of the buffer.
        nitems: The number of items to read.
        stream: A pointer to a stream.

    Returns:
        The number of elements successfully read which is less than nitems only
        if a read error or end-of-file is encountered. If size or nitems is 0,
        `fread()` shall return 0 and the contents of the array and the state of
        the stream remain unchanged. Otherwise, if a read error occurs, the
        error indicator for the stream shall be set, and `errno` shall be set to
        indicate the error.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fread.3p.html).
        Fn signature: `size_t fread(void *restrict ptr, size_t size,
            size_t nitems, FILE *restrict stream)`.
    """
    return external_call[
        "fread",
        C.u_int,
        UnsafePointer[C.void],
        C.u_int,
        C.u_int,
        UnsafePointer[FILE],
    ](ptr, size, nitems, stream)


fn rewind(stream: UnsafePointer[FILE]):
    """Libc POSIX `rewind` function.

    Args:
        stream: A pointer to a stream.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/rewind.3p.html).
        Fn signature: `void rewind(FILE *stream)`.
    """
    _ = external_call["rewind", C.void, UnsafePointer[FILE]](stream)


fn getline(
    lineptr: UnsafePointer[UnsafePointer[FILE]],
    n: UnsafePointer[C.u_int],
    stream: UnsafePointer[FILE],
) -> C.u_int:
    """Libc POSIX `getline` function.

    Args:
        lineptr: A pointer to a pointer to a buffer to store the read string.
        n: The length in bytes of the buffer.
        stream: A pointer to a stream.

    Returns:
        The number of bytes written into the buffer, including the delimiter
        character if one was encountered before EOF, but excluding the
        terminating NUL character. If the end-of-file indicator for the stream
        is set, or if no characters were read and the stream is at end-of-file,
        the end-of-file indicator for the stream shall be set and the function
        shall return -1.  If an error occurs, the error indicator for the stream
        shall be set, and the function shall return -1 and set `errno` to
        indicate the error.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/getline.3p.html).
        Fn signature: `ssize_t getline(char **restrict lineptr,
            size_t *restrict n, FILE *restrict stream);`.
    """
    return external_call[
        "getline",
        C.u_int,
        UnsafePointer[UnsafePointer[FILE]],
        UnsafePointer[C.u_int],
        UnsafePointer[FILE],
    ](lineptr, n, stream)


fn getdelim(
    lineptr: UnsafePointer[UnsafePointer[FILE]],
    n: UnsafePointer[C.u_int],
    stream: UnsafePointer[FILE],
) -> C.u_int:
    """Libc POSIX `getdelim` function.

    Args:
        lineptr: A pointer to a pointer to a buffer to store the read string.
        n: The length in bytes of the buffer.
        stream: A pointer to a stream.

    Returns:
        The number of bytes written into the buffer, including the delimiter
        character if one was encountered before EOF, but excluding the
        terminating NUL character. If the end-of-file indicator for the stream
        is set, or if no characters were read and the stream is at end-of-file,
        the end-of-file indicator for the stream shall be set and the function
        shall return -1.  If an error occurs, the error indicator for the stream
        shall be set, and the function shall return -1 and set `errno` to
        indicate the error.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/getdelim.3p.html).
        Fn signature: `ssize_t getdelim(char **restrict lineptr,
            size_t *restrict n, FILE *restrict stream);`.
    """
    return external_call[
        "getdelim",
        C.u_int,
        UnsafePointer[UnsafePointer[FILE]],
        UnsafePointer[C.u_int],
        UnsafePointer[FILE],
    ](lineptr, n, stream)


fn pread(
    fildes: C.int, buf: UnsafePointer[C.void], nbyte: C.u_int, offset: off_t
) -> C.u_int:
    """Libc POSIX `pread` function.

    Args:
        fildes: A File Descriptor to open the file with.
        buf: A pointer to a buffer to store the read string.
        nbyte: The maximum number of characters to read.
        offset: An offset to seek to.

    Returns:
        The number of bytes read. Otherwise -1 and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/read.3p.html).
        Fn signature: `ssize_t pread(int fildes, void *buf, size_t nbyte,
            off_t offset)`.
    """
    return external_call[
        "pread", C.u_int, C.int, UnsafePointer[C.void], C.u_int, off_t
    ](fildes, buf, nbyte, offset)


fn read(fildes: C.int, buf: UnsafePointer[C.void], nbyte: C.u_int) -> C.u_int:
    """Libc POSIX `read` function.

    Args:
        fildes: A File Descriptor to open the file with.
        buf: A pointer to a buffer to store the read string.
        nbyte: The maximum number of characters to read.

    Returns:
        The number of bytes read. Otherwise -1 and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/read.3p.html).
        Fn signature: `sssize_t read(int fildes, void *buf, size_t nbyte)`.
    """
    return external_call[
        "read", C.u_int, C.int, UnsafePointer[C.void], C.u_int
    ](fildes, buf, nbyte)


fn pwrite(
    fildes: C.int, buf: UnsafePointer[C.void], nbyte: C.u_int, offset: off_t
) -> C.u_int:
    """Libc POSIX `pwrite` function.

    Args:
        fildes: A File Descriptor to open the file with.
        buf: A pointer to a buffer to store the read string.
        nbyte: The maximum number of characters to read.
        offset: An offset to seek to.

    Returns:
        The number of bytes written. Otherwise -1 and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/write.3p.html).
        Fn signature: `ssize_t pwrite(int fildes, const void *buf, size_t nbyte,
            off_t offset)`.
    """
    return external_call[
        "pwrite", C.u_int, C.int, UnsafePointer[C.void], C.u_int, off_t
    ](fildes, buf, nbyte, offset)


fn write(fildes: C.int, buf: UnsafePointer[C.void], nbyte: C.u_int) -> C.u_int:
    """Libc POSIX `write` function.

    Args:
        fildes: A File Descriptor to open the file with.
        buf: A pointer to a buffer to store the read string.
        nbyte: The maximum number of characters to read.

    Returns:
        The number of bytes written. Otherwise -1 and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/write.3p.html).
        Fn signature: `ssize_t write(int fildes, const void *buf,
            size_t nbyte)`.
    """
    return external_call[
        "write", C.u_int, C.int, UnsafePointer[C.void], C.u_int
    ](fildes, buf, nbyte)


fn fclose(stream: UnsafePointer[FILE]) -> C.int:
    """Libc POSIX `fclose` function.

    Args:
        stream: A pointer to a stream.

    Returns:
       Value 0 on success, `EOF` (usually -1) and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fclose.3p.html).
        Fn signature: `int fclose(FILE *stream)`.
    """
    return external_call["fclose", C.int, UnsafePointer[FILE]](stream)


fn ftell(stream: UnsafePointer[FILE]) -> C.long:
    """Libc POSIX `ftell` function.

    Args:
        stream: A pointer to a stream.

    Returns:
        The byte offset form the start. Otherwise -1 and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/ftell.3p.html).
        Fn signature: `long ftell(FILE *stream)`.
    """
    return external_call["ftell", C.long, UnsafePointer[FILE]](stream)


fn ftello(stream: UnsafePointer[FILE]) -> off_t:
    """Libc POSIX `ftello` function.

    Args:
        stream: A pointer to a stream.

    Returns:
        The byte offset form the start. Otherwise -1 and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/ftell.3p.html).
        Fn signature: `off_t ftello(FILE *stream)`.
    """
    return external_call["ftello", off_t, UnsafePointer[FILE]](stream)


fn fflush(stream: UnsafePointer[FILE]) -> C.int:
    """Libc POSIX `fflush` function.

    Args:
        stream

    Returns:
        Value 0 on success, otherwise `EOF` (usually -1) and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fflush.3p.html).
        Fn signature: `int fflush(FILE *stream)`.
    """
    return external_call["fflush", C.int, UnsafePointer[FILE]](stream)


fn clearerr(stream: UnsafePointer[FILE]):
    """Libc POSIX `feof` function.

    Args:
        stream: A pointer to a stream.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/clearerr.3p.html).
        Fn signature: `void clearerr(FILE *stream)`.
    """
    _ = external_call["clearerr", C.void, UnsafePointer[FILE]](stream)


fn feof(stream: UnsafePointer[FILE]) -> C.int:
    """Libc POSIX `feof` function.

    Args:
        stream: A pointer to a stream.

    Returns:
        A non-zero value if the end-of-file indicator associated with the stream
        is set, else 0.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/feof.3p.html).
        Fn signature: `int feof(FILE *stream)`.
    """
    return external_call["feof", C.int, UnsafePointer[FILE]](stream)


fn ferror(stream: UnsafePointer[FILE]) -> C.int:
    """Libc POSIX `ferror` function.

    Args:
        stream: A pointer to a stream.

    Returns:
        A non-zero value if the error indicator associated with the stream is
        set, else 0.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/ferror.3p.html).
        Fn signature: `int ferror(FILE *stream)`.
    """
    return external_call["ferror", C.int, UnsafePointer[FILE]](stream)


# FIXME: this should take in  *args: *T
fn ioctl(fildes: C.int, request: C.int) -> C.int:
    """Libc POSIX `ioctl` function.

    Args:
        fildes: A File Descriptor to open the file with.
        request: An offset to seek to.

    Returns:
        Upon successful completion, `ioctl()` shall return a value other than
        -1 that depends upon the STREAMS device control function. Otherwise, it
        shall return -1 and set `errno` to indicate the error.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/ioctl.3p.html).
        Fn signature: `int ioctl(int fildes, int request, ... /* arg */)`.
    """
    return external_call["ioctl", C.int, C.int, C.int](fildes, request)
