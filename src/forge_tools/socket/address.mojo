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


@value
struct SockAddr[
    sock_family: SockFamily,
    T0: CollectionElement,
    T1: CollectionElement,
    T2: CollectionElement = NoneType,
    T3: CollectionElement = NoneType,
    T4: CollectionElement = NoneType,
]:
    """Socket Address.

    Notes:

    - AF_INET: (host: String, port: UInt)
    - AF_INET6: (host: String, port: UInt, flowinfo: UInt, scope_id: UInt)
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
            SCLK: UInt,
            MOSI: UInt,
            MISO: UInt,
            CS: UInt,
        )
    - AF_I2C: (
            interface: String,
            address: UInt,
            SDA: UInt,
            SCL: UInt,
            baudrate: UInt,
            mode: String,
        )
    - AF_UART: (
            interface: String,
            rx_addr: UInt32,
            tx_addr: UInt32,
            baudrate: UInt,
            mode: String,
        )
    """

    # TODO: build constructor for each of the address types with standard
    # defaults values and constraint them.
    # Use Python's very good docs: https://docs.python.org/3/library/socket.html

    var host: T0
    """Host/Interface Identifier."""
    var port: T1
    """Port or protocol specific field."""
    var generic_field0: T2
    """Generic field 0."""
    var generic_field1: T3
    """Generic field 1."""
    var generic_field2: T4
    """Generic field 2."""

    fn __init__(inout self: SockAddr[_, String, UInt], host: String, port: Int):
        """Create an Address.

        Args:
            host: The IP.
            port: The port.
        """
        self.host = host
        self.port = port
        self.generic_field0 = None
        self.generic_field1 = None
        self.generic_field2 = None

    fn __init__(
        inout self: SockAddr[_, String, UInt], values: Tuple[StringLiteral, Int]
    ):
        """Create an Address.

        Args:
            values: The IP and port.
        """
        self = SockAddr[_, String, UInt](values[0], values[1])

    fn __init__(
        inout self: SockAddr[_, String, UInt], values: Tuple[String, Int]
    ):
        """Create an Address.

        Args:
            values: The IP and port.
        """
        self = SockAddr[_, String, UInt](values[0], values[1])

    fn __init__(inout self: IPv4Addr, value: String) raises:
        """Create an Address.

        Args:
            value: The string with IP and port.
        """
        var idx = value.rfind(":")
        if idx == -1:
            raise Error("port not found in String")
        self = IPv4Addr(value[:idx], int(value[idx + 1 :]))

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
        ...

    fn __init__(inout self: NETLINKAddr, pid: UInt, groups: UInt):
        """NETLINKAddr.

        Args:
            pid: The pid.
            groups: The groups.
        """
        ...

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
        ...

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
        ...

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
        ...

    fn __init__(inout self: BTL2CAPAddr, bdaddr: String, psm: UInt):
        """BTL2CAPAddr.

        Args:
            bdaddr: The Bluetooth address.
            psm: The psm.
        """
        ...

    fn __init__(inout self: BTRFCOMMAddr, bdaddr: String, channel: UInt):
        """BTRFCOMMAddr.

        Args:
            bdaddr: The Bluetooth address.
            channel: The channel.
        """
        ...

    fn __init__(inout self: BTHCIAddr, device_id: UInt):
        """BTHCIAddr.

        Args:
            device_id: The device_id.
        """
        ...

    fn __init__(inout self: BTSCOAddr, bdaddr: String):
        """BTSCOAddr.

        Args:
            bdaddr: The Bluetooth address.
        """
        ...

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
        ...

    fn __init__(inout self: VSOCKAddr, CID: UInt, port: UInt):
        """VSOCKAddr.

        Args:
            CID: The Context ID.
            port: The port.
        """
        ...

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
        ...

    fn __init__(inout self: QIPCRTRAddr, node: UInt, port: UInt):
        """QIPCRTRAddr.

        Args:
            node: The node.
            port: The port.
        """
        ...

    fn __init__(inout self: HYPERVAddr, vm_id: String, service_id: String):
        """HYPERVAddr.

        Args:
            vm_id: The virtual machine identifier.
            service_id: The service identifier of the registered service.
        """
        ...

    fn __init__(
        inout self: SPIAddr,
        interface: String,
        address: UInt,
        SCLK: UInt = 0,
        MOSI: UInt = 0,
        MISO: UInt = 0,
        CS: UInt = 0,
    ):
        """SPIAddr.

        Args:
            interface: The interface.
            address: The address.
            SCLK: The Serial Clock (pin number).
            MOSI: The Master Out Slave In (pin number).
            MISO: The Master In Slave Out (pin number).
            CS: The Chip Select (pin number).
        """
        ...

    fn __init__(
        inout self: I2CAddr,
        interface: String,
        address: UInt,
        SDA: UInt = 0,
        SCL: UInt = 0,
        baudrate: UInt = 100,
        mode: String = "Sm",
    ):
        """I2CAddr.

        Args:
            interface: The interface.
            address: The address.
            SDA: The Serial Data line Address (pin number).
            SCL: The Serial Clock Line (pin number).
            baudrate: The baudrate.
            mode: The mode.
        """
        ...

    fn __init__(
        inout self: UARTAddr,
        interface: String,
        rx_addr: UInt32 = 0,
        tx_addr: UInt32 = 1,
        baudrate: UInt = 115200,
        mode: String = "8N1",
    ):
        """UARTAddr.

        Args:
            interface: The interface.
            rx_addr: The rx_addr.
            tx_addr: The tx_addr.
            baudrate: The baudrate.
            mode: The mode.
        """
        ...


alias IPAddr = SockAddr[_, String, UInt]
"""Generic IP Address type, needs to be constrained on AF_INET or AF_INET6."""
alias IPv4Addr = SockAddr[SockFamily.AF_INET, String, UInt]
"""IPv4 Address: `(host: String, port: UInt)`."""
alias IPv6Addr = SockAddr[SockFamily.AF_INET6, String, UInt, UInt, UInt]
"""IPv6 Address: `(host: String, port: UInt, flowinfo: UInt, scope_id: UInt)`."""
alias NETLINKAddr = SockAddr[SockFamily.AF_NETLINK, UInt, UInt]
"""NETLINK Address: `(pid: UInt, groups: UInt)`."""
alias TIPCAddr = SockAddr[
    SockFamily.AF_TIPC, TIPCAddrType, UInt, UInt, UInt, TIPCScope
]
"""TIPC Address: `(
    addr_type: TIPCAddrType,
    v1: UInt,
    v2: UInt,
    v3: UInt,
    scope: TIPCScope,
)`."""
alias CANISOTPAddr = SockAddr[SockFamily.AF_CAN, String, UInt32, UInt32]
"""CAN ISOTP Address: `(interface: String, rx_addr: UInt32, tx_addr: UInt32)`."""
alias CANJ1939Addr = SockAddr[SockFamily.AF_CAN, String, UInt64, UInt32, UInt8]
"""CAN J1939 Address: `(interface: String, name: UInt64, pgn: UInt32, addr: UInt8)`."""
alias BTL2CAPAddr = SockAddr[SockFamily.AF_BLUETOOTH, String, UInt]
"""BLUETOOTH BTPROTO_L2CAP Address: `(bdaddr: String, psm: UInt)`."""
alias BTRFCOMMAddr = SockAddr[SockFamily.AF_BLUETOOTH, String, UInt]
"""BLUETOOTH BTPROTO_RFCOMM Address: `(bdaddr: String, channel: UInt)`."""
alias BTHCIAddr = SockAddr[SockFamily.AF_BLUETOOTH, UInt, NoneType]
"""BLUETOOTH BTPROTO_HCI Address: `(device_id: UInt)`."""
alias BTSCOAddr = SockAddr[SockFamily.AF_BLUETOOTH, UInt, NoneType]
"""BLUETOOTH BTPROTO_SCO Address: `(bdaddr: String)`."""
alias ALGAddr = SockAddr[SockFamily.AF_ALG, String, String, UInt32, UInt32]
"""ALG Address: `(type: String, name: String, feat: UInt32, mask: UInt32)`."""
alias VSOCKAddr = SockAddr[SockFamily.AF_VSOCK, UInt, UInt]
"""VSOCK Address: `(CID: UInt, port: UInt)`."""
alias PACKETAddr = SockAddr[SockFamily.AF_PACKET, String, UInt]
"""PACKET Address: `(
    ifname: String,
    proto: EtherProto,
    pkttype: EtherPacket,
    hatype: UInt,
    addr: UInt,
)`."""
alias QIPCRTRAddr = SockAddr[SockFamily.AF_QIPCRTR, String, UInt]
"""QIPCRTR Address: `(node: UInt, port: UInt)`."""
alias HYPERVAddr = SockAddr[SockFamily.AF_HYPERV, String, UInt]
"""HYPERV Address: `(vm_id: String, service_id: String)`."""
alias SPIAddr = SockAddr[SockFamily.AF_SPI, String, UInt]
"""SPI Address: `(
    interface: String,
    address: UInt,
    SCLK: UInt,
    MOSI: UInt,
    MISO: UInt,
    CS: UInt,
)`."""
alias I2CAddr = SockAddr[SockFamily.AF_I2C, String, UInt]
"""I2C Address: `(
    interface: String,
    address: UInt,
    SDA: UInt,
    SCL: UInt,
    baudrate: UInt,
    mode: String,
)`."""
alias UARTAddr = SockAddr[SockFamily.AF_UART, String, UInt]
"""UART Address: `(
    interface: String,
    rx_addr: UInt32,
    tx_addr: UInt32,
    baudrate: UInt,
    mode: String,
)`."""
