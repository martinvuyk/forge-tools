"""Libc POSIX constants."""

# ===----------------------------------------------------------------------=== #
# Error constants
# ===----------------------------------------------------------------------=== #

alias EPERM = 1
"""Constant: EPERM."""
alias ENOENT = 2
"""Constant: ENOENT."""
alias ESRCH = 3
"""Constant: ESRCH."""
alias EINTR = 4
"""Constant: EINTR."""
alias EIO = 5
"""Constant: EIO."""
alias ENXIO = 6
"""Constant: ENXIO."""
alias E2BIG = 7
"""Constant: E2BIG."""
alias ENOEXEC = 8
"""Constant: ENOEXEC."""
alias EBADF = 9
"""Constant: EBADF."""
alias ECHILD = 10
"""Constant: ECHILD."""
alias EAGAIN = 11
"""Constant: EAGAIN."""
alias ENOMEM = 12
"""Constant: ENOMEM."""
alias EACCES = 13
"""Constant: EACCES."""
alias EFAULT = 14
"""Constant: EFAULT."""
alias ENOTBLK = 15
"""Constant: ENOTBLK."""
alias EBUSY = 16
"""Constant: EBUSY."""
alias EEXIST = 17
"""Constant: EEXIST."""
alias EXDEV = 18
"""Constant: EXDEV."""
alias ENODEV = 19
"""Constant: ENODEV."""
alias ENOTDIR = 20
"""Constant: ENOTDIR."""
alias EISDIR = 21
"""Constant: EISDIR."""
alias EINVAL = 22
"""Constant: EINVAL."""
alias ENFILE = 23
"""Constant: ENFILE."""
alias EMFILE = 24
"""Constant: EMFILE."""
alias ENOTTY = 25
"""Constant: ENOTTY."""
alias ETXTBSY = 26
"""Constant: ETXTBSY."""
alias EFBIG = 27
"""Constant: EFBIG."""
alias ENOSPC = 28
"""Constant: ENOSPC."""
alias ESPIPE = 29
"""Constant: ESPIPE."""
alias EROFS = 30
"""Constant: EROFS."""
alias EMLINK = 31
"""Constant: EMLINK."""
alias EPIPE = 32
"""Constant: EPIPE."""
alias EDOM = 33
"""Constant: EDOM."""
alias ERANGE = 34
"""Constant: ERANGE."""
alias EWOULDBLOCK = EAGAIN
"""Constant: EWOULDBLOCK."""


# ===----------------------------------------------------------------------=== #
# Networking constants
# ===----------------------------------------------------------------------=== #

# Address Family Constants
alias AF_UNSPEC = 0
"""Constant: AF_UNSPEC."""
alias AF_UNIX = 1
"""Constant: AF_UNIX."""
alias AF_LOCAL = AF_UNIX
"""Constant: AF_LOCAL."""
alias AF_INET = 2
"""Constant: AF_INET."""
alias AF_AX25 = 3
"""Constant: AF_AX25."""
alias AF_IPX = 4
"""Constant: AF_IPX."""
alias AF_APPLETALK = 5
"""Constant: AF_APPLETALK."""
alias AF_NETROM = 6
"""Constant: AF_NETROM."""
alias AF_BRIDGE = 7
"""Constant: AF_BRIDGE."""
alias AF_ATMPVC = 8
"""Constant: AF_ATMPVC."""
alias AF_X25 = 9
"""Constant: AF_X25."""
alias AF_INET6 = 10
"""Constant: AF_INET6."""
alias AF_ROSE = 11
"""Constant: AF_ROSE."""
alias AF_DECnet = 12
"""Constant: AF_DECnet."""
alias AF_NETBEUI = 13
"""Constant: AF_NETBEUI."""
alias AF_SECURITY = 14
"""Constant: AF_SECURITY."""
alias AF_KEY = 15
"""Constant: AF_KEY."""
alias AF_NETLINK = 16
"""Constant: AF_NETLINK."""
alias AF_ROUTE = AF_NETLINK
"""Constant: AF_ROUTE."""
alias AF_PACKET = 17
"""Constant: AF_PACKET."""
alias AF_ASH = 18
"""Constant: AF_ASH."""
alias AF_ECONET = 19
"""Constant: AF_ECONET."""
alias AF_ATMSVC = 20
"""Constant: AF_ATMSVC."""
alias AF_RDS = 21
"""Constant: AF_RDS."""
alias AF_SNA = 22
"""Constant: AF_SNA."""
alias AF_IRDA = 23
"""Constant: AF_IRDA."""
alias AF_PPPOX = 24
"""Constant: AF_PPPOX."""
alias AF_WANPIPE = 25
"""Constant: AF_WANPIPE."""
alias AF_LLC = 26
"""Constant: AF_LLC."""
alias AF_CAN = 29
"""Constant: AF_CAN."""
alias AF_TIPC = 30
"""Constant: AF_TIPC."""
alias AF_BLUETOOTH = 31
"""Constant: AF_BLUETOOTH."""
alias AF_IUCV = 32
"""Constant: AF_IUCV."""
alias AF_RXRPC = 33
"""Constant: AF_RXRPC."""
alias AF_ISDN = 34
"""Constant: AF_ISDN."""
alias AF_PHONET = 35
"""Constant: AF_PHONET."""
alias AF_IEEE802154 = 36
"""Constant: AF_IEEE802154."""
alias AF_CAIF = 37
"""Constant: AF_CAIF."""
alias AF_ALG = 38
"""Constant: AF_ALG."""
alias AF_NFC = 39
"""Constant: AF_NFC."""
alias AF_VSOCK = 40
"""Constant: AF_VSOCK."""
alias AF_KCM = 41
"""Constant: AF_KCM."""
alias AF_QIPCRTR = 42
"""Constant: AF_QIPCRTR."""
alias AF_MAX = 43
"""Constant: AF_MAX."""

alias PF_UNSPEC = AF_UNSPEC
"""Constant: PF_UNSPEC."""
alias PF_UNIX = AF_UNIX
"""Constant: PF_UNIX."""
alias PF_LOCAL = AF_LOCAL
"""Constant: PF_LOCAL."""
alias PF_INET = AF_INET
"""Constant: PF_INET."""
alias PF_AX25 = AF_AX25
"""Constant: PF_AX25."""
alias PF_IPX = AF_IPX
"""Constant: PF_IPX."""
alias PF_APPLETALK = AF_APPLETALK
"""Constant: PF_APPLETALK."""
alias PF_NETROM = AF_NETROM
"""Constant: PF_NETROM."""
alias PF_BRIDGE = AF_BRIDGE
"""Constant: PF_BRIDGE."""
alias PF_ATMPVC = AF_ATMPVC
"""Constant: PF_ATMPVC."""
alias PF_X25 = AF_X25
"""Constant: PF_X25."""
alias PF_INET6 = AF_INET6
"""Constant: PF_INET6."""
alias PF_ROSE = AF_ROSE
"""Constant: PF_ROSE."""
alias PF_DECnet = AF_DECnet
"""Constant: PF_DECnet."""
alias PF_NETBEUI = AF_NETBEUI
"""Constant: PF_NETBEUI."""
alias PF_SECURITY = AF_SECURITY
"""Constant: PF_SECURITY."""
alias PF_KEY = AF_KEY
"""Constant: PF_KEY."""
alias PF_NETLINK = AF_NETLINK
"""Constant: PF_NETLINK."""
alias PF_ROUTE = AF_ROUTE
"""Constant: PF_ROUTE."""
alias PF_PACKET = AF_PACKET
"""Constant: PF_PACKET."""
alias PF_ASH = AF_ASH
"""Constant: PF_ASH."""
alias PF_ECONET = AF_ECONET
"""Constant: PF_ECONET."""
alias PF_ATMSVC = AF_ATMSVC
"""Constant: PF_ATMSVC."""
alias PF_RDS = AF_RDS
"""Constant: PF_RDS."""
alias PF_SNA = AF_SNA
"""Constant: PF_SNA."""
alias PF_IRDA = AF_IRDA
"""Constant: PF_IRDA."""
alias PF_PPPOX = AF_PPPOX
"""Constant: PF_PPPOX."""
alias PF_WANPIPE = AF_WANPIPE
"""Constant: PF_WANPIPE."""
alias PF_LLC = AF_LLC
"""Constant: PF_LLC."""
alias PF_CAN = AF_CAN
"""Constant: PF_CAN."""
alias PF_TIPC = AF_TIPC
"""Constant: PF_TIPC."""
alias PF_BLUETOOTH = AF_BLUETOOTH
"""Constant: PF_BLUETOOTH."""
alias PF_IUCV = AF_IUCV
"""Constant: PF_IUCV."""
alias PF_RXRPC = AF_RXRPC
"""Constant: PF_RXRPC."""
alias PF_ISDN = AF_ISDN
"""Constant: PF_ISDN."""
alias PF_PHONET = AF_PHONET
"""Constant: PF_PHONET."""
alias PF_IEEE802154 = AF_IEEE802154
"""Constant: PF_IEEE802154."""
alias PF_CAIF = AF_CAIF
"""Constant: PF_CAIF."""
alias PF_ALG = AF_ALG
"""Constant: PF_ALG."""
alias PF_NFC = AF_NFC
"""Constant: PF_NFC."""
alias PF_VSOCK = AF_VSOCK
"""Constant: PF_VSOCK."""
alias PF_KCM = AF_KCM
"""Constant: PF_KCM."""
alias PF_QIPCRTR = AF_QIPCRTR
"""Constant: PF_QIPCRTR."""
alias PF_MAX = AF_MAX
"""Constant: PF_MAX."""

# Socket Type constants
alias SOCK_STREAM = 1
"""Constant: SOCK_STREAM."""
alias SOCK_DGRAM = 2
"""Constant: SOCK_DGRAM."""
alias SOCK_RAW = 3
"""Constant: SOCK_RAW."""
alias SOCK_RDM = 4
"""Constant: SOCK_RDM."""
alias SOCK_SEQPACKET = 5
"""Constant: SOCK_SEQPACKET."""
alias SOCK_DCCP = 6
"""Constant: SOCK_DCCP."""
alias SOCK_PACKET = 10
"""Constant: SOCK_PACKET."""
# alias SOCK_CLOEXEC = O_CLOEXEC
# alias SOCK_NONBLOCK = O_NONBLOCK

# Internet (IP) protocols
# Updated from http://www.iana.org/assignments/protocol-numbers and other
# sources.
alias IPPROTO_IP = 0
"""internet protocol, pseudo protocol number."""
alias IPPROTO_HOPOPT = 0
"""IPv6 Hop-by-Hop Option [RFC1883]."""
alias IPPROTO_ICMP = 1
"""internet control message protocol."""
alias IPPROTO_IGMP = 2
"""Internet Group Management."""
alias IPPROTO_GGP = 3
"""gateway-gateway protocol."""
alias IPPROTO_IP_ENCAP = 4
"""IP encapsulated in IP (officially ``IP'')."""
alias IPPROTO_ST = 5
"""ST datagram mode."""
alias IPPROTO_TCP = 6
"""transmission control protocol."""
alias IPPROTO_EGP = 8
"""exterior gateway protocol."""
alias IPPROTO_IGP = 9
"""any private interior gateway (Cisco)."""
alias IPPROTO_PUP = 12
"""PARC universal packet protocol."""
alias IPPROTO_UDP = 17
"""user datagram protocol."""
alias IPPROTO_HMP = 20
"""host monitoring protocol."""
alias IPPROTO_XNS_IDP = 22
"""Xerox NS IDP."""
alias IPPROTO_RDP = 27
""""reliable datagram" protocol."""
alias IPPROTO_ISO_TP4 = 29
"""ISO Transport Protocol class 4 [RFC905]."""
alias IPPROTO_DCCP = 33
"""Datagram Congestion Control Prot. [RFC4340]."""
alias IPPROTO_XTP = 36
"""Xpress Transfer Protocol."""
alias IPPROTO_DDP = 37
"""Datagram Delivery Protocol."""
alias IPPROTO_IDPR_CMTP = 38
"""IDPR Control Message Transport."""
alias IPPROTO_IPV6 = 41
"""Internet Protocol, version 6."""
alias IPPROTO_IPV6_ROUTE = 43
"""Routing Header for IPv6."""
alias IPPROTO_IPV6_FRAG = 44
"""Fragment Header for IPv6."""
alias IPPROTO_IDRP = 45
"""Inter_Domain Routing Protocol."""
alias IPPROTO_RSVP = 46
"""Reservation Protocol."""
alias IPPROTO_GRE = 47
"""General Routing Encapsulation."""
alias IPPROTO_IPSEC_ESP = 50
"""Encap Security Payload [RFC2406]."""
alias IPPROTO_IPSEC_AH = 51
"""Authentication Header [RFC2402]."""
alias IPPROTO_SKIP = 57
"""SKIP."""
alias IPPROTO_IPV6_ICMP = 58
"""ICMP for IPv6."""
alias IPPROTO_IPV6_NONXT = 59
"""No Next Header for IPv6."""
alias IPPROTO_IPV6_OPTS = 60
"""Destination Options for IPv6."""
alias IPPROTO_RSPF_CPHB = 73
"""Radio Shortest Path First (officially CPHB)."""
alias IPPROTO_VMTP = 81
"""Versatile Message Transport."""
alias IPPROTO_EIGRP = 88
"""Enhanced Interior Routing Protocol (Cisco)."""
alias IPPROTO_OSPFIGP = 89
"""Open Shortest Path First IGP."""
alias IPPROTO_AX_25 = 93
"""AX.25 frames."""
alias IPPROTO_IPIP = 94
"""IP_within_IP Encapsulation Protocol."""
alias IPPROTO_ETHERIP = 97
"""Ethernet_within_IP Encapsulation [RFC3378]."""
alias IPPROTO_ENCAP = 98
"""Yet Another IP encapsulation [RFC1241]."""
alias IPPROTO_PIM = 103
"""Protocol Independent Multicast."""
alias IPPROTO_IPCOMP = 108
"""IP Payload Compression Protocol."""
alias IPPROTO_VRRP = 112
"""Virtual Router Redundancy Protocol [RFC5798]."""
alias IPPROTO_L2TP = 115
"""Layer Two Tunneling Protocol [RFC2661]."""
alias IPPROTO_ISIS = 124
"""IS_IS over IPv4."""
alias IPPROTO_SCTP = 132
"""Stream Control Transmission Protocol."""
alias IPPROTO_FC = 133
"""Fibre Channel."""
alias IPPROTO_MOBILITY_HEADER = 135
"""Mobility Support for IPv6 [RFC3775]."""
alias IPPROTO_UDPLITE = 136
"""UDP_Lite [RFC3828]."""
alias IPPROTO_MPLS_IN_IP = 137
"""MPLS_in_IP [RFC4023]."""
alias IPPROTO_HIP = 139
"""Host Identity Protocol."""
alias IPPROTO_SHIM6 = 140
"""Shim6 Protocol [RFC5533]."""
alias IPPROTO_WESP = 141
"""Wrapped Encapsulating Security Payload."""
alias IPPROTO_ROHC = 142
"""Robust Header Compression."""
alias IPPROTO_RAW = 255
"""Raw IP packets."""

# Address Information
alias AI_PASSIVE = 1
"""Constant: AI_PASSIVE."""
alias AI_CANONNAME = 2
"""Constant: AI_CANONNAME."""
alias AI_NUMERICHOST = 4
"""Constant: AI_NUMERICHOST."""
alias AI_V4MAPPED = 8
"""Constant: AI_V4MAPPED."""
alias AI_ALL = 16
"""Constant: AI_ALL."""
alias AI_ADDRCONFIG = 32
"""Constant: AI_ADDRCONFIG."""
alias AI_IDN = 64
"""Constant: AI_IDN."""

alias INET_ADDRSTRLEN = 16
"""Constant: INET_ADDRSTRLEN."""
alias INET6_ADDRSTRLEN = 46
"""Constant: INET6_ADDRSTRLEN."""

alias SHUT_RD = 0
"""Constant: SHUT_RD."""
alias SHUT_WR = 1
"""Constant: SHUT_WR."""
alias SHUT_RDWR = 2
"""Constant: SHUT_RDWR."""

# Socket level options (SOL_SOCKET)
alias SOL_SOCKET = 1
"""Constant: SOL_SOCKET."""

alias SO_DEBUG = 1
"""Constant: SO_DEBUG."""
alias SO_REUSEADDR = 2
"""Constant: SO_REUSEADDR."""
alias SO_TYPE = 3
"""Constant: SO_TYPE."""
alias SO_ERROR = 4
"""Constant: SO_ERROR."""
alias SO_DONTROUTE = 5
"""Constant: SO_DONTROUTE."""
alias SO_BROADCAST = 6
"""Constant: SO_BROADCAST."""
alias SO_SNDBUF = 7
"""Constant: SO_SNDBUF."""
alias SO_RCVBUF = 8
"""Constant: SO_RCVBUF."""
alias SO_KEEPALIVE = 9
"""Constant: SO_KEEPALIVE."""
alias SO_OOBINLINE = 10
"""Constant: SO_OOBINLINE."""
alias SO_NO_CHECK = 11
"""Constant: SO_NO_CHECK."""
alias SO_PRIORITY = 12
"""Constant: SO_PRIORITY."""
alias SO_LINGER = 13
"""Constant: SO_LINGER."""
alias SO_BSDCOMPAT = 14
"""Constant: SO_BSDCOMPAT."""
alias SO_REUSEPORT = 15
"""Constant: SO_REUSEPORT."""
alias SO_PASSCRED = 16
"""Constant: SO_PASSCRED."""
alias SO_PEERCRED = 17
"""Constant: SO_PEERCRED."""
alias SO_RCVLOWAT = 18
"""Constant: SO_RCVLOWAT."""
alias SO_SNDLOWAT = 19
"""Constant: SO_SNDLOWAT."""
alias SO_RCVTIMEO = 20
"""Constant: SO_RCVTIMEO."""
alias SO_SNDTIMEO = 21
"""Constant: SO_SNDTIMEO."""
alias SO_SECURITY_AUTHENTICATION = 22
"""Constant: SO_SECURITY_AUTHENTICATION."""
alias SO_SECURITY_ENCRYPTION_TRANSPORT = 23
"""Constant: SO_SECURITY_ENCRYPTION_TRANSPORT."""
alias SO_SECURITY_ENCRYPTION_NETWORK = 24
"""Constant: SO_SECURITY_ENCRYPTION_NETWORK."""
alias SO_BINDTODEVICE = 25
"""Constant: SO_BINDTODEVICE."""
alias SO_ATTACH_FILTER = 26
"""Constant: SO_ATTACH_FILTER."""
alias SO_DETACH_FILTER = 27
"""Constant: SO_DETACH_FILTER."""
alias SO_GET_FILTER = SO_ATTACH_FILTER
"""Constant: SO_GET_FILTER."""
alias SO_PEERNAME = 28
"""Constant: SO_PEERNAME."""
alias SO_TIMESTAMP = 29
"""Constant: SO_TIMESTAMP."""
alias SO_ACCEPTCONN = 30
"""Constant: SO_ACCEPTCONN."""
alias SO_PEERSEC = 31
"""Constant: SO_PEERSEC."""
alias SO_SNDBUFFORCE = 32
"""Constant: SO_SNDBUFFORCE."""
alias SO_RCVBUFFORCE = 33
"""Constant: SO_RCVBUFFORCE."""
alias SO_PASSSEC = 34
"""Constant: SO_PASSSEC."""
alias SO_TIMESTAMPNS = 35
"""Constant: SO_TIMESTAMPNS."""
alias SO_MARK = 36
"""Constant: SO_MARK."""
alias SO_TIMESTAMPING = 37
"""Constant: SO_TIMESTAMPING."""
alias SO_PROTOCOL = 38
"""Constant: SO_PROTOCOL."""
alias SO_DOMAIN = 39
"""Constant: SO_DOMAIN."""
alias SO_RXQ_OVFL = 40
"""Constant: SO_RXQ_OVFL."""
alias SO_WIFI_STATUS = 41
"""Constant: SO_WIFI_STATUS."""
alias SCM_WIFI_STATUS = SO_WIFI_STATUS
"""Constant: SCM_WIFI_STATUS."""
alias SO_PEEK_OFF = 42
"""Constant: SO_PEEK_OFF."""
alias SO_NOFCS = 43
"""Constant: SO_NOFCS."""
alias SO_LOCK_FILTER = 44
"""Constant: SO_LOCK_FILTER."""
alias SO_SELECT_ERR_QUEUE = 45
"""Constant: SO_SELECT_ERR_QUEUE."""
alias SO_BUSY_POLL = 46
"""Constant: SO_BUSY_POLL."""
alias SO_MAX_PACING_RATE = 47
"""Constant: SO_MAX_PACING_RATE."""
alias SO_BPF_EXTENSIONS = 48
"""Constant: SO_BPF_EXTENSIONS."""
alias SO_INCOMING_CPU = 49
"""Constant: SO_INCOMING_CPU."""
alias SO_ATTACH_BPF = 50
"""Constant: SO_ATTACH_BPF."""
alias SO_DETACH_BPF = SO_DETACH_FILTER
"""Constant: SO_DETACH_BPF."""
alias SO_ATTACH_REUSEPORT_CBPF = 51
"""Constant: SO_ATTACH_REUSEPORT_CBPF."""
alias SO_ATTACH_REUSEPORT_EBPF = 52
"""Constant: SO_ATTACH_REUSEPORT_EBPF."""
alias SO_CNX_ADVICE = 53
"""Constant: SO_CNX_ADVICE."""
alias SCM_TIMESTAMPING_OPT_STATS = 54
"""Constant: SCM_TIMESTAMPING_OPT_STATS."""
alias SO_MEMINFO = 55
"""Constant: SO_MEMINFO."""
alias SO_INCOMING_NAPI_ID = 56
"""Constant: SO_INCOMING_NAPI_ID."""
alias SO_COOKIE = 57
"""Constant: SO_COOKIE."""
alias SCM_TIMESTAMPING_PKTINFO = 58
"""Constant: SCM_TIMESTAMPING_PKTINFO."""
alias SO_PEERGROUPS = 59
"""Constant: SO_PEERGROUPS."""
alias SO_ZEROCOPY = 60
"""Constant: SO_ZEROCOPY."""
alias SO_TXTIME = 61
"""Constant: SO_TXTIME."""
alias SCM_TXTIME = SO_TXTIME
"""Constant: SCM_TXTIME."""
alias SO_BINDTOIFINDEX = 62
"""Constant: SO_BINDTOIFINDEX."""
alias SO_TIMESTAMP_NEW = 63
"""Constant: SO_TIMESTAMP_NEW."""
alias SO_TIMESTAMPNS_NEW = 64
"""Constant: SO_TIMESTAMPNS_NEW."""
alias SO_TIMESTAMPING_NEW = 65
"""Constant: SO_TIMESTAMPING_NEW."""
alias SO_RCVTIMEO_NEW = 66
"""Constant: SO_RCVTIMEO_NEW."""
alias SO_SNDTIMEO_NEW = 67
"""Constant: SO_SNDTIMEO_NEW."""
alias SO_DETACH_REUSEPORT_BPF = 68
"""Constant: SO_DETACH_REUSEPORT_BPF."""

# TCP level options (IPPROTO_TCP)
alias TCP_NODELAY = 1
"""Constant: TCP_NODELAY."""
alias TCP_KEEPIDLE = 2
"""Constant: TCP_KEEPIDLE."""
alias TCP_KEEPINTVL = 3
"""Constant: TCP_KEEPINTVL."""
alias TCP_KEEPCNT = 4
"""Constant: TCP_KEEPCNT."""

# IPv4 level options (IPPROTO_IP)
alias IP_TOS = 1
"""IP type of service and precedence."""
alias IP_TTL = 2
"""IP time to live."""
alias IP_HDRINCL = 3
"""Header is included with data."""
alias IP_OPTIONS = 4
"""IP per-packet options."""
alias IP_RECVOPTS = 6
"""Receive all IP options w/datagram."""
alias IP_RETOPTS = 7
"""Set/get IP per-packet options."""
alias IP_RECVRETOPTS = IP_RETOPTS
"""Receive IP options for response."""
alias IP_MULTICAST_IF = 32
"""Set/get IP multicast i/f."""
alias IP_MULTICAST_TTL = 33
"""Set/get IP multicast ttl."""
alias IP_MULTICAST_LOOP = 34
"""Set/get IP multicast loopback."""
alias IP_ADD_MEMBERSHIP = 35
"""Add an IP group membership."""
alias IP_DROP_MEMBERSHIP = 36
"""Drop an IP group membership."""
alias IP_UNBLOCK_SOURCE = 37
"""Unblock data from source."""
alias IP_BLOCK_SOURCE = 38
"""Block data from source."""
alias IP_ADD_SOURCE_MEMBERSHIP = 39
"""Join source group."""
alias IP_DROP_SOURCE_MEMBERSHIP = 40
"""Leave source group."""
alias IP_MSFILTER = 41

# IPv6 level options (IPPROTO_IPV6)
alias IPV6_ADDRFORM = 1
"""Constant: IPV6_ADDRFORM."""
alias IPV6_2292PKTINFO = 2
"""Constant: IPV6_2292PKTINFO."""
alias IPV6_2292HOPOPTS = 3
"""Constant: IPV6_2292HOPOPTS."""
alias IPV6_2292DSTOPTS = 4
"""Constant: IPV6_2292DSTOPTS."""
alias IPV6_2292RTHDR = 5
"""Constant: IPV6_2292RTHDR."""
alias IPV6_2292PKTOPTIONS = 6
"""Constant: IPV6_2292PKTOPTIONS."""
alias IPV6_CHECKSUM = 7
"""Constant: IPV6_CHECKSUM."""
alias IPV6_2292HOPLIMIT = 8
"""Constant: IPV6_2292HOPLIMIT."""
alias IPV6_NEXTHOP = 9
"""Constant: IPV6_NEXTHOP."""
alias IPV6_AUTHHDR = 10
"""Constant: IPV6_AUTHHDR."""
alias IPV6_UNICAST_HOPS = 16
"""Constant: Set the unicast hop limit for the socket."""
alias IPV6_MULTICAST_IF = 17
"""Constant: IPV6_MULTICAST_IF."""
alias IPV6_MULTICAST_HOPS = 18
"""Constant: Set the multicast hop limit for the socket."""
alias IPV6_MULTICAST_LOOP = 19
"""Constant: IPV6_MULTICAST_LOOP."""
alias IPV6_JOIN_GROUP = 20
"""Constant: Join IPv6 multicast group."""
alias IPV6_LEAVE_GROUP = 21
"""Constant: Leave IPv6 multicast group."""
alias IPV6_ROUTER_ALERT = 22
"""Constant: IPV6_ROUTER_ALERT."""
alias IPV6_MTU_DISCOVER = 23
"""Constant: IPV6_MTU_DISCOVER."""
alias IPV6_MTU = 24
"""Constant: IPV6_MTU."""
alias IPV6_RECVERR = 25
"""Constant: IPV6_RECVERR."""
alias IPV6_V6ONLY = 26
"""Constant: Don't support IPv4 access."""
alias IPV6_JOIN_ANYCAST = 27
"""Constant: IPV6_JOIN_ANYCAST."""
alias IPV6_LEAVE_ANYCAST = 28
"""Constant: IPV6_LEAVE_ANYCAST."""
alias IPV6_IPSEC_POLICY = 34
"""Constant: IPV6_IPSEC_POLICY."""
alias IPV6_XFRM_POLICY = 35
"""Constant: IPV6_XFRM_POLICY."""
alias IPV6_RECVPKTINFO = 49
"""Pass an IPV6_RECVPKTINFO ancillary message that contains a in6_pktinfo
structure that supplies some information about the incoming packet."""
alias IPV6_PKTINFO = 50
"""Constant: IPV6_PKTINFO."""
alias IPV6_RECVHOPLIMIT = 51
"""Constant: IPV6_RECVHOPLIMIT."""
alias IPV6_HOPLIMIT = 52
"""Constant: IPV6_HOPLIMIT."""
alias IPV6_RECVHOPOPTS = 53
"""Constant: IPV6_RECVHOPOPTS."""
alias IPV6_HOPOPTS = 54
"""Constant: IPV6_HOPOPTS."""
alias IPV6_RTHDRDSTOPTS = 55
"""Constant: IPV6_RTHDRDSTOPTS."""
alias IPV6_RECVRTHDR = 56
"""Constant: IPV6_RECVRTHDR."""
alias IPV6_RTHDR = 57
"""Constant: IPV6_RTHDR."""
alias IPV6_RECVDSTOPTS = 58
"""Constant: IPV6_RECVDSTOPTS."""
alias IPV6_DSTOPTS = 59
"""Constant: IPV6_DSTOPTS."""
alias IPV6_RECVTCLASS = 66
"""Constant: IPV6_RECVTCLASS."""
alias IPV6_TCLASS = 67
"""Constant: IPV6_TCLASS."""
alias IPV6_ADDR_PREFERENCES = 72
"""RFC5014: Source address selection."""
alias IPV6_PREFER_SRC_TMP = 0x0001
"""Prefer temporary address as source."""
alias IPV6_PREFER_SRC_PUBLIC = 0x0002
"""Prefer public address as source."""
alias IPV6_PREFER_SRC_PUBTMP_DEFAULT = 0x0100
"""Either public or temporary address is selected as a default source depending
on the output interface configuration (this is the default value)."""
alias IPV6_PREFER_SRC_COA = 0x0004
"""Prefer Care-of address as source."""
alias IPV6_PREFER_SRC_HOME = 0x0400
"""Prefer Home address as source."""
alias IPV6_PREFER_SRC_CGA = 0x0008
"""Prefer CGA (Cryptographically Generated Address) address as source."""
alias IPV6_PREFER_SRC_NONCGA = 0x0800
"""Prefer non-CGA address as source."""

# Obsolete synonyms for the above.
alias IPV6_ADD_MEMBERSHIP = IPV6_JOIN_GROUP
"""Constant: IPV6_ADD_MEMBERSHIP."""
alias IPV6_DROP_MEMBERSHIP = IPV6_LEAVE_GROUP
"""Constant: IPV6_DROP_MEMBERSHIP."""
alias IPV6_RXHOPOPTS = IPV6_HOPOPTS
"""Constant: IPV6_RXHOPOPTS."""
alias IPV6_RXDSTOPTS = IPV6_DSTOPTS
"""Constant: IPV6_RXDSTOPTS."""

# IPV6_MTU_DISCOVER values.
alias IPV6_PMTUDISC_DONT = 0
"""Never send DF frames."""
alias IPV6_PMTUDISC_WANT = 1
"""Use per route hints."""
alias IPV6_PMTUDISC_DO = 2
"""Always DF."""
alias IPV6_PMTUDISC_PROBE = 3
"""Ignore dst pmtu."""

# ===----------------------------------------------------------------------=== #
# File constants
# ===----------------------------------------------------------------------=== #

alias FM_READ = "r"
"""Constant: FM_READ."""
alias FM_WRITE = "w"
"""Constant: FM_WRITE."""
alias FM_APPEND = "a"
"""Constant: FM_APPEND."""
alias FM_BINARY = "b"
"""Constant: FM_BINARY."""
alias FM_PLUS = "+"
"""Constant: FM_PLUS."""

alias SEEK_SET = 0
"""Constant: SEEK_SET."""
alias SEEK_CUR = 1
"""Constant: SEEK_CUR."""
alias SEEK_END = 2
"""Constant: SEEK_END."""

alias O_RDONLY = 0
"""Constant: O_RDONLY."""
alias O_WRONLY = 1
"""Constant: O_WRONLY."""
alias O_RDWR = 2
"""Constant: O_RDWR."""
alias O_APPEND = 8
"""Constant: O_APPEND."""
alias O_CREAT = 512
"""Constant: O_CREAT."""
alias O_TRUNC = 1024
"""Constant: O_TRUNC."""
alias O_EXCL = 2048
"""Constant: O_EXCL."""
alias O_SYNC = 8192
"""Constant: O_SYNC."""
alias O_NONBLOCK = 16384
"""Constant: O_NONBLOCK."""
alias O_ACCMODE = 3
"""Constant: O_ACCMODE."""
alias O_CLOEXEC = 524288
"""Constant: O_CLOEXEC."""

# from fcntl.h
alias O_EXEC = -1
"""Constant: O_EXEC."""
alias O_SEARCH = -1
"""Constant: O_SEARCH."""
alias O_DIRECTORY = -1
"""Constant: O_DIRECTORY."""
alias O_DSYNC = -1
"""Constant: O_DSYNC."""
alias O_NOCTTY = -1
"""Constant: O_NOCTTY."""
alias O_NOFOLLOW = -1
"""Constant: O_NOFOLLOW."""
alias O_RSYNC = -1
"""Constant: O_RSYNC."""
alias O_TTY_INIT = -1
"""Constant: O_TTY_INIT."""

alias STDIN_FILENO = 0
"""Constant: STDIN_FILENO."""
alias STDOUT_FILENO = 1
"""Constant: STDOUT_FILENO."""
alias STDERR_FILENO = 2
"""Constant: STDERR_FILENO."""

alias F_DUPFD = 0
"""Constant: F_DUPFD."""
alias F_GETFD = 1
"""Constant: F_GETFD."""
alias F_SETFD = 2
"""Constant: F_SETFD."""
alias F_GETFL = 3
"""Constant: F_GETFL."""
alias F_SETFL = 4
"""Constant: F_SETFL."""
alias F_GETOWN = 5
"""Constant: F_GETOWN."""
alias F_SETOWN = 6
"""Constant: F_SETOWN."""
alias F_GETLK = 7
"""Constant: F_GETLK."""
alias F_SETLK = 8
"""Constant: F_SETLK."""
alias F_SETLKW = 9
"""Constant: F_SETLKW."""
alias F_RGETLK = 10
"""Constant: F_RGETLK."""
alias F_RSETLK = 11
"""Constant: F_RSETLK."""
alias F_CNVT = 12
"""Constant: F_CNVT."""
alias F_RSETLKW = 13
"""Constant: F_RSETLKW."""
alias F_DUPFD_CLOEXEC = 14
"""Constant: F_DUPFD_CLOEXEC."""

# TODO
alias FD_CLOEXEC = -1
"""Constant: FD_CLOEXEC."""
alias F_RDLCK = -1
"""Constant: F_RDLCK."""
alias F_UNLCK = -1
"""Constant: F_UNLCK."""
alias F_WRLCK = -1
"""Constant: F_WRLCK."""

alias AT_EACCESS = 512
"""Constant: AT_EACCESS."""
alias AT_FDCWD = -100
"""Constant: AT_FDCWD."""
alias AT_SYMLINK_NOFOLLOW = 256
"""Constant: AT_SYMLINK_NOFOLLOW."""
alias AT_REMOVEDIR = 512
"""Constant: AT_REMOVEDIR."""
alias AT_SYMLINK_FOLLOW = 1024
"""Constant: AT_SYMLINK_FOLLOW."""
alias AT_NO_AUTOMOUNT = 2048
"""Constant: AT_NO_AUTOMOUNT."""
alias AT_EMPTY_PATH = 4096
"""Constant: AT_EMPTY_PATH."""
alias AT_RECURSIVE = 32768
"""Constant: AT_RECURSIVE."""


# ===----------------------------------------------------------------------=== #
# Logging constants
# ===----------------------------------------------------------------------=== #


alias LOG_PID = -1
"""Constant: LOG_PID."""
alias LOG_CONS = -1
"""Constant: LOG_CONS."""
alias LOG_NDELAY = -1
"""Constant: LOG_NDELAY."""
alias LOG_ODELAY = -1
"""Constant: LOG_ODELAY."""
alias LOG_NOWAIT = -1
"""Constant: LOG_NOWAIT."""
alias LOG_KERN = -1
"""Constant: LOG_KERN."""
alias LOG_USER = -1
"""Constant: LOG_USER."""
alias LOG_MAIL = -1
"""Constant: LOG_MAIL."""
alias LOG_NEWS = -1
"""Constant: LOG_NEWS."""
alias LOG_UUCP = -1
"""Constant: LOG_UUCP."""
alias LOG_DAEMON = -1
"""Constant: LOG_DAEMON."""
alias LOG_AUTH = -1
"""Constant: LOG_AUTH."""
alias LOG_CRON = -1
"""Constant: LOG_CRON."""
alias LOG_LPR = -1
"""Constant: LOG_LPR."""
alias LOG_LOCAL0 = -1
"""Constant: LOG_LOCAL0."""
alias LOG_LOCAL1 = -1
"""Constant: LOG_LOCAL1."""
alias LOG_LOCAL2 = -1
"""Constant: LOG_LOCAL2."""
alias LOG_LOCAL3 = -1
"""Constant: LOG_LOCAL3."""
alias LOG_LOCAL4 = -1
"""Constant: LOG_LOCAL4."""
alias LOG_LOCAL5 = -1
"""Constant: LOG_LOCAL5."""
alias LOG_LOCAL6 = -1
"""Constant: LOG_LOCAL6."""
alias LOG_LOCAL7 = -1
"""Constant: LOG_LOCAL7."""
alias LOG_MASK = -1  # (pri)
"""Constant: LOG_MASK."""
alias LOG_EMERG = -1
"""Constant: LOG_EMERG."""
alias LOG_ALERT = -1
"""Constant: LOG_ALERT."""
alias LOG_CRIT = -1
"""Constant: LOG_CRIT."""
alias LOG_ERR = -1
"""Constant: LOG_ERR."""
alias LOG_WARNING = -1
"""Constant: LOG_WARNING."""
alias LOG_NOTICE = -1
"""Constant: LOG_NOTICE."""
alias LOG_INFO = -1
"""Constant: LOG_INFO."""
alias LOG_DEBUG = -1
"""Constant: LOG_DEBUG."""
