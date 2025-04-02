from benchmark import (
    Bench,
    BenchConfig,
    Bencher,
    BenchId,
    Unit,
    keep,
    run,
    clobber_memory,
)
from random import seed, random_float64


# ===----------------------------------------------------------------------===#
# Benchmark Data
# ===----------------------------------------------------------------------===#
fn make_list[capacity: Int, T: DType = DType.int64]() -> List[Scalar[T]]:
    a = List[Scalar[T]](capacity=capacity)
    for i in range(0, capacity):

        @parameter
        if T == DType.int64:
            a[i] = rebind[Scalar[T]](random.random_si64(0, capacity))
        elif T == DType.float64:
            a[i] = rebind[Scalar[T]](random.random_float64(0, capacity))
        else:
            a[i] = 0
    a.size = capacity
    return a^


# ===----------------------------------------------------------------------===#
# Benchmark list init
# ===----------------------------------------------------------------------===#


@parameter
fn bench_list_init[capacity: Int](mut b: Bencher) raises:
    @always_inline
    @parameter
    fn call_fn():
        p = DTypePointer[DType.int64].alloc(capacity)
        p.scatter(Int64(1), Int64(0))
        res = List[Int64](
            unsafe_pointer=UnsafePointer[Int64]._from_dtype_ptr(p),
            size=capacity,
            capacity=capacity,
        )
        clobber_memory()
        keep(res.data.address)

    b.iter[call_fn]()


# ===----------------------------------------------------------------------===#
# Benchmark list Insert
# ===----------------------------------------------------------------------===#
@parameter
fn bench_list_insert[capacity: Int](mut b: Bencher) raises:
    items = make_list[capacity]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(0, capacity):
            items.insert(i, random.random_si64(0, capacity).value)
        clobber_memory()

    b.iter[call_fn]()
    keep(items.data.address)


# ===----------------------------------------------------------------------===#
# Benchmark list Lookup
# ===----------------------------------------------------------------------===#
@parameter
fn bench_list_lookup[capacity: Int](mut b: Bencher) raises:
    items = make_list[capacity]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(0, capacity):
            res = 0
            for idx in range(capacity):
                if items.unsafe_get(idx) == i:
                    res = idx
                    break
            keep(res)

    b.iter[call_fn]()
    keep(items.data.address)


# ===----------------------------------------------------------------------===#
# Benchmark list contains
# ===----------------------------------------------------------------------===#
@parameter
fn bench_list_contains[capacity: Int](mut b: Bencher) raises:
    items = make_list[capacity]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(0, capacity):
            res = False
            for idx in range(capacity):
                if items.unsafe_get(idx) == i:
                    res = True
                    break
            keep(res)

    b.iter[call_fn]()
    keep(items.data.address)


# ===----------------------------------------------------------------------===#
# Benchmark list count
# ===----------------------------------------------------------------------===#
@parameter
fn bench_list_count[capacity: Int](mut b: Bencher) raises:
    items = make_list[capacity]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(0, capacity):
            res = 0
            for idx in range(capacity):
                if items.unsafe_get(idx) == i:
                    res += 1
            keep(res)

    b.iter[call_fn]()
    keep(items.data.address)


# ===----------------------------------------------------------------------===#
# Benchmark list sum
# ===----------------------------------------------------------------------===#
@parameter
fn bench_list_sum[capacity: Int](mut b: Bencher) raises:
    items = make_list[capacity]()

    @always_inline
    @parameter
    fn call_fn() raises:
        res: Int64 = 0
        for i in range(capacity):
            res += items.unsafe_get(i)
        clobber_memory()
        keep(res)

    b.iter[call_fn]()
    keep(items.data.address)


# ===----------------------------------------------------------------------===#
# Benchmark list filter
# ===----------------------------------------------------------------------===#
@parameter
fn bench_list_filter[capacity: Int](mut b: Bencher) raises:
    items = make_list[capacity]()

    fn filterfn(a: Int64) -> Scalar[DType.bool]:
        return a < (capacity // 2)

    @always_inline
    @parameter
    fn call_fn() raises:
        res = List[Int64](capacity=capacity)
        amnt = 0
        for i in range(capacity):
            if filterfn(items.unsafe_get(i)):
                res.unsafe_set(amnt, items.unsafe_get(i))
                amnt += 1
                clobber_memory()
        keep(res.data.address)

    b.iter[call_fn]()
    keep(items.data.address)


# ===----------------------------------------------------------------------===#
# Benchmark list apply
# ===----------------------------------------------------------------------===#
@parameter
fn bench_list_apply[capacity: Int](mut b: Bencher) raises:
    items = make_list[capacity]()

    fn applyfn(a: Int64) -> Scalar[DType.int64]:
        if a < Int64.MAX_FINITE // 2:
            return a * 2
        return a

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(capacity):
            items.unsafe_set(i, applyfn(items.unsafe_get(i)))
            clobber_memory()

    b.iter[call_fn]()
    keep(items.data.address)


# ===----------------------------------------------------------------------===#
# Benchmark list multiply
# ===----------------------------------------------------------------------===#
@parameter
fn bench_list_multiply[capacity: Int](mut b: Bencher) raises:
    items = make_list[capacity]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(capacity):
            items.unsafe_set(i, items.unsafe_get(i) * 2)
            clobber_memory()

    b.iter[call_fn]()
    keep(items.data.address)


# ===----------------------------------------------------------------------===#
# Benchmark list reverse
# ===----------------------------------------------------------------------===#
@parameter
fn bench_list_reverse[capacity: Int](mut b: Bencher) raises:
    items = make_list[capacity, DType.uint8]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for _ in range(1_000):
            items.reverse()
            clobber_memory()

    b.iter[call_fn]()
    keep(items.data.address)


# ===----------------------------------------------------------------------===#
# Benchmark list dot
# ===----------------------------------------------------------------------===#
@parameter
fn bench_list_dot[capacity: Int](mut b: Bencher) raises:
    arr1 = make_list[capacity, DType.float64]()
    arr2 = make_list[capacity, DType.float64]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for _ in range(1_000):
            res: Float64 = 0
            for i in range(len(arr1)):
                res += arr1.unsafe_get(i) * arr2.unsafe_get(i)
            clobber_memory()
            keep(res)

    b.iter[call_fn]()
    keep(arr1.data)
    keep(arr2.data)


# ===----------------------------------------------------------------------===#
# Benchmark list cross
# ===----------------------------------------------------------------------===#
@parameter
fn bench_list_cross(mut b: Bencher) raises:
    arr1 = List[Float64](capacity=3)
    arr1[0] = random_float64(0, 500)
    arr1[1] = random_float64(0, 500)
    arr1[2] = random_float64(0, 500)
    arr2 = List[Float64](capacity=3)
    arr2[0] = random_float64(0, 500)
    arr2[1] = random_float64(0, 500)
    arr2[2] = random_float64(0, 500)

    @always_inline
    @parameter
    fn call_fn() raises:
        for _ in range(1_000):
            res = List[Float64](
                arr1.unsafe_get(1) * arr2.unsafe_get(2)
                - arr1.unsafe_get(2) * arr2.unsafe_get(1),
                arr1.unsafe_get(2) * arr2.unsafe_get(0)
                - arr1.unsafe_get(0) * arr2.unsafe_get(2),
                arr1.unsafe_get(0) * arr2.unsafe_get(1)
                - arr1.unsafe_get(1) * arr2.unsafe_get(0),
            )
            keep(res.data.address)

    b.iter[call_fn]()
    keep(arr1.data)
    keep(arr2.data)


# ===----------------------------------------------------------------------===#
# Benchmark Main
# ===----------------------------------------------------------------------===#
def main():
    seed()
    m = Bench(BenchConfig(num_repetitions=5, warmup_iters=100))
    alias sizes = Tuple(3, 8, 16, 32, 64, 128, 256)

    @parameter
    for i in range(7):
        alias size = sizes[i]
        # m.bench_function[bench_list_init[size]](
        #     BenchId("bench_list_init[" + String(size) + "]")
        # )
        # m.bench_function[bench_list_insert[size]](
        #     BenchId("bench_list_insert[" + String(size) + "]")
        # )
        # m.bench_function[bench_list_lookup[size]](
        #     BenchId("bench_list_lookup[" + String(size) + "]")
        # )
        # m.bench_function[bench_list_contains[size]](
        #     BenchId("bench_list_contains[" + String(size) + "]")
        # )
        # m.bench_function[bench_list_count[size]](
        #     BenchId("bench_list_count[" + String(size) + "]")
        # )
        m.bench_function[bench_list_sum[size]](
            BenchId("bench_list_sum[" + String(size) + "]")
        )
        m.bench_function[bench_list_filter[size]](
            BenchId("bench_list_filter[" + String(size) + "]")
        )
        m.bench_function[bench_list_apply[size]](
            BenchId("bench_list_apply[" + String(size) + "]")
        )
        m.bench_function[bench_list_multiply[size]](
            BenchId("bench_list_multiply[" + String(size) + "]")
        )
        # m.bench_function[bench_list_reverse[size]](
        #     BenchId("bench_list_reverse[" + String(size) + "]")
        # )
        # m.bench_function[bench_list_dot[size]](
        #     BenchId("bench_list_dot[" + String(size) + "]")
        # )
        # m.bench_function[bench_list_cross](BenchId("bench_list_cross"))
    print("")
    values = Dict[String, List[Float64]]()
    for i in m.info_vec:
        res = i[].result.mean()
        val = values.get(i[].name, List[Float64](0, 0))
        values[i[].name] = List[Float64](res + val[0], val[1] + 1)
    for i in values.items():
        print(i[].key, ":", i[].value[0] / i[].value[1])
