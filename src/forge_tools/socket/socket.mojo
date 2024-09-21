"""Socket module. An async take on Python's socket interface.

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


#### [Python's socket docs](https://docs.python.org/3/library/socket.html).
"""

from sys import info
from collections import Optional
from memory import UnsafePointer
from utils import Variant

from forge_tools.ffi.c import (
    ntohs,
    ntohl,
    htons,
    htonl,
    inet_aton,
    inet_ntoa,
    in_addr,
)

from .address import SockAddr, IPv4Addr, IPv6Addr
from ._linux import _LinuxSocket
from ._unix import _UnixSocket
from ._windows import _WindowsSocket


# TODO enum
@register_passable("trivial")
struct SockFamily:
    """Socket Address Family."""

    alias AF_INET = "AF_INET"
    """AF_INET."""
    alias AF_INET6 = "AF_INET6"  # TODO: implement
    """AF_INET6."""
    alias AF_UNIX = "AF_UNIX"  # TODO: implement
    """AF_UNIX."""
    alias AF_NETLINK = "AF_NETLINK"  # TODO: implement
    """AF_NETLINK."""
    alias AF_TIPC = "AF_TIPC"  # TODO: implement
    """AF_TIPC."""
    alias AF_CAN = "AF_CAN"  # TODO: implement
    """AF_CAN."""
    alias AF_BLUETOOTH = "AF_BLUETOOTH"  # TODO: implement
    """AF_BLUETOOTH."""
    alias AF_ALG = "AF_ALG"  # TODO: implement
    """AF_ALG."""
    alias AF_VSOCK = "AF_VSOCK"  # TODO: implement
    """AF_VSOCK."""
    alias AF_PACKET = "AF_PACKET"  # TODO: implement
    """AF_PACKET."""
    alias AF_QIPCRTR = "AF_QIPCRTR"  # TODO: implement
    """AF_QIPCRTR."""
    alias AF_HYPERV = "AF_HYPERV"  # TODO: implement
    """AF_HYPERV."""
    alias AF_SPI = "AF_SPI"  # TODO: implement
    """"AF_SPI". Notes: This Address Family is not standard since there is none.
    """
    alias AF_I2C = "AF_I2C"  # TODO: implement
    """"AF_I2C". Notes: This Address Family is not standard since there is none.
    """
    alias AF_UART = "AF_UART"  # TODO: implement
    """"AF_UART". Notes: This Address Family is not standard since there is
    none.
    """
    var _selected: StringLiteral

    fn __init__(inout self, selected: StringLiteral):
        """Construct an instance.

        Args:
            selected: The selected value.
        """
        debug_assert(
            selected
            in (
                Self.AF_INET,
                Self.AF_INET6,
                Self.AF_UNIX,
                Self.AF_NETLINK,
                Self.AF_TIPC,
                Self.AF_CAN,
                Self.AF_BLUETOOTH,
                Self.AF_ALG,
                Self.AF_VSOCK,
                Self.AF_PACKET,
                Self.AF_QIPCRTR,
                Self.AF_HYPERV,
                Self.AF_SPI,
                Self.AF_I2C,
                Self.AF_UART,
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

#     fn close(owned self) raises:
#         """Closes the Socket."""
#         ...

#     fn __del__(owned self):
#         """Closes the Socket if it's the last reference to its
#         `FileDescriptor`.
#         """
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

#     @staticmethod
#     async fn socketpair() raises -> (Self, Self):
#         """Create a pair of socket objects from the sockets returned by the
#         platform `socketpair()` function."""
#         ...

#     async fn send_fds(self, fds: List[FileDescriptor]) -> Bool:
#         """Send file descriptor to the socket."""
#         ...

#     async fn recv_fds(self, maxfds: Int) -> Optional[List[FileDescriptor]]:
#         """Receive file descriptors from the socket."""
#         ...

#     async fn send(self, buf: UnsafePointer[UInt8], length: UInt) -> UInt:
#         """Send a buffer of bytes to the socket."""
#         return 0

#     async fn recv(self, buf: UnsafePointer[UInt8], max_len: UInt) -> UInt:
#         """Receive up to max_len bytes into the buffer."""
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
#     fn getservbyname[
#         T: SockAddr
#     ](name: String, proto: SockProtocol = SockProtocol.TCP) -> Optional[T]:
#         """Map a service name and a protocol name to a port number."""
#         ...

#     fn getdefaulttimeout(self) -> Optional[SockTime]:
#         """Get the default timeout value."""
#         ...

#     fn setdefaulttimeout(self, value: SockTime) -> Bool:
#         """Set the default timeout value."""
#         ...

#     async fn accept(self) -> (Self, sock_address):
#         """Return a new socket representing the connection, and the address of
#         the client.
#         """
#         ...


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
    sock_address: SockAddr = IPv4Addr,
    sock_platform: SockPlatform = _get_current_platform(),
](CollectionElement):
    """Struct for using Sockets. In the future this struct should be able to
    use any implementation that conforms to the SocketInterface trait, once
    traits can have attributes and have parameters defined. This will allow the
    user to implement the interface for whatever functionality is missing and
    inject the type.

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
        with Socket.create_server(("0.0.0.0", 8000)) as server:
            while True:
                conn, addr = await server.accept()
                ...  # handle new connection

            # TODO: once we have async generators:
            # async for conn, addr in server:
            #     ...  # handle new connection
    ```

    In the future something like this should be possible:
    ```mojo
    from multiprocessing import Pool
    from forge_tools.socket import Socket, IPv4Addr


    async fn handler(conn: Socket, addr: IPv4Addr):
        ...

    async def main():
        with Socket.create_server(("0.0.0.0", 8000)) as server:
            with Pool() as pool:
                _ = await pool.starmap(handler, server)
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
        # elif sock_platform is SockPlatform.UNIX:
        #     self._impl = Self._unix_s()
        # elif sock_platform is SockPlatform.WINDOWS:
        #     self._impl = Self._windows_s()
        else:
            constrained[False, "Platform not supported yet."]()
            self._impl = Self._linux_s()

    fn close(owned self) raises:
        """Closes the Socket."""

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return self._impl.unsafe_get[Self._linux_s]()[].close()
        _ = self^

    fn __del__(owned self):
        """Closes the Socket if it's the last reference to its
        `FileDescriptor`.
        """
        _ = self^

    fn __enter__(owned self) -> Self:
        """Enter a context.

        Returns:
            The instance of self.
        """
        return self^

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

    @staticmethod
    async fn socketpair() raises -> (Self, Self):
        """Create a pair of socket objects from the sockets returned by the
        platform `socketpair()` function.

        Returns:
            The result.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            var s = await Self._linux_s.socketpair()
            return Self(s[0]), Self(s[1])
        else:
            constrained[False, "Platform not supported yet."]()
            return Self(), Self()

    fn get_fd(self) -> FileDescriptor:
        """Get an ARC reference to the Socket's FileDescriptor.

        Returns:
            The ARC pointer to the FileDescriptor.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return self._impl.unsafe_get[Self._linux_s]()[].fd
        else:
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
            return (
                await self._impl.unsafe_get[Self._linux_s]()[].recv_fds(maxfds)
            )^
        else:
            constrained[False, "Platform not supported yet."]()
            return None

    async fn send(self, buf: UnsafePointer[UInt8], length: UInt) -> UInt:
        """Send a buffer of bytes to the socket.

        Args:
            buf: The bytes buffer to send.
            length: The amount of items in the buffer.

        Returns:
            The amount of bytes sent.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return await self._impl.unsafe_get[Self._linux_s]()[].send(
                buf, length
            )
        else:
            constrained[False, "Platform not supported yet."]()
            return False

    async fn send(self, buf: List[UInt8]) -> UInt:
        """Send a List of bytes to the socket.

        Args:
            buf: The list of bytes to send.

        Returns:
            The amount of bytes sent.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return await self._impl.unsafe_get[Self._linux_s]()[].send(buf)
        else:
            constrained[False, "Platform not supported yet."]()
            return False

    async fn recv(self, buf: UnsafePointer[UInt8], max_len: UInt) -> UInt:
        """Receive up to max_len bytes into the buffer.

        Args:
            buf: The buffer to recieve to.
            max_len: The maximum amount of bytes to recieve.

        Returns:
            The amount of bytes recieved.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return await self._impl.unsafe_get[Self._linux_s]()[].recv(
                buf, max_len
            )
        else:
            constrained[False, "Platform not supported yet."]()
            return 0

    async fn recv(self, max_len: UInt) -> List[UInt8]:
        """Receive up to max_len bytes.

        Args:
            max_len: The maximum amount of bytes to recieve.

        Returns:
            The bytes recieved.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return (
                await self._impl.unsafe_get[Self._linux_s]()[].recv(max_len)
            )^
        else:
            constrained[False, "Platform not supported yet."]()
            return List[UInt8]()

    fn gethostname(self) -> Optional[String]:
        """Return the current hostname.

        Returns:
            The result.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return self._impl.unsafe_get[Self._linux_s]()[].gethostname()
        else:
            constrained[False, "Platform not supported yet."]()
            return ""

    @staticmethod
    fn gethostbyname(name: String) -> Optional[sock_address]:
        """Map a hostname to its Address.

        Returns:
            The result.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return Self._linux_s.gethostbyname(name)
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
        else:
            constrained[False, "Platform not supported yet."]()
            return None

    @staticmethod
    fn getservbyname(
        name: String, proto: SockProtocol = SockProtocol.TCP
    ) -> Optional[sock_address]:
        """Map a service name and a protocol name to a port number.

        Returns:
            The result.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return Self._linux_s.getservbyname(name, proto)
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
        return ntohs(value)

    fn ntohl(self, value: UInt32) -> UInt32:
        """Convert 32 bit int from network to host byte order.

        Args:
            value: The value to convert.

        Returns:
            The result.
        """
        return ntohl(value)

    fn htons(self, value: UInt16) -> UInt16:
        """Convert 16 bit int from host to network byte order.

        Args:
            value: The value to convert.

        Returns:
            The result.
        """
        return htons(value)

    fn htonl(self, value: UInt32) -> UInt32:
        """Convert 32 bit int from host to network byte order.

        Args:
            value: The value to convert.

        Returns:
            The result.
        """
        return htonl(value)

    fn inet_aton(self, value: String) -> Optional[UInt32]:
        """Convert IPv4 address string (123.45.67.89) to 32-bit packed format.

        Args:
            value: The value to convert.

        Returns:
            The result.
        """
        var res = in_addr(0)
        var err = inet_aton(value.unsafe_ptr().bitcast[Int8](), res)
        if err == 0:
            return None
        return res.s_addr

    fn inet_ntoa(self, value: UInt32) -> String:
        """Convert 32-bit packed format to IPv4 address string (123.45.67.89).

        Args:
            value: The value to convert.

        Returns:
            The result.
        """
        var length = 0
        var ptr = inet_ntoa(value).bitcast[UInt8]()
        for i in range(7, 16):
            if ptr[i] == 0:
                length = i + 1
                break
        return String(ptr=ptr, len=length)

    fn getdefaulttimeout(self) -> Optional[SockTime]:
        """Get the default timeout value.

        Returns:
            The default timeout.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return self._impl.unsafe_get[Self._linux_s]()[].getdefaulttimeout()
        else:
            constrained[False, "Platform not supported yet."]()
            return None

    fn setdefaulttimeout(self, value: SockTime) -> Bool:
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
        else:
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

    async fn accept(self) raises -> (Self, sock_address):
        """Return a new socket representing the connection, and the address of
        the client.

        Returns:
            The connection and the Address.
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            var conn_addr = await self._impl.unsafe_get[
                Self._linux_s
            ]()[].accept()
            return Self(conn_addr[0]), conn_addr[1]
        else:
            constrained[False, "Platform not supported yet."]()
            raise Error("Failed to create socket.")

    @staticmethod
    fn create_connection(
        address: IPv4Addr,
        timeout: SockTime = _DEFAULT_SOCKET_TIMEOUT,
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
        else:
            constrained[False, "Platform not supported yet."]()
            raise Error("Failed to create socket.")

    @staticmethod
    fn create_connection(
        address: IPv6Addr,
        timeout: SockTime = _DEFAULT_SOCKET_TIMEOUT,
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
        returns the socket object.

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

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return Self._linux_s.create_server(
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

        Returns:
            The Socket.

        Examples:
        ```mojo
        from forge_tools.socket import Socket, SockFamily, IPv6Addr


        async def main():
            alias S = Socket[SockFamily.AF_INET6, sock_address=IPv6Addr]
            with S.create_server(IPv6Addr("::1", 8000)) as server:
                while True:
                    conn, addr = await server.accept()
                    ...  # handle new connection

                # TODO: once we have async generators:
                # async for conn, addr in server:
                #     ...  # handle new connection
        ```
        .
        """

        @parameter
        if sock_platform is SockPlatform.LINUX:
            return Self._linux_s.create_server(
                address,
                backlog=backlog,
                reuse_port=reuse_port,
                dualstack_ipv6=dualstack_ipv6,
            )
        else:
            constrained[False, "Platform not supported yet."]()
            raise Error("Failed to create socket.")


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
                Self.MICROSECONDS,
                Self.MILISECONDS,
                Self.SECONDS,
                Self.MINUTES,
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


@register_passable("trivial")
struct SockTime:
    """SockTime."""

    var time: Int
    """Time."""
    var unit: SockTimeUnits
    """Unit."""

    fn __init__(
        inout self, value: Int, unit: SockTimeUnits = SockTimeUnits.MINUTES
    ):
        """Construct a SockTime.

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


alias _DEFAULT_SOCKET_TIMEOUT = SockTime(1, SockTimeUnits.MINUTES)
