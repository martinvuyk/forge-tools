"""Socket module. An async take on [Python's socket interface](\
https://docs.python.org/3/library/socket.html).

#### Functions:

- `socket()`
    - create a new socket object.
- `socketpair()`
    - create a pair of new socket objects.
- `send_fds()`
    - Send file descriptor to the socket.
- `recv_fds()`
    - Receive file descriptors from the socket.
- `gethostname()`
    - return the current hostname.
- `gethostbyname()`
    - Map a hostname to its Address.
- `gethostbyaddr()`
    - Map an Address to DNS info.
- `getservbyname()`
    - map a service name and a protocol name to a port number.
- `ntohs()`, `ntohl()`
    - convert 16, 32 bit int from network to host byte order.
- `htons()`, `htonl()`
    - convert 16, 32 bit int from host to network byte order.
- `inet_aton()`
    - convert IP addr string (123.45.67.89) to 32-bit packed format.
- `inet_ntoa()`
    - convert 32-bit packed format IP to string (123.45.67.89)
- `getdefaulttimeout()`
    - get the default timeout value.
- `setdefaulttimeout()`
    - set the default timeout value.
- `create_connection()`
    - connects to an address, with an optional timeout and optional source
        address.
- `create_server()`
    - create a TCP socket and bind it to a specified address.


#### Python functions whose functionality is covered by other means:

- `share()`, `dup()`, `fileno()`
    - use `get_fd()` instead.
- `fromfd()` & `fromshare()`
    - use `Socket(fd: FileDescriptor)` constructor instead.
- `detach()`
    - functionality covered by the type's destructor.
"""

from sys import info
from collections import Optional
from memory import UnsafePointer, stack_allocation, Arc
from utils import Variant, Span, StringSlice

from forge_tools.ffi.c.types import C, in_addr

from .address import SockFamily, SockAddr, IPv4Addr, IPv6Addr
from ._linux import _LinuxSocket
from ._unix import _UnixSocket
from ._windows import _WindowsSocket


# TODO enum
@register_passable("trivial")
struct SockType:
    """Socket Type."""

    alias SOCK_STREAM = "SOCK_STREAM"
    """SOCK_STREAM."""
    alias SOCK_DGRAM = "SOCK_DGRAM"  # TODO: implement
    """SOCK_DGRAM."""
    alias SOCK_RAW = "SOCK_RAW"  # TODO: implement
    """SOCK_RAW."""
    alias SOCK_RDM = "SOCK_RDM"  # TODO: implement
    """SOCK_RDM."""
    alias SOCK_SEQPACKET = "SOCK_SEQPACKET"  # TODO: implement
    """SOCK_SEQPACKET."""

    # TODO the rest
    var _selected: StringLiteral

    fn __init__(inout self, selected: StringLiteral):
        """Construct an instance.

        Args:
            selected: The selected value.
        """
        debug_assert(
            selected
            in (
                Self.SOCK_STREAM,
                Self.SOCK_DGRAM,
                Self.SOCK_RAW,
                Self.SOCK_RDM,
                Self.SOCK_SEQPACKET,
            ),
            "selected value is not valid",
        )
        self._selected = selected

    fn __is__(self, value: StringLiteral) -> Bool:
        """Whether the selected value is the given value.

        Args:
            value: The value.

        Returns:
            The result.
        """
        return self._selected == value


# TODO enum
@register_passable("trivial")
struct SockProtocol:
    """Socket Transmission Protocol."""

    alias TCP = "TCP"
    """Transmission Control Protocol."""
    alias UDP = "UDP"  # TODO: implement
    """User Datagram Protocol."""
    alias SCTP = "SCTP"  # TODO: implement
    """Stream Control Transmission Protocol."""
    alias IPPROTO_UDPLITE = "IPPROTO_UDPLITE"  # TODO: implement
    """Lightweight User Datagram Protocol."""
    alias SPI = "SPI"  # TODO: implement. inspiration: https://github.com/OnionIoT/spi-gpio-driver
    """Serial Peripheral Interface."""
    alias I2C = "I2C"  # TODO: implement. inspiration: https://github.com/OnionIoT/i2c-exp-driver, https://github.com/swedishborgie/libmma8451
    """Inter Integrated Circuit."""
    alias UART = "UART"  # TODO: implement. inspiration: https://github.com/AndreRenaud/simple_uart
    """Universal Asynchronous Reciever Transmitter."""
    var _selected: StringLiteral

    fn __init__(inout self, selected: StringLiteral):
        """Construct an instance.

        Args:
            selected: The selected value.
        """
        debug_assert(
            selected
            in (
                Self.TCP,
                Self.UDP,
                Self.SCTP,
                Self.IPPROTO_UDPLITE,
                Self.SPI,
                Self.I2C,
                Self.UART,
            ),
            "selected value is not valid",
        )
        self._selected = selected

    fn __is__(self, value: StringLiteral) -> Bool:
        """Whether the selected value is the given value.

        Args:
            value: The value.

        Returns:
            The result.
        """
        return self._selected == value


# TODO enum
@register_passable("trivial")
struct SockPlatform:
    """Socket Platform."""

    alias LINUX = "LINUX"
    """LINUX."""
    alias APPLE = "APPLE"  # TODO: implement instead of sending to generic UNIX
    """APPLE."""
    alias BSD = "BSD"  # TODO: implement instead of sending to generic UNIX
    """BSD."""
    alias FREERTOS = "FREERTOS"  # TODO: implement instead of sending to generic UNIX
    """FREERTOS."""
    alias WASI = "WASI"  # TODO: implement
    """WASI."""
    alias UNIX = "UNIX"  # TODO: implement
    """Generic POSIX compliant OS."""
    alias WINDOWS = "WINDOWS"  # TODO: implement
    """WINDOWS."""
    # TODO other important platforms
    var _selected: StringLiteral

    fn __init__(inout self, selected: StringLiteral):
        """Construct an instance.

        Args:
            selected: The selected value.
        """
        debug_assert(
            selected
            in (
                Self.LINUX,
                Self.APPLE,
                Self.BSD,
                Self.FREERTOS,
                Self.WASI,
                Self.UNIX,
                Self.WINDOWS,
            ),
            "selected value is not valid",
        )
        self._selected = selected

    fn __is__(self, value: StringLiteral) -> Bool:
        """Whether the selected value is the given value. Unix matches with all
        POSIX-ish platforms.

        Args:
            value: The value.

        Returns:
            The result.
        """
        return self._selected == value or (
            value == SockPlatform.UNIX
            and self._selected
            in (SockPlatform.UNIX, Self.LINUX, Self.APPLE, Self.BSD)
        )


# TODO: trait declarations do not support parameters yet
# trait SocketInterface[
#     sock_family: SockFamily,
#     sock_type: SockType,
#     sock_protocol: SockProtocol,
#     sock_address: SockAddr,
#     sock_platform: SockPlatform,
# ](CollectionElement):
#     """Interface for Sockets."""

#     fn __init__(inout self) raises:
#         """Create a new socket object."""
#         ...

#    fn __init__(inout self, fd: Arc[FileDescriptor]):
#        """Create a new socket object from an open `Arc[FileDescriptor]`."""
#        ...

#     fn close(owned self) raises:
#         """Closes the Socket if it's the last reference to its
#         `Arc[FileDescriptor]`.
#         """
#         ...

#     fn __del__(owned self):
#         """Closes the Socket if it's the last reference to its
#         `Arc[FileDescriptor]`.
#         """
#         ...

#     fn setsockopt(self, level: Int, option_name: Int, option_value: Int) raises:
#         """Set socket options."""
#         ...

#     fn bind(self, address: sock_address) raises:
#         """Bind the socket to address. The socket must not already be bound."""
#         ...

#     fn listen(self, backlog: UInt = 0) raises:
#         """Enable a server to accept connections. `backlog` specifies the number
#         of unaccepted connections that the system will allow before refusing
#         new connections. If `backlog == 0`, a default value is chosen.
#         """
#         ...

#     async fn connect(self, address: sock_address) raises:
#         """Connect to a remote socket at address."""
#         ...

#     async fn accept(self) -> Optional[(Self, sock_address)]:
#         """Return a new socket representing the connection, and the address of
#         the client."""
#         ...

#    # TODO: once we have async generators
#    fn __iter__(self) -> _SocketIter:
#        """Iterate asynchronously over the incoming connections."""
#        ...

#     @staticmethod
#     fn socketpair() raises -> (Self, Self):
#         """Create a pair of socket objects from the sockets returned by the
#         platform `socketpair()` function."""
#         ...

#     fn get_fd(self) -> Arc[FileDescriptor]:
#         """Get the Socket's ARC FileDescriptor."""
#         ...

#     async fn send_fds(self, fds: List[FileDescriptor]) -> Bool:
#         """Send file descriptor to the socket."""
#         ...

#     async fn recv_fds(self, maxfds: Int) -> List[FileDescriptor]:
#         """Receive file descriptors from the socket."""
#         ...

#     async fn send(self, buf: Span[UInt8]) -> UInt:
#         """Send a buffer of bytes to the socket."""
#         return 0

#     async fn recv(self, buf: Span[UInt8]) -> UInt:
#         """Receive up to `len(buf)` bytes into the buffer."""
#         return 0

#     @staticmethod
#     fn gethostname() -> Optional[String]:
#         """Return the current hostname."""
#         ...

#     @staticmethod
#     fn gethostbyname(name: String) -> Optional[sock_address]:
#         """Map a hostname to its Address."""
#         ...

#     @staticmethod
#     fn gethostbyaddr(address: sock_address) -> Optional[String]:
#         """Map an Address to DNS info."""
#         ...

#     @staticmethod
#     fn getservbyname(
#         name: String, proto: SockProtocol = SockProtocol.TCP
#     ) -> Optional[sock_address]:
#         """Map a service name and a protocol name to a port number."""
#         ...

#     @staticmethod
#     fn getdefaulttimeout() -> Optional[Float64]:
#         """Get the default timeout value."""
#         ...

#     @staticmethod
#     fn setdefaulttimeout(value: Optional[Float64]) -> Bool:
#         """Set the default timeout value."""
#         ...

#     fn settimeout(self, value: Optional[Float64]) -> Bool:
#         """Set the socket timeout value."""
#         ...

#    # TODO: This should return an iterator instead
#    @staticmethod
#    fn getaddrinfo(
#        address: sock_address, flags: Int = 0
#    ) raises -> List[
#        (SockFamily, SockType, SockProtocol, String, sock_address)
#    ]:
#        """Get the available address information.
#        ...


fn current_sock_platform() -> SockPlatform:
    """Get the current platform.

    Returns:
        The current platform.
    """
    if info.os_is_linux():
        return SockPlatform.LINUX
    elif info.os_is_macos():
        return SockPlatform.APPLE
    elif info.os_is_windows():
        return SockPlatform.WINDOWS
    else:
        print(
            "Platform not specifically supported yet. Using UNIX as default",
            file=2,
        )
        return SockPlatform.UNIX


@value
struct Socket[
    sock_family: SockFamily = SockFamily.AF_INET,
    sock_type: SockType = SockType.SOCK_STREAM,
    sock_protocol: SockProtocol = SockProtocol.TCP,
    sock_address: SockAddr = IPv4Addr,
    sock_platform: SockPlatform = current_sock_platform(),
](CollectionElement):
    """Struct for using Sockets. In the future this struct should be able to
    use any implementation that conforms to the `SocketInterface` trait, once
    traits can be parametrized. This will allow the user to implement the
    interface for whatever functionality is missing and inject the type.

    Parameters:
        sock_family: The socket family e.g. `SockFamily.AF_INET`.
        sock_type: The socket type e.g. `SockType.SOCK_STREAM`.
        sock_protocol: The socket protocol e.g. `SockProtocol.TCP`.
        sock_address: The address type for the socket.
        sock_platform: The socket platform e.g. `SockPlatform.LINUX`.

    Examples:

    ```mojo
    from forge_tools.socket import Socket


    async def main():
        # TODO: once we have async generators:
        # async for conn_attempt in Socket.create_server(("0.0.0.0", 8000)):
        #     conn, addr = conn_attempt[]
        #     ...  # handle new connection

        with Socket.create_server(("0.0.0.0", 8000)) as server:
            while True:
                conn, addr = (await server.accept())[]
                ...  # handle new connection
    ```

    In the future something like this should be possible:
    ```mojo
    from collections import Optional
    from multiprocessing import Pool
    from forge_tools.socket import Socket, IPv4Addr


    async fn handler(conn_attempt: Optional[(Socket, IPv4Addr)]):
        if not conn_attempt:
            return
        conn, addr = conn_attempt.value()
        ...

    async def main():
        server = Socket.create_server(("0.0.0.0", 8000))
        with Pool() as pool:
            _ = await pool.map(handler, server)
    ```
    .
    """

    alias _linux_s = _LinuxSocket[
        sock_family, sock_type, sock_protocol, sock_address
    ]
    alias _unix_s = _UnixSocket[
        sock_family, sock_type, sock_protocol, sock_address
    ]
    alias _windows_s = _WindowsSocket[
        sock_family, sock_type, sock_protocol, sock_address
    ]
    # TODO: need to be able to use SocketInterface trait regardless of type
    alias _variant = Variant[Self._linux_s, Self._unix_s, Self._windows_s]
    var _impl: Self._variant

    fn __init__(inout self, impl: Self._variant):
        """Construct a socket object from an implementation of the
        SocketInterface.

        Args:
            impl: The SocketInterface implementation.
        """
        self._impl = impl

    fn __init__(inout self) raises:
        """Create a new socket object."""

        @parameter
        if sock_platform is SockPlatform.LINUX:
            self._impl = Self._linux_s()
        elif sock_platform is SockPlatform.UNIX:
            self._impl = Self._unix_s()
        else:
            constrained[False, "Platform not supported yet."]()
            self._impl = Self._linux_s()

    fn __init__(inout self, fd: Arc[FileDescriptor]):
        """Create a new socket object from an open `Arc[FileDescriptor]`."""

        @parameter
        if sock_platform is SockPlatform.LINUX:
            self._impl = Self._linux_s(fd)
        elif sock_platform is SockPlatform.UNIX:
            self._impl = Self._unix_s(fd)
        else:
            constrained[False, "Platform not supported yet."]()
            self._impl = Self._linux_s(fd)

    fn close(owned self) raises:
        """Closes the Socket if it's the last reference to its
        `Arc[FileDescriptor]`.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            self._impl[Self._linux_s].close()
        elif sock_platform is SockPlatform.UNIX:
            self._impl[Self._unix_s].close()
        else:
            constrained[False, "Platform not supported yet."]()
            raise Error("Failed to close socket.")

    fn __del__(owned self):
        """Closes the Socket if it's the last reference to its
        `Arc[FileDescriptor]`.
        """
        _ = self^

    fn __enter__(owned self) -> Self:
        """Enter a context.

        Returns:
            The instance of self.
        """
        return self^

    fn setsockopt(self, level: Int, option_name: Int, option_value: Int) raises:
        """Set socket options.

        Args:
            level: Protocol Level see SOL_ alises.
            option_name: Option name see SO_ alises.
            option_value: A pointer to a buffer containing the option value.

        Notes:
            [Reference](\
            https://man7.org/linux/man-pages/man3/setsockopt.3p.html).
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            conn_addr = self._impl[Self._linux_s].setsockopt(
                level, option_name, option_value
            )
        elif sock_platform is SockPlatform.UNIX:
            conn_addr = self._impl[Self._unix_s].setsockopt(
                level, option_name, option_value
            )
        else:
            constrained[False, "Platform not supported yet."]()
            raise Error("Failed to set socket options.")

    fn bind(self, address: sock_address) raises:
        """Bind the socket to address. The socket must not already be bound."""

        @parameter
        if sock_platform is SockPlatform.LINUX:
            self._impl[Self._linux_s].bind(address)
        elif sock_platform is SockPlatform.UNIX:
            self._impl[Self._unix_s].bind(address)
        else:
            constrained[False, "Platform not supported yet."]()
            raise Error("Failed to create socket.")

    fn listen(self, backlog: UInt = 0) raises:
        """Enable a server to accept connections. `backlog` specifies the number
        of unaccepted connections that the system will allow before refusing
        new connections. If `backlog == 0`, a default value is chosen.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            self._impl[Self._linux_s].listen(backlog)
        elif sock_platform is SockPlatform.UNIX:
            self._impl[Self._unix_s].listen(backlog)
        else:
            constrained[False, "Platform not supported yet."]()
            raise Error("Failed to create socket.")

    async fn connect(self, address: sock_address) raises:
        """Connect to a remote socket at address."""

        @parameter
        if sock_platform is SockPlatform.LINUX:
            await self._impl[Self._linux_s].connect(address)
        elif sock_platform is SockPlatform.UNIX:
            await self._impl[Self._unix_s].connect(address)
        else:
            constrained[False, "Platform not supported yet."]()
            raise Error("Failed to create socket.")

    async fn accept(self) -> Optional[(Self, sock_address)]:
        """Return a new socket representing the connection, and the address of
        the client.

        Returns:
            The connection and the Address.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            attempt = await self._impl[Self._linux_s].accept()
            if not attempt:
                return None
            conn, addr = attempt.value()
            return Self(conn), addr
        elif sock_platform is SockPlatform.UNIX:
            attempt = await self._impl[Self._unix_s].accept()
            if not attempt:
                return None
            conn, addr = attempt.value()
            return Self(conn), addr
        else:
            constrained[False, "Platform not supported yet."]()
            return None

    @staticmethod
    fn socketpair() raises -> (Self, Self):
        """Create a pair of socket objects from the sockets returned by the
        platform `socketpair()` function.

        Returns:
            The result.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            var s = Self._linux_s.socketpair()
            return Self(s[0]), Self(s[1])
        elif sock_platform is SockPlatform.UNIX:
            var s = Self._unix_s.socketpair()
            return Self(s[0]), Self(s[1])
        else:
            constrained[False, "Platform not supported yet."]()
            return Self(), Self()

    fn get_fd(self) -> Arc[FileDescriptor]:
        """Get the Socket's ARC FileDescriptor.

        Returns:
            The Socket's ARC FileDescriptor.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return self._impl[Self._linux_s].get_fd()
        elif sock_platform is SockPlatform.UNIX:
            return self._impl[Self._unix_s].get_fd()
        else:
            constrained[False, "Platform not supported yet."]()
            return Arc(FileDescriptor(0))

    async fn send_fds(self, fds: List[FileDescriptor]) -> Bool:
        """Send file descriptors to the socket.

        Args:
            fds: FileDescriptors.

        Returns:
            True on success, False otherwise.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return await self._impl[Self._linux_s].send_fds(fds)
        elif sock_platform is SockPlatform.UNIX:
            return await self._impl[Self._unix_s].send_fds(fds)
        else:
            constrained[False, "Platform not supported yet."]()
            return False

    async fn recv_fds(self, maxfds: UInt) -> Optional[List[FileDescriptor]]:
        """Receive up to maxfds file descriptors.

        Args:
            maxfds: The maximum amount of file descriptors.

        Returns:
            The file descriptors.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return await self._impl[Self._linux_s].recv_fds(maxfds)
        else:
            constrained[False, "Platform not supported yet."]()
            return None

    async fn send(self, buf: Span[UInt8], flags: Int = 0) -> Int:
        """Send a buffer of bytes to the socket.

        Args:
            buf: The buffer of bytes to send.
            flags: The [optional flags](\
https://manpages.debian.org/bookworm/manpages-dev/\
recv.2.en.html#The_flags_argument).

        Returns:
            The amount of bytes sent, -1 on error.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return await self._impl[Self._linux_s].send(buf, flags)
        elif sock_platform is SockPlatform.UNIX:
            return await self._impl[Self._unix_s].send(buf, flags)
        else:
            constrained[False, "Platform not supported yet."]()
            return False

    async fn recv(self, buf: Span[UInt8], flags: Int = 0) -> Int:
        """Receive up to `len(buf)` bytes into the buffer.

        Args:
            buf: The buffer to recieve to.
            flags: The [optional flags](\
https://manpages.debian.org/bookworm/manpages-dev/\
recv.2.en.html#The_flags_argument).

        Returns:
            The amount of bytes recieved, -1 on error.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return await self._impl[Self._linux_s].recv(buf, flags)
        elif sock_platform is SockPlatform.UNIX:
            return await self._impl[Self._unix_s].recv(buf, flags)
        else:
            constrained[False, "Platform not supported yet."]()
            return 0

    fn gethostname(self) -> Optional[String]:
        """Return the current hostname.

        Returns:
            The result.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return self._impl[Self._linux_s].gethostname()
        elif sock_platform is SockPlatform.UNIX:
            return self._impl[Self._unix_s].gethostname()
        else:
            constrained[False, "Platform not supported yet."]()
            return None

    @staticmethod
    fn gethostbyname(name: String) -> Optional[sock_address]:
        """Map a hostname to its Address.

        Returns:
            The result.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return Self._linux_s.gethostbyname(name)
        elif sock_platform is SockPlatform.UNIX:
            return Self._unix_s.gethostbyname(name)
        else:
            constrained[False, "Platform not supported yet."]()
            return None

    @staticmethod
    fn gethostbyaddr(address: sock_address) -> Optional[String]:
        """Map an Address to DNS info.

        Returns:
            The result.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return Self._linux_s.gethostbyaddr(address)
        elif sock_platform is SockPlatform.UNIX:
            return Self._unix_s.gethostbyaddr(address)
        else:
            constrained[False, "Platform not supported yet."]()
            return None

    @staticmethod
    fn getservbyname(name: String) -> Optional[sock_address]:
        """Map a service name and a protocol name to a port number.

        Returns:
            The result.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return Self._linux_s.getservbyname(name)
        elif sock_platform is SockPlatform.UNIX:
            return Self._unix_s.getservbyname(name)
        else:
            constrained[False, "Platform not supported yet."]()
            return None

    @staticmethod
    fn ntohs(value: UInt16) -> UInt16:
        """Convert 16 bit int from network to host byte order.

        Args:
            value: The value to convert.

        Returns:
            The result.
        """
        return Self._unix_s.lib.ntohs(value)

    @staticmethod
    fn ntohl(value: UInt32) -> UInt32:
        """Convert 32 bit int from network to host byte order.

        Args:
            value: The value to convert.

        Returns:
            The result.
        """
        return Self._unix_s.lib.ntohl(value)

    @staticmethod
    fn htons(value: UInt16) -> UInt16:
        """Convert 16 bit int from host to network byte order.

        Args:
            value: The value to convert.

        Returns:
            The result.
        """
        return Self._unix_s.lib.htons(value)

    @staticmethod
    fn htonl(value: UInt32) -> UInt32:
        """Convert 32 bit int from host to network byte order.

        Args:
            value: The value to convert.

        Returns:
            The result.
        """
        return Self._unix_s.lib.htonl(value)

    @staticmethod
    fn inet_aton(value: String) -> Optional[UInt32]:
        """Convert IPv4 address string (123.45.67.89) to 32-bit packed format.

        Args:
            value: The value to convert.

        Returns:
            The result.
        """

        ptr = stack_allocation[1, in_addr]()
        err = Self._unix_s.lib.inet_aton(
            value.unsafe_ptr().bitcast[C.char](), ptr
        )
        if err == 0:
            return None
        return ptr[0].s_addr

    @staticmethod
    fn inet_ntoa(value: UInt32) -> String:
        """Convert 32-bit packed format to IPv4 address string (123.45.67.89).

        Args:
            value: The value to convert.

        Returns:
            The result.
        """

        length = 0
        ptr = Self._unix_s.lib.inet_ntoa(value).bitcast[UInt8]()
        for i in range(7, 16):
            if ptr[i] == 0:
                length = i
                break
        alias S = StringSlice[ImmutableAnyOrigin]
        return String(S(ptr=ptr, length=length))

    @staticmethod
    fn getdefaulttimeout() -> Optional[Float64]:
        """Returns the default timeout for new socket objects (in seconds).

        Returns:
            The default timeout in seconds.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return Self._linux_s.getdefaulttimeout()
        elif sock_platform is SockPlatform.UNIX:
            return Self._unix_s.getdefaulttimeout()
        else:
            constrained[False, "Platform not supported yet."]()
            return None

    @staticmethod
    fn setdefaulttimeout(value: Optional[Float64]) -> Bool:
        """Set the default timeout value (in seconds).

        Args:
            value: The timeout in seconds.

        Returns:
            True on success, False otherwise.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return Self._linux_s.setdefaulttimeout(value)
        elif sock_platform is SockPlatform.UNIX:
            return Self._unix_s.setdefaulttimeout(value)
        else:
            constrained[False, "Platform not supported yet."]()
            return False

    fn settimeout(self, value: Optional[Float64]) -> Bool:
        """Set the socket timeout value.

        Args:
            value: The timeout.

        Returns:
            True on success, False otherwise.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return self._impl[Self._linux_s].settimeout(value)
        elif sock_platform is SockPlatform.UNIX:
            return self._impl[Self._unix_s].settimeout(value)
        else:
            constrained[False, "Platform not supported yet."]()
            return False

    # TODO: once we have async generators
    # fn __iter__(self) -> _SocketIter:
    #     """Iterate asynchronously over the incoming connections.

    #     Returns:
    #         The async iterator.

    #     Examples:
    #     ```mojo
    #     from forge_tools.socket import Socket

    #     async def main():
    #         with Socket.create_server(("0.0.0.0", 8000)) as server:
    #             async for conn, addr in server:
    #                 ...  # handle new connection
    #     ```
    #     .
    #     """
    #     ...

    # TODO: should this return an iterator instead?
    @staticmethod
    fn getaddrinfo(
        address: sock_address, flags: Int = 0
    ) raises -> List[
        (SockFamily, SockType, SockProtocol, String, sock_address)
    ]:
        """Get the available address information.
        
        Notes:
            [Linux reference](\
                https://man7.org/linux/man-pages/man3/freeaddrinfo.3p.html).
            [Windows reference](\
https://learn.microsoft.com/en-us/windows/win32/api/ws2tcpip/\
nf-ws2tcpip-getaddrinfo).
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return Self._linux_s.getaddrinfo(address, flags)
        elif sock_platform is SockPlatform.UNIX:
            return Self._unix_s.getaddrinfo(address, flags)
        else:
            constrained[False, "Platform not supported yet."]()
            return List[
                (SockFamily, SockType, SockProtocol, String, sock_address)
            ]()

    @staticmethod
    fn create_connection(
        address: IPv4Addr,
        timeout: Optional[Float64] = None,
        source_address: IPv4Addr = ("", 0),
        *,
        all_errors: Bool = False,
    ) raises -> Self:
        """Convenience function. Connect to address and return the socket
        object.

        Args:
            address: The Address to bind to.
            timeout: The timeout for attempting to connect.
            source_address: A host of '' or port 0 tells the OS to use the
                default.
            all_errors: When a connection cannot be created, raises the last
                error if all_errors is False, and an ExceptionGroup of all
                errors if all_errors is True.

        Returns:
            The Socket.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return Self._linux_s.create_connection(
                address, timeout, source_address, all_errors=all_errors
            )
        elif sock_platform is SockPlatform.UNIX:
            return Self._unix_s.create_connection(
                address, timeout, source_address, all_errors=all_errors
            )
        else:
            constrained[False, "Platform not supported yet."]()
            raise Error("Failed to create socket.")

    @staticmethod
    fn create_connection(
        address: IPv6Addr,
        timeout: Optional[Float64] = None,
        source_address: IPv6Addr = IPv6Addr("", 0),
        *,
        all_errors: Bool = False,
    ) raises -> Self:
        """Convenience function. Connect to address and return the socket
        object.

        Args:
            address: The Address to bind to.
            timeout: The timeout for attempting to connect.
            source_address: A host of '' or port 0 tells the OS to use the
                default.
            all_errors: When a connection cannot be created, raises the last
                error if all_errors is False, and an ExceptionGroup of all
                errors if all_errors is True.

        Returns:
            The Socket.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return Self._linux_s.create_connection(
                address, timeout, source_address, all_errors=all_errors
            )
        elif sock_platform is SockPlatform.UNIX:
            return Self._unix_s.create_connection(
                address, timeout, source_address, all_errors=all_errors
            )
        else:
            constrained[False, "Platform not supported yet."]()
            raise Error("Failed to create socket.")

    # TODO(#3305): add structmethod constraint
    # @structmethod
    # fn create_server(
    #     stc: Socket[SockFamily.AF_INET, SockType.SOCK_STREAM, *_],
    #     address: IPv4Addr,
    #     *,
    #     backlog: Optional[Int] = None,
    #     reuse_port: Bool = False,
    # ) raises -> __type_of(stc):
    @staticmethod
    fn create_server(
        address: IPv4Addr,
        *,
        backlog: Optional[Int] = None,
        reuse_port: Bool = False,
    ) raises -> Self:
        """Convenience function which creates a socket bound to the address and
        returns the listening socket object.

        Args:
            address: The adress of the new server.
            backlog: Is the queue size passed to socket.listen().
            reuse_port: Dictates whether to use the SO_REUSEPORT socket
                option.

        Returns:
            The Socket.

        Examples:
        ```mojo
        from forge_tools.socket import Socket


        async def main():
            # TODO: once we have async generators:
            # async for conn_attempt in Socket.create_server(("0.0.0.0", 8000)):
            #     conn, addr = conn_attempt[]
            #     ...  # handle new connection

            with Socket.create_server(("0.0.0.0", 8000)) as server:
                while True:
                    conn, addr = (await server.accept())[]
                    ...  # handle new connection

        ```
        .
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return Self._linux_s.create_server(
                address, backlog=backlog, reuse_port=reuse_port
            )
        elif sock_platform is SockPlatform.UNIX:
            return Self._unix_s.create_server(
                address, backlog=backlog, reuse_port=reuse_port
            )
        else:
            constrained[False, "Platform not supported yet."]()
            raise Error("Failed to create socket.")

    # TODO(#3305): add structmethod constraint
    # @structmethod
    # fn create_server(
    #     stc: Socket[SockFamily.AF_INET6, SockType.SOCK_STREAM, *_],
    #     address: IPv6Addr,
    #     *,
    #     backlog: Optional[Int] = None,
    #     reuse_port: Bool = False,
    #     dualstack_ipv6: Bool = False,
    # ) raises -> __type_of(stc):
    @staticmethod
    fn create_server(
        address: IPv6Addr,
        *,
        backlog: Optional[Int] = None,
        reuse_port: Bool = False,
    ) raises -> Self:
        """Convenience function which creates a socket bound to the address and
        returns the listening socket object. By default no dual stack IPv6.

        Args:
            address: The adress of the new server.
            backlog: Is the queue size passed to socket.listen().
            reuse_port: Dictates whether to use the SO_REUSEPORT socket
                option.

        Returns:
            The Socket.

        Examples:
        ```mojo
        from forge_tools.socket import Socket, SockFamily, IPv6Addr


        async def main():
            alias S = Socket[SockFamily.AF_INET6, sock_address=IPv6Addr]
            # TODO: once we have async generators:
            # async for conn_attempt in S.create_server(IPv6Addr("::1", 8000)):
            #     conn, addr = conn_attempt[]
            #     ...  # handle new connection

            with S.create_server(IPv6Addr("::1", 8000)) as server:
                while True:
                    conn, addr = (await server.accept())[]
                    ...  # handle new connection
        ```
        .
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return Self._linux_s.create_server(
                address,
                backlog=backlog,
                reuse_port=reuse_port,
            )
        elif sock_platform is SockPlatform.UNIX:
            return Self._unix_s.create_server(
                address,
                backlog=backlog,
                reuse_port=reuse_port,
            )
        else:
            constrained[False, "Platform not supported yet."]()
            raise Error("Failed to create socket.")

    @staticmethod
    fn create_server(
        address: IPv6Addr,
        *,
        dualstack_ipv6: Bool,
        backlog: Optional[Int] = None,
        reuse_port: Bool = False,
    ) raises -> (
        Self,
        Socket[
            SockFamily.AF_INET,
            sock_type,
            sock_protocol,
            IPv4Addr,
            sock_platform,
        ],
    ):
        """Convenience function which creates a socket bound to the address and
        returns the listening socket object.

        Args:
            address: The adress of the new server.
            dualstack_ipv6: If true and the platform supports it, it will
                create an AF_INET6 socket able to accept both IPv4 or IPv6
                connections. When false it will explicitly disable this
                option on platforms that enable it by default (e.g. Linux).
            backlog: Is the queue size passed to socket.listen().
            reuse_port: Dictates whether to use the SO_REUSEPORT socket
                option.

        Returns:
            A pair of IPv6 and IPv4 sockets.
        """
        alias S = Socket[
            SockFamily.AF_INET,
            sock_type,
            sock_protocol,
            IPv4Addr,
            sock_platform,
        ]

        @parameter
        if sock_platform is SockPlatform.LINUX:
            var res = Self._linux_s.create_server(
                address,
                backlog=backlog,
                reuse_port=reuse_port,
                dualstack_ipv6=dualstack_ipv6,
            )
            return Self(res[0]), S(res[1])
        elif sock_platform is SockPlatform.UNIX:
            var res = Self._unix_s.create_server(
                address,
                backlog=backlog,
                reuse_port=reuse_port,
                dualstack_ipv6=dualstack_ipv6,
            )
            return Self(res[0]), S(res[1])
        else:
            constrained[False, "Platform not supported yet."]()
            raise Error("Failed to create socket.")
