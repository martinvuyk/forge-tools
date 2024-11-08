# RUN: %mojo %s

from testing import assert_equal, assert_false, assert_raises, assert_true

from memory import UnsafePointer, stack_allocation
from forge_tools.ffi.jvm.logging import *
from forge_tools.ffi.jvm.types import *


def main():
    ...
