from .socket import (
    _SocketInterface,
    SockFamily,
    SockType,
    SockProtocol,
    Address,
    SockTimeout,
    _DEFAULT_SOCKET_TIMEOUT,
)


@value
struct _LinuxSocket[
    sock_family: SockFamily,  # TODO: change once we have enums
    sock_type: SockType,
    sock_protocol: SockProtocol,
](_SocketInterface):
    var fd: Arc[FileDescriptor]
    """The Socket's `Arc[FileDescriptor]`."""

    fn __init__(inout self) raises:
        """Create a new socket object."""
        raise Error("Failed to create socket.")

    fn __init__(inout self, fd: Arc[FileDescriptor]) raises:
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
            if self.fd.count() == 1:
                self.close()
        except:
            pass

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

    @staticmethod
    fn gethostname() -> Optional[String]:
        """Return the current hostname."""
        return None

    @staticmethod
    fn gethostbyname(name: String) -> Optional[Address]:
        """Map a hostname to its Address."""
        return None

    @staticmethod
    fn gethostbyaddr(address: Address) -> Optional[String]:
        """Map an Address to DNS info."""
        return None

    @staticmethod
    fn getservbyname(
        name: String, proto: SockProtocol = SockProtocol.TCP
    ) -> Optional[Address]:
        """Map a service name and a protocol name to a port number."""
        return None

    fn getdefaulttimeout(self) -> Optional[SockTimeout]:
        """Get the default timeout value."""
        return None

    fn setdefaulttimeout(self, value: SockTimeout) -> Bool:
        """Set the default timeout value."""
        return False

    async fn accept(self) -> (Self, Address):
        """Return a new socket representing the connection, and the address of
        the client.
        """
        return self, Address("", 0)

    @staticmethod
    fn create_connection(
        address: Address,
        timeout: SockTimeout = _DEFAULT_SOCKET_TIMEOUT,
        source_address: Optional[Address] = None,
        *,
        all_errors: Bool = False,
    ) raises -> Self:
        """Connects to an address, with an optional timeout and
        optional source address."""
        raise Error("Failed to create socket.")

    @staticmethod
    fn create_server(
        address: Address,
        *,
        backlog: Optional[Int] = None,
        reuse_port: Bool = False,
        dualstack_ipv6: Bool = False,
    ) raises -> Self:
        """Create a TCP socket and bind it to a specified address."""
        raise Error("Failed to create socket.")
