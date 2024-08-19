from collections import Optional
from .socket import (
    # SocketInterface,
    SockFamily,
    SockType,
    SockProtocol,
    SockTime,
    _DEFAULT_SOCKET_TIMEOUT,
)
from .address import SockAddr, IPv4Addr, IPAddr


@value
struct _BSDSocket[
    sock_family: SockFamily, sock_type: SockType, sock_protocol: SockProtocol
]:
    var fd: FileDescriptor
    """The Socket's `FileDescriptor`."""

    fn __init__(inout self) raises:
        """Create a new socket object."""
        raise Error("Failed to create socket.")

    fn __init__(inout self, fd: FileDescriptor) raises:
        """Create a new socket object from an open `FileDescriptor`."""
        raise Error("Failed to create socket.")

    fn close(owned self) raises:
        """Closes the Socket."""
        ...  # TODO: implement

    fn __del__(owned self):
        """Closes the Socket if it's the last reference to its
        `FileDescriptor`.
        """
        try:
            self^.close()
        except:
            pass

    fn bind[T: SockAddr](self, address: T) raises:
        """Bind the socket to address. The socket must not already be bound."""
        ...

    fn listen(self, backlog: UInt = 0) raises:
        """Enable a server to accept connections. `backlog` specifies the number
        of unaccepted connections that the system will allow before refusing
        new connections. If `backlog == 0`, a default value is chosen.
        """
        ...

    async fn connect[T: SockAddr](self, address: T) raises:
        """Connect to a remote socket at address."""
        ...

    @staticmethod
    async fn socketpair() raises -> (Self, Self):
        """Create a pair of socket objects from the sockets returned by the
        platform `socketpair()` function."""
        raise Error("Failed to create socket.")

    async fn send_fds(self, fds: List[FileDescriptor]) -> Bool:
        """Send file descriptors to the socket."""
        return False

    async fn recv_fds(self, maxfds: Int) -> Optional[List[FileDescriptor]]:
        """Receive file descriptors from the socket."""
        return None

    async fn send(self, buf: UnsafePointer[UInt8], length: UInt) -> UInt:
        """Send a buffer of bytes to the socket."""
        return 0

    async fn send(self, buf: List[UInt8]) -> UInt:
        """Send a list of bytes to the socket."""
        return 0

    async fn recv(self, buf: UnsafePointer[UInt8], max_len: UInt) -> UInt:
        """Receive up to max_len bytes into the buffer."""
        return 0

    async fn recv(self, max_len: UInt) -> List[UInt8]:
        """Receive up to max_len bytes."""
        return List[UInt8]()

    @staticmethod
    fn gethostname() -> Optional[String]:
        """Return the current hostname."""
        return None

    @staticmethod
    fn gethostbyname[T: SockAddr](name: String) -> Optional[T]:
        """Map a hostname to its Address."""
        return None

    @staticmethod
    fn gethostbyaddr[T: SockAddr](address: T) -> Optional[String]:
        """Map an Address to DNS info."""
        return None

    @staticmethod
    fn getservbyname[
        T: SockAddr
    ](name: String, proto: SockProtocol = SockProtocol.TCP) -> Optional[T]:
        """Map a service name and a protocol name to a port number."""
        return None

    fn getdefaulttimeout(self) -> Optional[SockTime]:
        """Get the default timeout value."""
        return None

    fn setdefaulttimeout(self, value: SockTime) -> Bool:
        """Set the default timeout value."""
        return False

    async fn accept[T: SockAddr](self) raises -> (Self, T):
        """Return a new socket representing the connection, and the address of
        the client.
        """
        raise Error("Failed to create socket.")

    @staticmethod
    fn create_connection(
        address: IPv4Addr[sock_family],
        timeout: SockTime = _DEFAULT_SOCKET_TIMEOUT,
        source_address: IPv4Addr[sock_family] = IPv4Addr[sock_family](("", 0)),
        *,
        all_errors: Bool = False,
    ) raises -> Self:
        """Connects to an address, with an optional timeout and
        optional source address."""
        raise Error("Failed to create socket.")

    @staticmethod
    fn create_server(
        address: IPv6Addr[sock_family],
        *,
        backlog: Optional[Int] = None,
        reuse_port: Bool = False,
        dualstack_ipv6: Bool = False,
    ) raises -> Self:
        """Create a TCP socket and bind it to a specified address."""
        raise Error("Failed to create socket.")
