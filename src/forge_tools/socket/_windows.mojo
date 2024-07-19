# from .socket import _SocketInterface


@value
struct _WindowsSocket[
    sock_family: StringLiteral,  # TODO: change once we have enums
    sock_type: StringLiteral,
    sock_protocol: StringLiteral,
]:
    fn __init__(inout self) raises:
        """Create a new socket object."""
        return None

    @staticmethod
    async fn socket() -> Optional[Self]:
        """Create a new socket object."""
        return None

    async fn socketpair(self) -> Optional[Bool]:
        """Create a pair of new socket objects."""
        return None

    async fn fromfd(self) -> Optional[Self]:
        """Create a socket object from an open file descriptor."""
        return None

    async fn send_fds(self) -> Optional[Bool]:
        """Send file descriptor to the socket."""
        return None

    async fn recv_fds(self) -> Optional[String]:
        """Receive file descriptors from the socket."""
        return None

    async fn fromshare(self) -> Optional[Self]:
        """Create a socket object from data received from socket.share()."""
        return None

    async fn gethostname(
        self,
    ) -> Optional[String]:
        """Return the current hostname."""
        return None

    async fn gethostbyname(
        self,
    ) -> Optional[String]:
        """Map a hostname to its IP number."""
        return None

    async fn gethostbyaddr(
        self,
    ) -> Optional[String]:
        """Map an IP number or hostname to DNS info."""
        return None

    async fn getservbyname(
        self,
    ) -> Optional[String]:
        """Map a service name and a protocol name to a port number."""
        return None

    async fn getprotobyname(self) -> Optional[Int]:
        """Map a protocol name (e.g. 'tcp') to a number."""
        return None

    async fn ntohs(self, value: Int) -> Optional[Int]:
        """Convert 16, 32 bit int from network to host byte order."""
        return None

    async fn ntohl(self, value: Int) -> Optional[Int]:
        """Convert 16, 32 bit int from network to host byte order."""
        return None

    async fn htons(self, value: Int) -> Optional[Int]:
        """Convert 16, 32 bit int from host to network byte order."""
        return None

    async fn htonl(self, value: Int) -> Optional[Int]:
        """Convert 16, 32 bit int from host to network byte order."""
        return None

    async fn inet_aton(self, value: String) -> Optional[UInt32]:
        """Convert IP addr string (123.45.67.89) to 32-bit packed format."""
        return None

    async fn inet_ntoa(self, value: UInt32) -> Optional[String]:
        """Convert 32-bit packed format IP to string (123.45.67.89)."""
        return None

    async fn getdefaulttimeout(self) -> Optional[Float64]:
        """Get the default timeout value."""
        return None

    async fn setdefaulttimeout(self, value: Float64) -> Optional[Bool]:
        """Set the default timeout value."""
        return None

    async fn create_connection(self) -> Optional[Bool]:
        """Connects to an address, with an optional timeout and
        optional source address."""
        return None

    async fn create_server(self) -> Optional[Bool]:
        """Create a TCP socket and bind it to a specified address."""
        return None
