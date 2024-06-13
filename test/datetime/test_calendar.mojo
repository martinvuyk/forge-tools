# ===----------------------------------------------------------------------=== #
# Copyright (c) 2024, Modular Inc. All rights reserved.
#
# Licensed under the Apache License v2.0 with LLVM Exceptions:
# https://llvm.org/LICENSE.txt
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ===----------------------------------------------------------------------=== #
# RUN: %mojo -debug-level full %s
from testing import assert_equal, assert_false, assert_raises, assert_true

from datetime.calendar import (
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
