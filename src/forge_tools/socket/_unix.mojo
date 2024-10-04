from collections import Optional
from memory import UnsafePointer, stack_allocation
from utils import Span, StaticTuple, StringSlice
from sys.intrinsics import _type_is_eq
from sys import sizeof
from .socket import (
    # SocketInterface,
    SockFamily,
    SockType,
    SockProtocol,
)
from .address import SockAddr, IPv4Addr, IPv6Addr
from forge_tools.ffi.c import (
    AF_INET,
    AF_INET6,
    AF_UNIX,
    AF_NETLINK,
    AF_TIPC,
    AF_CAN,
    AF_BLUETOOTH,
    AF_ALG,
    AF_VSOCK,
    AF_PACKET,
    AF_QIPCRTR,
    SOCK_STREAM,
    SOCK_DGRAM,
    SOCK_RAW,
    SOCK_RDM,
    SOCK_SEQPACKET,
    IPPROTO_TCP,
    IPPROTO_UDP,
    IPPROTO_SCTP,
    IPPROTO_UDPLITE,
    C,
    socket,
    htons,
    in_addr,
    sockaddr,
    sockaddr_in,
    socklen_t,
    shutdown,
    SHUT_RDWR,
    bind,
    listen,
    connect,
    accept,
    send,
    recv,
    char_ptr_to_string,
    inet_pton,
    sa_family_t,
    IPPROTO_IPV6,
    IPV6_V6ONLY,
    NULL,
    setsockopt,
    addrinfo,
    getaddrinfo,
    strlen,
    SOL_SOCKET,
    SO_REUSEADDR,
    SO_REUSEPORT,
    errno,
    strerror,
    STDERR_FILENO,
)


@value
struct _UnixSocket[
    sock_family: SockFamily,
    sock_type: SockType,
    sock_protocol: SockProtocol,
    sock_address: SockAddr,
]:
    """Generic POSIX compliant socket implementation."""

    var fd: FileDescriptor
    """The Socket's `FileDescriptor`."""
    alias _sock_family = _get_unix_sock_family_constant(sock_family)
    alias _sock_type = _get_unix_sock_type_constant(sock_type)
    alias _sock_protocol = _get_unix_sock_protocol_constant(sock_protocol)

    fn __init__(inout self) raises:
        """Create a new socket object."""
        var fd = socket(Self._sock_family, Self._sock_type, Self._sock_protocol)
        if fd == -1:
            var message = char_ptr_to_string(strerror(errno()))
            raise Error("Failed to create socket: " + message)
        self.fd = FileDescriptor(int(fd))

    fn __init__(inout self, fd: FileDescriptor):
        """Create a new socket object from an open `FileDescriptor`."""
        self.fd = fd

    fn close(owned self) raises:
        """Closes the Socket."""
        _ = self^

    fn __del__(owned self):
        """Closes the Socket if it's the last reference to its
        `FileDescriptor`.
        """
        try:
            var err = shutdown(self.fd.value, SHUT_RDWR)
            if err == -1:
                var message = char_ptr_to_string(strerror(errno()))
                raise Error("Failed trying to close the socket: " + message)
        except e:
            print(e, file=STDERR_FILENO)

    fn setsockopt(self, level: Int, option_name: Int, option_value: Int) raises:
        """Set socket options."""
        var ptr = stack_allocation[1, Int]()
        ptr[0] = option_value
        var cvoid = ptr.bitcast[C.void]()
        var s = sizeof[Int]()
        if setsockopt(self.fd.value, level, option_name, cvoid, s) == -1:
            var message = char_ptr_to_string(strerror(errno()))
            raise Error("Failed to set socket options: " + message)

    fn bind(self, address: sock_address) raises:
        """Bind the socket to address. The socket must not already be bound."""

        @parameter
        if _type_is_eq[sock_address, IPv4Addr]():
            var addr = rebind[IPv4Addr](address)
            var port = htons(addr.port)
            var ip_buf = stack_allocation[4, C.void]()
            var ip_ptr = addr.host.unsafe_ptr().bitcast[C.char]()
            var err = inet_pton(Self._sock_family, ip_ptr, ip_buf)
            if err == 0:
                raise Error("Invalid Address.")
            var ip = ip_buf.bitcast[C.u_int]().load()
            var zero = StaticTuple[C.char, 8]()
            var ai = sockaddr_in(Self._sock_family, port, ip, zero)
            var ai_ptr = UnsafePointer.address_of(ai).bitcast[sockaddr]()
            if bind(self.fd.value, ai_ptr, sizeof[sockaddr_in]()) == -1:
                _ = ai
                var message = char_ptr_to_string(strerror(errno()))
                raise Error("Failed to bind the socket: " + message)
            _ = ai
        else:
            constrained[False, "Currently unsupported Address type"]()
            raise Error("Failed to bind the socket.")

    fn listen(self, backlog: UInt = 0) raises:
        """Enable a server to accept connections. `backlog` specifies the number
        of unaccepted connections that the system will allow before refusing
        new connections. If `backlog == 0`, a default value is chosen.
        """
        if listen(self.fd.value, C.int(backlog)) == -1:
            var message = char_ptr_to_string(strerror(errno()))
            raise Error("Failed to listen on socket: " + message)

    async fn connect(self, address: sock_address) raises:
        """Connect to a remote socket at address."""

        @parameter
        if _type_is_eq[sock_address, IPv4Addr]():
            var addr = rebind[IPv4Addr](address)
            var port = htons(addr.port)
            var ip_buf = stack_allocation[4, C.void]()
            var ip_ptr = addr.host.unsafe_ptr().bitcast[C.char]()
            var err = inet_pton(Self._sock_family, ip_ptr, ip_buf)
            if err == 0:
                raise Error("Invalid Address.")
            var ip = ip_buf.bitcast[C.u_int]().load()
            var zero = StaticTuple[C.char, 8]()
            var ai = sockaddr_in(Self._sock_family, port, ip, zero)
            var ai_ptr = UnsafePointer.address_of(ai).bitcast[sockaddr]()
            if connect(self.fd.value, ai_ptr, sizeof[sockaddr_in]()) == -1:
                _ = ai
                var message = char_ptr_to_string(strerror(errno()))
                raise Error("Failed to create socket: " + message)
            _ = ai
        else:
            constrained[False, "currently unsupported Address type"]()
            raise Error("Failed to create socket.")

    async fn accept(self) raises -> (Self, sock_address):
        """Return a new socket representing the connection, and the address of
        the client.
        """

        @parameter
        if _type_is_eq[sock_address, IPv4Addr]():
            var addr_ptr = stack_allocation[1, sockaddr]()
            var sin_size = socklen_t(sizeof[socklen_t]())
            var size_ptr = UnsafePointer[socklen_t].address_of(sin_size)
            var fd = accept(self.fd.value, addr_ptr, size_ptr)
            _ = sin_size
            if fd == -1:
                var message = char_ptr_to_string(strerror(errno()))
                raise Error("Failed to create socket: " + message)
            var sa_family = addr_ptr.bitcast[sa_family_t]()[0]
            if sa_family != Self._sock_family:
                raise Error("Wrong Address Family for this socket.")
            var ptr = (addr_ptr.bitcast[sa_family_t]() + 1).bitcast[C.char]()
            var addr_str = String(ptr=ptr.bitcast[UInt8](), len=int(sin_size))
            return Self(fd=int(fd)), sock_address(addr_str^)
        else:
            constrained[False, "currently unsupported Address type"]()
            raise Error("Failed to create socket.")

    @staticmethod
    async fn socketpair() raises -> (Self, Self):
        """Create a pair of socket objects from the sockets returned by the
        platform `socketpair()` function."""
        raise Error("Failed to create socket.")

    fn getfd(self) -> FileDescriptor:
        """Get an ARC reference to the Socket's FileDescriptor.

        Returns:
            The ARC pointer to the FileDescriptor.
        """
        return 0

    @staticmethod
    async fn fromfd(fd: FileDescriptor) -> Optional[Self]:
        """Create a socket object from an open file descriptor."""
        return None

    async fn send_fds(self, fds: List[FileDescriptor]) -> Bool:
        """Send file descriptors to the socket."""
        return False

    async fn recv_fds(self, maxfds: Int) -> List[FileDescriptor]:
        """Receive file descriptors from the socket."""
        return List[FileDescriptor]()

    async fn send(self, buf: Span[UInt8], flags: Int = 0) -> Int:
        """Send a buffer of bytes to the socket."""
        var ptr = buf.unsafe_ptr().bitcast[C.void]()
        return int(send(self.fd.value, ptr, len(buf), flags))

    async fn recv(self, buf: Span[UInt8], flags: Int = 0) -> Int:
        """Receive up to `len(buf)` bytes into the buffer."""
        var ptr = buf.unsafe_ptr().bitcast[C.void]()
        return int(recv(self.fd.value, ptr, len(buf), flags))

    @staticmethod
    fn gethostname() -> Optional[String]:
        """Return the current hostname."""
        return None

    @staticmethod
    fn gethostbyname(name: String) -> Optional[sock_address]:
        """Map a hostname to its Address."""
        return None

    @staticmethod
    fn gethostbyaddr(address: sock_address) -> Optional[String]:
        """Map an Address to DNS info."""
        return None

    @staticmethod
    fn getservbyname(name: String) -> Optional[sock_address]:
        """Map a service name and a protocol name to a port number."""
        return None

    @staticmethod
    fn getdefaulttimeout() -> Optional[Float64]:
        """Get the default timeout value."""
        return None

    @staticmethod
    fn setdefaulttimeout(value: Optional[Float64]) -> Bool:
        """Set the default timeout value."""
        return False

    fn settimeout(self, value: Optional[Float64]) -> Bool:
        """Set the socket timeout value."""
        return False

    # TODO: should this return an iterator instead?
    @staticmethod
    fn getaddrinfo(
        address: sock_address, flags: Int = 0
    ) raises -> List[
        (SockFamily, SockType, SockProtocol, String, sock_address)
    ]:
        """Get the available address information.
        
        Notes:
            [Reference](\
            https://man7.org/linux/man-pages/man3/freeaddrinfo.3p.html).
        """
        var info = List[
            Tuple[SockFamily, SockType, SockProtocol, String, sock_address]
        ]()
        var hints = addrinfo()
        hints.ai_family = Self._sock_family
        hints.ai_socktype = Self._sock_type
        hints.ai_flags = flags
        hints.ai_protocol = Self._sock_protocol
        var hints_p = UnsafePointer[addrinfo].address_of(hints)
        var nodename = str(address)
        var nodename_p = nodename.unsafe_ptr().bitcast[C.char]()
        var servname_p = NULL.bitcast[C.char]()
        var result = addrinfo()
        alias UP = UnsafePointer
        var res_p = C.ptr_addr(int(UP[addrinfo].address_of(result)))
        var res_p_p = UP[C.ptr_addr].address_of(res_p)
        var err = getaddrinfo(nodename_p, servname_p, hints_p, res_p_p)
        if err != 0:
            raise Error("Error in getaddrinfo(). Code: " + str(err))
        var next_addr = NULL
        var first = True
        while first or next_addr != NULL:
            first = False
            var af = _parse_unix_sock_family_constant(int(result.ai_family))
            var st = _parse_unix_sock_type_constant(int(result.ai_socktype))
            var pt = _parse_unix_sock_protocol_constant(int(result.ai_protocol))
            var addrlen = int(result.ai_addrlen)
            var addr_ptr = result.ai_addr.bitcast[UInt8]()
            alias S = StringSlice[ImmutableAnyLifetime]
            var addr = String(S(unsafe_from_utf8_ptr=addr_ptr, len=addrlen))
            var can = String()
            if flags != 0:
                var p = result.ai_canonname
                var l = int(strlen(p))
                can = String(S(unsafe_from_utf8_ptr=p.bitcast[UInt8](), len=l))
            info.append((af, st, pt, can^, sock_address(addr^)))
            result = next_addr.bitcast[addrinfo]()[0]
            next_addr = result.ai_next
        return info^

    @staticmethod
    fn create_connection(
        address: IPv4Addr,
        timeout: Optional[Float64] = None,
        source_address: IPv4Addr = IPv4Addr(),
        *,
        all_errors: Bool = False,
    ) raises -> Self:
        """Connects to an address, with an optional timeout and optional source
        address."""
        alias cond = _type_is_eq[sock_address, IPv4Addr]()
        constrained[cond, "sock_address must be IPv4Addr"]()
        var errors = List[String]()
        var idx = 0
        var time = timeout.value() if timeout else Self.getdefaulttimeout()
        for res in Self.getaddrinfo(rebind[sock_address](address)):
            try:
                var socket = Self()
                _ = socket.settimeout(time)
                socket.bind(rebind[sock_address](source_address))
                await socket.connect(res[][4])
                return socket^
            except e:
                errors[idx] = str(e)
                if all_errors:
                    idx += 1

        raise Error(String("; ").join(errors))  # TODO: need ErrorGroup

    @staticmethod
    fn create_connection(
        address: IPv6Addr,
        timeout: Optional[Float64] = None,
        source_address: IPv6Addr = IPv6Addr(),
        *,
        all_errors: Bool = False,
    ) raises -> Self:
        """Connects to an address, with an optional timeout and optional source
        address."""
        alias cond = _type_is_eq[sock_address, IPv6Addr]()
        constrained[cond, "sock_address must be IPv6Addr"]()
        var errors = List[String]()
        var idx = 0
        var time = timeout.value() if timeout else Self.getdefaulttimeout()
        for res in Self.getaddrinfo(rebind[sock_address](address)):
            try:
                var socket = Self()
                _ = socket.settimeout(time)
                socket.bind(rebind[sock_address](source_address))
                await socket.connect(res[][4])
                return socket^
            except e:
                errors[idx] = str(e)
                if all_errors:
                    idx += 1

        raise Error(String("; ").join(errors))  # TODO: need ErrorGroup

    @staticmethod
    fn create_server(
        address: IPv4Addr,
        *,
        backlog: Optional[Int] = None,
        reuse_port: Bool = False,
    ) raises -> Self:
        """Create a socket, bind it to a specified address, and listen."""
        alias cond = _type_is_eq[sock_address, IPv4Addr]()
        constrained[cond, "sock_address must be IPv4Addr"]()
        var socket = Self()
        socket.setsockopt(SOL_SOCKET, SO_REUSEADDR, 1)
        if reuse_port:
            socket.setsockopt(SOL_SOCKET, SO_REUSEPORT, 1)
        socket.bind(rebind[sock_address](address))
        socket.listen(backlog=backlog.value() if backlog else 0)
        return socket^

    @staticmethod
    fn create_server(
        address: IPv6Addr,
        *,
        backlog: Optional[Int] = None,
        reuse_port: Bool = False,
    ) raises -> Self:
        """Create a socket, bind it to a specified address, and listen. Default
        no dual stack IPv6."""
        alias cond = _type_is_eq[sock_address, IPv6Addr]()
        constrained[cond, "sock_address must be IPv6Addr"]()
        var socket = Self()
        socket.setsockopt(SOL_SOCKET, SO_REUSEADDR, 1)
        socket.setsockopt(IPPROTO_IPV6, IPV6_V6ONLY, 1)
        if reuse_port:
            socket.setsockopt(SOL_SOCKET, SO_REUSEPORT, 1)
        socket.bind(rebind[sock_address](address))
        socket.listen(backlog=backlog.value() if backlog else 0)
        return socket^

    @staticmethod
    fn create_server(
        address: IPv6Addr,
        *,
        dualstack_ipv6: Bool,
        backlog: Optional[Int] = None,
        reuse_port: Bool = False,
    ) raises -> (
        Self,
        _UnixSocket[SockFamily.AF_INET, sock_type, sock_protocol, IPv4Addr],
    ):
        """Create a socket, bind it to a specified address, and listen."""
        alias S = _UnixSocket[
            SockFamily.AF_INET, sock_type, sock_protocol, IPv4Addr
        ]
        alias cond = _type_is_eq[sock_address, IPv6Addr]()
        constrained[cond, "sock_address must be IPv6Addr"]()
        var ipv6_sock = Self()
        ipv6_sock.setsockopt(SOL_SOCKET, SO_REUSEADDR, 1)
        if dualstack_ipv6:
            ipv6_sock.setsockopt(IPPROTO_IPV6, IPV6_V6ONLY, 0)
        else:
            ipv6_sock.setsockopt(IPPROTO_IPV6, IPV6_V6ONLY, 1)
        if reuse_port:
            ipv6_sock.setsockopt(SOL_SOCKET, SO_REUSEPORT, 1)
        ipv6_sock.bind(rebind[sock_address](address))
        ipv6_sock.listen(backlog=backlog.value() if backlog else 0)
        return ipv6_sock^, S(fd=ipv6_sock.fd) if dualstack_ipv6 else S()


@always_inline("nodebug")
fn _get_unix_sock_family_constant(sock_family: SockFamily) -> Int:
    if sock_family is SockFamily.AF_INET:
        return AF_INET
    elif sock_family is SockFamily.AF_INET6:
        return AF_INET6
    elif sock_family is SockFamily.AF_UNIX:
        return AF_UNIX
    elif sock_family is SockFamily.AF_NETLINK:
        return AF_NETLINK
    elif sock_family is SockFamily.AF_TIPC:
        return AF_TIPC
    elif sock_family is SockFamily.AF_CAN:
        return AF_CAN
    elif sock_family is SockFamily.AF_BLUETOOTH:
        return AF_BLUETOOTH
    elif sock_family is SockFamily.AF_ALG:
        return AF_ALG
    elif sock_family is SockFamily.AF_VSOCK:
        return AF_VSOCK
    elif sock_family is SockFamily.AF_PACKET:
        return AF_PACKET
    elif sock_family is SockFamily.AF_QIPCRTR:
        return AF_QIPCRTR
    else:
        return -1


@always_inline("nodebug")
fn _get_unix_sock_type_constant(sock_type: SockType) -> Int:
    if sock_type is SockType.SOCK_STREAM:
        return SOCK_STREAM
    elif sock_type is SockType.SOCK_DGRAM:
        return SOCK_DGRAM
    elif sock_type is SockType.SOCK_RAW:
        return SOCK_RAW
    elif sock_type is SockType.SOCK_RDM:
        return SOCK_RDM
    elif sock_type is SockType.SOCK_SEQPACKET:
        return SOCK_SEQPACKET
    else:
        return -1


@always_inline("nodebug")
fn _get_unix_sock_protocol_constant(sock_protocol: SockProtocol) -> Int:
    if sock_protocol is SockProtocol.TCP:
        return IPPROTO_TCP
    elif sock_protocol is SockProtocol.UDP:
        return IPPROTO_UDP
    elif sock_protocol is SockProtocol.SCTP:
        return IPPROTO_SCTP
    elif sock_protocol is SockProtocol.IPPROTO_UDPLITE:
        return IPPROTO_UDPLITE
    else:
        return -1


@always_inline("nodebug")
fn _parse_unix_sock_family_constant(sock_family: Int) -> SockFamily:
    if sock_family == AF_INET:
        return SockFamily.AF_INET
    elif sock_family == AF_INET6:
        return SockFamily.AF_INET6
    elif sock_family == AF_UNIX:
        return SockFamily.AF_UNIX
    elif sock_family == AF_NETLINK:
        return SockFamily.AF_NETLINK
    elif sock_family == AF_TIPC:
        return SockFamily.AF_TIPC
    elif sock_family == AF_CAN:
        return SockFamily.AF_CAN
    elif sock_family == AF_BLUETOOTH:
        return SockFamily.AF_BLUETOOTH
    elif sock_family == AF_ALG:
        return SockFamily.AF_ALG
    elif sock_family == AF_VSOCK:
        return SockFamily.AF_VSOCK
    elif sock_family == AF_PACKET:
        return SockFamily.AF_PACKET
    elif sock_family == AF_QIPCRTR:
        return SockFamily.AF_QIPCRTR
    else:
        return ""


@always_inline("nodebug")
fn _parse_unix_sock_type_constant(sock_type: Int) -> SockType:
    if sock_type == SOCK_STREAM:
        return SockType.SOCK_STREAM
    elif sock_type == SOCK_DGRAM:
        return SockType.SOCK_DGRAM
    elif sock_type == SOCK_RAW:
        return SockType.SOCK_RAW
    elif sock_type == SOCK_RDM:
        return SockType.SOCK_RDM
    elif sock_type == SOCK_SEQPACKET:
        return SockType.SOCK_SEQPACKET
    else:
        return ""


@always_inline("nodebug")
fn _parse_unix_sock_protocol_constant(sock_protocol: Int) -> SockProtocol:
    if sock_protocol == IPPROTO_TCP:
        return SockProtocol.TCP
    elif sock_protocol == IPPROTO_UDP:
        return SockProtocol.UDP
    elif sock_protocol == IPPROTO_SCTP:
        return SockProtocol.SCTP
    elif sock_protocol == IPPROTO_UDPLITE:
        return SockProtocol.IPPROTO_UDPLITE
    else:
        return ""
