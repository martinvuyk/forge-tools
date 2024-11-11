"""FFI utils for the C programming language.

Notes:
    The functions in this module follow only the Libc POSIX standard. Exceptions
    are made only for Windows.
"""


from .constants import *
from .types import *
from .libc import Libc, TryLibc
