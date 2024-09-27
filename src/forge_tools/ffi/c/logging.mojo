"""Libc POSIX logging syscalls."""

from sys.ffi import external_call
from memory import UnsafePointer
from .types import *


fn openlog(ident: UnsafePointer[C.char], logopt: C.int, facility: C.int):
    """Libc POSIX `openlog` function.

    Args:
        ident: A File Descriptor to open the file with.
        logopt: An offset to seek to.
        facility: Arguments for the format string.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/closelog.3p.html).
        Fn signature: `void openlog(const char *ident, int logopt,
            int facility)`.
    """
    _ = external_call["openlog", C.void, UnsafePointer[C.char], C.int, C.int](
        ident, logopt, facility
    )


# FIXME: this should take in  *args: *T
fn syslog(priority: C.int, message: UnsafePointer[C.char]):
    """Libc POSIX `syslog` function.

    Args:
        priority: A File Descriptor to open the file with.
        message: An offset to seek to.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/closelog.3p.html).
        Fn signature: `void syslog(int priority, const char *message,
            ... /* arguments */)`.
    """
    _ = external_call["syslog", C.void, C.int, UnsafePointer[C.char]](
        priority, message
    )


fn setlogmask(maskpri: C.int) -> C.int:
    """Libc POSIX `setlogmask` function.

    Args:
        maskpri: A File Descriptor to open the file with.

    Returns:
        The previous log priority mask.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/closelog.3p.html).
        Fn signature: ` int setlogmask(int maskpri)`.
    """
    return external_call["setlogmask", C.int, C.int](maskpri)


fn closelog():
    """Libc POSIX `closelog` function.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/closelog.3p.html).
        Fn signature: `void closelog(void)`.
    """
    _ = external_call["closelog", C.void]()
