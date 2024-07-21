"""Socket module.

The goal is to achieve as close an interface as possible to
Python's [socket implementation](https://docs.python.org/3/library/socket.html).

From Python's socket docs:

This module provides socket operations and some related functions.
On Unix, it supports IP (Internet Protocol) and Unix domain sockets.
On other systems, it only supports IP. Functions specific for a
socket are available as methods of the socket object.

Functions:

socket() -- create a new socket object
socketpair() -- create a pair of new socket objects
fromfd() -- create a socket object from an open file descriptor
send_fds() -- Send file descriptor to the socket.
recv_fds() -- Receive file descriptors from the socket.
fromshare() -- create a socket object from data received from socket.share()
gethostname() -- return the current hostname
gethostbyname() -- Map a hostname to its Address
gethostbyaddr() -- Map an Address to DNS info
getservbyname() -- map a service name and a protocol name to a port number
ntohs(), ntohl() -- convert 16, 32 bit int from network to host byte order
htons(), htonl() -- convert 16, 32 bit int from host to network byte order
inet_aton() -- convert IP addr string (123.45.67.89) to 32-bit packed format
inet_ntoa() -- convert 32-bit packed format IP to string (123.45.67.89)
socket.getdefaulttimeout() -- get the default timeout value
socket.setdefaulttimeout() -- set the default timeout value
create_connection() -- connects to an address, with an optional timeout and
                       optional source address.
create_server() -- create a TCP socket and bind it to a specified address.
"""

from sys import info

from ._linux import _LinuxSocket
from ._unix import _UnixSocket
from ._windows import _WindowsSocket


# TODO enum
@register_passable("trivial")
struct SockFamily:
    """SockFamily."""

    alias AF_INET = "AF_INET"
    """AF_INET."""
    alias AF_INET6 = "AF_INET6"  # TODO: implement
    """AF_INET6."""
    # TODO the rest
    var _selected: StringLiteral

    fn __init__(inout self, selected: StringLiteral):
        """Construct an instance.

        Args:
            selected: The selected value.
        """
        debug_assert(
            selected in (self.AF_INET, Self.AF_INET6),
            "selected value is not valid",
        )
        self._selected = selected

    fn __is__(self, value: StringLiteral) -> Bool:
        """Whether the selected value is the give value.

        Args:
            value: The value.

        Returns:
            The result.
        """
        return self._selected == value


# TODO enum
@register_passable("trivial")
struct SockType:
    """SockType."""

    alias SOCK_STREAM = "SOCK_STREAM"
    """SOCK_STREAM."""
    alias SOCK_DGRAM = "SOCK_DGRAM"  # TODO: implement
    """SOCK_DGRAM."""
    alias SOCK_RAW = "SOCK_RAW"  # TODO: implement
    """SOCK_RAW."""
    # TODO the rest
    var _selected: StringLiteral

    fn __init__(inout self, selected: StringLiteral):
        """Construct an instance.

        Args:
            selected: The selected value.
        """
        debug_assert(
            selected in (Self.SOCK_STREAM, Self.SOCK_DGRAM, Self.SOCK_RAW),
            "selected value is not valid",
        )
        self._selected = selected

    fn __is__(self, value: StringLiteral) -> Bool:
        """Whether the selected value is the give value.

        Args:
            value: The value.

        Returns:
            The result.
        """
        return self._selected == value


# TODO enum
@register_passable("trivial")
struct SockProtocol:
    alias TCP = "TCP"
    alias UDP = "UDP"  # TODO: implement
    # TODO the rest
    var _selected: StringLiteral

    fn __init__(inout self, selected: StringLiteral):
        """Construct an instance.

        Args:
            selected: The selected value.
        """
        debug_assert(
            selected in (Self.TCP, Self.UDP), "selected value is not valid"
        )
        self._selected = selected

    fn __is__(self, value: StringLiteral) -> Bool:
        """Whether the selected value is the give value.

        Args:
            value: The value.

        Returns:
            The result.
        """
        return self._selected == value


# TODO enum
@register_passable("trivial")
struct SockPlatform:
    alias LINUX = "LINUX"
    alias APPLE = "APPLE"  # TODO: implement instead of sending to generic UNIX
    alias BSD = "BSD"  # TODO: implement instead of sending to generic UNIX
    alias FREERTOS = "FREERTOS"  # TODO: implement instead of sending to generic UNIX
    alias WASI = "WASI"  # TODO: implement
    alias UNIX = "UNIX"  # TODO: implement
    """Generic POSIX compliant OS."""
    alias WINDOWS = "WINDOWS"  # TODO: implement
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
        """Whether the selected value is the give value.

        Args:
            value: The value.

        Returns:
            The result.
        """
        return self._selected == value


trait _SocketInterface:
    """Interface for Sockets."""

    # var fd: Arc[FileDescriptor]
    # """The Socket's `Arc[FileDescriptor]`."""

    fn __init__(inout self) raises:
        """Create a new socket object."""
        ...

    fn close(owned self) raises:
        """Closes the Socket."""
        ...

    fn __del__(owned self):
        """Closes the Socket if it's the last reference to its
        `Arc[FileDescriptor]`.
        """
        ...

    @staticmethod
    async fn socketpair() raises -> (Self, Self):
        """Create a pair of socket objects from the sockets returned by the
        platform `socketpair()` function."""
        ...

    async fn send_fds(self, fds: List[FileDescriptor]) -> Bool:
        """Send file descriptor to the socket."""
        ...

    async fn recv_fds(self, maxfds: Int) -> Optional[List[Arc[FileDescriptor]]]:
        """Receive file descriptors from the socket."""
        ...

    @staticmethod
    fn gethostname() -> Optional[String]:
        """Return the current hostname."""
        ...

    @staticmethod
    fn gethostbyname(name: String) -> Optional[Address]:
        """Map a hostname to its Address."""
        ...

    @staticmethod
    fn gethostbyaddr(address: Address) -> Optional[String]:
        """Map an Address to DNS info."""
        ...

    @staticmethod
    fn getservbyname(
        name: String, proto: SockProtocol = SockProtocol.TCP
    ) -> Optional[Address]:
        """Map a service name and a protocol name to a port number."""
        ...

    fn getdefaulttimeout(self) -> Optional[SockTimeout]:
        """Get the default timeout value."""
        ...

    fn setdefaulttimeout(self, value: SockTimeout) -> Bool:
        """Set the default timeout value."""
        ...

    async fn accept(self) -> (Self, Address):
        """Return a new socket representing the connection, and the address of
        the client.
        """
        ...

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
        ...

    @staticmethod
    fn create_server(
        address: Address,
        *,
        backlog: Optional[Int] = None,
        reuse_port: Bool = False,
        dualstack_ipv6: Bool = False,
    ) raises -> Self:
        """Create a TCP socket and bind it to a specified address."""
        ...


fn _get_current_platform() -> StringLiteral:
    if info.os_is_linux():
        return SockPlatform.LINUX
    elif info.os_is_macos():
        return SockPlatform.APPLE
    elif info.os_is_windows():
        return SockPlatform.WINDOWS
    else:
        return SockPlatform.UNIX


@value
struct Socket[
    sock_family: SockFamily = SockFamily.AF_INET,
    sock_type: SockType = SockType.SOCK_STREAM,
    sock_protocol: SockProtocol = SockProtocol.TCP,
    sock_platform: SockPlatform = _get_current_platform(),
](CollectionElement):
    """Struct for using Sockets.

    Parameters:
        sock_family: The socket family e.g. `SockFamily.AF_INET`.
        sock_type: The socket type e.g. `SockType.SOCK_STREAM`.
        sock_protocol: The socket protocol e.g. `SockProtocol.TCP`.
        sock_platform: The socket platform e.g. `SockPlatform.LINUX`.
    """

    alias _linux_s = _LinuxSocket[sock_family, sock_type, sock_protocol]
    alias _unix_s = _UnixSocket[sock_family, sock_type, sock_protocol]
    alias _windows_s = _WindowsSocket[sock_family, sock_type, sock_protocol]
    # TODO: need to be able to use _SocketInterface trait regardless of type
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
        # elif sock_platform in (
        #     SockPlatform.UNIX,
        #     SockPlatform.APPLE,
        #     SockPlatform.BSD,
        # ):
        #     self._impl = Self._unix_s()
        # elif sock_platform is SockPlatform.WINDOWS:
        #     self._impl = Self._windows_s()
        else:
            constrained[False, "Platform not supported yet."]()
            self._impl = Self._linux_s()

    fn __enter__(owned self) -> Self:
        """Enter a context.

        Returns:
            The instance of self.
        """
        return self^

    @staticmethod
    async fn socketpair() raises -> (Self, Self):
        """Create a pair of socket objects from the sockets returned by the
        platform `socketpair()` function.

        Returns:
            The result.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return await Self._linux_s.socketpair()
        constrained[False, "Platform not supported yet."]()
        return Self(), Self()

    fn get_fd(self) -> Arc[FileDescriptor]:
        """Get an ARC reference to the Socket's FileDescriptor.

        Returns:
            The ARC pointer to the FileDescriptor.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return Self._linux_s.fd
        constrained[False, "Platform not supported yet."]()
        return FileDescriptor(2)

    async fn send_fds(self, fds: List[FileDescriptor]) -> Bool:
        """Send file descriptors to the socket.

        Args:
            fds: FileDescriptors.

        Returns:
            True on success, False otherwise.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return await self._impl.unsafe_get[Self._linux_s]()[].send_fds(fds)
        constrained[False, "Platform not supported yet."]()
        return False

    async fn recv_fds(self, maxfds: Int) -> Optional[List[FileDescriptor]]:
        """Receive up to maxfds file descriptors.

        Args:
            maxfds: The maximum amount of file descriptors.

        Returns:
            The file descriptors.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return await self._impl.unsafe_get[Self._linux_s]()[].recv_fds(
                maxfds
            )
        constrained[False, "Platform not supported yet."]()
        return None

    fn gethostname(self) -> String:
        """Return the current hostname.

        Returns:
            The result.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return self._impl.unsafe_get[Self._linux_s]()[].gethostname()
        constrained[False, "Platform not supported yet."]()
        return ""

    @staticmethod
    fn gethostbyname(name: String) -> Optional[Address]:
        """Map a hostname to its Address.

        Returns:
            The result.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return Self._linux_s.gethostbyname(name)
        constrained[False, "Platform not supported yet."]()
        return None

    @staticmethod
    fn gethostbyaddr(address: Address) -> Optional[String]:
        """Map an Address to DNS info.

        Returns:
            The result.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return Self._linux_s.gethostbyaddr(address)
        constrained[False, "Platform not supported yet."]()
        return None

    @staticmethod
    fn getservbyname(
        name: String, proto: SockProtocol = SockProtocol.TCP
    ) -> Optional[Address]:
        """Map a service name and a protocol name to a port number.

        Returns:
            The result.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return Self._linux_s.getservbyname(name, proto)
        constrained[False, "Platform not supported yet."]()
        return None

    @staticmethod
    fn ntohs(value: Int) -> Int:
        """Convert 16, 32 bit int from network to host byte order.

        Args:
            value: The value to convert.

        Returns:
            The result.
        """

        return 0  # TODO: implement

    fn ntohl(self, value: Int) -> Int:
        """Convert 16, 32 bit int from network to host byte order.

        Args:
            value: The value to convert.

        Returns:
            The result.
        """

        return 0  # TODO: implement

    fn htons(self, value: Int) -> Int:
        """Convert 16, 32 bit int from host to network byte order.

        Args:
            value: The value to convert.

        Returns:
            The result.
        """

        return 0  # TODO: implement

    fn htonl(self, value: Int) -> Int:
        """Convert 16, 32 bit int from host to network byte order.

        Args:
            value: The value to convert.

        Returns:
            The result.
        """

        return 0  # TODO: implement

    fn inet_aton(self, value: String) -> Optional[UInt32]:
        """Convert IP addr string (123.45.67.89) to 32-bit packed format.

        Args:
            value: The value to convert.

        Returns:
            The result.
        """

        return None  # TODO: implement

    fn inet_ntoa(self, value: UInt32) -> Optional[String]:
        """Convert 32-bit packed format IP to string (123.45.67.89).

        Args:
            value: The value to convert.

        Returns:
            The result.
        """

        return None  # TODO: implement

    fn getdefaulttimeout(self) -> Optional[SockTimeout]:
        """Get the default timeout value.

        Returns:
            The default timeout.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return self._impl.unsafe_get[Self._linux_s]()[].getdefaulttimeout()
        constrained[False, "Platform not supported yet."]()
        return None

    fn setdefaulttimeout(self, value: SockTimeout) -> Bool:
        """Set the default timeout value.

        Args:
            value: The timeout.

        Returns:
            True on success, False otherwise.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return self._impl.unsafe_get[Self._linux_s]()[].setdefaulttimeout(
                value
            )
        constrained[False, "Platform not supported yet."]()
        return False

    # TODO: once we have async generators
    # fn __iter__(self) -> _SocketIter:
    #     """Iterate asyncronously over the incoming connections.

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

    async fn accept(self) -> (Self, Address):
        """Return a new socket representing the connection, and the address of
        the client.

        Returns:
            The connection and the Address.
        """

        var new_sock = self
        return new_sock^, Address("", 0)  # TODO: implement

    @staticmethod
    fn create_connection(
        address: Address,
        timeout: SockTimeout = _DEFAULT_SOCKET_TIMEOUT,
        source_address: Optional[Address] = None,
        *,
        all_errors: Bool = False,
    ) raises -> Self:
        """Convenience function. Connect to address and return the socket
        object.

        Args:
            address: The Address to bind to.
            timeout: Passing the optional timeout parameter will set the timeout
                on the socket instance before attempting to connect. If no
                timeout is supplied, the global default timeout setting returned
                by `self.getdefaulttimeout` is used.
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
        constrained[False, "Platform not supported yet."]()
        raise Error("Failed to create socket.")

    @staticmethod
    fn create_server(
        address: Address,
        *,
        backlog: Optional[Int] = None,
        reuse_port: Bool = False,
        dualstack_ipv6: Bool = False,
    ) raises -> Self:
        """Convenience function which creates a socket bound to the address and
        returns the socket object.

        Args:
            address: The adress of the new server.
            backlog: Is the queue size passed to socket.listen().
            reuse_port: Dictates whether to use the SO_REUSEPORT socket
                option.
            dualstack_ipv6: If true and the platform supports it, it will
                create an AF_INET6 socket able to accept both IPv4 or IPv6
                connections. When false it will explicitly disable this
                option on platforms that enable it by default (e.g. Linux).

        Constraints:
            - sock_family can only be AF_INET or AF_INET6.
            - sock_type must be SOCK_STREAM.

        Returns:
            The Socket.

        Examples:
        ```mojo
        from forge_tools.socket import Socket


        async def main():
            with Socket.create_server(("0.0.0.0", 8000)) as server:
                while True:
                    conn, addr = await server.accept()
                    ...  # handle new connection

                # TODO: once we have async generators:
                # async for conn, addr in server:
                #     ...  # handle new connection
        ```
        .
        """

        constrained[
            sock_family._selected in (SockFamily.AF_INET, SockFamily.AF_INET6),
            "sock_family can only be AF_INET or AF_INET6",
        ]()
        constrained[
            sock_type is SockType.SOCK_STREAM, "sock_type must be SOCK_STREAM"
        ]()

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return Self._linux_s.create_server(
                address,
                backlog=backlog,
                reuse_port=reuse_port,
                dualstack_ipv6=dualstack_ipv6,
            )
        constrained[False, "Platform not supported yet."]()
        raise Error("Failed to create socket.")


@value
struct Address:
    """Address."""

    var ip: String
    """Ip."""
    var port: Int
    """Port."""

    fn __init__(inout self, ip: StringLiteral, port: Int):
        """Create an Address.

        Args:
            ip: The IP.
            port: The port.
        """
        self.ip = str(ip)
        self.port = port

    fn __init__(inout self, values: Tuple[StringLiteral, Int]):
        """Create an Address.

        Args:
            values: The IP and port.
        """
        self = Self(values[0], values[1])

    fn __init__(inout self, values: Tuple[String, Int]):
        """Create an Address.

        Args:
            values: The IP and port.
        """
        self = Self(values[0], values[1])

    fn __init__(inout self, value: String) raises:
        """Create an Address.

        Args:
            value: The string with IP and port.
        """
        var idx = value.rfind(":")
        if idx == -1:
            raise Error("port not found in String")
        self = Self(value[:idx], int(value[idx + 1 :]))


# TODO: enum
@register_passable("trivial")
struct SockTimeUnits:
    alias MICROSECONDS = "MICROSECONDS"
    """MICROSECONDS."""
    alias MILISECONDS = "MILISECONDS"
    """MILISECONDS."""
    alias SECONDS = "SECONDS"
    """SECONDS."""
    alias MINUTES = "MINUTES"
    """MINUTES."""
    var _selected: StringLiteral

    fn __init__(inout self, selected: StringLiteral):
        """Construct an instance.

        Args:
            selected: The selected value.
        """
        debug_assert(
            selected
            in (
                self.MICROSECONDS,
                Self.MILISECONDS,
                Self.SECONDS,
                Self.MINUTES,
            ),
            "selected value is not valid",
        )
        self._selected = selected

    fn __is__(self, value: StringLiteral) -> Bool:
        """Whether the selected value is the give value.

        Args:
            value: The value.

        Returns:
            The result.
        """
        return self._selected == value


@register_passable("trivial")
struct SockTimeout:
    """SockTimeout."""

    var time: UInt
    """Time. Unsigned integer to enforce setting a timeout."""
    var unit: SockTimeUnits
    """Unit."""

    fn __init__(
        inout self, value: UInt, unit: SockTimeUnits = SockTimeUnits.MINUTES
    ):
        """Construct a SockTimeout.

        Args:
            value: The value for the timeout.
            unit: The SockTimeUnits instance to measure by.
        """
        debug_assert(
            unit._selected
            in (
                SockTimeUnits.MICROSECONDS,
                SockTimeUnits.MILISECONDS,
                SockTimeUnits.SECONDS,
                SockTimeUnits.MINUTES,
            ),
            "unit is not in SockTimeUnits",
        )
        self.time = value
        self.unit = unit


alias _DEFAULT_SOCKET_TIMEOUT = SockTimeout(1, SockTimeUnits.MINUTES)
