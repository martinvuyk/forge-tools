"""Libc POSIX networking syscalls."""

from sys.ffi import external_call
from memory import UnsafePointer
from .types import *


fn htonl(hostlong: C.u_int) -> C.u_int:
    """Libc POSIX `htonl` function.

    Args:
        hostlong: A 32-bit unsigned integer in host byte order.

    Returns:
        A 32-bit unsigned integer in network byte order.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/htonl.3p.html).
        Fn signature: `uint32_t htonl(uint32_t hostlong)`.
    """
    return external_call["htonl", C.u_int](hostlong)


fn htons(hostshort: C.u_short) -> C.u_short:
    """Libc POSIX `htons` function.

    Args:
        hostshort: A 16-bit unsigned integer in host byte order.

    Returns:
        A 16-bit unsigned integer in network byte order.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/htonl.3p.html).
        Fn signature: `uint16_t htons(uint16_t hostshort)`.
    """
    return external_call["htons", C.u_short](hostshort)


fn ntohl(netlong: C.u_int) -> C.u_int:
    """Libc POSIX `ntohl` function.

    Args:
        netlong: A 32-bit unsigned integer in network byte order.

    Returns:
        A 32-bit unsigned integer in host byte order.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/htonl.3p.html).
        Fn signature: `uint32_t ntohl(uint32_t netlong)`.
    """
    return external_call["ntohl", C.u_int](netlong)


fn ntohs(netshort: C.u_short) -> C.u_short:
    """Libc POSIX `ntohs` function.

    Args:
        netshort: A 16-bit unsigned integer in network byte order.

    Returns:
        A 16-bit unsigned integer in host byte order.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/htonl.3p.html).
        Fn signature: `uint16_t ntohs(uint16_t netshort)`.
    """
    return external_call["ntohs", C.u_short](netshort)


fn inet_ntop(
    af: C.int,
    src: UnsafePointer[C.void],
    dst: UnsafePointer[C.char],
    size: socklen_t,
) -> UnsafePointer[C.char]:
    """Libc POSIX `inet_ntop` function.

    Args:
        af: Address Family see AF_ alises.
        src: A pointer to a binary address.
        dst: A pointer to a buffer to store the string representation of the
            address.
        size: The size of the buffer pointed by dst.

    Returns:
        A pointer to the buffer containing the text string if the conversion
        succeeds, and `NULL` otherwise, and set `errno` to indicate the error.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/inet_ntop.3p.html.).
        Fn signature: `const char *inet_ntop(int af, const void *restrict src,
            char *restrict dst, socklen_t size)`.
    """
    return external_call["inet_ntop", UnsafePointer[C.char]](af, src, dst, size)


fn inet_pton(
    af: C.int, src: UnsafePointer[C.char], dst: UnsafePointer[C.void]
) -> C.int:
    """Libc POSIX `inet_pton` function.

    Args:
        af: Address Family see AF_ alises.
        src: A pointer to a string representation of an address.
        dst: A pointer to a buffer to store the binary address.

    Returns:
        Returns 1 on success (network address was successfully converted). 0 is
        returned if src does not contain a character string representing a valid
        network address in the specified address family.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/inet_ntop.3p.html).
        Fn signature: `int inet_pton(int af, const char *restrict src,
            void *restrict dst)`.
    """
    return external_call["inet_pton", C.int](af, src, dst)


fn inet_addr(cp: UnsafePointer[C.char]) -> in_addr_t:
    """Libc POSIX `inet_addr` function.

    Args:
        cp: A pointer to a string representation of an address.

    Returns:
        If the input is invalid, INADDR_NONE (usually -1) is returned. Use of
        this function is problematic because -1 is a valid address
        `(255.255.255.255)`. Avoid its use in favor of inet_aton(),
        inet_pton(3), or getaddrinfo(3), which provide a cleaner way to indicate
        error return.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/inet_addr.3p.html).
        Fn signature: `in_addr_t inet_addr(const char *cp)`.
    """
    return external_call["inet_addr", in_addr_t](cp)


fn inet_aton(cp: UnsafePointer[C.char], addr: UnsafePointer[in_addr]) -> C.int:
    """Libc POSIX `inet_aton` function.

    Args:
        cp: A pointer to a string representation of an address.
        addr: A pointer to a binary address.

    Returns:
        Value 1 if successful, 0 if the string is invalid.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/inet_aton.3.html).
        Fn signature: `int inet_aton(const char *cp, struct in_addr *inp)`.
    """
    return external_call["inet_aton", C.int](cp, addr)


fn inet_ntoa(addr: in_addr) -> UnsafePointer[C.char]:
    """Libc POSIX `inet_ntoa` function.

    Args:
        addr: A pointer to a binary address.

    Returns:
        A pointer to the string in IPv4 dotted-decimal notation.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/inet_addr.3p.html).
        Fn signature: `char *inet_ntoa(struct in_addr in)`.
        Allocated buffer is 16-18 bytes depending on implementation.
    """
    return external_call["inet_ntoa", UnsafePointer[C.char]](addr)


fn socket(domain: C.int, type: C.int, protocol: C.int) -> C.int:
    """Libc POSIX `socket` function.

    Args:
        domain: Address Family see AF_ alises.
        type: Socket Type see SOCK_ alises.
        protocol: Protocol see IPPROTO_ alises.

    Returns:
        A file descriptor for the socket.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/socket.3p.html).
        Fn signature: `int socket(int domain, int type, int protocol)`.
    """
    return external_call["socket", C.int](domain, type, protocol)


fn socketpair(
    domain: C.int,
    type: C.int,
    protocol: C.int,
    socket_vector: UnsafePointer[C.int],
) -> C.int:
    """Libc POSIX `socketpair` function.

    Args:
        domain: Address Family see AF_ alises.
        type: Socket Type see SOCK_ alises.
        protocol: Protocol see IPPROTO_ alises.
        socket_vector: A pointer of `C.int` of length 2 to store the file
            descriptors.

    Returns:
        Value 0 on success, -1 on error and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/socketpair.3p.html).
        Fn signature: `int socketpair(int domain, int type, int protocol,
           int socket_vector[2])`.
    """
    return external_call["socket", C.int](domain, type, protocol, socket_vector)


fn setsockopt(
    socket: C.int,
    level: C.int,
    option_name: C.int,
    option_value: UnsafePointer[C.void],
    option_len: socklen_t,
) -> C.int:
    """Libc POSIX `setsockopt` function.

    Args:
        socket: The socket's file descriptor.
        level: Protocol Level see SOL_ alises.
        option_name: Option name see SO_ alises.
        option_value: A pointer to a buffer containing the option value.
        option_len: The size of the buffer pointed by option_value.

    Returns:
        Value 0 on success, -1 on error and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/setsockopt.3p.html).
        Fn signature: `int setsockopt(int socket, int level, int option_name,
            const void *option_value, socklen_t option_len)`.
    """
    return external_call["setsockopt", C.int](
        socket, level, option_name, option_value, option_len
    )


fn bind(
    socket: C.int, address: UnsafePointer[sockaddr], address_len: socklen_t
) -> C.int:
    """Libc POSIX `bind` function.

    Args:
        socket: The socket's file descriptor.
        address: A pointer to the address.
        address_len: The length of the pointer.

    Returns:
        Value 0 on success, -1 on error and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/bind.3p.html).
        Fn signature: `int bind(int socket, const struct sockaddr *address,
            socklen_t address_len)`.
    """
    return external_call["bind", C.int](socket, address, address_len)


fn listen(socket: C.int, backlog: C.int) -> C.int:
    """Libc POSIX `listen` function.

    Args:
        socket: The socket's file descriptor.
        backlog: The maximum length to which the queue of pending connections
            for socket may grow.

    Returns:
        Value 0 on success, -1 on error and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/listen.3p.html).
        Fn signature: `int listen(int socket, int backlog)`.
    """
    return external_call["listen", C.int, C.int, C.int](socket, backlog)


fn accept(
    socket: C.int,
    address: UnsafePointer[sockaddr],
    address_len: UnsafePointer[socklen_t],
) -> C.int:
    """Libc POSIX `accept` function.

    Args:
        socket: The socket's file descriptor.
        address: A pointer to a buffer to store the address of the accepted
            socket.
        address_len: A pointer to a buffer to store the length of the address of
            the accepted socket.

    Returns:
        Value 0 on success, -1 on error and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/accept.3p.html).
        Fn signature: `int accept(int socket, struct sockaddr *restrict address,
            socklen_t *restrict address_len);`.
    """
    return external_call["accept", C.int](socket, address, address_len)


fn connect(
    socket: C.int, address: UnsafePointer[sockaddr], address_len: socklen_t
) -> C.int:
    """Libc POSIX `connect` function.

    Args:
        socket: The socket's file descriptor.
        address: A pointer of the address to connect to.
        address_len: The length of the address.

    Returns:
        Value 0 on success, -1 on error and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/connect.3p.html).
        Fn signature: `int connect(int socket, const struct sockaddr *address,
            socklen_t address_len)`.
    """
    return external_call["connect", C.int](socket, address, address_len)


fn recv(
    socket: C.int, buffer: UnsafePointer[C.void], length: size_t, flags: C.int
) -> ssize_t:
    """Libc POSIX `recv` function.

    Args:
        socket: The socket's file descriptor.
        buffer: A pointer to a buffer to store the recieved bytes.
        length: The amount of bytes to store in the buffer.
        flags: Specifies the type of message reception.

    Returns:
        The amount of bytes recieved. Value -1 on error and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/recv.3p.html).
        Fn signature: `ssize_t recv(int socket, void *buffer, size_t length,
            int flags)`.
    """
    return external_call["recv", ssize_t](socket, buffer, length, flags)


fn recvfrom(
    socket: C.int,
    buffer: UnsafePointer[C.void],
    length: size_t,
    flags: C.int,
    address: UnsafePointer[sockaddr],
    address_len: UnsafePointer[socklen_t],
) -> ssize_t:
    """Libc POSIX `recvfrom` function.

    Args:
        socket: The socket's file descriptor.
        buffer: A pointer to a buffer to store the recieved bytes.
        length: The amount of bytes to store in the buffer.
        flags: Specifies the type of message reception.
        address: A pointer to a sockaddr to store the address of the sending
            socket.
        address_len: A pointer to a buffer to store the length of the address of
            the sending socket.

    Returns:
        The amount of bytes recieved. Value -1 on error and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/recvfrom.3p.html).
        Fn signature: `ssize_t recvfrom(int socket, void *restrict buffer,
            size_t length, int flags, struct sockaddr *restrict address,
            socklen_t *restrict address_len)`.
    """
    return external_call["recvfrom", ssize_t](
        socket, buffer, length, flags, address, address_len
    )


fn send(
    socket: C.int, buffer: UnsafePointer[C.void], length: size_t, flags: C.int
) -> ssize_t:
    """Libc POSIX `send` function.

    Args:
        socket: The socket's file descriptor.
        buffer: Points to the buffer containing the message to send.
        length: Specifies the length of the message in bytes.
        flags: Specifies the type of message transmission.

    Returns:
        The number of bytes sent. Value -1 on error and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/send.3p.html).
        Fn signature: `ssize_t send(int socket, const void *buffer,
            size_t length, int flags)`.
    """
    return external_call["send", ssize_t](socket, buffer, length, flags)


fn sendto(
    socket: C.int,
    message: UnsafePointer[C.void],
    length: size_t,
    flags: C.int,
    dest_addr: UnsafePointer[sockaddr],
    dest_len: socklen_t,
) -> ssize_t:
    """Libc POSIX `sendto` function.

    Args:
        socket: The socket's file descriptor.
        message: A pointer to a buffer to store the address of the accepted
            socket.
        length: A pointer to a buffer to store the length of the address of the
            accepted socket.
        flags: A pointer to a buffer to store the length of the address of the
            accepted socket.
        dest_addr: A pointer to a buffer to store the length of the address of
            the accepted socket.
        dest_len: A pointer to a buffer to store the length of the address of
            the accepted socket.

    Returns:
        The number of bytes sent. Value -1 on error and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/sendto.3p.html).
        Fn signature: `ssize_t sendto(int socket, const void *message,
            size_t length, int flags, const struct sockaddr *dest_addr,
            socklen_t dest_len)`.
    """
    return external_call["sendto", ssize_t](
        socket, message, length, flags, dest_addr, dest_len
    )


fn shutdown(socket: C.int, how: C.int) -> C.int:
    """Libc POSIX `shutdown` function.

    Args:
        socket: The socket's file descriptor.
        how: A pointer to a buffer to store the length of the address of the
            accepted socket.

    Returns:
        Value 0 on success, -1 on error and `errno` is set.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/shutdown.3p.html).
        Fn signature: `int shutdown(int socket, int how)`.
    """
    return external_call["shutdown", C.int](socket, how)


# FIXME: res should be res: UnsafePointer[UnsafePointer[addrinfo]]
fn getaddrinfo(
    nodename: UnsafePointer[C.char],
    servname: UnsafePointer[C.char],
    hints: UnsafePointer[addrinfo],
    res: UnsafePointer[C.ptr_addr],
) -> C.int:
    """Libc POSIX `getaddrinfo` function.

    Args:
        nodename: The node name.
        servname: The service name.
        hints: The hints.
        res: The Pointer to the Pointer to store the result.

    Returns:
        Value 0 on success, one of several errors otherwise.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/freeaddrinfo.3p.html).
        Fn signature: `int getaddrinfo(const char *restrict nodename,
            const char *restrict servname, const struct addrinfo *restrict hints
            , struct addrinfo **restrict res)`.
    """
    return external_call["getaddrinfo", C.int](nodename, servname, hints, res)


fn gai_strerror(ecode: C.int) -> UnsafePointer[C.char]:
    """Libc POSIX `gai_strerror` function.

    Args:
        ecode: An error code.

    Returns:
        A pointer to a text string describing an error value for the
        `getaddrinfo()` and `getnameinfo()` functions.

    Notes:
        [Reference](https://man7.org/linux/man-pages/man3/gai_strerror.3p.html).
        Fn signature: `const char *gai_strerror(int ecode)`.
    """
    return external_call["gai_strerror", UnsafePointer[C.char]](ecode)
