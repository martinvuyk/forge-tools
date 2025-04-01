from benchmark import (
    Bench,
    BenchConfig,
    Bencher,
    BenchId,
    Unit,
    keep,
    run,
)
from random import seed, random_float64

from forge_tools.collections import Array


# ===----------------------------------------------------------------------===#
# Benchmark Data
# ===----------------------------------------------------------------------===#
fn make_array[
    capacity: Int, static: Bool, T: DType = DType.int64
]() -> Array[T, capacity, static]:
    a = Array[T, capacity, static](fill=0)
    for i in range(0, capacity):

        @parameter
        if T == DType.int64:
            a.vec[i] = rebind[Scalar[T]](random.random_si64(0, capacity))
        elif T == DType.float64:
            a.vec[i] = rebind[Scalar[T]](random.random_float64(0, capacity))
    a.capacity_left = 0
    return a


# ===----------------------------------------------------------------------===#
# Benchmark Array init
# ===----------------------------------------------------------------------===#


@parameter
fn bench_array_init[capacity: Int, static: Bool](mut b: Bencher) raises:
    @always_inline
    @parameter
    fn call_fn():
        res = Array[DType.int64, capacity, static](fill=0)
        keep(res)

    b.iter[call_fn]()


# ===----------------------------------------------------------------------===#
# Benchmark Array Insert
# ===----------------------------------------------------------------------===#
@parameter
fn bench_array_insert[capacity: Int, static: Bool](mut b: Bencher) raises:
    arr = make_array[capacity, static]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(0, capacity):
            arr.insert(i, random.random_si64(0, capacity).value)

    b.iter[call_fn]()
    keep(arr.vec.value)


# ===----------------------------------------------------------------------===#
# Benchmark Array Lookup
# ===----------------------------------------------------------------------===#
@parameter
fn bench_array_lookup[capacity: Int, static: Bool](mut b: Bencher) raises:
    arr = make_array[capacity, static]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(0, capacity):
            res = arr.index(i)
            keep(res._value._impl)

    b.iter[call_fn]()
    keep(arr.vec.value)


# ===----------------------------------------------------------------------===#
# Benchmark Array contains
# ===----------------------------------------------------------------------===#
@parameter
fn bench_array_contains[capacity: Int, static: Bool](mut b: Bencher) raises:
    arr = make_array[capacity, static]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(0, capacity):
            res = i in arr
            keep(res)

    b.iter[call_fn]()
    keep(arr.vec.value)


# ===----------------------------------------------------------------------===#
# Benchmark Array count
# ===----------------------------------------------------------------------===#
@parameter
fn bench_array_count[capacity: Int, static: Bool](mut b: Bencher) raises:
    arr = make_array[capacity, static]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(0, capacity):
            res = arr.count(i)
            keep(res)

    b.iter[call_fn]()
    keep(arr.vec.value)


# ===----------------------------------------------------------------------===#
# Benchmark Array sum
# ===----------------------------------------------------------------------===#
@parameter
fn bench_array_sum[capacity: Int](mut b: Bencher) raises:
    arr = make_array[capacity, False]()

    @always_inline
    @parameter
    fn call_fn() raises:
        res = arr.sum()
        keep(res)

    b.iter[call_fn]()
    keep(arr.vec.value)


# ===----------------------------------------------------------------------===#
# Benchmark Array filter
# ===----------------------------------------------------------------------===#
@parameter
fn bench_array_filter[capacity: Int, static: Bool](mut b: Bencher) raises:
    arr = make_array[capacity, static]()

    fn filterfn(a: Int64) -> Scalar[DType.bool]:
        return a < (capacity // 2)

    @always_inline
    @parameter
    fn call_fn() raises:
        res = arr.filter(filterfn)
        keep(res)

    b.iter[call_fn]()
    keep(arr.vec.value)


# ===----------------------------------------------------------------------===#
# Benchmark Array apply
# ===----------------------------------------------------------------------===#
@parameter
fn bench_array_apply[capacity: Int, static: Bool](mut b: Bencher) raises:
    arr = make_array[capacity, static]()

    fn applyfn(a: Int64) -> Scalar[DType.int64]:
        if a < Int64.MAX_FINITE // 2:
            return a * 2
        return a

    @always_inline
    @parameter
    fn call_fn() raises:
        arr.apply(applyfn)

    b.iter[call_fn]()
    keep(arr.vec.value)


# ===----------------------------------------------------------------------===#
# Benchmark Array multiply
# ===----------------------------------------------------------------------===#
@parameter
fn bench_array_multiply[capacity: Int](mut b: Bencher) raises:
    arr = make_array[capacity, False]()

    @always_inline
    @parameter
    fn call_fn() raises:
        arr *= 2

    b.iter[call_fn]()
    keep(arr.vec.value)


# ===----------------------------------------------------------------------===#
# Benchmark Array reverse
# ===----------------------------------------------------------------------===#
@parameter
fn bench_array_reverse[capacity: Int](mut b: Bencher) raises:
    arr = make_array[capacity, False, DType.int64]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for _ in range(1_000):
            arr.reverse()

    b.iter[call_fn]()
    keep(arr.vec.value)


# ===----------------------------------------------------------------------===#
# Benchmark Array dot
# ===----------------------------------------------------------------------===#
@parameter
fn bench_array_dot[capacity: Int](mut b: Bencher) raises:
    arr1 = make_array[capacity, True, DType.float64]()
    arr2 = make_array[capacity, True, DType.float64]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for _ in range(1_000):
            res = arr1.dot(arr2)
            keep(res)

    b.iter[call_fn]()
    keep(arr1)
    keep(arr2)


# ===----------------------------------------------------------------------===#
# Benchmark Array cross
# ===----------------------------------------------------------------------===#
@parameter
fn bench_array_cross(mut b: Bencher) raises:
    arr1 = Array[DType.float64, 3, True](
        random_float64(0, 500), random_float64(0, 500), random_float64(0, 500)
    )
    arr2 = Array[DType.float64, 3, True](
        random_float64(0, 500), random_float64(0, 500), random_float64(0, 500)
    )

    @always_inline
    @parameter
    fn call_fn() raises:
        for _ in range(1_000):
            res = arr1.cross(arr2)
            keep(res)

    b.iter[call_fn]()
    keep(arr1)
    keep(arr2)


# ===----------------------------------------------------------------------===#
# Benchmark Main
# ===----------------------------------------------------------------------===#
def main():
    seed()
    m = Bench(BenchConfig(num_repetitions=5, warmup_iters=100))
    alias sizes = Tuple(3, 8, 16, 32, 64, 128, 256)

    @parameter
    for i in range(7):
        alias size = sizes.get[i, Int]()
        # m.bench_function[bench_array_init[size, False]](
        #     BenchId("bench_array_init[" + String(size) + "]")
        # )
        # FIXME: for some reason, static does not appear faster in these benchmarks
        # m.bench_function[bench_array_init[size, True]](
        #     BenchId("bench_array_init_static[" + String(size) + "]")
        # )
        # m.bench_function[bench_array_insert[size, False]](
        #     BenchId("bench_array_insert[" + String(size) + "]")
        # )
        # m.bench_function[bench_array_insert[size, True]](
        #     BenchId("bench_array_insert_static[" + String(size) + "]")
        # )
        # m.bench_function[bench_array_lookup[size, False]](
        #     BenchId("bench_array_lookup[" + String(size) + "]")
        # )
        # m.bench_function[bench_array_lookup[size, True]](
        #     BenchId("bench_array_lookup_static[" + String(size) + "]")
        # )
        # m.bench_function[bench_array_contains[size, False]](
        #     BenchId("bench_array_contains[" + String(size) + "]")
        # )
        # m.bench_function[bench_array_contains[size, True]](
        #     BenchId("bench_array_contains_static[" + String(size) + "]")
        # )
        # m.bench_function[bench_array_count[size, False]](
        #     BenchId("bench_array_count[" + String(size) + "]")
        # )
        # m.bench_function[bench_array_count[size, True]](
        #     BenchId("bench_array_count_static[" + String(size) + "]")
        # )
        m.bench_function[bench_array_sum[size]](
            BenchId("bench_array_sum[" + String(size) + "]")
        )
        m.bench_function[bench_array_filter[size, False]](
            BenchId("bench_array_filter[" + String(size) + "]")
        )
        # m.bench_function[bench_array_filter[size, True]](
        #     BenchId("bench_array_filter_static[" + String(size) + "]")
        # )
        m.bench_function[bench_array_apply[size, True]](
            BenchId("bench_array_apply[" + String(size) + "]")
        )
        # m.bench_function[bench_array_apply[size, True]](
        #     BenchId("bench_array_apply_static[" + String(size) + "]")
        # )
        m.bench_function[bench_array_multiply[size]](
            BenchId("bench_array_multiply[" + String(size) + "]")
        )
        # m.bench_function[bench_array_reverse[size]](
        #     BenchId("bench_array_reverse[" + String(size) + "]")
        # )
        # m.bench_function[bench_array_dot[size]](
        #     BenchId("bench_array_dot[" + String(size) + "]")
        # )
        # m.bench_function[bench_array_cross](BenchId("bench_array_cross"))

    print("")
    values = Dict[String, List[Float64]]()
    for i in m.info_vec:
        res = i[].result.mean()
        val = values.get(i[].name, List[Float64](0, 0))
        values[i[].name] = List[Float64](res + val[0], val[1] + 1)
    for i in values.items():
        print(i[].key, ":", i[].value[0] / i[].value[1])
