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
    var a = List[Scalar[T]](capacity=capacity)
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
fn bench_list_init[capacity: Int](inout b: Bencher) raises:
    @always_inline
    @parameter
    fn call_fn():
        var p = DTypePointer[DType.int64].alloc(capacity)
        p.scatter(Int64(1), Int64(0))
        var res = List[Int64](
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
fn bench_list_insert[capacity: Int](inout b: Bencher) raises:
    var items = make_list[capacity]()

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
fn bench_list_lookup[capacity: Int](inout b: Bencher) raises:
    var items = make_list[capacity]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(0, capacity):
            var res = 0
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
fn bench_list_contains[capacity: Int](inout b: Bencher) raises:
    var items = make_list[capacity]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(0, capacity):
            var res = False
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
fn bench_list_count[capacity: Int](inout b: Bencher) raises:
    var items = make_list[capacity]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(0, capacity):
            var res = 0
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
fn bench_list_sum[capacity: Int](inout b: Bencher) raises:
    var items = make_list[capacity]()

    @always_inline
    @parameter
    fn call_fn() raises:
        var res: Int64 = 0
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
fn bench_list_filter[capacity: Int](inout b: Bencher) raises:
    var items = make_list[capacity]()

    fn filterfn(a: Int64) -> Scalar[DType.bool]:
        return a < (capacity // 2)

    @always_inline
    @parameter
    fn call_fn() raises:
        var res = List[Int64](capacity=capacity)
        var amnt = 0
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
fn bench_list_apply[capacity: Int](inout b: Bencher) raises:
    var items = make_list[capacity]()

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
fn bench_list_multiply[capacity: Int](inout b: Bencher) raises:
    var items = make_list[capacity]()

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
fn bench_list_reverse[capacity: Int](inout b: Bencher) raises:
    var items = make_list[capacity, DType.uint8]()

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
fn bench_list_dot[capacity: Int](inout b: Bencher) raises:
    var arr1 = make_list[capacity, DType.float64]()
    var arr2 = make_list[capacity, DType.float64]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for _ in range(1_000):
            var res: Float64 = 0
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
fn bench_list_cross(inout b: Bencher) raises:
    var arr1 = List[Float64](capacity=3)
    arr1[0] = random_float64(0, 500)
    arr1[1] = random_float64(0, 500)
    arr1[2] = random_float64(0, 500)
    var arr2 = List[Float64](capacity=3)
    arr2[0] = random_float64(0, 500)
    arr2[1] = random_float64(0, 500)
    arr2[2] = random_float64(0, 500)

    @always_inline
    @parameter
    fn call_fn() raises:
        for _ in range(1_000):
            var res = List[Float64](
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
    var m = Bench(BenchConfig(num_repetitions=5, warmup_iters=100))
    alias sizes = Tuple(3, 8, 16, 32, 64, 128, 256)

    @parameter
    for i in range(7):
        alias size = sizes.get[i, Int]()
        # m.bench_function[bench_list_init[size]](
        #     BenchId("bench_list_init[" + str(size) + "]")
        # )
        # m.bench_function[bench_list_insert[size]](
        #     BenchId("bench_list_insert[" + str(size) + "]")
        # )
        # m.bench_function[bench_list_lookup[size]](
        #     BenchId("bench_list_lookup[" + str(size) + "]")
        # )
        # m.bench_function[bench_list_contains[size]](
        #     BenchId("bench_list_contains[" + str(size) + "]")
        # )
        # m.bench_function[bench_list_count[size]](
        #     BenchId("bench_list_count[" + str(size) + "]")
        # )
        m.bench_function[bench_list_sum[size]](
            BenchId("bench_list_sum[" + str(size) + "]")
        )
        m.bench_function[bench_list_filter[size]](
            BenchId("bench_list_filter[" + str(size) + "]")
        )
        m.bench_function[bench_list_apply[size]](
            BenchId("bench_list_apply[" + str(size) + "]")
        )
        m.bench_function[bench_list_multiply[size]](
            BenchId("bench_list_multiply[" + str(size) + "]")
        )
        # m.bench_function[bench_list_reverse[size]](
        #     BenchId("bench_list_reverse[" + str(size) + "]")
        # )
        # m.bench_function[bench_list_dot[size]](
        #     BenchId("bench_list_dot[" + str(size) + "]")
        # )
        # m.bench_function[bench_list_cross](BenchId("bench_list_cross"))
    print("")
    var values = Dict[String, List[Float64]]()
    for i in m.info_vec:
        var res = i[].result.mean()
        var val = values.get(i[].name, List[Float64](0, 0))
        values[i[].name] = List[Float64](res + val[0], val[1] + 1)
    for i in values.items():
        print(i[].key, ":", i[].value[0] / i[].value[1])
