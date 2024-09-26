from collections import Optional
from memory import UnsafePointer
from utils import Span, StaticTuple
from sys.intrinsics import _type_is_eq
from sys import sizeof
from .socket import (
    # SocketInterface,
    SockFamily,
    SockType,
    SockProtocol,
    SockTime,
    _DEFAULT_SOCKET_TIMEOUT,
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
    TCP,
    UDP,
    SCTP,
    UDPLite,
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
        raise Error("Failed to create socket.")

    fn close(owned self) raises:
        """Closes the Socket."""
        _ = shutdown(self.fd.value, SHUT_RDWR)

    fn __del__(owned self):
        """Closes the Socket if it's the last reference to its
        `FileDescriptor`.
        """
        try:
            self.close()
        except:
            pass

    fn bind(self, address: sock_address) raises:
        """Bind the socket to address. The socket must not already be bound."""

        @parameter
        if _type_is_eq[sock_address, IPv4Addr]():
            var addr = rebind[IPv4Addr](address)
            var port = htons(addr.port)
            var ip_buf = UnsafePointer[C.void].alloc(4)
            var ip_ptr = addr.host.unsafe_cstr_ptr()
            var err = inet_pton(Self._sock_family, ip_ptr, ip_buf)
            if err == 0:
                raise Error("Invalid Address.")
            var ip = ip_buf.bitcast[C.u_int]().load()
            var zero = StaticTuple[C.char, 8]()
            var ai = sockaddr_in(Self._sock_family, port, ip, zero)
            var ai_ptr = UnsafePointer.address_of(ai).bitcast[sockaddr]()
            if bind(self.fd.value, ai_ptr, sizeof[sockaddr_in]()) == -1:
                _ = ai
                raise Error("Failed to create socket.")
            _ = ai
        else:
            constrained[False, "currently unsupported Address type"]()
            raise Error("Failed to create socket.")

    fn listen(self, backlog: UInt = 0) raises:
        """Enable a server to accept connections. `backlog` specifies the number
        of unaccepted connections that the system will allow before refusing
        new connections. If `backlog == 0`, a default value is chosen.
        """
        if listen(self.fd.value, C.int(backlog)) == -1:
            raise Error("Failed to listen on socket.")

    async fn connect(self, address: sock_address) raises:
        """Connect to a remote socket at address."""

        @parameter
        if _type_is_eq[sock_address, IPv4Addr]():
            var addr = rebind[IPv4Addr](address)
            var port = htons(addr.port)
            var ip_buf = UnsafePointer[C.void].alloc(4)
            var ip_ptr = addr.host.unsafe_cstr_ptr()
            var err = inet_pton(Self._sock_family, ip_ptr, ip_buf)
            if err == 0:
                raise Error("Invalid Address.")
            var ip = ip_buf.bitcast[C.u_int]().load()
            var zero = StaticTuple[C.char, 8]()
            var ai = sockaddr_in(Self._sock_family, port, ip, zero)
            var ai_ptr = UnsafePointer.address_of(ai).bitcast[sockaddr]()
            if connect(self.fd.value, ai_ptr, sizeof[sockaddr_in]()) == -1:
                _ = ai
                raise Error("Failed to create socket.")
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
            var their_addr_ptr = UnsafePointer[sockaddr].alloc(1)
            var sin_size = socklen_t(sizeof[socklen_t]())
            var size_ptr = UnsafePointer[socklen_t].address_of(sin_size)
            var fd = accept(self.fd.value, their_addr_ptr, size_ptr)
            _ = sin_size
            if fd == -1:
                raise Error("Failed to create socket.")
            var addr = their_addr_ptr[]
            if addr.sa_family != Self._sock_family:
                raise Error("Wrong Address Family for this socket.")
            var ptr = UnsafePointer[C.char].alloc(14)

            @parameter
            for i in range(14):
                ptr[i] = addr.sa_data[i]
            var addr_str = char_ptr_to_string(ptr)
            _ = addr
            var ip_addr = rebind[sock_address](IPv4Addr(host_port=addr_str^))
            return Self(fd=int(fd)), ip_addr^
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

    fn getdefaulttimeout(self) -> Optional[SockTime]:
        """Get the default timeout value."""
        return None

    fn setdefaulttimeout(self, value: SockTime) -> Bool:
        """Set the default timeout value."""
        return False

    @staticmethod
    fn create_connection(
        address: IPv4Addr,
        timeout: SockTime = _DEFAULT_SOCKET_TIMEOUT,
        source_address: IPv4Addr = IPv4Addr(("", 0)),
        *,
        all_errors: Bool = False,
    ) raises -> Self:
        """Connects to an address, with an optional timeout and
        optional source address."""
        raise Error("Failed to create socket.")

    @staticmethod
    fn create_connection(
        address: IPv6Addr,
        timeout: SockTime = _DEFAULT_SOCKET_TIMEOUT,
        source_address: IPv6Addr = IPv6Addr("", 0),
        *,
        all_errors: Bool = False,
    ) raises -> Self:
        """Connects to an address, with an optional timeout and
        optional source address."""
        raise Error("Failed to create socket.")

    @staticmethod
    fn create_server(
        address: IPv4Addr,
        *,
        backlog: Optional[Int] = None,
        reuse_port: Bool = False,
    ) raises -> Self:
        """Create a TCP socket and bind it to a specified address."""
        raise Error("Failed to create socket.")

    @staticmethod
    fn create_server(
        address: IPv6Addr,
        *,
        backlog: Optional[Int] = None,
        reuse_port: Bool = False,
        dualstack_ipv6: Bool = False,
    ) raises -> Self:
        """Create a TCP socket and bind it to a specified address."""
        raise Error("Failed to create socket.")


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
        return TCP
    elif sock_protocol is SockProtocol.UDP:
        return UDP
    elif sock_protocol is SockProtocol.SCTP:
        return SCTP
    elif sock_protocol is SockProtocol.IPPROTO_UDPLITE:
        return UDPLite
    else:
        return -1
