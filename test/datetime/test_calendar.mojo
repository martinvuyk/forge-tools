# RUN: %mojo %s

from testing import assert_equal, assert_false, assert_raises, assert_true

from forge_tools.datetime.calendar import (
    CalendarHashes,
    Calendar,
    Gregorian,
    UTCFast,
    PythonCalendar,
    UTCCalendar,
)


fn test_default_calendar_hashes() raises:
    # TODO
    pass


fn test_gregorian_calendar_hashes() raises:
    # TODO
    pass


fn test_gregorian_calendar() raises:
    # TODO
    pass


fn test_utcfast_calendar() raises:
    # TODO
    pass


fn test_python_calendar() raises:
    # TODO
    pass


fn test_gregorian_utc_calendar() raises:
    # TODO
    pass


fn main() raises:
    test_default_calendar_hashes()
    test_gregorian_calendar_hashes()
    test_gregorian_calendar()
    test_utcfast_calendar()
    test_python_calendar()
    test_gregorian_utc_calendar()
