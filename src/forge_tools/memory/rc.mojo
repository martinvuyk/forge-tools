"""Reference counter module."""
from memory import UnsafePointer


struct _RcInner[T: Movable]:
    var refcount: UInt64
    var payload: T

    fn __init__(out self, owned value: T):
        """Create an initialized instance of this with a refcount of 1."""
        self.refcount = 1
        self.payload = value^

    fn add_ref(out self):
        """Increment the refcount."""
        self.refcount += 1

    fn drop_ref(out self):
        """Decrement the refcount and return true if the result hits zero."""
        self.refcount -= 1


@register_passable
struct Rc[T: Movable]:
    """Reference counter."""

    alias _inner_type = _RcInner[T]
    var _inner: UnsafePointer[_RcInner[T]]

    fn __init__(out self, owned value: T):
        """Create an initialized instance of this with a refcount of 1."""
        self._inner = UnsafePointer[Self._inner_type].alloc(1)
        # Cannot use init_pointee_move as _ArcInner isn't movable.
        __get_address_as_uninit_lvalue(self._inner.address) = Self._inner_type(
            value^
        )

    fn __init__(out self, *, other: Self):
        """Copy the object.

        Args:
            other: The value to copy.
        """
        other._inner[].add_ref()
        self._inner = other._inner

    fn __copyinit__(out self, existing: Self):
        """Copy an existing reference. Increment the refcount to the object.

        Args:
            existing: The existing reference.
        """
        # Order here does not matter since `existing` can't be destroyed until
        # sometime after we return.
        existing._inner[].add_ref()
        self._inner = existing._inner

    fn increment(out self):
        self._inner[].add_ref()

    fn decrement(out self):
        self._inner[].drop_ref()

    @no_inline
    fn __del__(owned self):
        """Delete the smart pointer reference.

        Decrement the ref count for the reference. If there are no more
        references, delete the object and free its memory.
        """
        self.decrement()

        if self.count() == 1:
            # Call inner destructor, then free the memory.
            self._inner.destroy_pointee()
            self._inner.free()

    fn count(self) -> UInt64:
        """Count the amount of current references.

        Returns:
            The current amount of references to the pointee.
        """
        return self._inner[0].refcount[0]

    fn unsafe_ptr(self) -> UnsafePointer[T]:
        """Retrieves a pointer to the underlying memory.

        Returns:
            The UnsafePointer to the underlying memory.
        """
        return UnsafePointer.address_of(self._inner[0].payload)
