"""Socket package.
The goal is to achieve as close an interface as possible to
Python's [socket implementation](https://docs.python.org/3/library/socket.html).

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
# TODO: better docs and show examples.
from .socket import (
    Socket,
    SockFamily,
    SockType,
    SockProtocol,
    SockPlatform,
)
from .address import IPv4Addr, IPv6Addr, IPAddr, SockAddr
