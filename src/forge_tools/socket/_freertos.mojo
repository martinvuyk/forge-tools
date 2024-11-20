from collections import Optional
from memory import UnsafePointer, Arc
from sys.intrinsics import _type_is_eq
from utils import Span
from forge_tools.ffi.c.types import C
from .socket import (
    # SocketInterface,
    SockType,
    SockProtocol,
)
from .address import SockFamily, SockAddr, IPv4Addr, IPv6Addr
from ._unix import _UnixSocket


@value
struct _FreeRTOSSocket[
    sock_family: SockFamily,
    sock_type: SockType,
    sock_protocol: SockProtocol,
    sock_address: SockAddr,
]:
    alias _ST = _UnixSocket[sock_family, sock_type, sock_protocol, sock_address]
    var _sock: Self._ST

    alias _ipv4 = _FreeRTOSSocket[
        SockFamily.AF_INET, sock_type, sock_protocol, IPv4Addr
    ]

    fn __init__(out self) raises:
        """Create a new socket object."""
        self._sock = Self._ST()

    fn __init__(out self, fd: Arc[FileDescriptor]):
        """Create a new socket object from an open `Arc[FileDescriptor]`."""
        self._sock = Self._ST(fd=fd)

    fn close(owned self) raises:
        """Closes the Socket."""
        self._sock.close()

    fn __del__(owned self):
        """Closes the Socket if it's the last reference to its
        `FileDescriptor`.
        """
        ...

    fn setsockopt[
        D: DType = C.int.element_type
    ](self, level: C.int, option_name: C.int, option_value: Scalar[D]) raises:
        """Set socket options."""
        self._sock.setsockopt(level, option_name, option_value)

    fn bind(self, address: sock_address) raises:
        """Bind the socket to address. The socket must not already be bound."""
        self._sock.bind(address)

    fn listen(self, backlog: UInt = 0) raises:
        """Enable a server to accept connections. `backlog` specifies the number
        of unaccepted connections that the system will allow before refusing
        new connections. If `backlog == 0`, a default value is chosen.
        """
        self._sock.listen(backlog)

    async fn connect(self, address: sock_address) raises:
        """Connect to a remote socket at address."""
        await self._sock.connect(address)

    async fn accept(self) -> Optional[(Self, sock_address)]:
        """Return a new socket representing the connection, and the address of
        the client."""
        res = await self._sock.accept()
        if not res:
            return None
        s_a = res.value()
        return Self(fd=s_a[0].get_fd()), s_a[1]

    @staticmethod
    fn socketpair() raises -> (Self, Self):
        """Create a pair of socket objects from the sockets returned by the
        platform `socketpair()` function."""
        s_s = Self._ST.socketpair()
        return Self(fd=s_s[0].get_fd()), Self(fd=s_s[1].get_fd())

    fn get_fd(self) -> FileDescriptor:
        """Get the Socket's `FileDescriptor`."""
        return self._sock.get_fd()

    async fn send_fds(self, fds: List[FileDescriptor]) -> Bool:
        """Send file descriptors to the socket."""
        return await self._sock.send_fds(fds)

    async fn recv_fds(self, maxfds: Int) -> List[FileDescriptor]:
        """Receive file descriptors from the socket."""
        return await self._sock.recv_fds(maxfds)

    async fn send(self, buf: Span[UInt8], flags: C.int = 0) -> Int:
        """Send a buffer of bytes to the socket."""
        return await self._sock.send(buf, flags)

    async fn recv[O: MutableOrigin](
        self, buf: Span[UInt8, O], flags: C.int = 0
    ) -> Int:
        return await self._sock.recv(buf, flags)

    @staticmethod
    fn gethostname() -> Optional[String]:
        """Return the current hostname."""
        return Self._ST.gethostname()

    @staticmethod
    fn gethostbyname(name: String) -> Optional[sock_address]:
        """Map a hostname to its Address."""
        return Self._ST.gethostbyname(name)

    @staticmethod
    fn gethostbyaddr(address: sock_address) -> Optional[String]:
        """Map an Address to DNS info."""
        return Self._ST.gethostbyaddr(address)

    @staticmethod
    fn getservbyname(name: String) -> Optional[sock_address]:
        """Map a service name and a protocol name to a port number."""
        return Self._ST.getservbyname(name)

    @staticmethod
    fn getdefaulttimeout() -> Optional[Float64]:
        """Get the default timeout value."""
        return Self._ST.getdefaulttimeout()

    @staticmethod
    fn setdefaulttimeout(value: Optional[Float64]) -> Bool:
        """Set the default timeout value."""
        return Self._ST.setdefaulttimeout(value)

    fn settimeout(self, value: Optional[Float64]) -> Bool:
        """Set the socket timeout value."""
        return self._sock.settimeout(value)

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
        return Self._ST.getaddrinfo(address, flags)

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
        return Self._ST.create_connection(
            address, timeout, source_address, all_errors=all_errors
        )

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
        return Self._ST.create_connection(
            address, timeout, source_address, all_errors=all_errors
        )

    @staticmethod
    fn create_server(
        address: IPv4Addr,
        *,
        backlog: Optional[Int] = None,
        reuse_port: Bool = False,
    ) raises -> Self:
        """Create a socket, bind it to a specified address, and listen."""
        return Self._ST.create_server(
            address, backlog=backlog, reuse_port=reuse_port
        )

    @staticmethod
    fn create_server(
        address: IPv6Addr,
        *,
        backlog: Optional[Int] = None,
        reuse_port: Bool = False,
    ) raises -> Self:
        """Create a socket, bind it to a specified address, and listen. Default
        no dual stack IPv6."""
        return Self._ST.create_server(
            address, backlog=backlog, reuse_port=reuse_port
        )

    @staticmethod
    fn create_server(
        address: IPv6Addr,
        *,
        dualstack_ipv6: Bool,
        backlog: Optional[Int] = None,
        reuse_port: Bool = False,
    ) raises -> (Self, Self._ipv4):
        """Create a socket, bind it to a specified address, and listen."""
        s_s = Self._ST.create_server(
            address,
            dualstack_ipv6=dualstack_ipv6,
            backlog=backlog,
            reuse_port=reuse_port,
        )
        return Self(fd=s_s[0].get_fd()), Self._ipv4(fd=s_s[1].get_fd())
