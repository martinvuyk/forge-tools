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
"""`TimeZone` module.

- Notes:
    - IANA is supported: [`TimeZone` and DST data sources](
        http://www.iana.org/time-zones/repository/tz-link.html).
        [List of TZ identifiers (`tz_str`)](
        https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
"""

from collections import Optional

from .zoneinfo import (
    Offset,
    ZoneDST,
    ZoneInfo,
    ZoneInfoMem32,
    ZoneInfoMem8,
    ZoneStorageDST,
    ZoneStorageNoDST,
    offset_at,
    get_zoneinfo,
)


struct TimeZone[
    dst_storage: ZoneStorageDST = ZoneInfoMem32,
    no_dst_storage: ZoneStorageNoDST = ZoneInfoMem8,
    iana: Bool = True,
    pyzoneinfo: Bool = True,
    native: Bool = False,
](Copyable, Movable, Writable):
    """`TimeZone` struct. Because of a POSIX standard, if you set
    the tz_str e.g. Etc/UTC-4 it means 4 hours east of UTC
    which is UTC + 4 in numbers. That is:
    `TimeZone("Etc/UTC-4", offset_h=4, offset_m=0, sign=1)`. If
    `TimeZone[iana=True]("Etc/UTC-4")`, the correct offsets are
    returned for the calculations, but the attributes offset_h,
    offset_m and sign will remain the default 0, 0, 1 respectively.

    Parameters:
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
    """

    var tz_str: StaticString
    """[`TZ identifier`](
        https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)."""
    var has_dst: Bool
    """Whether the `TimeZone` has Daylight Saving Time."""
    var _dst: dst_storage
    var _no_dst: no_dst_storage

    fn __init__(
        out self,
        tz_str: StaticString = "Etc/UTC",
        offset_h: UInt8 = 0,
        offset_m: UInt8 = 0,
        sign: UInt8 = 1,
        has_dst: Bool = False,
        zoneinfo: Optional[ZoneInfo[dst_storage, no_dst_storage]] = None,
    ):
        """Construct a `TimeZone`.

        Args:
            tz_str: The [`TZ identifier`](
                https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
            offset_h: Offset for the hour.
            offset_m: Offset for the minute.
            sign: Sign: {1, -1}.
            has_dst: Whether the `TimeZone` has Daylight Saving Time.
            zoneinfo: The ZoneInfo for the `TimeZone` to instantiate.
                defaults to looking for info on all available timezones.
        """
        debug_assert(
            offset_h < 100
            and offset_h >= 0
            and offset_m < 100
            and offset_m >= 0
            and (sign == 1 or sign == -1),
            (
                "utc offsets can't have a member bigger than 100, and sign must"
                " be either 1 or -1"
            ),
        )

        self.tz_str = tz_str
        self.has_dst = has_dst
        self._dst = dst_storage()
        self._no_dst = no_dst_storage()
        if not has_dst:
            s = (
                -1 if sign == -1
                and not (offset_h == 0 and offset_m == 0) else 1
            )
            self._no_dst.add(tz_str, Offset(offset_h, offset_m, s))

        z = zoneinfo

        @parameter
        if native:
            if not zoneinfo:
                z = get_zoneinfo[dst_storage, no_dst_storage]()
            if not z:
                return

        @parameter
        if iana:
            zi = z.value()
            if has_dst:
                dst = zi.with_dst.get(tz_str)
                if not dst:
                    return
                self._dst.add(tz_str, dst.value())
                return
            tz = zi.with_no_dst.get(tz_str)
            if not tz:
                return
            self._no_dst.add(tz_str, tz.value())

    fn __getattr__(self, name: StaticString) raises -> Int8:
        """Get the attribute.

        Args:
            name: The name of the attribute.

        Returns:
            The attribute.

        Raises:
            "ZoneInfo not found".
        """

        if name not in ["offset_h", "offset_m", "sign"]:
            constrained[False, "there is no such attribute"]()
            return 0

        var offset: Offset
        if self.has_dst:
            var data = self._dst.get(self.tz_str)
            if not data:
                raise Error("ZoneInfo not found")
            offset = data.value().from_hash()[2]
        else:
            var data = self._no_dst.get(self.tz_str)
            if not data:
                raise Error("ZoneInfo not found")
            offset = data.value()

        if name == "offset_h":
            return offset.hour.cast[DType.int8]()
        elif name == "offset_m":
            return offset.minute.cast[DType.int8]()
        elif name == "sign":
            return offset.sign
        constrained[False, "there is no such attribute"]()
        return 0

    fn offset_at(
        self,
        year: UInt16,
        month: UInt8,
        day: UInt8,
        hour: UInt8 = 0,
        minute: UInt8 = 0,
        second: UInt8 = 0,
    ) -> Offset:
        """Return the UTC offset for the `TimeZone` at the given date.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.

        Returns:
            The Offset.
        """

        @parameter
        if iana and native:
            tz = self._dst.get(self.tz_str)
            var offset = offset_at(tz, year, month, day, hour, minute, second)
            if offset:
                return offset.value()
        elif iana and pyzoneinfo:
            try:
                from python import Python

                zoneinfo = Python.import_module("zoneinfo")
                dt = Python.import_module("datetime")
                zone = zoneinfo.ZoneInfo(self.tz_str)
                local = dt.datetime(year, month, day, hour, tzinfo=zone)
                offset = local.utcoffset()
                sign = 1 if offset.days == -1 else -1
                hours = Int(offset.seconds) // (60 * 60) - Int(hour)
                minutes = Int(offset.seconds) % 60
                return Offset(hours, minutes, sign)
            except:
                pass

        data = self._no_dst.get(self.tz_str)
        if data:
            return data.value()
        return Offset(0, 0, 1)

    @always_inline
    fn write_to[W: Writer](self, mut writer: W):
        """Write the `TimeZone` to a writer.

        Parameters:
            W: The writer type.

        Args:
            writer: The writer to write to.
        """
        writer.write(self.tz_str)

    @always_inline("nodebug")
    fn __str__(self) -> String:
        """Str.

        Returns:
            String.
        """
        return self.tz_str

    @always_inline("nodebug")
    fn __repr__(self) -> String:
        """Repr.

        Returns:
            String.
        """
        return self.__str__()

    @always_inline("nodebug")
    fn __eq__(self, other: Self) -> Bool:
        """Whether the tz_str from both TimeZones
        are the same.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.tz_str == other.tz_str

    @always_inline("nodebug")
    fn __ne__(self, other: Self) -> Bool:
        """Whether the tz_str from both TimeZones
        are different.

        Args:
            other: Other.

        Returns:
            Bool.
        """
        return self.tz_str != other.tz_str

    @staticmethod
    fn from_offset(
        year: UInt16,
        month: UInt8,
        day: UInt8,
        offset_h: UInt8,
        offset_m: UInt8,
        sign: UInt8,
    ) -> Self:
        """Build a UTC TZ string from the offset.

        Args:
            year: Year.
            month: Month.
            day: Day.
            offset_h: Offset for the hour.
            offset_m: Offset for the minute.
            sign: Sign: {1, -1}.

        Returns:
            Self.
        """
        _ = year, month, day, offset_h, offset_m, sign
        # TODO: it should create an Etc/UTC-X TimeZone
        return Self()
