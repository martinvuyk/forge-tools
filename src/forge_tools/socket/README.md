# Notes on Socket
I'll use this document to note down my thoughts as I'm still reading up and
trying to come up with something worthy.


#### Compatibility with Python
- How much compatibility and at what API layer do we enforce it?
    - Is the endgoal ASGI compatibility or that the socket interface remains as
    similar to Python's as possible ?
- How do we prepare the infrastructure for those higher level APIs while still
allowing lower level control if desired for other protocols ?
- Do we develop an async only interface ?


#### Decisions on the choice of kernel IO protocols
- Should we even develop a syncronous poll model like Python's?
- Is it worth it using [io_uring](https://kernel.dk/io_uring.pdf) (Linux),
[kqueue](https://man.freebsd.org/cgi/man.cgi?query=kqueue&sektion=2) (Unix),
[IOCP](
https://learn.microsoft.com/en-us/windows/win32/fileio/i-o-completion-ports)
(Windows) ?
    - How much would we need to deviate from Python's APIs ?
        - Do we setup a unified async API like [Tigerbeetle's](
https://tigerbeetle.com/blog/a-friendly-abstraction-over-iouring-and-kqueue) ?
            - Can we keep mostly the same API as Python's but make it async ?
    - How do we deal with external C library dependencies like [liburing](
    https://github.com/axboe/liburing) if we decide to use it ?
        - Do we wait for everything to be implemented in Mojo ? 
        ([io_uring project](https://github.com/dmitry-salin/io_uring))
    - How portable is an async completion model for WASI and microcontrollers
    (FreeRTOS & others) ?
        - How do we deal with other platforms without async IO in the kernel ?


#### Possible steps to approach this
1. Build scaffolding for most important platforms in an extensible manner.
2. Setup a Unified socket interface that all platforms adhere to but constraint
on what is currently supported for each.
3. Make sync APIs first with async wrappers, progresively develop async infra.
    1. Make sync TCP work for Linux as a starting point.
    2. Develop sync TCP for other platforms.
    3. Start making things really async under the hood.
    4. Develop other protocols.



#### Current outlook
The idea is for the Socket struct to be the overarching API for any one platform
specific socket implementation
```mojo
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
   """
   ...
```

The idea is for the interface to be generic and let each implementation
constraint at compile time what it supports and what it doesn't.

The Socket struct should be parametrizable with the implementation of the
socket interface 
```mojo
socket_impl: SocketInterface = _LinuxSocket[
    sock_family, sock_type, sock_protocol, sock_address
]
```

The interface for any socket implementation looks like this:
(many features are not part of the Mojo language, take it as pseudocode)
```mojo
trait SocketInterface[
    sock_family: SockFamily,
    sock_type: SockType,
    sock_protocol: SockProtocol,
    sock_address: SockAddr,
    sock_platform: SockPlatform,
](CollectionElement):
    """Interface for Sockets."""

    fn __init__(inout self) raises:
        """Create a new socket object."""
        ...

   fn __init__(inout self, fd: FileDescriptor):
       """Create a new socket object from an open `FileDescriptor`."""
       ...

    fn close(owned self) raises:
        """Closes the Socket."""
        ...

    fn __del__(owned self):
        """Closes the Socket if it's the last reference to its
        `FileDescriptor`.
        """
        ...

    fn setsockopt(self, level: Int, option_name: Int, option_value: Int) raises:
        """Set socket options."""
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

    # TODO: This should return an async iterator instead
    async fn accept(self) -> (Self, sock_address):
        """Return a new socket representing the connection, and the address of
        the client."""
        ...

   # TODO: once we have async generators
   fn __iter__(self) -> _SocketIter:
       """Iterate asynchronously over the incoming connections."""
       ...

    @staticmethod
    async fn socketpair() raises -> (Self, Self):
        """Create a pair of socket objects from the sockets returned by the
        platform `socketpair()` function."""
        ...

    async fn send_fds(self, fds: List[FileDescriptor]) -> Bool:
        """Send file descriptor to the socket."""
        ...

    async fn recv_fds(self, maxfds: Int) -> List[FileDescriptor]:
        """Receive file descriptors from the socket."""
        ...

    async fn send(self, buf: Span[UInt8]) -> UInt:
        """Send a buffer of bytes to the socket."""
        return 0

    async fn recv(self, buf: Span[UInt8]) -> UInt:
        """Receive up to `len(buf)` bytes into the buffer."""
        return 0

    @staticmethod
    fn gethostname() -> Optional[String]:
        """Return the current hostname."""
        ...

    @staticmethod
    fn gethostbyname(name: String) -> Optional[sock_address]:
        """Map a hostname to its Address."""
        ...

    @staticmethod
    fn gethostbyaddr(address: sock_address) -> Optional[String]:
        """Map an Address to DNS info."""
        ...

    @staticmethod
    fn getservbyname(
        name: String, proto: SockProtocol = SockProtocol.TCP
    ) -> Optional[sock_address]:
        """Map a service name and a protocol name to a port number."""
        ...

    @staticmethod
    fn getdefaulttimeout() -> Optional[Float64]:
        """Get the default timeout value."""
        ...

    @staticmethod
    fn setdefaulttimeout(value: Optional[Float64]) -> Bool:
        """Set the default timeout value."""
        ...

    fn settimeout(self, value: Optional[Float64]) -> Bool:
        """Set the socket timeout value."""
        ...

   # TODO: This should return an iterator instead
   @staticmethod
   fn getaddrinfo(
       address: sock_address, flags: Int = 0
   ) raises -> List[
       (SockFamily, SockType, SockProtocol, String, sock_address)
   ]:
       """Get the available address information.
       ...
```


What this all will allow is to build higher level pythonic syntax to do servers
for any protocol and inject whatever implementation for any platform specific
use case that the user does not find in the stdlib but exists in an external
library.

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
