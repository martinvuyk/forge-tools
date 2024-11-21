from collections import Optional
from memory import UnsafePointer, stack_allocation, Arc
from os import abort
from sys import sizeof
from sys.intrinsics import _type_is_eq
from utils import Span, StaticTuple, StringSlice
from .socket import (
    # SocketInterface,
    SockType,
    SockProtocol,
)
from .address import SockFamily, SockAddr, IPv4Addr, IPv6Addr
from forge_tools.ffi.c.libc import Libc
from forge_tools.ffi.c.types import (
    C,
    in_addr,
    sockaddr,
    sockaddr_in,
    socklen_t,
    addrinfo,
    char_ptr_to_string,
    char_ptr,
    sa_family_t,
)
from forge_tools.ffi.c.constants import (
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
    SHUT_RDWR,
    IPPROTO_IPV6,
    IPV6_V6ONLY,
    SOL_SOCKET,
    SO_REUSEADDR,
    SO_REUSEPORT,
    STDERR_FILENO,
    SO_KEEPALIVE,
    SOL_TCP,
    TCP_KEEPIDLE,
    TCP_KEEPINTVL,
    TCP_KEEPCNT,
    TCP_NODELAY,
)


@value
struct _UnixSocket[
    sock_family: SockFamily,
    sock_type: SockType,
    sock_protocol: SockProtocol,
    sock_address: SockAddr,
]:
    """Generic POSIX compliant socket implementation."""

    var fd: Arc[FileDescriptor]
    """The Socket's `Arc[FileDescriptor]`."""
    alias lib = Libc[static=False]()
    """The dynamically linked Libc."""
    alias _sock_family = _get_unix_sock_family_constant(sock_family)
    alias _sock_type = _get_unix_sock_type_constant(sock_type)
    alias _sock_protocol = _get_unix_sock_protocol_constant(sock_protocol)

    alias _ipv4 = _UnixSocket[
        SockFamily.AF_INET, sock_type, sock_protocol, IPv4Addr
    ]

    fn __init__(out self) raises:
        """Create a new socket object."""
        fd = self.lib.socket(
            Self._sock_family, Self._sock_type, Self._sock_protocol
        )
        if fd == -1:
            message = char_ptr_to_string(
                self.lib.strerror(self.lib.get_errno())
            )
            raise Error("Failed to create socket: " + message)
        self.fd = FileDescriptor(int(fd))

    fn __init__(out self, fd: Arc[FileDescriptor]):
        """Create a new socket object from an open `Arc[FileDescriptor]`."""
        self.fd = fd

    fn close(owned self) raises:
        """Closes the Socket."""
        alias lib = Self.lib
        err = lib.shutdown(self.fd[].value, SHUT_RDWR)
        if err == -1:
            message = char_ptr_to_string(lib.strerror(lib.get_errno()))
            raise Error("Failed trying to close the socket: " + message)

    fn __del__(owned self):
        """Closes the Socket if it's the last reference to its
        `FileDescriptor`.
        """
        try:
            if self.fd.count() == 1:
                self.close()
        except e:
            print(e, file=STDERR_FILENO)

    fn setsockopt[
        D: DType = C.int.element_type
    ](self, level: C.int, option_name: C.int, option_value: Scalar[D]) raises:
        """Set socket options."""
        ptr = stack_allocation[1, Scalar[D]]()
        ptr[0] = option_value
        cvoid = ptr.bitcast[C.void]()
        s = socklen_t(sizeof[Scalar[D]]())
        fd = self.fd[].value
        if self.lib.setsockopt(fd, level, option_name, cvoid, s) == -1:
            message = char_ptr_to_string(
                self.lib.strerror(self.lib.get_errno())
            )
            raise Error("Failed to set socket options: " + message)

    fn bind(self, address: sock_address) raises:
        """Bind the socket to address. The socket must not already be bound."""

        @parameter
        if _type_is_eq[sock_address, IPv4Addr]():
            addr = rebind[IPv4Addr](address)
            port = self.lib.htons(addr.port)
            ip_buf = stack_allocation[4, C.void]()
            ip_ptr = char_ptr(addr.host)
            err = self.lib.inet_pton(Self._sock_family, ip_ptr, ip_buf)
            if err == 0:
                raise Error("Invalid Address.")
            ip = ip_buf.bitcast[C.u_int]().load()
            zero = StaticTuple[C.char, 8]()
            ai = sockaddr_in(Self._sock_family, port, in_addr(ip), zero)
            ai_ptr = UnsafePointer.address_of(ai).bitcast[sockaddr]()
            if (
                self.lib.bind(self.fd[].value, ai_ptr, sizeof[sockaddr_in]())
                == -1
            ):
                _ = ai
                message = char_ptr_to_string(
                    self.lib.strerror(self.lib.get_errno())
                )
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
        if self.lib.listen(self.fd[].value, C.int(backlog)) == -1:
            message = char_ptr_to_string(
                self.lib.strerror(self.lib.get_errno())
            )
            raise Error("Failed to listen on socket: " + message)

    async fn connect(self, address: sock_address) raises:
        """Connect to a remote socket at address."""

        @parameter
        if _type_is_eq[sock_address, IPv4Addr]():
            addr = rebind[IPv4Addr](address)
            port = self.lib.htons(addr.port)
            ip_buf = stack_allocation[4, C.void]()
            ip_ptr = addr.host.unsafe_ptr().bitcast[C.char]()
            err = self.lib.inet_pton(Self._sock_family, ip_ptr, ip_buf)
            if err == 0:
                raise Error("Invalid Address.")
            ip = ip_buf.bitcast[C.u_int]().load()
            zero = StaticTuple[C.char, 8]()
            ai = sockaddr_in(Self._sock_family, port, in_addr(ip), zero)
            ai_ptr = UnsafePointer.address_of(ai).bitcast[sockaddr]()
            if (
                self.lib.connect(self.fd[].value, ai_ptr, sizeof[sockaddr_in]())
                == -1
            ):
                _ = ai
                message = char_ptr_to_string(
                    self.lib.strerror(self.lib.get_errno())
                )
                raise Error("Failed to create socket: " + message)
            _ = ai
        else:
            constrained[False, "currently unsupported Address type"]()
            raise Error("Failed to create socket.")

    async fn accept(self) -> Optional[(Self, sock_address)]:
        """Return a new socket representing the connection, and the address of
        the client.
        """

        @parameter
        if _type_is_eq[sock_address, IPv4Addr]():
            try:
                addr_ptr = stack_allocation[1, sockaddr]()
                sin_size = socklen_t(sizeof[socklen_t]())
                size_ptr = UnsafePointer[socklen_t].address_of(sin_size)
                fd = int(self.lib.accept(self.fd[].value, addr_ptr, size_ptr))
                if fd == -1:
                    message = char_ptr_to_string(
                        self.lib.strerror(self.lib.get_errno())
                    )
                    raise Error("Failed to create socket: " + message)
                sa_family = addr_ptr.bitcast[sa_family_t]()[0]
                if sa_family != Self._sock_family:
                    raise Error("Wrong Address Family for this socket.")
                p = (addr_ptr.bitcast[sa_family_t]() + 1).bitcast[C.char]()
                addr_str = String(ptr=p.bitcast[UInt8](), length=int(sin_size))
                return Self(fd=FileDescriptor(fd)), sock_address(addr_str^)
            except e:
                print(str(e), file=STDERR_FILENO)
                return None
        else:
            constrained[False, "currently unsupported Address type"]()
            return None

    @staticmethod
    fn socketpair() raises -> (Self, Self):
        """Create a pair of socket objects from the sockets returned by the
        platform `socketpair()` function."""
        socket_vector = stack_allocation[2, C.int]()
        err = Self.lib.socketpair(
            Self._sock_family,
            Self._sock_type,
            Self._sock_protocol,
            socket_vector,
        )
        if err == -1:
            message = char_ptr_to_string(
                Self.lib.strerror(Self.lib.get_errno())
            )
            raise Error("Failed to create socket: " + message)
        return Self(fd=FileDescriptor(int(socket_vector[0]))), Self(
            fd=FileDescriptor(int(socket_vector[1]))
        )

    fn get_fd(self) -> FileDescriptor:
        """Get an ARC reference to the Socket's FileDescriptor.

        Returns:
            The ARC FileDescriptor.
        """
        return self.fd[]

    async fn send_fds(self, fds: List[FileDescriptor]) -> Bool:
        """Send file descriptors to the socket."""
        return False

    async fn recv_fds(self, maxfds: Int) -> List[FileDescriptor]:
        """Receive file descriptors from the socket."""
        return List[FileDescriptor]()

    async fn send(self, buf: Span[UInt8], flags: C.int = 0) -> Int:
        """Send a buffer of bytes to the socket."""
        ptr = buf.unsafe_ptr().bitcast[C.void]()
        sent = int(self.lib.send(self.fd[].value, ptr, len(buf), flags))
        if sent == -1:
            print(
                char_ptr_to_string(self.lib.strerror(self.lib.get_errno())),
                file=STDERR_FILENO,
            )
        return sent

    async fn recv[O: MutableOrigin](
        self, buf: Span[UInt8, O], flags: C.int = 0
    ) -> Int:
        ptr = buf.unsafe_ptr().bitcast[C.void]()
        recvd = int(self.lib.recv(self.fd[].value, ptr, len(buf), flags))
        if recvd == -1:
            print(
                char_ptr_to_string(self.lib.strerror(self.lib.get_errno())),
                file=STDERR_FILENO,
            )
        return recvd

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
        info = List[
            Tuple[SockFamily, SockType, SockProtocol, String, sock_address]
        ]()
        hints = addrinfo()
        hints.ai_family = Self._sock_family
        hints.ai_socktype = Self._sock_type
        hints.ai_flags = flags
        hints.ai_protocol = Self._sock_protocol
        hints_p = UnsafePointer[addrinfo].address_of(hints)
        nodename = str(address)
        result = addrinfo()
        alias UP = UnsafePointer
        res_p = C.ptr_addr(int(UP[addrinfo].address_of(result)))
        res_p_p = UP[C.ptr_addr].address_of(res_p)
        err = Self.lib.getaddrinfo(
            char_ptr(nodename), char_ptr(C.NULL), hints_p, res_p_p
        )
        if err != 0:
            msg = char_ptr_to_string(Self.lib.strerror(err))
            raise Error("Error in getaddrinfo(). Code: " + msg)
        next_addr = C.NULL
        first = True
        while first or next_addr != C.NULL:
            first = False
            af = _parse_unix_sock_family_constant(int(result.ai_family))
            st = _parse_unix_sock_type_constant(int(result.ai_socktype))
            pt = _parse_unix_sock_protocol_constant(int(result.ai_protocol))
            addrlen = int(result.ai_addrlen)
            addr_ptr = result.ai_addr.bitcast[UInt8]()
            alias S = StringSlice[ImmutableAnyOrigin]
            addr = String(S(ptr=addr_ptr, length=addrlen))
            can = String()
            if flags != 0:
                p = result.ai_canonname
                l = int(Self.lib.strlen(p))
                can = String(S(ptr=p.bitcast[UInt8](), length=l))
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
        errors = List[String]()
        idx = 0
        time = timeout.value() if timeout else Self.getdefaulttimeout()
        for res in Self.getaddrinfo(rebind[sock_address](address)):
            try:
                socket = Self()
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
        errors = List[String]()
        idx = 0
        time = timeout.value() if timeout else Self.getdefaulttimeout()
        for res in Self.getaddrinfo(rebind[sock_address](address)):
            try:
                socket = Self()
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
        socket = Self()
        socket.reuse_address(True, full_duplicates=reuse_port)
        socket.no_delay()
        socket.keep_alive(False)
        socket.bind(rebind[sock_address](address))
        socket.listen(backlog=backlog.or_else(0))
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
        socket = Self()
        socket.setsockopt(IPPROTO_IPV6, IPV6_V6ONLY, 1)
        socket.reuse_address(True, full_duplicates=reuse_port)
        socket.no_delay()
        socket.keep_alive(False)
        socket.bind(rebind[sock_address](address))
        socket.listen(backlog=backlog.or_else(0))
        return socket^

    @staticmethod
    fn create_server(
        address: IPv6Addr,
        *,
        dualstack_ipv6: Bool,
        backlog: Optional[Int] = None,
        reuse_port: Bool = False,
    ) raises -> (Self, Self._ipv4):
        """Create a socket, bind it to a specified address, and listen."""
        alias cond = _type_is_eq[sock_address, IPv6Addr]()
        constrained[cond, "sock_address must be IPv6Addr"]()
        ipv6_sock = Self()
        ipv6_sock.setsockopt(IPPROTO_IPV6, IPV6_V6ONLY, int(not dualstack_ipv6))
        ipv6_sock.reuse_address(True, full_duplicates=reuse_port)
        ipv6_sock.no_delay()
        ipv6_sock.keep_alive(False)
        ipv6_sock.bind(rebind[sock_address](address))
        ipv6_sock.listen(backlog=backlog.or_else(0))
        return (
            ipv6_sock^,
            Self._ipv4(fd=ipv6_sock.fd) if dualstack_ipv6 else Self._ipv4(),
        )

    fn keep_alive(
        self,
        enable: Bool = True,
        idle: C.int = 2 * 60 * 60,
        interval: C.int = 75,
        count: C.int = 10,
    ) raises:
        """Whether and how to keep the connection alive."""
        @parameter
        if sock_protocol is SockProtocol.TCP:
            self.setsockopt(SOL_SOCKET, SO_KEEPALIVE, int(enable))
            if enable:
                self.setsockopt(SOL_TCP, TCP_KEEPIDLE, idle)
                self.setsockopt(SOL_TCP, TCP_KEEPINTVL, interval)
                self.setsockopt(SOL_TCP, TCP_KEEPCNT, count)
        else:
            constrained[False, "unsupported protocol for this function"]()
            return abort()

    fn reuse_address(
        self, value: Bool = True, *, full_duplicates: Bool = True
    ) raises:
        """Whether to allow duplicated addresses."""
        @parameter
        if (
            sock_family is SockFamily.AF_INET
            or sock_family is SockFamily.AF_INET6
        ):
            self.setsockopt(SOL_SOCKET, SO_REUSEADDR, int(value))
            self.setsockopt(SOL_SOCKET, SO_REUSEPORT, int(full_duplicates))
        else:
            constrained[False, "unsupported address family for this function"]()
            return abort()

    fn no_delay(self, value: Bool = True) raises:
        """Whether to send packets ASAP without accumulating more."""
        @parameter
        if sock_protocol is SockProtocol.TCP:
            self.setsockopt(SOL_SOCKET, TCP_NODELAY, int(value))
        else:
            constrained[False, "unsupported protocol for this function"]()
            return abort()


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
