"""FFI utils for the C programming language.

Notes:
    The functions in this module follow only the POSIX standard.
"""

from sys.intrinsics import _mlirtype_is_eq
from sys.ffi import external_call
from memory import UnsafePointer
from utils import StaticTuple


# Adapted from https://github.com/crisadamo/mojo-Libc which doesn't currently
# (2024-07-22) have a licence, so I'll assume MIT licence.
# Huge thanks for the work done.


struct C:
    """C types. This assumes that the platform is 32 or 64 bit, and char is
    always 8 bit (POSIX standard).
    """

    alias char = Int8
    """C type: `char`. The signedness of `char` is platform specific. Most
    systems, including x86 GNU/Linux and Windows, use `signed char`, but those
    based on PowerPC and ARM processors typically use `unsigned char`."""
    alias s_char = Int8
    """C type: `signed char`."""
    alias u_char = UInt8
    """C type: `unsigned char`."""
    alias short = Int16
    """C type: `short`."""
    alias u_short = UInt16
    """C type: `unsigned short`."""
    alias int = Int32
    """C type: `int`."""
    alias u_int = UInt32
    """C type: `unsigned int`."""
    alias long = Int64
    """C type: `long`."""
    alias u_long = UInt64
    """C type: `unsigned long`."""
    alias long_long = Int64
    """C type: `long long`."""
    alias u_long_long = UInt64
    """C type: `unsigned long long`."""
    alias float = Float32
    """C type: `float`."""
    alias double = Float64
    """C type: `double`."""
    alias void = Int8
    """C type: `void`."""


# --- ( error.h Constants )-----------------------------------------------------
alias EPERM = 1
alias ENOENT = 2
alias ESRCH = 3
alias EINTR = 4
alias EIO = 5
alias ENXIO = 6
alias E2BIG = 7
alias ENOEXEC = 8
alias EBADF = 9
alias ECHILD = 10
alias EAGAIN = 11
alias ENOMEM = 12
alias EACCES = 13
alias EFAULT = 14
alias ENOTBLK = 15
alias EBUSY = 16
alias EEXIST = 17
alias EXDEV = 18
alias ENODEV = 19
alias ENOTDIR = 20
alias EISDIR = 21
alias EINVAL = 22
alias ENFILE = 23
alias EMFILE = 24
alias ENOTTY = 25
alias ETXTBSY = 26
alias EFBIG = 27
alias ENOSPC = 28
alias ESPIPE = 29
alias EROFS = 30
alias EMLINK = 31
alias EPIPE = 32
alias EDOM = 33
alias ERANGE = 34
alias EWOULDBLOCK = EAGAIN

# --- ( Network Related Constants )---------------------------------------------
alias sa_family_t = C.u_short
alias socklen_t = C.u_int
alias in_addr_t = C.u_int
alias in_port_t = C.u_short

# Address Family Constants
alias AF_UNSPEC = 0
alias AF_UNIX = 1
alias AF_LOCAL = AF_UNIX
alias AF_INET = 2
alias AF_AX25 = 3
alias AF_IPX = 4
alias AF_APPLETALK = 5
alias AF_NETROM = 6
alias AF_BRIDGE = 7
alias AF_ATMPVC = 8
alias AF_X25 = 9
alias AF_INET6 = 10
alias AF_ROSE = 11
alias AF_DECnet = 12
alias AF_NETBEUI = 13
alias AF_SECURITY = 14
alias AF_KEY = 15
alias AF_NETLINK = 16
alias AF_ROUTE = AF_NETLINK
alias AF_PACKET = 17
alias AF_ASH = 18
alias AF_ECONET = 19
alias AF_ATMSVC = 20
alias AF_RDS = 21
alias AF_SNA = 22
alias AF_IRDA = 23
alias AF_PPPOX = 24
alias AF_WANPIPE = 25
alias AF_LLC = 26
alias AF_CAN = 29
alias AF_TIPC = 30
alias AF_BLUETOOTH = 31
alias AF_IUCV = 32
alias AF_RXRPC = 33
alias AF_ISDN = 34
alias AF_PHONET = 35
alias AF_IEEE802154 = 36
alias AF_CAIF = 37
alias AF_ALG = 38
alias AF_NFC = 39
alias AF_VSOCK = 40
alias AF_KCM = 41
alias AF_QIPCRTR = 42
alias AF_MAX = 43

alias PF_UNSPEC = AF_UNSPEC
alias PF_UNIX = AF_UNIX
alias PF_LOCAL = AF_LOCAL
alias PF_INET = AF_INET
alias PF_AX25 = AF_AX25
alias PF_IPX = AF_IPX
alias PF_APPLETALK = AF_APPLETALK
alias PF_NETROM = AF_NETROM
alias PF_BRIDGE = AF_BRIDGE
alias PF_ATMPVC = AF_ATMPVC
alias PF_X25 = AF_X25
alias PF_INET6 = AF_INET6
alias PF_ROSE = AF_ROSE
alias PF_DECnet = AF_DECnet
alias PF_NETBEUI = AF_NETBEUI
alias PF_SECURITY = AF_SECURITY
alias PF_KEY = AF_KEY
alias PF_NETLINK = AF_NETLINK
alias PF_ROUTE = AF_ROUTE
alias PF_PACKET = AF_PACKET
alias PF_ASH = AF_ASH
alias PF_ECONET = AF_ECONET
alias PF_ATMSVC = AF_ATMSVC
alias PF_RDS = AF_RDS
alias PF_SNA = AF_SNA
alias PF_IRDA = AF_IRDA
alias PF_PPPOX = AF_PPPOX
alias PF_WANPIPE = AF_WANPIPE
alias PF_LLC = AF_LLC
alias PF_CAN = AF_CAN
alias PF_TIPC = AF_TIPC
alias PF_BLUETOOTH = AF_BLUETOOTH
alias PF_IUCV = AF_IUCV
alias PF_RXRPC = AF_RXRPC
alias PF_ISDN = AF_ISDN
alias PF_PHONET = AF_PHONET
alias PF_IEEE802154 = AF_IEEE802154
alias PF_CAIF = AF_CAIF
alias PF_ALG = AF_ALG
alias PF_NFC = AF_NFC
alias PF_VSOCK = AF_VSOCK
alias PF_KCM = AF_KCM
alias PF_QIPCRTR = AF_QIPCRTR
alias PF_MAX = AF_MAX

# Socket Type constants
alias SOCK_STREAM = 1
alias SOCK_DGRAM = 2
alias SOCK_RAW = 3
alias SOCK_RDM = 4
alias SOCK_SEQPACKET = 5
alias SOCK_DCCP = 6
alias SOCK_PACKET = 10
# alias SOCK_CLOEXEC = O_CLOEXEC
# alias SOCK_NONBLOCK = O_NONBLOCK

# Internet (IP) protocols
# Updated from http://www.iana.org/assignments/protocol-numbers and other
# sources.
alias IP = 0  # internet protocol, pseudo protocol number
alias HOPOPT = 0  # IPv6 Hop-by-Hop Option [RFC1883]
alias ICMP = 1  # internet control message protocol
alias IGMP = 2  # Internet Group Management
alias GGP = 3  # gateway-gateway protocol
alias IP_ENCAP = 4  # IP encapsulated in IP (officially ``IP'')
alias ST = 5  # ST datagram mode
alias TCP = 6  # transmission control protocol
alias EGP = 8  # exterior gateway protocol
alias IGP = 9  # any private interior gateway (Cisco)
alias PUP = 12  # PARC universal packet protocol
alias UDP = 17  # user datagram protocol
alias HMP = 20  # host monitoring protocol
alias XNS_IDP = 22  # Xerox NS IDP
alias RDP = 27  # "reliable datagram" protocol
alias ISO_TP4 = 29  # ISO Transport Protocol class 4 [RFC905]
alias DCCP = 33  # Datagram Congestion Control Prot. [RFC4340]
alias XTP = 36  # Xpress Transfer Protocol
alias DDP = 37  # Datagram Delivery Protocol
alias IDPR_CMTP = 38  # IDPR Control Message Transport
alias IPv6 = 41  # Internet Protocol, version 6
alias IPv6_Route = 43  # Routing Header for IPv6
alias IPv6_Frag = 44  # Fragment Header for IPv6
alias IDRP = 45  # Inter_Domain Routing Protocol
alias RSVP = 46  # Reservation Protocol
alias GRE = 47  # General Routing Encapsulation
alias IPSEC_ESP = 50  # Encap Security Payload [RFC2406]
alias IPSEC_AH = 51  # Authentication Header [RFC2402]
alias SKIP = 57  # SKIP
alias IPv6_ICMP = 58  # ICMP for IPv6
alias IPv6_NoNxt = 59  # No Next Header for IPv6
alias IPv6_Opts = 60  # Destination Options for IPv6
alias RSPF_CPHB = 73  # Radio Shortest Path First (officially CPHB)
alias VMTP = 81  # Versatile Message Transport
alias EIGRP = 88  # Enhanced Interior Routing Protocol (Cisco)
alias OSPFIGP = 89  # Open Shortest Path First IGP
alias AX_25 = 93  # AX.25 frames
alias IPIP = 94  # IP_within_IP Encapsulation Protocol
alias ETHERIP = 97  # Ethernet_within_IP Encapsulation [RFC3378]
alias ENCAP = 98  # Yet Another IP encapsulation [RFC1241]
alias PIM = 103  # Protocol Independent Multicast
alias IPCOMP = 108  # IP Payload Compression Protocol
alias VRRP = 112  # Virtual Router Redundancy Protocol [RFC5798]
alias L2TP = 115  # Layer Two Tunneling Protocol [RFC2661]
alias ISIS = 124  # IS_IS over IPv4
alias SCTP = 132  # Stream Control Transmission Protocol
alias FC = 133  # Fibre Channel
alias Mobility_Header = 135  # Mobility Support for IPv6 [RFC3775]
alias UDPLite = 136  # UDP_Lite [RFC3828]
alias MPLS_in_IP = 137  # MPLS_in_IP [RFC4023]
alias HIP = 139  # Host Identity Protocol
alias Shim6 = 140  # Shim6 Protocol [RFC5533]
alias WESP = 141  # Wrapped Encapsulating Security Payload
alias ROHC = 142  # Robust Header Compression


# Address Information
alias AI_PASSIVE = 1
alias AI_CANONNAME = 2
alias AI_NUMERICHOST = 4
alias AI_V4MAPPED = 8
alias AI_ALL = 16
alias AI_ADDRCONFIG = 32
alias AI_IDN = 64

alias INET_ADDRSTRLEN = 16
alias INET6_ADDRSTRLEN = 46

alias SHUT_RD = 0
alias SHUT_WR = 1
alias SHUT_RDWR = 2


alias SOL_SOCKET = 1

alias SO_DEBUG = 1
alias SO_REUSEADDR = 2
alias SO_TYPE = 3
alias SO_ERROR = 4
alias SO_DONTROUTE = 5
alias SO_BROADCAST = 6
alias SO_SNDBUF = 7
alias SO_RCVBUF = 8
alias SO_KEEPALIVE = 9
alias SO_OOBINLINE = 10
alias SO_NO_CHECK = 11
alias SO_PRIORITY = 12
alias SO_LINGER = 13
alias SO_BSDCOMPAT = 14
alias SO_REUSEPORT = 15
alias SO_PASSCRED = 16
alias SO_PEERCRED = 17
alias SO_RCVLOWAT = 18
alias SO_SNDLOWAT = 19
alias SO_RCVTIMEO = 20
alias SO_SNDTIMEO = 21
# alias SO_RCVTIMEO_OLD = 20
# alias SO_SNDTIMEO_OLD = 21
alias SO_SECURITY_AUTHENTICATION = 22
alias SO_SECURITY_ENCRYPTION_TRANSPORT = 23
alias SO_SECURITY_ENCRYPTION_NETWORK = 24
alias SO_BINDTODEVICE = 25
alias SO_ATTACH_FILTER = 26
alias SO_DETACH_FILTER = 27
alias SO_GET_FILTER = SO_ATTACH_FILTER
alias SO_PEERNAME = 28
alias SO_TIMESTAMP = 29
# alias SO_TIMESTAMP_OLD = 29
alias SO_ACCEPTCONN = 30
alias SO_PEERSEC = 31
alias SO_SNDBUFFORCE = 32
alias SO_RCVBUFFORCE = 33
alias SO_PASSSEC = 34
alias SO_TIMESTAMPNS = 35
# alias SO_TIMESTAMPNS_OLD = 35
alias SO_MARK = 36
alias SO_TIMESTAMPING = 37
# alias SO_TIMESTAMPING_OLD = 37
alias SO_PROTOCOL = 38
alias SO_DOMAIN = 39
alias SO_RXQ_OVFL = 40
alias SO_WIFI_STATUS = 41
alias SCM_WIFI_STATUS = SO_WIFI_STATUS
alias SO_PEEK_OFF = 42
alias SO_NOFCS = 43
alias SO_LOCK_FILTER = 44
alias SO_SELECT_ERR_QUEUE = 45
alias SO_BUSY_POLL = 46
alias SO_MAX_PACING_RATE = 47
alias SO_BPF_EXTENSIONS = 48
alias SO_INCOMING_CPU = 49
alias SO_ATTACH_BPF = 50
alias SO_DETACH_BPF = SO_DETACH_FILTER
alias SO_ATTACH_REUSEPORT_CBPF = 51
alias SO_ATTACH_REUSEPORT_EBPF = 52
alias SO_CNX_ADVICE = 53
alias SCM_TIMESTAMPING_OPT_STATS = 54
alias SO_MEMINFO = 55
alias SO_INCOMING_NAPI_ID = 56
alias SO_COOKIE = 57
alias SCM_TIMESTAMPING_PKTINFO = 58
alias SO_PEERGROUPS = 59
alias SO_ZEROCOPY = 60
alias SO_TXTIME = 61
alias SCM_TXTIME = SO_TXTIME
alias SO_BINDTOIFINDEX = 62
alias SO_TIMESTAMP_NEW = 63
alias SO_TIMESTAMPNS_NEW = 64
alias SO_TIMESTAMPING_NEW = 65
alias SO_RCVTIMEO_NEW = 66
alias SO_SNDTIMEO_NEW = 67
alias SO_DETACH_REUSEPORT_BPF = 68


# --- ( Network Related Structs )-----------------------------------------------
@value
@register_passable("trivial")
struct in_addr:
    var s_addr: in_addr_t


@value
@register_passable("trivial")
struct in6_addr:
    var s6_addr: StaticTuple[C.char, 16]


@value
@register_passable("trivial")
struct sockaddr:
    var sa_family: sa_family_t
    var sa_data: StaticTuple[C.char, 14]


@value
@register_passable("trivial")
struct sockaddr_in:
    var sin_family: sa_family_t
    var sin_port: in_port_t
    var sin_addr: in_addr
    var sin_zero: StaticTuple[C.char, 8]


@value
@register_passable("trivial")
struct sockaddr_in6:
    var sin6_family: sa_family_t
    var sin6_port: in_port_t
    var sin6_flowinfo: C.u_int
    var sin6_addr: in6_addr
    var sin6_scope_id: C.u_int


@value
@register_passable("trivial")
struct addrinfo:
    var ai_flags: C.int
    var ai_family: C.int
    var ai_socktype: C.int
    var ai_protocol: C.int
    var ai_addrlen: socklen_t
    var ai_addr: UnsafePointer[sockaddr]
    var ai_canonname: UnsafePointer[C.char]
    # FIXME: This should be UnsafePointer[addrinfo]
    var ai_next: UnsafePointer[C.void]

    fn __init__(inout self):
        self = Self(
            0,
            0,
            0,
            0,
            0,
            UnsafePointer[sockaddr](),
            UnsafePointer[C.char](),
            UnsafePointer[C.void](),
        )


fn char_ptr_to_string(s: UnsafePointer[C.char]) -> String:
    return String(ptr=s.bitcast[UInt8](), len=int(strlen(s) + 1))


fn strlen(s: UnsafePointer[C.char]) -> C.u_int:
    """Libc POSIX `strlen` function.

    Args:
        s: A pointer to a C string.

    Returns:
        The length of the string.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/strlen.3p.html).
        Fn signature: `size_t strlen(const char *s)`.
    """
    return external_call["strlen", C.u_int, UnsafePointer[C.char]](s)


# --- ( Network Related Syscalls & Structs )------------------------------------


fn htonl(hostlong: C.u_int) -> C.u_int:
    """Libc POSIX `htonl` function.

    Args:
        hostlong: A 32-bit unsigned integer in host byte order.

    Returns:
        A 32-bit unsigned integer in network byte order.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/htonl.3p.html).
        Fn signature: `uint32_t htonl(uint32_t hostlong)`.
    """
    return external_call["htonl", C.u_int, C.u_int](hostlong)


fn htons(hostshort: C.u_short) -> C.u_short:
    """Libc POSIX `htons` function.

    Args:
        hostshort: A 16-bit unsigned integer in host byte order.

    Returns:
        A 16-bit unsigned integer in network byte order.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/htonl.3p.html).
        Fn signature: `uint16_t htons(uint16_t hostshort)`.
    """
    return external_call["htons", C.u_short, C.u_short](hostshort)


fn ntohl(netlong: C.u_int) -> C.u_int:
    """Libc POSIX `ntohl` function.

    Args:
        netlong: A 32-bit unsigned integer in network byte order.

    Returns:
        A 32-bit unsigned integer in host byte order.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/htonl.3p.html).
        Fn signature: `uint32_t ntohl(uint32_t netlong)`.
    """
    return external_call["ntohl", C.u_int, C.u_int](netlong)


fn ntohs(netshort: C.u_short) -> C.u_short:
    """Libc POSIX `ntohs` function.

    Args:
        netshort: A 16-bit unsigned integer in network byte order.

    Returns:
        A 16-bit unsigned integer in host byte order.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/htonl.3p.html).
        Fn signature: `uint16_t ntohs(uint16_t netshort)`.
    """
    return external_call["ntohs", C.u_short, C.u_short](netshort)


fn inet_ntop(
    af: C.int,
    src: UnsafePointer[C.void],
    dst: UnsafePointer[C.char],
    size: socklen_t,
) -> UnsafePointer[C.char]:
    """Libc POSIX `inet_ntop` function.

    Args:
        af: Address Family see AF_ alises.
        src: A pointer to a binary address.
        dst: A pointer to a buffer to store the string representation of the
            address.
        size: The size of the buffer pointed by dst.

    Returns:
        A pointer.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/inet_ntop.3p.html.).
        Fn signature: `const char *inet_ntop(int af, const void *restrict src,
            char *restrict dst, socklen_t size)`.
    """
    return external_call[
        "inet_ntop",
        UnsafePointer[C.char],
        C.int,
        UnsafePointer[C.void],
        UnsafePointer[C.char],
        socklen_t,
    ](af, src, dst, size)


fn inet_pton(
    af: C.int, src: UnsafePointer[C.char], dst: UnsafePointer[C.void]
) -> C.int:
    """Libc POSIX `inet_pton` function.

    Args:
        af: Address Family see AF_ alises.
        src: A pointer to a string representation of an address.
        dst: A pointer to a buffer to store the binary address.

    Returns:
        Returns 1 on success (network address was successfully converted). 0 is
        returned if src does not contain a character string representing a valid
        network address in the specified address family.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/inet_ntop.3p.html).
        Fn signature: `int inet_pton(int af, const char *restrict src,
            void *restrict dst)`.
    """
    return external_call[
        "inet_pton", C.int, C.int, UnsafePointer[C.char], UnsafePointer[C.void]
    ](af, src, dst)


fn inet_addr(cp: UnsafePointer[C.char]) -> in_addr_t:
    """Libc POSIX `inet_addr` function.

    Args:
        cp: A pointer to a string representation of an address.

    Returns:
        If the input is invalid, INADDR_NONE (usually -1) is
            returned.  Use of this function is problematic because -1 is a
            valid address (255.255.255.255).  Avoid its use in favor of
            inet_aton(), inet_pton(3), or getaddrinfo(3), which provide a
            cleaner way to indicate error return.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/inet_addr.3p.html).
        Fn signature: `in_addr_t inet_addr(const char *cp)`.
    """
    return external_call["inet_addr", in_addr_t, UnsafePointer[C.char]](cp)


fn inet_aton(cp: UnsafePointer[C.char], addr: UnsafePointer[in_addr]) -> C.int:
    """Libc POSIX `inet_aton` function.

    Args:
        cp: A pointer to a string representation of an address.
        addr: A pointer to a binary address.

    Returns:
        1 if the supplied string was successfully interpreted, or 0 if the
            string is invalid.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/inet_aton.3.html).
        Fn signature: `int inet_aton(const char *cp, struct in_addr *inp)`.
    """
    return external_call[
        "inet_aton", C.int, UnsafePointer[C.char], UnsafePointer[in_addr]
    ](cp, addr)


fn inet_ntoa(addr: in_addr) -> UnsafePointer[C.char]:
    """Libc POSIX `inet_ntoa` function.

    Args:
        addr: A pointer to a binary address.

    Returns:
        A pointer to the string in IPv4 dotted-decimal notation.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/inet_addr.3p.html).
        Fn signature: `char *inet_ntoa(struct in_addr in)`.
        Allocated buffer is 16-18 bytes depending on implementation.
    """
    return external_call["inet_ntoa", UnsafePointer[C.char], in_addr](addr)


fn socket(domain: C.int, type: C.int, protocol: C.int) -> C.int:
    """Libc POSIX `socket` function.

    Args:
        domain: Address Family see AF_ alises.
        type: Socket Type see SOCK_ alises.
        protocol: Protocol see IPPROTO_ alises.

    Returns:
        A pointer to a socket.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/socket.3p.html).
        Fn signature: `int socket(int domain, int type, int protocol)`.
    """
    return external_call["socket", C.int, C.int, C.int, C.int](
        domain, type, protocol
    )


fn setsockopt(
    socket: C.int,
    level: C.int,
    option_name: C.int,
    option_value: UnsafePointer[C.void],
    option_len: socklen_t,
) -> C.int:
    """Libc POSIX `setsockopt` function.

    Args:
        socket: A pointer to a socket.
        level: Protocol Level see SOL_ alises.
        option_name: Option name see SO_ alises.
        option_value: A pointer to a buffer containing the option value.
        option_len: The size of the buffer pointed by option_value.

    Returns:
        Value 0 on success, -1 on error.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/setsockopt.3p.html).
        Fn signature: `int setsockopt(int socket, int level, int option_name,
            const void *option_value, socklen_t option_len)`.
    """
    return external_call[
        "setsockopt",
        C.int,
        C.int,
        C.int,
        C.int,
        UnsafePointer[C.void],
        socklen_t,
    ](socket, level, option_name, option_value, option_len)


fn bind(
    socket: C.int, address: UnsafePointer[sockaddr], address_len: socklen_t
) -> C.int:
    """Libc POSIX `bind` function.

    Args:
        socket: The socket.
        address: A pointer to the address.
        address_len: The length of the pointer.

    Returns:
        An int.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/bind.3p.html).
        Fn signature: `int bind(int socket, const struct sockaddr *address,
            socklen_t address_len)`.
    """
    return external_call[
        "bind", C.int, C.int, UnsafePointer[sockaddr], socklen_t
    ](socket, address, address_len)


fn listen(socket: C.int, backlog: C.int) -> C.int:
    """Libc POSIX `listen` function.

    Args:
        socket: A pointer to a socket.
        backlog: The maximum length to which the queue of pending connections
            for socket may grow.

    Returns:
        A pointer to a socket.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/listen.3p.html).
        Fn signature: `int listen(int socket, int backlog)`.
    """
    return external_call["listen", C.int, C.int, C.int](socket, backlog)


fn accept(
    socket: C.int,
    address: UnsafePointer[sockaddr],
    address_len: UnsafePointer[socklen_t],
) -> C.int:
    """Libc POSIX `accept` function.

    Args:
        socket: A pointer to a socket.
        address: A pointer to a buffer to store the address of the accepted
            socket.
        address_len: A pointer to a buffer to store the length of the address of
            the accepted socket.

    Returns:
        A pointer to a socket.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/accept.3p.html).
        Fn signature: `int accept(int socket, struct sockaddr *restrict address,
            socklen_t *restrict address_len);`.
    """
    return external_call[
        "accept",
        C.int,
        C.int,
        UnsafePointer[sockaddr],
        UnsafePointer[socklen_t],
    ](socket, address, address_len)


fn connect(
    socket: C.int, address: UnsafePointer[sockaddr], address_len: socklen_t
) -> C.int:
    """Libc POSIX `connect` function.

    Args:
        socket: A pointer to a socket.
        address: A pointer to a buffer to store the address of the accepted
            socket.
        address_len: A pointer to a buffer to store the length of the address of
            the accepted socket.

    Returns:
        A pointer to a socket.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/connect.3p.html).
        Fn signature: `int connect(int socket, const struct sockaddr *address,
            socklen_t address_len)`.
    """
    return external_call[
        "connect", C.int, C.int, UnsafePointer[sockaddr], socklen_t
    ](socket, address, address_len)


fn recv(
    socket: C.int, buffer: UnsafePointer[C.void], length: C.u_int, flags: C.int
) -> C.u_int:
    """Libc POSIX `recv` function.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/recv.3p.html).
        Fn signature: `ssize_t recv(int socket, void *buffer, size_t length,
            int flags)`.
    """
    return external_call[
        "recv", C.u_int, C.int, UnsafePointer[C.void], C.u_int, C.int
    ](socket, buffer, length, flags)


fn recvfrom(
    socket: C.int,
    buffer: UnsafePointer[C.void],
    length: C.u_int,
    flags: C.int,
    address: UnsafePointer[sockaddr],
    address_len: UnsafePointer[socklen_t],
) -> C.u_int:
    """Libc POSIX `recvfrom` function.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/recvfrom.3p.html).
        Fn signature: `ssize_t recvfrom(int socket, void *restrict buffer,
            size_t length, int flags, struct sockaddr *restrict address,
            socklen_t *restrict address_len)`.
    """
    return external_call[
        "recvfrom",
        C.u_int,
        C.int,
        UnsafePointer[C.void],
        C.u_int,
        C.int,
        UnsafePointer[sockaddr],
        UnsafePointer[socklen_t],
    ](socket, buffer, length, flags, address, address_len)


fn send(
    socket: C.int, buffer: UnsafePointer[C.void], length: C.u_int, flags: C.int
) -> C.u_int:
    """Libc POSIX `send` function.

    Args:
        socket: A pointer to a socket.
        buffer: A pointer to a buffer to store the address of the accepted
            socket.
        length: A pointer to a buffer to store the length of the address of the
            accepted socket.
        flags: A pointer to a buffer to store the length of the address of the
            accepted socket.

    Returns:
        A pointer to a socket.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/send.3p.html).
        Fn signature: `ssize_t send(int socket, const void *buffer,
            size_t length, int flags)`.
    """
    return external_call[
        "send", C.u_int, C.int, UnsafePointer[C.void], C.u_int, C.int
    ](socket, buffer, length, flags)


fn sendto(
    socket: C.int,
    message: UnsafePointer[C.void],
    length: C.u_int,
    flags: C.int,
    dest_addr: UnsafePointer[sockaddr],
    dest_len: socklen_t,
) -> C.u_int:
    """Libc POSIX `sendto` function.

    Args:
        socket: A pointer to a socket.
        message: A pointer to a buffer to store the address of the accepted
            socket.
        length: A pointer to a buffer to store the length of the address of the
            accepted socket.
        flags: A pointer to a buffer to store the length of the address of the
            accepted socket.
        dest_addr: A pointer to a buffer to store the length of the address of
            the accepted socket.
        dest_len: A pointer to a buffer to store the length of the address of
            the accepted socket.

    Returns:
        A pointer to a socket.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/sendto.3p.html).
        Fn signature: `ssize_t sendto(int socket, const void *message,
            size_t length, int flags, const struct sockaddr *dest_addr,
            socklen_t dest_len)`.
    """
    return external_call[
        "sendto",
        C.u_int,
        C.int,
        UnsafePointer[C.void],
        C.u_int,
        C.int,
        UnsafePointer[sockaddr],
        socklen_t,
    ](socket, message, length, flags, dest_addr, dest_len)


fn shutdown(socket: C.int, how: C.int) -> C.int:
    """Libc POSIX `shutdown` function.

    Args:
        socket: A pointer to a socket.
        how: A pointer to a buffer to store the length of the address of the
            accepted socket.

    Returns:
        A pointer to a socket.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/shutdown.3p.html).
        Fn signature: `int shutdown(int socket, int how)`.
    """
    return external_call["shutdown", C.int, C.int, C.int](socket, how)


fn getaddrinfo(
    nodename: UnsafePointer[C.char],
    servname: UnsafePointer[C.char],
    hints: UnsafePointer[addrinfo],
    res: UnsafePointer[UnsafePointer[addrinfo]],
) -> C.int:
    """Libc POSIX `getaddrinfo` function.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/getaddrinfo.3p.html).
        Fn signature: `int getaddrinfo(const char *restrict nodename,
            const char *restrict servname, const struct addrinfo *restrict hints
            , struct addrinfo **restrict res)`.
    """
    return external_call[
        "getaddrinfo",
        C.int,
        UnsafePointer[C.char],
        UnsafePointer[C.char],
        UnsafePointer[addrinfo],
        UnsafePointer[UnsafePointer[addrinfo]],
    ](nodename, servname, hints, res)


fn gai_strerror(ecode: C.int) -> UnsafePointer[C.char]:
    """Libc POSIX `gai_strerror` function.

    Args:
        ecode: A pointer to a socket.

    Returns:
        A pointer to a socket.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/gai_strerror.3p.html).
        Fn signature: `const char *gai_strerror(int ecode)`.
    """
    return external_call["gai_strerror", UnsafePointer[C.char], C.int](ecode)


# fn get_addr(ptr: UnsafePointer[sockaddr]) -> sockaddr:
#    if ptr.load().sa_family == AF_INET:
#        ptr.bitcast[sockaddr_in]().load().sin_addr
#    return ptr.bitcast[sockaddr_in6]().load().sin6_addr


fn inet_pton(address_family: Int, address: String) -> Int:
    var ip_buf_size = 4
    if address_family == AF_INET6:
        ip_buf_size = 16

    var ip_buf = UnsafePointer[C.void].alloc(ip_buf_size)
    _ = inet_pton(
        rebind[C.int](address_family),
        address.unsafe_ptr().bitcast[C.char](),
        ip_buf,
    )
    return int(ip_buf.bitcast[C.u_int]()[])


# --- ( File Related Syscalls & Structs )---------------------------------------
alias off_t = Int64
alias mode_t = UInt32

alias FM_READ = "r"
alias FM_WRITE = "w"
alias FM_APPEND = "a"
alias FM_BINARY = "b"
alias FM_PLUS = "+"

alias SEEK_SET = 0
alias SEEK_CUR = 1
alias SEEK_END = 2

alias O_RDONLY = 0
alias O_WRONLY = 1
alias O_RDWR = 2
alias O_APPEND = 8
alias O_CREAT = 512
alias O_TRUNC = 1024
alias O_EXCL = 2048
alias O_SYNC = 8192
alias O_NONBLOCK = 16384
alias O_ACCMODE = 3
alias O_CLOEXEC = 524288

# from fcntl.h
alias O_EXEC = -1
alias O_SEARCH = -1
alias O_DIRECTORY = -1
alias O_DSYNC = -1
alias O_NOCTTY = -1
alias O_NOFOLLOW = -1
alias O_RSYNC = -1
alias O_TTY_INIT = -1

alias STDIN_FILENO = 0
alias STDOUT_FILENO = 1
alias STDERR_FILENO = 2

alias F_DUPFD = 0
alias F_GETFD = 1
alias F_SETFD = 2
alias F_GETFL = 3
alias F_SETFL = 4
alias F_GETOWN = 5
alias F_SETOWN = 6
alias F_GETLK = 7
alias F_SETLK = 8
alias F_SETLKW = 9
alias F_RGETLK = 10
alias F_RSETLK = 11
alias F_CNVT = 12
alias F_RSETLKW = 13
alias F_DUPFD_CLOEXEC = 14

# TODO
alias FD_CLOEXEC = -1
alias F_RDLCK = -1
alias F_UNLCK = -1
alias F_WRLCK = -1

alias AT_EACCESS = 512
alias AT_FDCWD = -100
alias AT_SYMLINK_NOFOLLOW = 256
alias AT_REMOVEDIR = 512
alias AT_SYMLINK_FOLLOW = 1024
alias AT_NO_AUTOMOUNT = 2048
alias AT_EMPTY_PATH = 4096
alias AT_RECURSIVE = 32768


@register_passable("trivial")
struct FILE:
    pass


# TODO: this should take in  *args: *T
fn fcntl(fildes: C.int, cmd: C.int) -> C.int:
    """Libc POSIX `fcntl` function.

    Args:
        fildes: A File Descriptor to close.
        cmd: A command to execute.

    Returns:
        0 if succesful, otherwise -1 and errno set to indicate the error.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/close.3p.html).
        Fn signature: `int fcntl(int fildes, int cmd, ...)`.
    """

    return external_call["fcntl", C.int, C.int, C.int](fildes, cmd)


fn close(fildes: C.int) -> C.int:
    """Libc POSIX `close` function.

    Args:
        fildes: A File Descriptor to close.

    Returns:
        0 if succesful, otherwise -1 and errno set to indicate the error.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/close.3p.html).
        Fn signature: `int close(int fildes)`.
    """
    return external_call["close", C.int, C.int](fildes)


# TODO: this should take in  *args: *T
fn open(path: UnsafePointer[C.char], oflag: C.int) -> C.int:
    """Libc POSIX `open` function.

    Args:
        path: A path to a file.
        oflag: A flag to open the file with.

    Returns:
        A File Descriptor or -1 in case of failure

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/open.3p.html).
        Fn signature: `int open(const char *path, int oflag, ...)`.
    """

    return external_call["open", C.int, UnsafePointer[C.char], C.int](
        path, oflag
    )


# TODO: this should take in  *args: *T
fn openat(fd: C.int, path: UnsafePointer[C.char], oflag: C.int) -> C.int:
    """Libc POSIX `open` function.

    Args:
        fd: A File Descriptor to open the file with.
        path: A path to a file.
        oflag: A flag to open the file with.

    Returns:
        A File Descriptor or -1 in case of failure

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/open.3p.html).
        Fn signature: `int openat(int fd, const char *path, int oflag, ...)`.
    """
    return external_call["openat", C.int, C.int, UnsafePointer[C.char], C.int](
        fd, path, oflag
    )


fn fopen(
    pathname: UnsafePointer[C.char], mode: UnsafePointer[C.char]
) -> UnsafePointer[FILE]:
    """Libc POSIX `fopen` function.

    Args:
        pathname: A path to a file.
        mode: A mode to open the file with.

    Returns:
        A File Descriptor or -1 in case of failure.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fopen.3p.html).
        Fn signature: `FILE *fopen(const char *restrict pathname,
            const char *restrict mode)`.
    """
    return external_call[
        "fopen",
        UnsafePointer[FILE],
        UnsafePointer[C.char],
        UnsafePointer[C.char],
    ](pathname, mode)


fn fdopen(fildes: C.int, mode: UnsafePointer[C.char]) -> UnsafePointer[FILE]:
    """Libc POSIX `fdopen` function.

    Args:
        fildes: A File Descriptor to open the file with.
        mode: A mode to open the file with.

    Returns:
        A File Descriptor or -1 in case of failure.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fdopen.3p.html).
        Fn signature: `FILE *fdopen(int fildes, const char *mode)`.
    """
    return external_call[
        "fdopen", UnsafePointer[FILE], C.int, UnsafePointer[C.char]
    ](fildes, mode)


fn freopen(
    pathname: UnsafePointer[C.char],
    mode: UnsafePointer[C.char],
    stream: UnsafePointer[FILE],
) -> UnsafePointer[FILE]:
    """Libc POSIX `freopen` function.

    Args:
        pathname: A path to a file.
        mode: A mode to open the file with.
        stream: A pointer to a stream.

    Returns:
        A File Descriptor or -1 in case of failure.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/freopen.3p.html).
        Fn signature: `FILE *freopen(const char *restrict pathname,
            const char *restrict mode, FILE *restrict stream)`.
    """
    return external_call[
        "freopen",
        UnsafePointer[FILE],
        UnsafePointer[C.char],
        UnsafePointer[C.char],
        UnsafePointer[FILE],
    ](pathname, mode, stream)


fn fmemopen(
    buf: UnsafePointer[C.void], size: C.u_int, mode: UnsafePointer[C.char]
) -> UnsafePointer[FILE]:
    """Libc POSIX `fmemopen` function.

    Args:
        buf: A pointer to a buffer.
        size: The size of the buffer.
        mode: A mode to open the file with.

    Returns:
        A File Descriptor or -1 in case of failure.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fmemopen.3p.html).
        Fn signature: `FILE *fmemopen(void *restrict buf, size_t size,
            const char *restrict mode)`.
    """
    return external_call[
        "fmemopen",
        UnsafePointer[FILE],
        UnsafePointer[C.void],
        C.u_int,
        UnsafePointer[C.char],
    ](buf, size, mode)


fn creat(path: UnsafePointer[C.char], mode: mode_t) -> C.int:
    """Libc POSIX `creat` function.

    Args:
        path: A path to a file.
        mode: A mode to open the file with.

    Returns:
        A File Descriptor or -1 in case of failure.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/creat.3p.html).
        Fn signature: `int creat(const char *path, mode_t mode)`.
    """
    return external_call["creat", C.int, UnsafePointer[C.char], mode_t](
        path, mode
    )


fn fseek(stream: UnsafePointer[FILE], offset: C.long, whence: C.int) -> C.int:
    """Libc POSIX `fseek` function.

    Args:
        stream: A pointer to a stream.
        offset: An offset to seek to.
        whence: A pointer to a buffer to store the length of the address of the
            accepted socket.

    Returns:
        A File Descriptor or -1 in case of failure

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fseek.3p.html).
        Fn signature: `int fseek(FILE *stream, long offset, int whence)`.
    """
    return external_call["fseek", C.int, UnsafePointer[FILE], C.long, C.int](
        stream, offset, whence
    )


fn fseeko(stream: UnsafePointer[FILE], offset: off_t, whence: C.int) -> C.int:
    """Libc POSIX `fseeko` function.

    Args:
        stream: A pointer to a stream.
        offset: An offset to seek to.
        whence: A pointer to a buffer to store the length of the address of the
            accepted socket.

    Returns:
        A File Descriptor or -1 in case of failure.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fseek.3p.html).
        Fn signature: `int fseeko(FILE *stream, off_t offset, int whence)`.
    """
    return external_call["fseeko", C.int, UnsafePointer[FILE], off_t, C.int](
        stream, offset, whence
    )


fn lseek(fildes: C.int, offset: off_t, whence: C.int) -> off_t:
    """Libc POSIX `lseek` function.

    Args:
        fildes: A File Descriptor to open the file with.
        offset: An offset to seek to.
        whence: A pointer to a buffer to store the length of the address of the
            accepted socket.

    Returns:
        A File Descriptor or -1 in case of failure.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/lseek.3p.html).
        Fn signature: `off_t lseek(int fildes, off_t offset, int whence)`.
    """
    return external_call["lseek", off_t, C.int, off_t, C.int](
        fildes, offset, whence
    )


fn fputc(c: C.int, stream: UnsafePointer[FILE]) -> C.int:
    """Libc POSIX `fputc` function.

    Args:
        c: A character to write.
        stream: A pointer to a stream.

    Returns:
        A File Descriptor or -1 in case of failure.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fputc.3p.html).
        Fn signature: `int fputc(int c, FILE *stream)`.
    """
    return external_call["fputc", C.int, C.int, UnsafePointer[FILE]](c, stream)


fn fputs(s: UnsafePointer[C.char], stream: UnsafePointer[FILE]) -> C.int:
    """Libc POSIX `fputs` function.

    [Reference](https://man7.org/linux/man-pages/man3/fputs.3p.html).
    Fn signature: `int fputs(const char *restrict s, FILE *restrict stream)`.

    Args:
        s: A string to write.
        stream: A pointer to a stream.
    Returns: A File Descriptor or -1 in case of failure
    """
    return external_call[
        "fputs",
        C.int,
        UnsafePointer[C.char],
        UnsafePointer[FILE],
    ](s, stream)


fn fgetc(stream: UnsafePointer[FILE]) -> C.int:
    """Libc POSIX `fgetc` function.

    Args:
        stream: A pointer to a stream.

    Returns:
        A File Descriptor or -1 in case of failure.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fgetc.3p.html).
        Fn signature: `int fgetc(FILE *stream)`.
    """
    return external_call["fgets", C.int, UnsafePointer[FILE]](stream)


fn fgets(
    s: UnsafePointer[C.char], n: C.int, stream: UnsafePointer[FILE]
) -> UnsafePointer[C.char]:
    """Libc POSIX `fgets` function.

    Args:
        s: A pointer to a buffer to store the read string.
        n: The maximum number of characters to read.
        stream: A pointer to a stream.

    Returns:
        A File Descriptor or -1 in case of failure.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fgets.3p.html).
        Fn signature: `char *fgets(char *restrict s, int n,
            FILE *restrict stream)`.
    """
    return external_call[
        "fgets",
        UnsafePointer[C.char],
        UnsafePointer[C.char],
        C.int,
        UnsafePointer[FILE],
    ](s, n, stream)


# TODO: this should take in  *args: *T
fn dprintf(fildes: C.int, format: UnsafePointer[C.char]) -> C.int:
    """Libc POSIX `dprintf` function.

    Args:
        fildes: A File Descriptor to open the file with.
        format: A format string.

    Returns:
        A File Descriptor or -1 in case of failure.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fprintf.3p.html).
        Fn signature: `int dprintf(int fildes,
            const char *restrict format, ...)`.
    """
    return external_call["dprintf", C.int, C.int, UnsafePointer[C.char]](
        fildes, format
    )


# TODO: this should take in  *args: *T
fn fprintf(stream: UnsafePointer[FILE], format: UnsafePointer[C.char]) -> C.int:
    """Libc POSIX `fprintf` function.

    Args:
        stream: A pointer to a stream.
        format: A format string.

    Returns:
        An int.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fprintf.3p.html).
        Fn signature: `int fprintf(FILE *restrict stream,
            const char *restrict format, ...)`.
    """
    return external_call[
        "fprintf", C.int, UnsafePointer[FILE], UnsafePointer[C.char]
    ](stream, format)


# printf's family function(s) this is used to implement the rest of the printf's family
fn _printf[callee: StringLiteral](format: UnsafePointer[C.char]) -> C.int:
    return external_call[callee, C.int, UnsafePointer[C.char]](format)


fn _printf[
    callee: StringLiteral, T0: AnyType
](format: UnsafePointer[C.char], arg0: T0) -> C.int:
    return external_call[callee, C.int, UnsafePointer[C.char], T0](format, arg0)


fn _printf[
    callee: StringLiteral, T0: AnyType, T1: AnyType
](format: UnsafePointer[C.char], arg0: T0, arg1: T1) -> C.int:
    return external_call[callee, C.int, UnsafePointer[C.char], T0, T1](
        format, arg0, arg1
    )


fn _printf[
    callee: StringLiteral, T0: AnyType, T1: AnyType, T2: AnyType
](format: UnsafePointer[C.char], arg0: T0, arg1: T1, arg2: T2) -> C.int:
    return external_call[callee, C.int, UnsafePointer[C.char], T0, T1, T2](
        format, arg0, arg1, arg2
    )


fn _printf[
    callee: StringLiteral, T0: AnyType, T1: AnyType, T2: AnyType, T3: AnyType
](
    format: UnsafePointer[C.char], arg0: T0, arg1: T1, arg2: T2, arg3: T3
) -> C.int:
    return external_call[callee, C.int, UnsafePointer[C.char], T0, T1, T2, T3](
        format, arg0, arg1, arg2, arg3
    )


fn _printf[
    callee: StringLiteral,
    T0: AnyTrivialRegType,
    T1: AnyTrivialRegType,
    T2: AnyTrivialRegType,
    T3: AnyTrivialRegType,
    T4: AnyTrivialRegType,
](
    format: UnsafePointer[C.char],
    arg0: T0,
    arg1: T1,
    arg2: T2,
    arg3: T3,
    arg4: T4,
) -> C.int:
    return external_call[
        callee, C.int, UnsafePointer[C.char], T0, T1, T2, T3, T4
    ](format, arg0, arg1, arg2, arg3, arg4)


fn _printf[
    callee: StringLiteral,
    T0: AnyTrivialRegType,
    T1: AnyTrivialRegType,
    T2: AnyTrivialRegType,
    T3: AnyTrivialRegType,
    T4: AnyTrivialRegType,
    T5: AnyTrivialRegType,
](
    format: UnsafePointer[C.char],
    arg0: T0,
    arg1: T1,
    arg2: T2,
    arg3: T3,
    arg4: T4,
    arg5: T5,
) -> C.int:
    return external_call[
        callee, C.int, UnsafePointer[C.char], T0, T1, T2, T3, T4, T5
    ](format, arg0, arg1, arg2, arg3, arg4, arg5)


fn _printf[callee: StringLiteral](format: String) -> C.int:
    return _printf[callee](format.unsafe_ptr().bitcast[C.char]())


fn _printf[
    callee: StringLiteral, T0: AnyType
](format: String, arg0: T0) -> C.int:
    return _printf[callee, T0](format.unsafe_ptr().bitcast[C.char](), arg0)


fn _printf[
    callee: StringLiteral, T0: AnyType, T1: AnyType
](format: String, arg0: T0, arg1: T1) -> C.int:
    return _printf[callee, T0, T1](
        format.unsafe_ptr().bitcast[C.char](), arg0, arg1
    )


fn _printf[
    callee: StringLiteral, T0: AnyType, T1: AnyType, T2: AnyType
](format: String, arg0: T0, arg1: T1, arg2: T2) -> C.int:
    return _printf[callee, T0, T1, T2](
        format.unsafe_ptr().bitcast[C.char](), arg0, arg1, arg2
    )


fn _printf[
    callee: StringLiteral, T0: AnyType, T1: AnyType, T2: AnyType, T3: AnyType
](format: String, arg0: T0, arg1: T1, arg2: T2, arg3: T3) -> C.int:
    return _printf[callee, T0, T1, T2, T3](
        format.unsafe_ptr().bitcast[C.char](), arg0, arg1, arg2, arg3
    )


fn _printf[
    callee: StringLiteral,
    T0: AnyTrivialRegType,
    T1: AnyTrivialRegType,
    T2: AnyTrivialRegType,
    T3: AnyTrivialRegType,
    T4: AnyTrivialRegType,
](format: String, arg0: T0, arg1: T1, arg2: T2, arg3: T3, arg4: T4) -> C.int:
    return _printf[callee, T0, T1, T2, T3, T4](
        format.unsafe_ptr().bitcast[C.char](), arg0, arg1, arg2, arg3, arg4
    )


fn _printf[
    callee: StringLiteral,
    T0: AnyTrivialRegType,
    T1: AnyTrivialRegType,
    T2: AnyTrivialRegType,
    T3: AnyTrivialRegType,
    T4: AnyTrivialRegType,
    T5: AnyTrivialRegType,
](
    format: String, arg0: T0, arg1: T1, arg2: T2, arg3: T3, arg4: T4, arg5: T5
) -> C.int:
    return _printf[callee, T0, T1, T2, T3, T4, T5](
        format.unsafe_ptr().bitcast[C.char](),
        arg0,
        arg1,
        arg2,
        arg3,
        arg4,
        arg5,
    )


fn printf(format: UnsafePointer[C.char]) -> C.int:
    return _printf["printf"](format)


fn printf[T0: AnyType](format: UnsafePointer[C.char], arg0: T0) -> C.int:
    return _printf["printf", T0](format, arg0)


fn printf[
    T0: AnyType, T1: AnyType
](format: UnsafePointer[C.char], arg0: T0, arg1: T1) -> C.int:
    return _printf["printf", T0, T1](format, arg0, arg1)


fn printf[
    T0: AnyType, T1: AnyType, T2: AnyType
](format: UnsafePointer[C.char], arg0: T0, arg1: T1, arg2: T2) -> C.int:
    return _printf["printf", T0, T1, T2](format, arg0, arg1, arg2)


fn printf[
    T0: AnyType, T1: AnyType, T2: AnyType, T3: AnyType
](
    format: UnsafePointer[C.char], arg0: T0, arg1: T1, arg2: T2, arg3: T3
) -> C.int:
    return _printf["printf", T0, T1, T2, T3](format, arg0, arg1, arg2, arg3)


fn printf[
    T0: AnyTrivialRegType,
    T1: AnyTrivialRegType,
    T2: AnyTrivialRegType,
    T3: AnyTrivialRegType,
    T4: AnyTrivialRegType,
](
    format: UnsafePointer[C.char],
    arg0: T0,
    arg1: T1,
    arg2: T2,
    arg3: T3,
    arg4: T4,
) -> C.int:
    return _printf["printf", T0, T1, T2, T3, T4](
        format, arg0, arg1, arg2, arg3, arg4
    )


fn printf[
    T0: AnyTrivialRegType,
    T1: AnyTrivialRegType,
    T2: AnyTrivialRegType,
    T3: AnyTrivialRegType,
    T4: AnyTrivialRegType,
    T5: AnyTrivialRegType,
](
    format: UnsafePointer[C.char],
    arg0: T0,
    arg1: T1,
    arg2: T2,
    arg3: T3,
    arg4: T4,
    arg5: T5,
) -> C.int:
    return _printf["printf", T0, T1, T2, T3, T4, T5](
        format, arg0, arg1, arg2, arg3, arg4, arg5
    )


fn printf(format: String) -> C.int:
    return _printf["printf"](format)


fn printf[T0: AnyType](format: String, arg0: T0) -> C.int:
    return _printf["printf", T0](format, arg0)


fn printf[
    T0: AnyType, T1: AnyType
](format: String, arg0: T0, arg1: T1) -> C.int:
    return _printf["printf", T0, T1](format, arg0, arg1)


fn printf[
    T0: AnyType, T1: AnyType, T2: AnyType
](format: String, arg0: T0, arg1: T1, arg2: T2) -> C.int:
    return _printf["printf", T0, T1, T2](format, arg0, arg1, arg2)


fn printf[
    T0: AnyType, T1: AnyType, T2: AnyType, T3: AnyType
](format: String, arg0: T0, arg1: T1, arg2: T2, arg3: T3) -> C.int:
    return _printf["printf", T0, T1, T2, T3](format, arg0, arg1, arg2, arg3)


fn printf[
    T0: AnyTrivialRegType,
    T1: AnyTrivialRegType,
    T2: AnyTrivialRegType,
    T3: AnyTrivialRegType,
    T4: AnyTrivialRegType,
](format: String, arg0: T0, arg1: T1, arg2: T2, arg3: T3, arg4: T4) -> C.int:
    return _printf["printf", T0, T1, T2, T3, T4](
        format, arg0, arg1, arg2, arg3, arg4
    )


fn printf[
    T0: AnyTrivialRegType,
    T1: AnyTrivialRegType,
    T2: AnyTrivialRegType,
    T3: AnyTrivialRegType,
    T4: AnyTrivialRegType,
    T5: AnyTrivialRegType,
](
    format: String, arg0: T0, arg1: T1, arg2: T2, arg3: T3, arg4: T4, arg5: T5
) -> C.int:
    return _printf["printf", T0, T1, T2, T3, T4, T5](
        format, arg0, arg1, arg2, arg3, arg4, arg5
    )


# TODO: this should take in  *args: *T
fn snprintf(
    s: UnsafePointer[C.char],
    n: C.u_int,
    format: UnsafePointer[C.char],
) -> C.int:
    """Libc POSIX `snprintf` function.

    Args:
        s: A pointer to a buffer to store the read string.
        n: The maximum number of characters to read.
        format: A format string.

    Returns:
        A File Descriptor or -1 in case of failure

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fprintf.3p.html).
        Fn signature: ``int snprintf(char *restrict s, size_t n,`.
            const char *restrict format, ...)`.
    """
    return external_call[
        "snprintf",
        C.int,
        UnsafePointer[C.char],
        C.u_int,
        UnsafePointer[C.char],
    ](s, n, format)


# TODO: this should take in  *args: *T
fn sprintf(s: UnsafePointer[C.char], format: UnsafePointer[C.char]) -> C.int:
    """Libc POSIX `sprintf` function.

    Args:
        s: A pointer to a buffer to store the read string.
        format: A format string.

    Returns:
        A File Descriptor or -1 in case of failure.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fprintf.3p.html).
        Fn signature: ``int sprintf(char *restrict s,`.
            const char *restrict format, ...)`.
    """
    return external_call[
        "sprintf", C.int, UnsafePointer[C.char], UnsafePointer[C.char]
    ](s, format)


# TODO: this should take in  *args: *T
fn fscanf(stream: UnsafePointer[FILE], format: UnsafePointer[C.char]) -> C.int:
    """Libc POSIX `fscanf` function.

    Args:
        stream: A pointer to a stream.
        format: A format string.

    Returns:
        A File Descriptor or -1 in case of failure.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fscanf.3p.html).
        Fn signature: ``int fscanf(FILE *restrict stream,`.
            const char *restrict format, ...)`.
    """
    return external_call[
        "fscanf", C.int, UnsafePointer[FILE], UnsafePointer[C.char]
    ](stream, format)


# TODO: this should take in  *args: *T
fn scanf(format: UnsafePointer[C.char]) -> C.int:
    """Libc POSIX `scanf` function.

    Args:
        format: A format string.

    Returns:
        A File Descriptor or -1 in case of failure.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fscanf.3p.html).
        Fn signature: ``int scanf(const char *restrict format, ...)`.`.
    """
    return external_call["scanf", C.int, UnsafePointer[C.char]](format)


fn sscanf(s: UnsafePointer[C.char], format: UnsafePointer[C.char]) -> C.int:
    """Libc POSIX `sscanf` function.

    Args:
        s: A pointer to a buffer to store the read string.
        format: A format string.

    Returns:
        A File Descriptor or -1 in case of failure.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fscanf.3p.html).
        Fn signature: ``int sscanf(const char *restrict s,`.
            const char *restrict format, ...)`.
    """
    return external_call[
        "sscanf", C.int, UnsafePointer[C.char], UnsafePointer[C.char]
    ](s, format)


fn fread(
    ptr: UnsafePointer[C.void],
    size: C.u_int,
    nitems: C.u_int,
    stream: UnsafePointer[FILE],
) -> C.u_int:
    """Libc POSIX `fread` function.

    Args:
        ptr: A pointer to a buffer to store the read string.
        size: The size of the buffer.
        nitems: The number of items to read.
        stream: A pointer to a stream.

    Returns:
        A File Descriptor or -1 in case of failure.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fread.3p.html).
        Fn signature: `size_t fread(void *restrict ptr, size_t size,
            size_t nitems, FILE *restrict stream)`.
    """
    return external_call[
        "fread",
        C.u_int,
        UnsafePointer[C.void],
        C.u_int,
        C.u_int,
        UnsafePointer[FILE],
    ](ptr, size, nitems, stream)


fn rewind(stream: UnsafePointer[FILE]) -> C.void:
    """Libc POSIX `rewind` function.

    Args:
        stream: A pointer to a stream.

    Returns:
        A void.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/rewind.3p.html).
        Fn signature: `void rewind(FILE *stream)`.
    """
    return external_call["rewind", C.void, UnsafePointer[FILE]](stream)


fn getline(
    lineptr: UnsafePointer[UnsafePointer[FILE]],
    n: UnsafePointer[C.u_int],
    stream: UnsafePointer[FILE],
) -> C.u_int:
    """Libc POSIX `getline` function.

    Args:
        lineptr: A pointer to a pointer to a buffer to store the read string.
        n: A pointer to a buffer to store the length of the address of the
            accepted socket.
        stream: A pointer to a stream.

    Returns:
        Size of the lines read.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/getline.3p.html).
        Fn signature: `ssize_t getline(char **restrict lineptr,
            size_t *restrict n, FILE *restrict stream);`.
    """
    return external_call[
        "getline",
        C.u_int,
        UnsafePointer[UnsafePointer[FILE]],
        UnsafePointer[C.u_int],
        UnsafePointer[FILE],
    ](lineptr, n, stream)


fn pread(
    fildes: C.int, buf: UnsafePointer[C.void], nbyte: C.u_int, offset: off_t
) -> C.u_int:
    """Libc POSIX `pread` function.

    Args:
        fildes: A File Descriptor to open the file with.
        buf: A pointer to a buffer to store the read string.
        nbyte: The maximum number of characters to read.
        offset: An offset to seek to.

    Returns:
        A File Descriptor or -1 in case of failure.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/read.3p.html).
        Fn signature: `ssize_t pread(int fildes, void *buf, size_t nbyte,
            off_t offset)`.
    """
    return external_call[
        "pread", C.u_int, C.int, UnsafePointer[C.void], C.u_int, off_t
    ](fildes, buf, nbyte, offset)


fn read(fildes: C.int, buf: UnsafePointer[C.void], nbyte: C.u_int) -> C.u_int:
    """Libc POSIX `read` function.

    Args:
        fildes: A File Descriptor to open the file with.
        buf: A pointer to a buffer to store the read string.
        nbyte: The maximum number of characters to read.

    Returns:
        Amount of bytes read.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/read.3p.html).
        Fn signature: `sssize_t read(int fildes, void *buf, size_t nbyte)`.
    """
    return external_call[
        "read", C.u_int, C.int, UnsafePointer[C.void], C.u_int
    ](fildes, buf, nbyte)


fn pwrite(
    fildes: C.int, buf: UnsafePointer[C.void], nbyte: C.u_int, offset: off_t
) -> C.u_int:
    """Libc POSIX `pwrite` function.

    Args:
        fildes: A File Descriptor to open the file with.
        buf: A pointer to a buffer to store the read string.
        nbyte: The maximum number of characters to read.
        offset: An offset to seek to.

    Returns:
        Amount of bytes written.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/write.3p.html).
        Fn signature: `ssize_t pwrite(int fildes, const void *buf, size_t nbyte,
            off_t offset)`.
    """
    return external_call[
        "pwrite", C.u_int, C.int, UnsafePointer[C.void], C.u_int, off_t
    ](fildes, buf, nbyte, offset)


fn write(fildes: C.int, buf: UnsafePointer[C.void], nbyte: C.u_int) -> C.u_int:
    """Libc POSIX `write` function.

    Args:
        fildes: A File Descriptor to open the file with.
        buf: A pointer to a buffer to store the read string.
        nbyte: The maximum number of characters to read.

    Returns:
        Amount of bytes written.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/write.3p.html).
        Fn signature: `ssize_t write(int fildes, const void *buf,
            size_t nbyte)`.
    """
    return external_call[
        "write", C.u_int, C.int, UnsafePointer[C.void], C.u_int
    ](fildes, buf, nbyte)


fn fclose(stream: UnsafePointer[FILE]) -> C.int:
    """Libc POSIX `fclose` function.

    Args:
        stream: A pointer to a stream.

    Returns:
        A File Descriptor or -1 in case of failure.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/fclose.3p.html).
        Fn signature: `int fclose(FILE *stream)`.
    """
    return external_call["fclose", C.int, UnsafePointer[FILE]](stream)


fn ftell(stream: UnsafePointer[FILE]) -> C.long:
    """Libc POSIX `ftell` function.

    Args:
        stream: A pointer to a stream.

    Returns:
        The current file position of the given stream.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/ftell.3p.html).
        Fn signature: `long ftell(FILE *stream)`.
    """
    return external_call["ftell", C.long, UnsafePointer[FILE]](stream)


fn ftello(stream: UnsafePointer[FILE]) -> off_t:
    """Libc POSIX `ftello` function.

    Args:
        stream: A pointer to a stream.

    Returns:
        The current file position of the given stream.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/ftell.3p.html).
        Fn signature: `off_t ftello(FILE *stream)`.
    """
    return external_call["ftello", off_t, UnsafePointer[FILE]](stream)


# TODO
# fn fflush(stream: UnsafePointer[FILE]) -> C.int:
#     """Libc POSIX `fflush` function.

#     Args:
#         stream

#     Returns:
#         An int.

#     Notes:
#         [Reference](https://man7.org/linux/man-pages/man3/fflush.3p.html).
#         Fn signature: `int fflush(FILE *stream)`.
#     """
#     return external_call["fflush", C.int, UnsafePointer[FILE]](stream)


fn clearerr(stream: UnsafePointer[FILE]) -> C.void:
    """Libc POSIX `feof` function.

    Args:
        stream: A pointer to a stream.

    Returns:
        A void.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/clearerr.3p.html).
        Fn signature: `void clearerr(FILE *stream)`.
    """
    return external_call["clearerr", C.void, UnsafePointer[FILE]](stream)


fn feof(stream: UnsafePointer[FILE]) -> C.int:
    """Libc POSIX `feof` function.

    Args:
        stream: A pointer to a stream.

    Returns:
        1 if the end-of-file indicator associated with the stream is set,
            else 0.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/feof.3p.html).
        Fn signature: `int feof(FILE *stream)`.
    """
    return external_call["feof", C.int, UnsafePointer[FILE]](stream)


fn ferror(stream: UnsafePointer[FILE]) -> C.int:
    """Libc POSIX `ferror` function.

    Args:
        stream: A pointer to a stream.

    Returns:
        1 if the error indicator associated with the stream is set, else 0.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/ferror.3p.html).
        Fn signature: `int ferror(FILE *stream)`.
    """
    return external_call["ferror", C.int, UnsafePointer[FILE]](stream)


# TODO: add ioctl Options
# TODO: this should take in  *args: *T
fn ioctl(fildes: C.int, request: C.int) -> C.int:
    """Libc POSIX `ioctl` function.

    Args:
        fildes: A File Descriptor to open the file with.
        request: An offset to seek to.

    Returns:
        A File Descriptor or -1 in case of failure

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/ioctl.3p.html).
        Fn signature: `int ioctl(int fildes, int request, ... /* arg */)`.
    """
    return external_call["ioctl", C.int, C.int, C.int](fildes, request)


# --- ( Logging Syscalls ) -----------------------------------------------------
alias LOG_PID = -1
alias LOG_CONS = -1
alias LOG_NDELAY = -1
alias LOG_ODELAY = -1
alias LOG_NOWAIT = -1
alias LOG_KERN = -1
alias LOG_USER = -1
alias LOG_MAIL = -1
alias LOG_NEWS = -1
alias LOG_UUCP = -1
alias LOG_DAEMON = -1
alias LOG_AUTH = -1
alias LOG_CRON = -1
alias LOG_LPR = -1
alias LOG_LOCAL0 = -1
alias LOG_LOCAL1 = -1
alias LOG_LOCAL2 = -1
alias LOG_LOCAL3 = -1
alias LOG_LOCAL4 = -1
alias LOG_LOCAL5 = -1
alias LOG_LOCAL6 = -1
alias LOG_LOCAL7 = -1
alias LOG_MASK = -1  # (pri)
alias LOG_EMERG = -1
alias LOG_ALERT = -1
alias LOG_CRIT = -1
alias LOG_ERR = -1
alias LOG_WARNING = -1
alias LOG_NOTICE = -1
alias LOG_INFO = -1
alias LOG_DEBUG = -1


fn openlog(
    ident: UnsafePointer[C.char], logopt: C.int, facility: C.int
) -> C.void:
    """Libc POSIX `openlog` function.

    Args:
        ident: A File Descriptor to open the file with.
        logopt: An offset to seek to.
        facility: Arguments for the format string.

    Returns:
        A File Descriptor or -1 in case of failure.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/closelog.3p.html).
        Fn signature: `void openlog(const char *ident, int logopt,
            int facility)`.
    """
    return external_call[
        "openlog", C.void, UnsafePointer[C.char], C.int, C.int
    ](ident, logopt, facility)


# TODO: this should take in  *args: *T
fn syslog(priority: C.int, message: UnsafePointer[C.char]) -> C.void:
    """Libc POSIX `syslog` function.

    Args:
        priority: A File Descriptor to open the file with.
        message: An offset to seek to.

    Returns:
        A File Descriptor or -1 in case of failure.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/closelog.3p.html).
        Fn signature: `void syslog(int priority, const char *message,
            ... /* arguments */)`.
    """
    return external_call["syslog", C.void, C.int, UnsafePointer[C.char]](
        priority, message
    )


fn setlogmask(maskpri: C.int) -> C.int:
    """Libc POSIX `setlogmask` function.

    Args:
        maskpri: A File Descriptor to open the file with.

    Returns:
        A File Descriptor or -1 in case of failure.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/closelog.3p.html).
        Fn signature: ` int setlogmask(int maskpri)`.
    """
    return external_call["setlogmask", C.int, C.int](maskpri)


fn closelog():
    """Libc POSIX `closelog` function.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/closelog.3p.html).
        Fn signature: `void closelog(void)`.
    """
    _ = external_call["closelog", C.void]()
