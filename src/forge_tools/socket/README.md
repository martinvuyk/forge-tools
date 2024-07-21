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
            - Can an async API still wrap sync IO ?


#### Possible steps to approach this
1. Build scaffolding for most important platforms in an extensible manner.
2. Setup a Unified socket interface that all platforms adhere to but constraint
on what is currently supported for each.
3. Make sync APIs first with async wrappers, progresively develop async infra.
    1. Make sync TCP work for Linux as a starting point.
    2. Develop sync TCP for other platforms.
    3. Start making things really async under the hood.
    4. Develop other protocols.
