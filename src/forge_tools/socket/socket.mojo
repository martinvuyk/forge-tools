"""Socket module.
The goal is to achieve as close an interface as possible to
Python's [socket implementation](https://docs.python.org/3/library/socket.html)

From Python's socket docs:

This module provides socket operations and some related functions.
On Unix, it supports IP (Internet Protocol) and Unix domain sockets.
On other systems, it only supports IP. Functions specific for a
socket are available as methods of the socket object.

Functions:

socket() -- create a new socket object
socketpair() -- create a pair of new socket objects `[*]`
fromfd() -- create a socket object from an open file descriptor `[*]`
send_fds() -- Send file descriptor to the socket.
recv_fds() -- Receive file descriptors from the socket.
fromshare() -- create a socket object from data received from socket.share()
    `[*]`
gethostname() -- return the current hostname
gethostbyname() -- map a hostname to its IP number
gethostbyaddr() -- map an IP number or hostname to DNS info
getservbyname() -- map a service name and a protocol name to a port number
getprotobyname() -- map a protocol name (e.g. 'tcp') to a number
ntohs(), ntohl() -- convert 16, 32 bit int from network to host byte order
htons(), htonl() -- convert 16, 32 bit int from host to network byte order
inet_aton() -- convert IP addr string (123.45.67.89) to 32-bit packed format
inet_ntoa() -- convert 32-bit packed format IP to string (123.45.67.89)
socket.getdefaulttimeout() -- get the default timeout value
socket.setdefaulttimeout() -- set the default timeout value
create_connection() -- connects to an address, with an optional timeout and
                       optional source address.
create_server() -- create a TCP socket and bind it to a specified address.

`[*]` not available on all platforms!
"""

from ._linux import _LinuxSocket
from ._unix import _UnixSocket
from ._windows import _WindowsSocket


# TODO enum
struct SockFamily:
    alias IF_NET = "IF_NET"
    alias IF_NET6 = "IF_NET6"  # TODO: implement
    # TODO the rest


# TODO enum
struct SockType:
    alias SOCK_STREAM = "SOCK_STREAM"
    alias SOCK_DGRAM = "SOCK_DGRAM"  # TODO: implement
    alias SOCK_RAW = "SOCK_RAW"  # TODO: implement
    # TODO the rest


# TODO enum
struct SockProtocol:
    alias TCP = "TCP"
    alias UDP = "UDP"  # TODO: implement
    # TODO the rest


# TODO enum
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


# trait _SocketInterface:
#     """Interface for Sockets. `[*]` in function docstrings means not available
#     on all platforms!.
#     """

#     fn __init__(inout self) raises:
#         """Create a new socket object."""
#         ...

#     @staticmethod
#     async fn socket() -> Optional[Self]:
#         """Create a new socket object."""
#         ...

#     async fn socketpair(self) -> Optional[Bool]:
#         """Create a pair of new socket objects `[*]`."""
#         ...

#     async fn fromfd(self) -> Optional[Self]:
#         """Create a socket object from an open file descriptor `[*]`."""
#         ...

#     async fn send_fds(self) -> Optional[Bool]:
#         """Send file descriptor to the socket."""
#         ...

#     async fn recv_fds(self) -> Optional[String]:
#         """Receive file descriptors from the socket."""
#         ...

#     async fn fromshare(self) -> Optional[Self]:
#         """Create a socket object from data received from socket.share() `[*]`.
#         """
#         ...

#     async fn gethostname(
#         self,
#     ) -> Optional[String]:
#         """Return the current hostname."""
#         ...

#     async fn gethostbyname(
#         self,
#     ) -> Optional[String]:
#         """Map a hostname to its IP number."""
#         ...

#     async fn gethostbyaddr(
#         self,
#     ) -> Optional[String]:
#         """Map an IP number or hostname to DNS info."""
#         ...

#     async fn getservbyname(
#         self,
#     ) -> Optional[String]:
#         """Map a service name and a protocol name to a port number."""
#         ...

#     async fn getprotobyname(self) -> Optional[Int]:
#         """Map a protocol name (e.g. 'tcp') to a number."""
#         ...

#     async fn ntohs(self, value: Int) -> Optional[Int]:
#         """Convert 16, 32 bit int from network to host byte order."""
#         ...

#     async fn ntohl(self, value: Int) -> Optional[Int]:
#         """Convert 16, 32 bit int from network to host byte order."""
#         ...

#     async fn htons(self, value: Int) -> Optional[Int]:
#         """Convert 16, 32 bit int from host to network byte order."""
#         ...

#     async fn htonl(self, value: Int) -> Optional[Int]:
#         """Convert 16, 32 bit int from host to network byte order."""
#         ...

#     async fn inet_aton(self, value: String) -> Optional[UInt32]:
#         """Convert IP addr string (123.45.67.89) to 32-bit packed format."""
#         ...

#     async fn inet_ntoa(
#         self, value: UInt32
#     ) -> Optional[String]:
#         """Convert 32-bit packed format IP to string (123.45.67.89)."""
#         ...

#     async fn getdefaulttimeout(self) -> Optional[Float64]:
#         """Get the default timeout value."""
#         ...

#     async fn setdefaulttimeout(self, value: Float64) -> Optional[Bool]:
#         """Set the default timeout value."""
#         ...

#     async fn create_connection(self) -> Optional[Bool]:
#         """Connects to an address, with an optional timeout and
#         optional source address."""
#         ...

#     async fn create_server(self) -> Optional[Bool]:
#         """Create a TCP socket and bind it to a specified address."""
#         ...


@value
struct Socket[
    sock_family: StringLiteral,  # TODO: change once we have enums
    sock_type: StringLiteral,
    sock_protocol: StringLiteral,
    sock_platform: StringLiteral,
]:
    """Struct for using Sockets. `[*]` in function docstrings means not
    available on all platforms!.
    """

    alias _linux_s = _LinuxSocket[sock_family, sock_type, sock_protocol]
    alias _unix_s = _UnixSocket[sock_family, sock_type, sock_protocol]
    alias _windows_s = _WindowsSocket[sock_family, sock_type, sock_protocol]
    # TODO: need to be able to use _SocketInterface trait regardless of type
    alias _variant = Variant[Self._linux_s, Self._unix_s, Self._windows_s]
    var _impl: Self._variant

    fn __init__(inout self, impl: Self._variant):
        self._impl = impl

    fn __init__(inout self) raises:
        """Create a new socket object."""

        @parameter
        if sock_platform == SockPlatform.LINUX:
            self._impl = Self._linux_s()
        # elif sock_platform in (
        #     SockPlatform.UNIX,
        #     SockPlatform.APPLE,
        #     SockPlatform.BSD,
        # ):
        #     self._impl = Self._unix_s()
        # elif sock_platform == SockPlatform.WINDOWS:
        #     self._impl = Self._windows_s()
        else:
            constrained[False, "Platform not supported yet."]()
            self._impl = Self._linux_s()

    @staticmethod
    async fn socket() -> Optional[Self]:
        """Create a new socket object."""
        try:
            return Self()
        except:
            return None

    async fn socketpair(self) -> Optional[Bool]:
        """Create a pair of new socket objects `[*]`."""
        if self._impl.isa[Self._linux_s]():
            return await self._impl.unsafe_get[Self._linux_s]()[].socketpair()
        constrained[False, "Platform not supported yet."]()
        return None

    async fn fromfd(self) -> Optional[Self]:
        """Create a socket object from an open file descriptor `[*]`."""
        if self._impl.isa[Self._linux_s]():
            return Self(await self._impl.unsafe_get[Self._linux_s]()[].fromfd())
        constrained[False, "Platform not supported yet."]()
        return None

    async fn send_fds(self) -> Optional[Bool]:
        """Send file descriptor to the socket."""
        if self._impl.isa[Self._linux_s]():
            return await self._impl.unsafe_get[Self._linux_s]()[].send_fds()
        constrained[False, "Platform not supported yet."]()
        return None

    async fn recv_fds(self) -> Optional[String]:
        """Receive file descriptors from the socket."""
        if self._impl.isa[Self._linux_s]():
            return await self._impl.unsafe_get[Self._linux_s]()[].recv_fds()
        constrained[False, "Platform not supported yet."]()
        return None

    async fn fromshare(self) -> Optional[Self]:
        """Create a socket object from data received from socket.share() `[*]`.
        """
        if self._impl.isa[Self._linux_s]():
            return Self(
                await self._impl.unsafe_get[Self._linux_s]()[].fromshare()
            )
        constrained[False, "Platform not supported yet."]()
        return None

    async fn gethostname(
        self,
    ) -> Optional[String]:
        """Return the current hostname."""
        if self._impl.isa[Self._linux_s]():
            return await self._impl.unsafe_get[Self._linux_s]()[].gethostname()
        constrained[False, "Platform not supported yet."]()
        return None

    async fn gethostbyname(
        self,
    ) -> Optional[String]:
        """Map a hostname to its IP number."""
        if self._impl.isa[Self._linux_s]():
            return await self._impl.unsafe_get[
                Self._linux_s
            ]()[].gethostbyname()
        constrained[False, "Platform not supported yet."]()
        return None

    async fn gethostbyaddr(
        self,
    ) -> Optional[String]:
        """Map an IP number or hostname to DNS info."""
        if self._impl.isa[Self._linux_s]():
            return await self._impl.unsafe_get[
                Self._linux_s
            ]()[].gethostbyaddr()
        constrained[False, "Platform not supported yet."]()
        return None

    async fn getservbyname(
        self,
    ) -> Optional[String]:
        """Map a service name and a protocol name to a port number."""
        if self._impl.isa[Self._linux_s]():
            return await self._impl.unsafe_get[
                Self._linux_s
            ]()[].getservbyname()
        constrained[False, "Platform not supported yet."]()
        return None

    async fn getprotobyname(self) -> Optional[Int]:
        """Map a protocol name (e.g. 'tcp') to a number."""
        if self._impl.isa[Self._linux_s]():
            return await self._impl.unsafe_get[
                Self._linux_s
            ]()[].getprotobyname()
        constrained[False, "Platform not supported yet."]()
        return None

    async fn ntohs(self, value: Int) -> Optional[Int]:
        """Convert 16, 32 bit int from network to host byte order."""
        if self._impl.isa[Self._linux_s]():
            return await self._impl.unsafe_get[Self._linux_s]()[].ntohs(value)
        constrained[False, "Platform not supported yet."]()
        return None

    async fn ntohl(self, value: Int) -> Optional[Int]:
        """Convert 16, 32 bit int from network to host byte order."""
        if self._impl.isa[Self._linux_s]():
            return await self._impl.unsafe_get[Self._linux_s]()[].ntohl(value)
        constrained[False, "Platform not supported yet."]()
        return None

    async fn htons(self, value: Int) -> Optional[Int]:
        """Convert 16, 32 bit int from host to network byte order."""
        if self._impl.isa[Self._linux_s]():
            return await self._impl.unsafe_get[Self._linux_s]()[].htons(value)
        constrained[False, "Platform not supported yet."]()
        return None

    async fn htonl(self, value: Int) -> Optional[Int]:
        """Convert 16, 32 bit int from host to network byte order."""
        if self._impl.isa[Self._linux_s]():
            return await self._impl.unsafe_get[Self._linux_s]()[].htonl(value)
        constrained[False, "Platform not supported yet."]()
        return None

    async fn inet_aton(self, value: String) -> Optional[UInt32]:
        """Convert IP addr string (123.45.67.89) to 32-bit packed format."""
        if self._impl.isa[Self._linux_s]():
            return await self._impl.unsafe_get[Self._linux_s]()[].inet_aton(
                value
            )
        constrained[False, "Platform not supported yet."]()
        return None

    async fn inet_ntoa(self, value: UInt32) -> Optional[String]:
        """Convert 32-bit packed format IP to string (123.45.67.89)."""
        if self._impl.isa[Self._linux_s]():
            return await self._impl.unsafe_get[Self._linux_s]()[].inet_ntoa(
                value
            )
        constrained[False, "Platform not supported yet."]()
        return None

    async fn getdefaulttimeout(self) -> Optional[Float64]:
        """Get the default timeout value."""
        if self._impl.isa[Self._linux_s]():
            return await self._impl.unsafe_get[
                Self._linux_s
            ]()[].getdefaulttimeout()
        constrained[False, "Platform not supported yet."]()
        return None

    async fn setdefaulttimeout(self, value: Float64) -> Optional[Bool]:
        """Set the default timeout value."""
        if self._impl.isa[Self._linux_s]():
            return await self._impl.unsafe_get[
                Self._linux_s
            ]()[].setdefaulttimeout(value)
        constrained[False, "Platform not supported yet."]()
        return None

    async fn create_connection(self) -> Optional[Bool]:
        """Connects to an address, with an optional timeout and
        optional source address."""
        if self._impl.isa[Self._linux_s]():
            return await self._impl.unsafe_get[
                Self._linux_s
            ]()[].create_connection()
        constrained[False, "Platform not supported yet."]()
        return None

    async fn create_server(self) -> Optional[Bool]:
        """Create a TCP socket and bind it to a specified address."""
        if self._impl.isa[Self._linux_s]():
            return await self._impl.unsafe_get[
                Self._linux_s
            ]()[].create_server()
        constrained[False, "Platform not supported yet."]()
        return None
