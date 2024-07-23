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
    T5: CollectionElement = NoneType,
    T6: CollectionElement = NoneType,
    T7: CollectionElement = NoneType,
](CollectionElement):
    """Socket Address.

    Parameters:
        sock_family: The socket Address Family.
        T0: The type of the Address field.
        T1: The type of the Address field.
        T2: The type of the Address field.
        T3: The type of the Address field.
        T4: The type of the Address field.
        T5: The type of the Address field.
        T6: The type of the Address field.
        T7: The type of the Address field.

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
            baudrate: UInt,
            mode: UInt8,
            SCLK: UInt,
            MOSI: UInt,
            MISO: UInt,
            CS: UInt,
        )
    - AF_I2C: (
            interface: String,
            address: UInt,
            baudrate: UInt,
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
    var generic_field3: T5
    """Generic field 3."""
    var generic_field4: T6
    """Generic field 4."""
    var generic_field5: T6
    """Generic field 5."""

    # FIXME: currently not possible to rebind `AnyType` structs
    # I do not want to send a 0 in the args since I want to respect each
    # constructor's protocol specific defaults
    # fn __init__[
    #     A0: CollectionElement = NoneType,
    #     A1: CollectionElement = NoneType,
    #     A2: CollectionElement = NoneType,
    #     A3: CollectionElement = NoneType,
    # ](
    #     inout self: SockAddr[_, String, UInt, A0, A1, A2, A3],
    #     values: Tuple[String, Int],
    # ):
    #     """Create an Address.

    #     Args:
    #         values: The host and port.
    #     """
    #     @parameter
    #     if sock_family is SockFamily.AF_INET:
    #         self = rebind[__type_of(self)](IPv4Addr(values[0], values[1]))

    fn __init__(
        inout self: SockAddr[_, String, UInt],
        values: Tuple[StringLiteral, Int],
    ):
        """Create an Address.

        Args:
            values: The host and port.
        """
        self = __type_of(self)(
            values[0], values[1], None, None, None, None, None, None
        )

    fn __init__(
        inout self: SockAddr[_, String, UInt],
        values: Tuple[String, Int],
    ):
        """Create an Address.

        Args:
            values: The host and port.
        """
        self = __type_of(self)(
            values[0], values[1], None, None, None, None, None, None
        )

    fn __init__(
        inout self: SockAddr[_, String, UInt, UInt, UInt],
        values: Tuple[StringLiteral, Int],
    ):
        """Create an Address.

        Args:
            values: The host and port.
        """
        self = __type_of(self)(
            values[0], values[1], 0, 0, None, None, None, None
        )

    fn __init__(
        inout self: SockAddr[_, String, UInt, UInt, UInt],
        values: Tuple[String, Int],
    ):
        """Create an Address.

        Args:
            values: The host and port.
        """
        self = __type_of(self)(
            values[0], values[1], 0, 0, None, None, None, None
        )

    fn __init__(inout self: IPv4Addr, host: String, port: UInt):
        """Create an Address.

        Args:
            host: The IP.
            port: The port.
        """
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
        self.host = host
        self.port = port
        self.generic_field0 = flowinfo
        self.generic_field1 = scope_id

    fn __init__(inout self: NETLINKAddr, pid: UInt, groups: UInt):
        """NETLINKAddr.

        Args:
            pid: The pid.
            groups: The groups.
        """
        self.host = pid
        self.port = groups

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
        self.host = addr_type
        self.port = v1
        self.generic_field0 = v2
        self.generic_field1 = v3
        self.generic_field2 = scope

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
        self.host = interface
        self.port = rx_addr
        self.generic_field0 = tx_addr

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
        self.host = interface
        self.port = name
        self.generic_field0 = pgn
        self.generic_field1 = addr

    fn __init__(inout self: BTL2CAPAddr, bdaddr: String, *, psm: UInt):
        """BTL2CAPAddr.

        Args:
            bdaddr: The Bluetooth address.
            psm: The psm.
        """
        self.host = bdaddr
        self.port = psm

    # FIXME: redefinition of function '__init__' with identical signature
    # fn __init__(inout self: BTRFCOMMAddr, bdaddr: String, *, channel: UInt):
    #     """BTRFCOMMAddr.

    #     Args:
    #         bdaddr: The Bluetooth address.
    #         channel: The channel.
    #     """
    #     self.host = bdaddr
    #     self.port = channel

    fn __init__(inout self: BTHCIAddr, *, device_id: UInt):
        """BTHCIAddr.

        Args:
            device_id: The device_id.
        """
        self.host = device_id
        self.port = None

    # FIXME: redefinition of function '__init__' with identical signature
    # fn __init__(inout self: BTSCOAddr, *, bdaddr: UInt):
    #     """BTSCOAddr.

    #     Args:
    #         bdaddr: The Bluetooth address.
    #     """
    #     self.host = bdaddr
    #     self.port = None

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
        self.host = type
        self.port = name
        self.generic_field0 = feat
        self.generic_field1 = mask

    fn __init__(inout self: VSOCKAddr, CID: UInt, port: UInt):
        """VSOCKAddr.

        Args:
            CID: The Context ID.
            port: The port.
        """
        self.host = CID
        self.port = port

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
        self.host = ifname
        self.port = proto
        self.generic_field0 = pkttype
        self.generic_field1 = hatype
        self.generic_field2 = addr

    fn __init__(inout self: QIPCRTRAddr, node: UInt, port: UInt):
        """QIPCRTRAddr.

        Args:
            node: The node.
            port: The port.
        """
        self.host = node
        self.port = port

    fn __init__(inout self: HYPERVAddr, vm_id: String, service_id: String):
        """HYPERVAddr.

        Args:
            vm_id: The virtual machine identifier.
            service_id: The service identifier of the registered service.
        """
        self.host = vm_id
        self.port = service_id

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
        self.host = interface
        self.port = address
        self.generic_field0 = frequency_hz
        self.generic_field1 = mode
        self.generic_field2 = SCLK
        self.generic_field3 = MOSI
        self.generic_field4 = MISO
        self.generic_field5 = CS

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
        self.host = interface
        self.port = address
        self.generic_field0 = bitrate
        self.generic_field1 = mode
        self.generic_field2 = SDA
        self.generic_field3 = SCL

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
        self.host = interface
        self.port = baudrate
        self.generic_field0 = mode
        self.generic_field1 = rx_addr
        self.generic_field2 = tx_addr


alias IPAddr = SockAddr[_, String, UInt]
"""Generic IP Address type, needs to be constrained on AF_INET or AF_INET6."""
alias IPv4Addr = SockAddr[SockFamily.AF_INET, String, UInt]
"""IPv4Addr.

Args:
    host: The host.
    port: The port.
"""
alias IPv6Addr = SockAddr[SockFamily.AF_INET6, String, UInt, UInt, UInt]
"""IPv6Addr.

Args:
    host: The host.
    port: The port.
    flowinfo: The flowinfo.
    scope_id: The scope_id.
"""
alias NETLINKAddr = SockAddr[SockFamily.AF_NETLINK, UInt, UInt]
"""NETLINKAddr.

Args:
    pid: The pid.
    groups: The groups.
"""
alias TIPCAddr = SockAddr[
    SockFamily.AF_TIPC, TIPCAddrType, UInt, UInt, UInt, TIPCScope
]
"""TIPCAddr.

Args:
    addr_type: The addr_type.
    v1: The v1.
    v2: The v2.
    v3: The v3.
    scope: The scope.
"""
alias CANISOTPAddr = SockAddr[SockFamily.AF_CAN, String, UInt32, UInt32]
"""CANISOTPAddr.

Args:
    interface: The interface.
    rx_addr: The rx_addr.
    tx_addr: The tx_addr.
"""
alias CANJ1939Addr = SockAddr[SockFamily.AF_CAN, String, UInt64, UInt32, UInt8]
"""CANJ1939Addr.

Args:
    interface: The interface.
    name: The ECU name.
    pgn: The Parameter Group Number.
    addr: The address.
"""
alias BTL2CAPAddr = SockAddr[SockFamily.AF_BLUETOOTH, String, UInt]
"""BTL2CAPAddr.

Args:
    bdaddr: The Bluetooth address.
    psm: The psm.
"""
alias BTRFCOMMAddr = SockAddr[SockFamily.AF_BLUETOOTH, String, UInt]
"""BTRFCOMMAddr.

Args:
    bdaddr: The Bluetooth address.
    channel: The channel.
"""
alias BTHCIAddr = SockAddr[SockFamily.AF_BLUETOOTH, UInt, NoneType]
"""BTHCIAddr.

Args:
    device_id: The device_id.
"""
alias BTSCOAddr = SockAddr[SockFamily.AF_BLUETOOTH, UInt, NoneType]
"""BTSCOAddr.

Args:
    bdaddr: The Bluetooth address.
"""
alias ALGAddr = SockAddr[SockFamily.AF_ALG, String, String, UInt32, UInt32]
"""ALGAddr.

Args:
    type: The algorithm type as string, e.g. `aead`, `hash`, `skcipher`.
    name: The algorithm name and operation mode as string, e.g.
        `sha256`.
    feat: The features.
    mask: The mask.
"""
alias VSOCKAddr = SockAddr[SockFamily.AF_VSOCK, UInt, UInt]
"""VSOCKAddr.

Args:
    CID: The Context ID.
    port: The port.
"""
alias PACKETAddr = SockAddr[
    SockFamily.AF_PACKET, String, EtherProto, EtherPacket, UInt, UInt
]
"""PACKETAddr.

Args:
    ifname: The device name.
    proto: The Ethernet protocol number.
    pkttype: The packet type.
    hatype: The ARP hardware address type.
    addr: The hardware physical address.
"""
alias QIPCRTRAddr = SockAddr[SockFamily.AF_QIPCRTR, UInt, UInt]
"""QIPCRTRAddr.

Args:
    node: The node.
    port: The port.
"""
alias HYPERVAddr = SockAddr[SockFamily.AF_HYPERV, String, String]
"""HYPERVAddr.

Args:
    vm_id: The virtual machine identifier.
    service_id: The service identifier of the registered service.
"""
alias SPIAddr = SockAddr[
    SockFamily.AF_SPI, String, UInt, UInt, UInt8, UInt, UInt, UInt, UInt
]
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
"""
alias I2CAddr = SockAddr[
    SockFamily.AF_I2C, String, UInt, UInt, String, UInt, UInt
]
"""Inter Integrated Circuit Address.

Args:
    interface: The interface (e.g. `"COM1"` on Windows, or `"/dev/ttyUSB0"`
        on Linux).
    address: The address.
    bitrate: The bitrate.
    mode: The mode: {"Sm", "Fm", "Fm+", "Hs", "UFm"}.
    SDA: The Serial Data line Address (pin number).
    SCL: The Serial Clock Line (pin number).
"""
alias UARTAddr = SockAddr[
    SockFamily.AF_UART, String, UInt, String, UInt32, UInt32
]
"""Universal Asynchronous Reciever Transmitter Address.

Args:
    interface: The interface (e.g. `"COM1"` on Windows, or `"/dev/ttyUSB0"`
        on Linux).
    baudrate: The baudrate.
    mode: The mode.
    rx_addr: The rx_addr.
    tx_addr: The tx_addr.
"""
