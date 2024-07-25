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
struct _UnixSocket[
    sock_family: SockFamily, sock_type: SockType, sock_protocol: SockProtocol
]:
    """Generic POSIX compliant socket implementation."""

    fn __init__(inout self) raises:
        """Create a new socket object."""
        raise Error("Failed to create socket.")

    fn __init__(inout self, fd: Self._fd_type) raises:
        """Create a new socket object from an open `FileDescriptor`."""
        raise Error("Failed to create socket.")

    fn close(owned self) raises:
        """Closes the Socket."""
        ...  # TODO: implement

    fn __del__(owned self):
        """Closes the Socket if it's the last reference to its
        `Arc[FileDescriptor]`.
        """
        try:
            # TODO: use ARC to only close the last ref to the socket
            self.close()
        except:
            pass

    fn bind(self, address: SockAddr[sock_family, *_]) raises:
        """Bind the socket to address. The socket must not already be bound."""
        ...

    fn listen(self, backlog: UInt = 0) raises:
        """Enable a server to accept connections. `backlog` specifies the number
        of unaccepted connections that the system will allow before refusing
        new connections. If `backlog == 0`, a default value is chosen.
        """
        ...

    async fn connect(self, address: SockAddr[sock_family, *_]) raises:
        """Connect to a remote socket at address."""
        ...

    @staticmethod
    async fn socketpair() raises -> (Self, Self):
        """Create a pair of socket objects from the sockets returned by the
        platform `socketpair()` function."""
        raise Error("Failed to create socket.")

    fn getfd(self) -> Arc[FileDescriptor]:
        """Get an ARC reference to the Socket's FileDescriptor.

        Returns:
            The ARC pointer to the FileDescriptor.
        """
        return None

    @staticmethod
    async fn fromfd(fd: FileDescriptor) -> Optional[Self]:
        """Create a socket object from an open file descriptor."""
        return None

    async fn send_fds(self, fds: List[FileDescriptor]) -> Bool:
        """Send file descriptor to the socket."""
        return False

    async fn recv_fds(self, maxfds: Int) -> Optional[List[FileDescriptor]]:
        """Receive file descriptors from the socket."""
        return 0

    @staticmethod
    fn gethostname() -> Optional[String]:
        """Return the current hostname."""
        return None

    @staticmethod
    fn gethostbyname[
        T0: CollectionElement,
        T1: CollectionElement,
        T2: CollectionElement,
        T3: CollectionElement,
        T4: CollectionElement,
        T5: CollectionElement,
        T6: CollectionElement,
        T7: CollectionElement,
    ](name: String) -> Optional[
        SockAddr[sock_family, T0, T1, T2, T3, T4, T5, T6, T7]
    ]:
        """Map a hostname to its Address."""
        return None

    @staticmethod
    fn gethostbyaddr(address: SockAddr[sock_family, *_]) -> Optional[String]:
        """Map an Address to DNS info."""
        return None

    @staticmethod
    fn getservbyname[
        T0: CollectionElement,
        T1: CollectionElement,
        T2: CollectionElement,
        T3: CollectionElement,
        T4: CollectionElement,
        T5: CollectionElement,
        T6: CollectionElement,
        T7: CollectionElement,
    ](name: String, proto: SockProtocol = SockProtocol.TCP) -> Optional[
        SockAddr[sock_family, T0, T1, T2, T3, T4, T5, T6, T7]
    ]:
        """Map a service name and a protocol name to a port number."""
        return None

    fn getdefaulttimeout(self) -> Optional[SockTime]:
        """Get the default timeout value."""
        return None

    fn setdefaulttimeout(self, value: SockTime) -> Bool:
        """Set the default timeout value."""
        return False

    async fn accept[
        T0: CollectionElement,
        T1: CollectionElement,
        T2: CollectionElement,
        T3: CollectionElement,
        T4: CollectionElement,
        T5: CollectionElement,
        T6: CollectionElement,
        T7: CollectionElement,
    ](self) -> (Self, SockAddr[sock_family, T0, T1, T2, T3, T4, T5, T6, T7]):
        """Return a new socket representing the connection, and the address of
        the client.
        """
        return self, Address("", 0)

    @staticmethod
    fn create_connection(
        address: IPAddr[sock_family],
        timeout: SockTime = _DEFAULT_SOCKET_TIMEOUT,
        source_address: IPAddr[sock_family] = IPAddr[sock_family](("", 0)),
        *,
        all_errors: Bool = False,
    ) raises -> Self:
        """Connects to an address, with an optional timeout and
        optional source address."""
        raise Error("Failed to create socket.")

    @staticmethod
    fn create_server(
        address: IPAddr[sock_family],
        *,
        backlog: Optional[Int] = None,
        reuse_port: Bool = False,
        dualstack_ipv6: Bool = False,
    ) raises -> Self:
        """Create a TCP socket and bind it to a specified address."""
        raise Error("Failed to create socket.")
