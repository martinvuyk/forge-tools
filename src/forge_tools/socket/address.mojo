"""address module. Defines types of addresses and their standard defaults."""


from .socket import SockFamily


@register_passable("trivial")
struct TIPCAddrType:
    alias TIPC_ADDR_NAMESEQ = "TIPC_ADDR_NAMESEQ"
    """TIPC_ADDR_NAMESEQ."""
    alias TIPC_ADDR_MCAST = "TIPC_ADDR_MCAST"
    """TIPC_ADDR_MCAST."""
    alias TIPC_ADDR_NAME = "TIPC_ADDR_NAME"
    """TIPC_ADDR_NAME."""
    alias TIPC_ADDR_ID = "TIPC_ADDR_ID"
    """TIPC_ADDR_ID."""
    var _selected: StringLiteral

    fn __init__(inout self, selected: StringLiteral):
        """Construct an instance.

        Args:
            selected: The selected value.
        """
        debug_assert(
            selected
            in (
                Self.TIPC_ADDR_NAMESEQ,
                Self.TIPC_ADDR_MCAST,
                Self.TIPC_ADDR_NAME,
                Self.TIPC_ADDR_ID,
            ),
            "selected value is not valid",
        )
        self._selected = selected

    fn __is__(self, value: StringLiteral) -> Bool:
        """Whether the selected value is the give value.

        Args:
            value: The value.

        Returns:
            The result.
        """
        return self._selected == value


@register_passable("trivial")
struct TIPCScope:
    alias TIPC_ZONE_SCOPE = "TIPC_ZONE_SCOPE"
    """TIPC_ZONE_SCOPE."""
    alias TIPC_CLUSTER_SCOPE = "TIPC_CLUSTER_SCOPE"
    """TIPC_CLUSTER_SCOPE."""
    alias TIPC_NODE_SCOPE = "TIPC_NODE_SCOPE"
    """TIPC_NODE_SCOPE."""
    var _selected: StringLiteral

    fn __init__(inout self, selected: StringLiteral):
        """Construct an instance.

        Args:
            selected: The selected value.
        """
        debug_assert(
            selected
            in (
                Self.TIPC_ZONE_SCOPE,
                Self.TIPC_CLUSTER_SCOPE,
                Self.TIPC_NODE_SCOPE,
            ),
            "selected value is not valid",
        )
        self._selected = selected

    fn __is__(self, value: StringLiteral) -> Bool:
        """Whether the selected value is the give value.

        Args:
            value: The value.

        Returns:
            The result.
        """
        return self._selected == value


@register_passable("trivial")
struct EtherProto:
    alias ALL = "ALL"
    """ALL."""
    alias ARP = "ARP"
    """ARP."""
    alias IP = "IP"
    """IP."""
    alias IPV6 = "IPV6"
    """IPV6."""
    alias VLAN = "VLAN"
    """VLAN."""

    var _selected: StringLiteral

    fn __init__(inout self, selected: StringLiteral):
        """Construct an instance.

        Args:
            selected: The selected value.
        """
        debug_assert(
            selected
            in (
                Self.ALL,
                Self.ARP,
                Self.IP,
                Self.IPV6,
                Self.VLAN,
            ),
            "selected value is not valid",
        )
        self._selected = selected

    fn __is__(self, value: StringLiteral) -> Bool:
        """Whether the selected value is the give value.

        Args:
            value: The value.

        Returns:
            The result.
        """
        return self._selected == value


@register_passable("trivial")
struct EtherPacket:
    alias HOST = "HOST"
    """HOST."""
    alias BROADCAST = "BROADCAST"
    """BROADCAST."""
    alias MULTICAST = "MULTICAST"
    """MULTICAST."""
    alias OTHERHOST = "OTHERHOST"
    """OTHERHOST."""
    alias OUTGOING = "OUTGOING"
    """OUTGOING."""

    var _selected: StringLiteral

    fn __init__(inout self, selected: StringLiteral):
        """Construct an instance.

        Args:
            selected: The selected value.
        """
        debug_assert(
            selected
            in (
                Self.HOST,
                Self.BROADCAST,
                Self.MULTICAST,
                Self.OTHERHOST,
                Self.OUTGOING,
            ),
            "selected value is not valid",
        )
        self._selected = selected

    fn __is__(self, value: StringLiteral) -> Bool:
        """Whether the selected value is the give value.

        Args:
            value: The value.

        Returns:
            The result.
        """
        return self._selected == value


# trait SockAddr[sock_family: SockFamily](CollectionElement):
trait SockAddr(CollectionElementNew):
    """Socket Address.

    Parameters:
        sock_family: The socket Address Family.

    Notes:

    - AF_INET: (host: String, port: UInt)
    - AF_INET6: (host: String, port: UInt, flowinfo: UInt, scope_id: UInt
    - AF_UNIX: (host: String,)
    - AF_NETLINK: (pid: UInt, groups: UInt)
    - AF_TIPC: (
            addr_type: TIPCAddrType,
            v1: UInt,
            v2: UInt,
            v3: UInt,
            scope: TIPCScope,
        )
    - AF_CAN: (interface: String,)
        - CAN_ISOTP: (interface: String, rx_addr: UInt32, tx_addr: UInt32)
        - CAN_J1939: (interface: String, name: UInt64, pgn: UInt32, addr: UInt8)
    - AF_BLUETOOTH
        - BTPROTO_L2CAP: (bdaddr: String, psm: UInt)
        - BTPROTO_RFCOMM: (bdaddr: String, channel: UInt)
        - BTPROTO_HCI: (device_id: UInt)
    - AF_ALG: (type: String, name: String, feat: UInt32, mask: UInt32)
    - AF_VSOCK: (CID: UInt, port: UInt)
    - AF_PACKET: (
            ifname: String,
            proto: EtherProto,
            pkttype: EtherPacket,
            hatype: UInt,
            addr: UInt,
        )
    - AF_QIPCRTR: (node: UInt, port: UInt)
    - AF_HYPERV: (vm_id: String, service_id: String)
    - AF_SPI: (
            interface: String,
            address: UInt,
            frequency_hz: UInt,
            mode: UInt8,
            SCLK: UInt,
            MOSI: UInt,
            MISO: UInt,
            CS: UInt,
        )
    - AF_I2C: (
            interface: String,
            address: UInt,
            bitrate: UInt,
            mode: String,
            SDA: UInt,
            SCL: UInt,
        )
    - AF_UART: (
            interface: String,
            baudrate: UInt,
            mode: String,
            rx_addr: UInt32,
            tx_addr: UInt32,
        )
    """

    ...

@value
struct IPv4Addr[sock_family: SockFamily = SockFamily.AF_INET](SockAddr):
    """IPv4 Address (AF_INET).

    Args:
        host: The host.
        port: The port.
    """
    var host: String
    """The host."""
    var port: UInt
    """The port."""


    fn __init__(inout self: IPv4Addr, host: String, port: UInt):
        """Create an Address.

        Args:
            host: The IP.
            port: The port.
        """
        constrained[sock_family is SockFamily.AF_INET, "sock_family must be SockFamily.AF_INET"]()
        self.host = host
        self.port = port

    fn __init__(inout self: IPv4Addr, value: String) raises:
        """Create an Address.

        Args:
            value: The string with IP and port.
        """
        var idx = value.rfind(":")
        if idx == -1:
            raise Error("port not found in String")
        self = IPv4Addr(value[:idx], int(value[idx + 1 :]))

@value
struct IPv6Addr[sock_family: SockFamily = SockFamily.AF_INET6](SockAddr):
    """IPv6 Address (AF_INET6).

    Args:
        host: The host.
        port: The port.
        flowinfo: The flowinfo.
        scope_id: The scope_id.
    """
    var host: String
    """The host."""
    var port: UInt
    """The port."""
    var flowinfo: UInt
    """The flowinfo."""
    var scope_id: UInt
    """The scope_id."""

    fn __init__(
        inout self: IPv6Addr,
        host: String,
        port: UInt,
        flowinfo: UInt = 0,
        scope_id: UInt = 0,
    ):
        """IPv6Addr.

        Args:
            host: The host.
            port: The port.
            flowinfo: The flowinfo.
            scope_id: The scope_id.
        """
        constrained[sock_family is SockFamily.AF_INET6, "sock_family must be SockFamily.AF_INET6"]()
        self.host = host
        self.port = port
        self.flowinfo = flowinfo
        self.scope_id = scope_id


@value
struct UnixAddr[sock_family: SockFamily = SockFamily.AF_UNIX](SockAddr):
    """Unix local Address.

    Args:
        host: The sun_path (maximum of 108 bytes).

    Notes:
        [Reference](https://man7.org/linux/man-pages/man7/unix.7.html).
    """
    var host: String
    """The sun_path (maximum of 108 bytes)."""

    fn __init__(inout self: UnixAddr, host: String):
        """Create an Address.

        Args:
            host: The sun_path (maximum of 108 bytes).

        Notes:
            [Reference](https://man7.org/linux/man-pages/man7/unix.7.html).
        """
        constrained[sock_family is SockFamily.AF_UNIX, "sock_family must be SockFamily.AF_UNIX"]()
        self.host = host

@value
struct NETLINKAddr[sock_family: SockFamily = SockFamily.AF_NETLINK](SockAddr):
    """NETLINKAddr.

    Args:
        pid: The pid.
        groups: The groups.
    """
    var pid: UInt
    """The pid."""
    var groups: UInt
    """The groups."""

    fn __init__(inout self: NETLINKAddr, pid: UInt, groups: UInt):
        """NETLINKAddr.

        Args:
            pid: The pid.
            groups: The groups.
        """
        constrained[sock_family is SockFamily.AF_NETLINK, "sock_family must be SockFamily.AF_NETLINK"]()
        self.pid = pid
        self.groups = groups


@value
struct TIPCAddr[
    SockFamily.AF_TIPC
](SockAddr):
    """TIPCAddr.

    Args:
        addr_type: The addr_type.
        v1: The v1.
        v2: The v2.
        v3: The v3.
        scope: The scope.
    """
    var addr_type: TIPCAddrType
    """The addr_type."""
    var v1: UInt
    """The v1."""
    var v2: UInt
    """The v2."""
    var v3: UInt
    """The v3."""
    var scope: TIPCScope
    """The scope."""

    fn __init__(
        inout self: TIPCAddr,
        addr_type: TIPCAddrType,
        v1: UInt,
        v2: UInt,
        v3: UInt = 0,
        scope: TIPCScope = TIPCScope.TIPC_CLUSTER_SCOPE,
    ):
        """TIPCAddr.

        Args:
            addr_type: The addr_type.
            v1: The v1.
            v2: The v2.
            v3: The v3.
            scope: The scope.
        """
        constrained[sock_family is SockFamily.AF_TIPC, "sock_family must be SockFamily.AF_TIPC"]()
        self.addr_type = addr_type
        self.v1 = v1
        self.v2 = v2
        self.v3 = v3
        self.scope = scope

@value
struct CANISOTPAddr[sock_family: SockFamily = SockFamily.AF_CAN](SockAddr):
    """CANISOTPAddr.

    Args:
        interface: The interface.
        rx_addr: The rx_addr.
        tx_addr: The tx_addr.
    """
    var interface: String
    """The interface."""
    var rx_addr: UInt32
    """The rx_addr."""
    var tx_addr: UInt32
    """The tx_addr."""

    fn __init__(
        inout self: CANISOTPAddr,
        interface: String,
        rx_addr: UInt32 = 0,
        tx_addr: UInt32 = 1,
    ):
        """CANISOTPAddr.

        Args:
            interface: The interface.
            rx_addr: The rx_addr.
            tx_addr: The tx_addr.
        """
        constrained[sock_family is SockFamily.AF_CAN, "sock_family must be SockFamily.AF_CAN"]()
        self.interface = interface
        self.rx_addr = rx_addr
        self.tx_addr = tx_addr

@value
struct CANJ1939Addr[sock_family: SockFamily = SockFamily.AF_CAN](SockAddr):
    """CANJ1939Addr.

    Args:
        interface: The interface.
        name: The ECU name.
        pgn: The Parameter Group Number.
        addr: The address.
    """
    var interface: String
    """The interface."""
    var name: UInt64
    """The ECU name."""
    var pgn: UInt32
    """The Parameter Group Number."""
    var addr: UInt8
    """The address."""

    fn __init__(
        inout self: CANJ1939Addr,
        interface: String,
        name: UInt64,
        pgn: UInt32,
        addr: UInt8,
    ):
        """CANJ1939Addr.

        Args:
            interface: The interface.
            name: The ECU name.
            pgn: The Parameter Group Number.
            addr: The address.
        """
        constrained[sock_family is SockFamily.AF_CAN, "sock_family must be SockFamily.AF_CAN"]()
        self.interface = interface
        self.name = name
        self.pgn = pgn
        self.addr = addr

struct BTL2CAPAddr[sock_family: SockFamily = SockFamily.AF_BLUETOOTH](SockAddr):
    """BTL2CAPAddr.

    Args:
        bdaddr: The Bluetooth address.
        psm: The psm.
    """
    var bdaddr: String
    """The Bluetooth address."""
    var psm: UInt
    """The psm."""

    fn __init__(inout self: BTL2CAPAddr, bdaddr: String, psm: UInt):
        """BTL2CAPAddr.

        Args:
            bdaddr: The Bluetooth address.
            psm: The psm.
        """
        constrained[sock_family is SockFamily.AF_BLUETOOTH, "sock_family must be SockFamily.AF_BLUETOOTH"]()
        self.bdaddr = bdaddr
        self.psm = psm

struct BTRFCOMMAddr[sock_family: SockFamily = SockFamily.AF_BLUETOOTH](SockAddr):
    """BTRFCOMMAddr.

    Args:
        bdaddr: The Bluetooth address.
        channel: The channel.
    """
    var bdaddr: String
    """The Bluetooth address."""
    var channel: UInt
    """The channel."""
    fn __init__(inout self: BTRFCOMMAddr, bdaddr: String, channel: UInt):
        """BTRFCOMMAddr.

        Args:
            bdaddr: The Bluetooth address.
            channel: The channel.
        """
        constrained[sock_family is SockFamily.AF_BLUETOOTH, "sock_family must be SockFamily.AF_BLUETOOTH"]()
        self.bdaddr = bdaddr
        self.channel = channel


struct BTHCIAddr[sock_family: SockFamily = SockFamily.AF_BLUETOOTH](SockAddr):
    """BTHCIAddr.

    Args:
        device_id: The device_id.
    """
    var device_id: UInt
    """The device_id."""

    fn __init__(inout self: BTHCIAddr, device_id: UInt):
        """BTHCIAddr.

        Args:
            device_id: The device_id.
        """
        constrained[sock_family is SockFamily.AF_BLUETOOTH, "sock_family must be SockFamily.AF_BLUETOOTH"]()
        self.device_id = device_id


struct BTSCOAddr[sock_family: SockFamily = SockFamily.AF_BLUETOOTH](SockAddr):
    """BTSCOAddr.

    Args:
        bdaddr: The Bluetooth address.
    """
    var bdaddr: UInt
    """The Bluetooth address."""

    fn __init__(inout self: BTSCOAddr,bdaddr: UInt):
        """BTSCOAddr.

        Args:
            bdaddr: The Bluetooth address.
        """
        constrained[sock_family is SockFamily.AF_BLUETOOTH, "sock_family must be SockFamily.AF_BLUETOOTH"]()
        self.bdaddr = bdaddr


struct ALGAddr[sock_family: SockFamily = SockFamily.AF_ALG](SockAddr):
    """ALGAddr.

    Args:
        type: The algorithm type as string, e.g. `aead`, `hash`, `skcipher`.
        name: The algorithm name and operation mode as string, e.g.
            `sha256`.
        feat: The features.
        mask: The mask.
    """
    var type: String
    """The algorithm type as string, e.g. `aead`, `hash`, `skcipher`."""
    var name: String
    """The algorithm name and operation mode as string, e.g. `sha256`."""
    var feat: UInt32
    """The features."""
    var mask: UInt32
    """The mask."""

    fn __init__(
        inout self: ALGAddr,
        type: String,
        name: String,
        feat: UInt32 = 0,
        mask: UInt32 = 0,
    ):
        """ALGAddr.

        Args:
            type: The algorithm type as string, e.g. `aead`, `hash`, `skcipher`.
            name: The algorithm name and operation mode as string, e.g.
                `sha256`.
            feat: The features.
            mask: The mask.
        """
        constrained[sock_family is SockFamily.AF_ALG, "sock_family must be SockFamily.AF_ALG"]()
        self.type = type
        self.name = name
        self.feat = feat
        self.mask = mask

struct VSOCKAddr[sock_family: SockFamily = SockFamily.AF_VSOCK](SockAddr):
    """VSOCKAddr.

    Args:
        CID: The Context ID.
        port: The port.
    """
    var CID: UInt
    """The Context ID."""
    var port: UInt
    """The port."""

    fn __init__(inout self: VSOCKAddr, CID: UInt, port: UInt):
        """VSOCKAddr.

        Args:
            CID: The Context ID.
            port: The port.
        """
        constrained[sock_family is SockFamily.AF_VSOCK, "sock_family must be SockFamily.AF_VSOCK"]()
        self.CID = CID
        self.port = port



struct PACKETAddr[
    sock_family: SockFamily = SockFamily.AF_PACKET
](SockAddr):
    """PACKETAddr.

    Args:
        ifname: The device name.
        proto: The Ethernet protocol number.
        pkttype: The packet type.
        hatype: The ARP hardware address type.
        addr: The hardware physical address.
    """
    var ifname: String
    """The device name."""
    var proto: EtherProto
    """The Ethernet protocol number."""
    var pkttype: EtherPacket
    """The packet type."""
    var hatype: UInt
    """The ARP hardware address type."""
    var addr: UInt
    """The hardware physical address."""

    fn __init__(
        inout self: PACKETAddr,
        ifname: String,
        proto: EtherProto = EtherProto.ALL,
        pkttype: EtherPacket = EtherPacket.HOST,
        hatype: UInt = 0,
        addr: UInt = 0,
    ):
        """PACKETAddr.

        Args:
            ifname: The device name.
            proto: The Ethernet protocol number.
            pkttype: The packet type.
            hatype: The ARP hardware address type.
            addr: The hardware physical address.
        """
        constrained[sock_family is SockFamily.AF_PACKET, "sock_family must be SockFamily.AF_PACKET"]()
        self.ifname = ifname
        self.proto = proto
        self.pkttype = pkttype
        self.hatype = hatype
        self.addr = addr

struct QIPCRTRAddr[sock_family: SockFamily = SockFamily.AF_QIPCRTR](SockAddr):
    """QIPCRTRAddr.

    Args:
        node: The node.
        port: The port.
    """
    var node: UInt
    """The node."""
    var port: UInt
    """The port."""

    fn __init__(inout self: QIPCRTRAddr, node: UInt, port: UInt):
        """QIPCRTRAddr.

        Args:
            node: The node.
            port: The port.
        """
        constrained[sock_family is SockFamily.AF_QIPCRTR, "sock_family must be SockFamily.AF_QIPCRTR"]()
        self.node = node
        self.port = port

struct HYPERVAddr[sock_family: SockFamily = SockFamily.AF_HYPERV](SockAddr):
    """HYPERVAddr.

    Args:
        vm_id: The virtual machine identifier.
        service_id: The service identifier of the registered service.
    """
    var vm_id: String
    """The virtual machine identifier."""
    var service_id: String
    """The service identifier of the registered service."""

    fn __init__(inout self: HYPERVAddr, vm_id: String, service_id: String):
        """HYPERVAddr.

        Args:
            vm_id: The virtual machine identifier.
            service_id: The service identifier of the registered service.
        """
        constrained[sock_family is SockFamily.AF_HYPERV, "sock_family must be SockFamily.AF_HYPERV"]()
        self.vm_id = vm_id
        self.service_id = service_id

struct SPIAddr[
    sock_family: SockFamily = SockFamily.AF_SPI
](SockAddr):
    """Serial Peripheral Interface Address.

    Args:
        interface: The interface (e.g. `"COM1"` on Windows, or `"/dev/ttyUSB0"`
            on Linux).
        address: The address.
        frequency_hz: The frequency in Hz of the connection.
        mode: The SPI mode: {0, 1, 2, 3}.
        SCLK: The Serial Clock (pin number).
        MOSI: The Master Out Slave In (pin number).
        MISO: The Master In Slave Out (pin number).
        CS: The Chip Select (pin number).

    Notes:
        This struct is not a standard socket address since there is none.
    """
    var interface: String
    """The interface (e.g. `"COM1"` on Windows, or `"/dev/ttyUSB0"` on Linux).
    """
    var address: UInt
    """The address."""
    var frequency_hz: UInt
    """The frequency in Hz of the connection."""
    var mode: UInt8
    """The SPI mode: {0, 1, 2, 3}."""
    var SCLK: UInt
    """The Serial Clock (pin number)."""
    var MOSI: UInt
    """The Master Out Slave In (pin number)."""
    var MISO: UInt
    """The Master In Slave Out (pin number)."""
    var CS: UInt
    """The Chip Select (pin number)."""

    fn __init__(
        inout self: SPIAddr,
        interface: String,
        address: UInt,
        frequency_hz: UInt,
        mode: UInt8 = 0,
        SCLK: UInt = 0,
        MOSI: UInt = 0,
        MISO: UInt = 0,
        CS: UInt = 0,
    ):
        """Serial Peripheral Interface Address.

        Args:
            interface: The interface (e.g. `"COM1"` on Windows, or
                `"/dev/ttyUSB0"` on Linux).
            address: The address.
            frequency_hz: The frequency in Hz of the connection.
            mode: The SPI mode: {0, 1, 2, 3}.
            SCLK: The Serial Clock (pin number).
            MOSI: The Master Out Slave In (pin number).
            MISO: The Master In Slave Out (pin number).
            CS: The Chip Select (pin number).
        """
        constrained[sock_family is SockFamily.AF_SPI, "sock_family must be SockFamily.AF_SPI"]()
        self.interface = interface
        self.address = address
        self.frequency_hz = frequency_hz
        self.mode = mode
        self.SCLK = SCLK
        self.MOSI = MOSI
        self.MISO = MISO
        self.CS = CS



struct I2CAddr[
    sock_family: SockFamily = SockFamily.AF_I2C
](SockAddr):
    """Inter Integrated Circuit Address.

    Args:
        interface: The interface (e.g. `"COM1"` on Windows, or `"/dev/ttyUSB0"`
            on Linux).
        address: The address.
        bitrate: The bitrate.
        mode: The mode: {"Sm", "Fm", "Fm+", "Hs", "UFm"}.
        SDA: The Serial Data line Address (pin number).
        SCL: The Serial Clock Line (pin number).

    Notes:
        This struct is not a standard socket address since there is none.
    """
    var interface: String
    """The interface (e.g. `"COM1"` on Windows, or `"/dev/ttyUSB0"` on Linux).
    """
    var address: UInt
    """The address."""
    var bitrate: UInt
    """The bitrate."""
    var mode: String
    """The mode: {"Sm", "Fm", "Fm+", "Hs", "UFm"}."""
    var SDA: UInt
    """The Serial Data line Address (pin number)."""
    var SCL: UInt
    """The Serial Clock Line (pin number)."""

    fn __init__(
        inout self: I2CAddr,
        interface: String,
        address: UInt,
        bitrate: UInt = 100,
        mode: String = "Sm",
        SDA: UInt = 0,
        SCL: UInt = 0,
    ):
        """Inter Integrated Circuit Address.

        Args:
            interface: The interface (e.g. `"COM1"` on Windows, or
                `"/dev/ttyUSB0"` on Linux).
            address: The address.
            bitrate: The bitrate.
            mode: The mode: {"Sm", "Fm", "Fm+", "Hs", "UFm"}.
            SDA: The Serial Data line Address (pin number).
            SCL: The Serial Clock Line (pin number).
        """
        constrained[sock_family is SockFamily.AF_I2C, "sock_family must be SockFamily.AF_I2C"]()
        self.interface = interface
        self.address = address
        self.bitrate = bitrate
        self.mode = mode
        self.SDA = SDA
        self.SCL = SCL

struct UARTAddr[
    sock_family: SockFamily = SockFamily.AF_UART
](SockAddr):
    """Universal Asynchronous Reciever Transmitter Address.

    Args:
        interface: The interface (e.g. `"COM1"` on Windows, or `"/dev/ttyUSB0"`
            on Linux).
        baudrate: The baudrate.
        mode: The mode.
        rx_addr: The rx_addr.
        tx_addr: The tx_addr.
    
    Notes:
        This struct is not a standard socket address since there is none.
    """
    var interface: String
    """The interface (e.g. `"COM1"` on Windows, or `"/dev/ttyUSB0"` on Linux).
    """
    var baudrate: UInt
    """The baudrate."""
    var mode: String
    """The mode."""
    var rx_addr: UInt32
    """The rx_addr."""
    var tx_addr: UInt32
    """The tx_addr."""

    fn __init__(
        inout self: UARTAddr,
        interface: String,
        baudrate: UInt = 115200,
        mode: String = "8N1",
        rx_addr: UInt32 = 0,
        tx_addr: UInt32 = 1,
    ):
        """Universal Asynchronous Reciever Transmitter Address.

        Args:
            interface: The interface (e.g. `"COM1"` on Windows, or
                `"/dev/ttyUSB0"` on Linux).
            baudrate: The baudrate.
            mode: The mode.
            rx_addr: The rx_addr.
            tx_addr: The tx_addr.
        """
        constrained[sock_family is SockFamily.AF_UART, "sock_family must be SockFamily.AF_UART"]()
        self.host = interface
        self.port = baudrate
        self.generic_field0 = mode
        self.generic_field1 = rx_addr
        self.generic_field2 = tx_addr
