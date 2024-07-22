from .socket import (
    _SocketInterface,
    SockFamily,
    SockType,
    SockProtocol,
    SockAddr,
    SockTime,
    _DEFAULT_SOCKET_TIMEOUT,
)


@value
struct _UnixSocket[
    sock_family: SockFamily, sock_type: SockType, sock_protocol: SockProtocol
](_SocketInterface):
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
    fn gethostbyname(name: String) -> Optional[SockAddr]:
        """Map a hostname to its Address."""
        return None

    @staticmethod
    fn gethostbyaddr(address: SockAddr) -> Optional[String]:
        """Map an Address to DNS info."""
        return None

    @staticmethod
    fn getservbyname(
        name: String, proto: SockProtocol = SockProtocol.TCP
    ) -> Optional[SockAddr]:
        """Map a service name and a protocol name to a port number."""
        return None

    fn getdefaulttimeout(self) -> Optional[SockTime]:
        """Get the default timeout value."""
        return None

    fn setdefaulttimeout(self, value: SockTime) -> Bool:
        """Set the default timeout value."""
        return False

    async fn accept(self) -> (Self, SockAddr):
        """Return a new socket representing the connection, and the address of
        the client.
        """
        return self, Address("", 0)

    @staticmethod
    fn create_connection(
        address: SockAddr,
        timeout: SockTime = _DEFAULT_SOCKET_TIMEOUT,
        source_address: SockAddr = SockAddr("", 0),
        *,
        all_errors: Bool = False,
    ) raises -> Self:
        """Connects to an address, with an optional timeout and
        optional source address."""
        raise Error("Failed to create socket.")

    @staticmethod
    fn create_server(
        address: SockAddr,
        *,
        backlog: Optional[Int] = None,
        reuse_port: Bool = False,
        dualstack_ipv6: Bool = False,
    ) raises -> Self:
        """Create a TCP socket and bind it to a specified address."""
        raise Error("Failed to create socket.")
