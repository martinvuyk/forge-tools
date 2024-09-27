"""FFI utils for the C programming language.

Notes:
    The functions in this module follow only the Libc POSIX standard.
"""


# Adapted from https://github.com/crisadamo/mojo-Libc which doesn't currently
# (2024-07-22) have a licence, so I'll assume MIT licence.
# Huge thanks for the work done.

from .constants import *
from .files import *
from .logging import *
from .networking import *
from .types import *
