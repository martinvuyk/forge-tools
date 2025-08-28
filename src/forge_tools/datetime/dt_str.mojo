# ===----------------------------------------------------------------------=== #
# Copyright (c) 2024, Martin Vuyk Loperena
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
"""`DateTime` and `Date` String parsing module."""

from os import abort
from .timezone import (
    TimeZone,
    ZoneInfo,
    ZoneInfoMem32,
    ZoneInfoMem8,
    ZoneStorageDST,
    ZoneStorageNoDST,
)


@fieldwise_init
@register_passable("trivial")
struct IsoFormat:
    """Available formats to parse from and to
    [ISO 8601](https://es.wikipedia.org/wiki/ISO_8601)."""

    alias TZD_REGEX = "+|-[0-9]{2}:?[0-9]{2}"
    alias YYYYMMDD = IsoFormat("%4Y%m%d")
    """e.g. `19700101`"""
    alias YYYY_MM_DD = IsoFormat("%4Y-%m-%d")
    """e.g. `1970-01-01`"""
    alias HHMMSS = IsoFormat("%H%M%S")
    """e.g. `000000`"""
    alias HH_MM_SS = IsoFormat("%H:%M:%S")
    """e.g. `00:00:00`"""
    alias YYYYMMDDHHMMSS = IsoFormat("%4Y%m%d%H%M%S")
    """e.g. `19700101000000`"""
    alias YYYYMMDDHHMMSSTZD = IsoFormat("%4Y%m%d%H%M%S%z")
    """e.g. `19700101000000+0000`"""
    alias YYYY_MM_DD___HH_MM_SS = IsoFormat("%4Y-%m-%d %H:%M:%S")
    """e.g. `1970-01-01 00:00:00`"""
    alias YYYY_MM_DD_T_HH_MM_SS = IsoFormat("%4Y-%m-%dT%H:%M:%S")
    """e.g. `1970-01-01T00:00:00`"""
    alias YYYY_MM_DD_T_HH_MM_SS_TZD = IsoFormat("%4Y-%m-%dT%H:%M:%S%z")
    """e.g. `1970-01-01T00:00:00+00:00`"""
    var fmt_str: StaticString
    """The selected IsoFormat."""

    # @implicit
    # fn __init__(
    #     out self,
    #     selected: StaticString = Self.YYYY_MM_DD_T_HH_MM_SS_TZD.fmt_str,
    # ):
    #     """Construct an IsoFormat with selected fmt string.

    #     Args:
    #         selected: The selected IsoFormat.
    #     """
    #     debug_assert(self.byte_length() > 0, "`IsoFormat` not implemented")
    #     self.selected = selected

    fn byte_length(self) -> UInt:
        """Get the byte length of the selected `IsoFormat`.

        Returns:
            The selected `IsoFormat`'s byte length.
        """

        if self.fmt_str == self.YYYYMMDD.fmt_str:
            return "YYYYMMDD".byte_length()
        elif self.fmt_str == self.YYYY_MM_DD.fmt_str:
            return "YYYY_MM_DD".byte_length()
        elif self.fmt_str == self.HHMMSS.fmt_str:
            return "HHMMSS".byte_length()
        elif self.fmt_str == self.HH_MM_SS.fmt_str:
            return "HH_MM_SS".byte_length()
        elif self.fmt_str == self.YYYYMMDDHHMMSS.fmt_str:
            return "YYYYMMDDHHMMSS".byte_length()
        elif self.fmt_str == self.YYYYMMDDHHMMSSTZD.fmt_str:
            return "YYYYMMDDHHMMSSTZD".byte_length()
        elif self.fmt_str == self.YYYY_MM_DD___HH_MM_SS.fmt_str:
            return "YYYY_MM_DD___HH_MM_SS".byte_length()
        elif self.fmt_str == self.YYYY_MM_DD_T_HH_MM_SS.fmt_str:
            return "YYYY_MM_DD_T_HH_MM_SS".byte_length()
        elif self.fmt_str == self.YYYY_MM_DD_T_HH_MM_SS_TZD.fmt_str:
            return "YYYY_MM_DD_T_HH_MM_SS_TZD".byte_length()
        else:
            return 0


@always_inline
fn _get_strings(
    year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int
) -> (String, String, String, String, String, String):
    if year < 1000:
        var prefix: StaticString = "0"
        if year < 100:
            prefix = "00"
            if year < 10:
                prefix = "000"
        yyyy = String(prefix, year)
    else:
        yyyy = String(min(year, 9999))

    mm = String(min(month, 99)) if month > 9 else String("0", month)
    dd = String(min(day, 99)) if day > 9 else String("0", day)
    hh = String(min(hour, 99)) if hour > 9 else String("0", hour)
    m_str = String(min(minute, 99)) if minute > 9 else String("0", minute)
    ss = String(min(second, 99)) if second > 9 else String("0", second)
    return yyyy^, mm^, dd^, hh^, m_str^, ss^


alias _IntCopyable = Intable & Copyable & Movable


fn to_iso[
    W: Writer, //,
    iso: IsoFormat = IsoFormat.YYYY_MM_DD_T_HH_MM_SS_TZD,
    T1: _IntCopyable = Int,
    T2: _IntCopyable = Int,
    T3: _IntCopyable = Int,
    T4: _IntCopyable = Int,
    T5: _IntCopyable = Int,
    T6: _IntCopyable = Int,
](
    mut writer: W,
    year: T1,
    month: T2,
    day: T3,
    hour: T4,
    minute: T5,
    second: T6,
    tzd: String = "+00:00",
):
    """Build an [ISO 8601](https://es.wikipedia.org/wiki/ISO_8601) compliant
    `String`.

    Parameters:
        W: The writer type.
        iso: The chosen IsoFormat.
        T1: A Type that is `Intable & Copyable & Movable`.
        T2: A Type that is `Intable & Copyable & Movable`.
        T3: A Type that is `Intable & Copyable & Movable`.
        T4: A Type that is `Intable & Copyable & Movable`.
        T5: A Type that is `Intable & Copyable & Movable`.
        T6: A Type that is `Intable & Copyable & Movable`.

    Args:
        writer: The writer to write to.
        year: Year.
        month: Month.
        day: Day.
        hour: Hour.
        minute: Minute.
        second: Second.
        tzd: Time Zone designation String (full format i.e. `+00:00`).
    """

    ref (yyyy, mm, dd, HH, MM, SS) = _get_strings(
        Int(year), Int(month), Int(day), Int(hour), Int(minute), Int(second)
    )

    @parameter
    if iso.fmt_str == iso.YYYY_MM_DD_T_HH_MM_SS.fmt_str:
        writer.write(yyyy, "-", mm, "-", dd, "T", HH, ":", MM, ":", SS)
    elif iso.fmt_str == iso.YYYY_MM_DD_T_HH_MM_SS_TZD.fmt_str:
        writer.write(yyyy, "-", mm, "-", dd, "T", HH, ":", MM, ":", SS, tzd)
    elif iso.fmt_str == iso.YYYY_MM_DD___HH_MM_SS.fmt_str:
        writer.write(yyyy, "-", mm, "-", dd, " ", HH, ":", MM, ":", SS)
    elif iso.fmt_str == iso.YYYYMMDDHHMMSS.fmt_str:
        writer.write(yyyy, mm, dd, HH, MM, SS)
    elif iso.fmt_str == iso.YYYYMMDDHHMMSSTZD.fmt_str:
        writer.write(yyyy, mm, dd, HH, MM, SS, tzd[:3], tzd[-2:])
    elif iso.fmt_str == iso.YYYYMMDD.fmt_str:
        writer.write(yyyy, mm, dd)
    elif iso.fmt_str == iso.HHMMSS.fmt_str:
        writer.write(HH, MM, SS)
    elif iso.fmt_str == iso.YYYY_MM_DD.fmt_str:
        writer.write(yyyy, "-", mm, "-", dd)
    elif iso.fmt_str == iso.HH_MM_SS.fmt_str:
        writer.write(HH, ":", MM, ":", SS)
    else:
        constrained[False, "that IsoFormat is not yet supported"]()


fn from_iso[
    iso: IsoFormat = IsoFormat.YYYY_MM_DD_T_HH_MM_SS_TZD,
    dst_storage: ZoneStorageDST = ZoneInfoMem32,
    no_dst_storage: ZoneStorageNoDST = ZoneInfoMem8,
    iana: Bool = True,
    pyzoneinfo: Bool = True,
    native: Bool = False,
](s: String) raises -> (
    UInt16,
    UInt8,
    UInt8,
    UInt8,
    UInt8,
    UInt8,
    TimeZone[dst_storage, no_dst_storage, iana, pyzoneinfo, native],
):
    """Parses a string expecting given format.

    Parameters:
        iso: The chosen IsoFormat.
        dst_storage: The type of storage to use for ZoneInfo
            for zones with Dailight Saving Time. Default Memory.
        no_dst_storage: The type of storage to use for ZoneInfo
            for zones with no Dailight Saving Time. Default Memory.
        iana: Whether timezones from the [IANA database](
            http://www.iana.org/time-zones/repository/tz-link.html)
            are used. It defaults to using all available timezones,
            if getting them fails at compile time, it tries using
            python's zoneinfo if pyzoneinfo is set to True, otherwise
            it uses the offsets as is, no daylight saving or
            special exceptions. [List of TZ identifiers](
            https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
        pyzoneinfo: Whether to use python's zoneinfo and
            datetime to get full IANA support.
        native: (fast, partial IANA support) Whether to use a native Dict
            with the current timezones from the [List of TZ identifiers](
            https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
            at the time of compilation (for now they're hardcoded
            at stdlib release time, in the future it should get them
            from the OS). If it fails at compile time, it defaults to
            using the given offsets when the timezone was constructed.

    Args:
        s: The string.

    Returns:
        A tuple with the result.
    """
    alias tz = TimeZone[dst_storage, no_dst_storage, iana, pyzoneinfo, native]
    num0 = UInt8(0)
    result = UInt16(0), num0, num0, num0, num0, num0, tz()

    @parameter
    if iso.YYYYMMDD.fmt_str in iso.fmt_str:
        result[0] = atol(s[:4])
        result[1] = atol(s[4:6])

        @parameter
        if iso.fmt_str == iso.YYYYMMDD.fmt_str:
            return result^
        result[2] = atol(s[6:8])
        result[3] = atol(s[8:10])
        result[4] = atol(s[10:12])
        result[5] = atol(s[12:14])
    elif iso.YYYY_MM_DD.fmt_str in iso.fmt_str:
        result[0] = atol(s[:4])
        result[1] = atol(s[5:7])

        @parameter
        if iso.fmt_str == iso.YYYY_MM_DD.fmt_str:
            return result^
        result[2] = atol(s[8:10])
        result[3] = atol(s[11:13])
        result[4] = atol(s[14:16])
        result[5] = atol(s[17:19])
    elif iso.fmt_str == iso.HH_MM_SS.fmt_str:
        result[3] = atol(s[:2])
        result[4] = atol(s[3:5])
        result[5] = atol(s[6:8])
    elif iso.fmt_str == iso.HHMMSS.fmt_str:
        result[3] = atol(s[:2])
        result[4] = atol(s[2:4])
        result[5] = atol(s[4:6])

    @parameter
    if iso.fmt_str == iso.YYYY_MM_DD_T_HH_MM_SS_TZD.fmt_str:
        sign = 1
        if s[19] == "-":
            sign = -1
        h = atol(s[20:22])
        m: Int
        if s[22] == ":":
            m = atol(s[23:25])
        else:
            m = atol(s[22:24])
        result[6] = tz.from_offset(result[0], result[1], result[2], h, m, sign)
    elif iso.fmt_str == iso.YYYYMMDDHHMMSSTZD.fmt_str:
        sign = 1
        if s[14] == "-":
            sign = -1
        h = atol(s[15:17])
        m: Int
        if s[17] == ":":
            m = atol(s[18:20])
        else:
            m = atol(s[17:19])
        result[6] = tz.from_offset(result[0], result[1], result[2], h, m, sign)

    return result^


@fieldwise_init
struct _DateTime(Copyable, Movable):
    var year: UInt16
    var month: UInt8
    var day: UInt8
    var hour: UInt8
    var minute: UInt8
    var second: UInt8
    var m_second: UInt16
    var u_second: UInt16
    var n_second: UInt16


fn strptime(s: String, format_str: StaticString) -> Optional[_DateTime]:
    """Parses time from a `String`.

    Args:
        s: The string.
        format_str: The chosen format.

    Returns:
        An Optional tuple with the result.
    """

    # TODO: native
    try:
        from python import Python

        dt = Python.import_module("datetime")
        date = dt.datetime.strptime(s, format_str)
        return _DateTime(
            UInt16(Int(date.year)),
            UInt8(Int(date.month)),
            UInt8(Int(date.day)),
            UInt8(Int(date.hour)),
            UInt8(Int(date.minute)),
            UInt8(Int(date.second)),
            UInt16(Int(date.microsecond) // 1000),
            UInt16(Int(date.microsecond) % 1000),
            UInt16(0),
        )
    except:
        pass
    return None


fn strftime[
    T1: _IntCopyable = Int,
    T2: _IntCopyable = Int,
    T3: _IntCopyable = Int,
    T4: _IntCopyable = Int,
    T5: _IntCopyable = Int,
    T6: _IntCopyable = Int,
    T7: _IntCopyable = Int,
    T8: _IntCopyable = Int,
](
    format_str: String,
    year: T1,
    month: T2,
    day: T3,
    hour: T4,
    minute: T5,
    second: T6,
    m_second: T7,
    u_second: T8,
) -> String:
    """Formats time into a `String`.

    Args:
        format_str: Format_str.
        year: Year.
        month: Month.
        day: Day.
        hour: Hour.
        minute: Minute.
        second: Second.
        m_second: Milisecond.
        u_second: Microsecond.

    Returns:
        String.
    """

    # TODO: native
    # TODO: localization
    try:
        from python import Python

        dt = Python.import_module("datetime")
        date = dt.datetime(
            Int(year),
            Int(month),
            Int(day),
            Int(hour),
            Int(minute),
            Int(second),
            microsecond=(Int(m_second) * 1000 + Int(u_second)),
        )
        # FIXME: python issue https://github.com/python/cpython/issues/120713
        # remove after EOL of 3.11 (2027-10)
        return String(date.strftime(format_str.replace("%Y", "%4Y")))
    except:
        pass
    return ""
