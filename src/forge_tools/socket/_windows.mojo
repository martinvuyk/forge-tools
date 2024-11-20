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


@value
struct _WindowsSocket[
    sock_family: SockFamily,
    sock_type: SockType,
    sock_protocol: SockProtocol,
    sock_address: SockAddr,
]:
    var fd: Arc[FileDescriptor]
    """The Socket's `Arc[FileDescriptor]`."""

    fn __init__(out self) raises:
        """Create a new socket object."""
        raise Error("Failed to create socket.")

    fn __init__(out self, fd: Arc[FileDescriptor]):
        """Create a new socket object from an open `Arc[FileDescriptor]`."""
        self.fd = fd

    fn close(owned self) raises:
        """Closes the Socket."""
        ...  # TODO: implement

    fn __del__(owned self):
        """Closes the Socket if it's the last reference to its
        `FileDescriptor`.
        """
        ...

    fn bind(self, address: sock_address) raises:
        """Bind the socket to address. The socket must not already be bound."""
        ...

    fn listen(self, backlog: UInt = 0) raises:
        """Enable a server to accept connections. `backlog` specifies the number
        of unaccepted connections that the system will allow before refusing
        new connections. If `backlog == 0`, a default value is chosen.
        """
        ...

    async fn connect(self, address: sock_address) raises:
        """Connect to a remote socket at address."""
        ...

    async fn accept(self) -> Optional[(Self, sock_address)]:
        """Return a new socket representing the connection, and the address of
        the client.
        """
        return None

    @staticmethod
    fn socketpair() raises -> (Self, Self):
        """Create a pair of socket objects from the sockets returned by the
        platform `socketpair()` function."""
        raise Error("Failed to create socket.")

    fn get_fd(self) -> FileDescriptor:
        """Get the Socket's FileDescriptor."""
        return 0

    async fn send_fds(self, fds: List[FileDescriptor]) -> Bool:
        """Send file descriptors to the socket."""
        return False

    async fn recv_fds(self, maxfds: Int) -> List[FileDescriptor]:
        """Receive file descriptors from the socket."""
        return List[FileDescriptor]()

    async fn send(self, buf: Span[UInt8], flags: C.int = 0) -> Int:
        """Send a buffer of bytes to the socket."""
        return -1

    async fn recv[O: MutableOrigin](
        self, buf: Span[UInt8, O], flags: C.int = 0
    ) -> Int:
        return -1

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

    @staticmethod
    fn create_connection(
        address: IPv4Addr,
        timeout: Optional[Float64] = None,
        source_address: IPv4Addr = IPv4Addr(("", 0)),
        *,
        all_errors: Bool = False,
    ) raises -> Self:
        """Connects to an address, with an optional timeout and optional source
        address."""
        alias s = sock_address
        alias cond = _type_is_eq[s, IPv4Addr]() or _type_is_eq[s, IPv6Addr]()
        constrained[cond, "sock_address must be IPv4Addr or IPv6Addr"]()
        raise Error("Failed to create socket.")

    @staticmethod
    fn create_server(
        address: IPv4Addr,
        *,
        backlog: Optional[Int] = None,
        reuse_port: Bool = False,
    ) raises -> Self:
        """Create a socket, bind it to a specified address, and listen."""
        constrained[
            _type_is_eq[sock_address, IPv4Addr](),
            "sock_address must be IPv4Addr",
        ]()
        raise Error("Failed to create socket.")

    @staticmethod
    fn create_server(
        address: IPv6Addr,
        *,
        backlog: Optional[Int] = None,
        reuse_port: Bool = False,
        dualstack_ipv6: Bool = False,
    ) raises -> Self:
        """Create a socket, bind it to a specified address, and listen."""
        constrained[
            _type_is_eq[sock_address, IPv6Addr](),
            "sock_address must be IPv6Addr",
        ]()
        raise Error("Failed to create socket.")

    fn keep_alive(
        self,
        enable: Bool = True,
        idle: C.int = 2 * 60 * 60,
        interval: C.int = 75,
        count: C.int = 10,
    ) raises:
        """Set how to keep the connection alive."""
        raise Error("Failed to set socket options.")

    fn reuse_address(
        self, value: Bool = True, *, full_duplicates: Bool = True
    ) raises:
        """Set whether to allow duplicated addresses."""
        raise Error("Failed to set socket options.")
