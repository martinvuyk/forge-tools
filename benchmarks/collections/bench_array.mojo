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
    var a = Array[T, capacity, static]()
    for i in range(0, capacity):

        @parameter
        if T == DType.int64:
            a[i] = rebind[Scalar[T]](random.random_si64(0, capacity))
        elif T == DType.float64:
            a[i] = rebind[Scalar[T]](random.random_float64(0, capacity))
    a.capacity_left = 0
    return a


# ===----------------------------------------------------------------------===#
# Benchmark Array init
# ===----------------------------------------------------------------------===#


@parameter
fn bench_array_init[capacity: Int, static: Bool](inout b: Bencher) raises:
    @always_inline
    @parameter
    fn call_fn():
        var res = Array[DType.int64, capacity, static]()
        keep(res)

    b.iter[call_fn]()


# ===----------------------------------------------------------------------===#
# Benchmark Array Insert
# ===----------------------------------------------------------------------===#
@parameter
fn bench_array_insert[capacity: Int, static: Bool](inout b: Bencher) raises:
    var arr = make_array[capacity, static]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(0, capacity):
            arr.insert(i, random.random_si64(0, capacity).value)

    b.iter[call_fn]()
    keep(arr)


# ===----------------------------------------------------------------------===#
# Benchmark Array Lookup
# ===----------------------------------------------------------------------===#
@parameter
fn bench_array_lookup[capacity: Int, static: Bool](inout b: Bencher) raises:
    var arr = make_array[capacity, static]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(0, capacity):
            var res = arr.index(i)
            keep(res)

    b.iter[call_fn]()
    keep(arr)


# ===----------------------------------------------------------------------===#
# Benchmark Array contains
# ===----------------------------------------------------------------------===#
@parameter
fn bench_array_contains[capacity: Int, static: Bool](inout b: Bencher) raises:
    var arr = make_array[capacity, static]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(0, capacity):
            var res = i in arr
            keep(res)

    b.iter[call_fn]()
    keep(arr)


# ===----------------------------------------------------------------------===#
# Benchmark Array count
# ===----------------------------------------------------------------------===#
@parameter
fn bench_array_count[capacity: Int, static: Bool](inout b: Bencher) raises:
    var arr = make_array[capacity, static]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(0, capacity):
            var res = arr.count(i)
            keep(res)

    b.iter[call_fn]()
    keep(arr)


# ===----------------------------------------------------------------------===#
# Benchmark Array sum
# ===----------------------------------------------------------------------===#
@parameter
fn bench_array_sum[capacity: Int](inout b: Bencher) raises:
    var arr = make_array[capacity, False]()

    @always_inline
    @parameter
    fn call_fn() raises:
        var res = arr.sum()
        keep(res)

    b.iter[call_fn]()
    keep(arr)


# ===----------------------------------------------------------------------===#
# Benchmark Array filter
# ===----------------------------------------------------------------------===#
@parameter
fn bench_array_filter[capacity: Int, static: Bool](inout b: Bencher) raises:
    var arr = make_array[capacity, static]()

    fn filterfn(a: Int64) -> Scalar[DType.bool]:
        return a < (capacity // 2)

    @always_inline
    @parameter
    fn call_fn() raises:
        var res = arr.filter(filterfn)
        keep(res)

    b.iter[call_fn]()
    keep(arr)


# ===----------------------------------------------------------------------===#
# Benchmark Array apply
# ===----------------------------------------------------------------------===#
@parameter
fn bench_array_apply[capacity: Int, static: Bool](inout b: Bencher) raises:
    var arr = make_array[capacity, static]()

    fn applyfn(a: Int64) -> Scalar[DType.int64]:
        return a * 2

    @always_inline
    @parameter
    fn call_fn() raises:
        arr.apply(applyfn)

    b.iter[call_fn]()
    keep(arr)


# ===----------------------------------------------------------------------===#
# Benchmark Array multiply
# ===----------------------------------------------------------------------===#
@parameter
fn bench_array_multiply[capacity: Int](inout b: Bencher) raises:
    var arr = make_array[capacity, False]()

    @always_inline
    @parameter
    fn call_fn() raises:
        arr *= 2

    b.iter[call_fn]()
    keep(arr)


# ===----------------------------------------------------------------------===#
# Benchmark Array reverse
# ===----------------------------------------------------------------------===#
@parameter
fn bench_array_reverse[capacity: Int](inout b: Bencher) raises:
    var arr = make_array[capacity, False, DType.int64]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for _ in range(1_000):
            arr.reverse()

    b.iter[call_fn]()
    keep(arr)


# ===----------------------------------------------------------------------===#
# Benchmark Array dot
# ===----------------------------------------------------------------------===#
@parameter
fn bench_array_dot[capacity: Int](inout b: Bencher) raises:
    var arr1 = make_array[capacity, True, DType.float64]()
    var arr2 = make_array[capacity, True, DType.float64]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for _ in range(1_000):
            var res = arr1.dot(arr2)
            keep(res)

    b.iter[call_fn]()
    keep(arr1)
    keep(arr2)


# ===----------------------------------------------------------------------===#
# Benchmark Array cross
# ===----------------------------------------------------------------------===#
@parameter
fn bench_array_cross(inout b: Bencher) raises:
    var arr1 = Array[DType.float64, 3, True](
        random_float64(0, 500), random_float64(0, 500), random_float64(0, 500)
    )
    var arr2 = Array[DType.float64, 3, True](
        random_float64(0, 500), random_float64(0, 500), random_float64(0, 500)
    )

    @always_inline
    @parameter
    fn call_fn() raises:
        for _ in range(1_000):
            var res = arr1.cross(arr2)
            keep(res)

    b.iter[call_fn]()
    keep(arr1)
    keep(arr2)


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
        # m.bench_function[bench_array_init[size, False]](
        #     BenchId("bench_array_init[" + str(size) + "]")
        # )
        # # FIXME: for some reason, static does not appear faster in these benchmarks
        # # m.bench_function[bench_array_init[size, True]](
        # #     BenchId("bench_array_init_static[" + str(size) + "]")
        # # )
        # m.bench_function[bench_array_insert[size, False]](
        #     BenchId("bench_array_insert[" + str(size) + "]")
        # )
        # # m.bench_function[bench_array_insert[size, True]](
        # #     BenchId("bench_array_insert_static[" + str(size) + "]")
        # # )
        # m.bench_function[bench_array_lookup[size, False]](
        #     BenchId("bench_array_lookup[" + str(size) + "]")
        # )
        # # m.bench_function[bench_array_lookup[size, True]](
        # #     BenchId("bench_array_lookup_static[" + str(size) + "]")
        # # )
        # m.bench_function[bench_array_contains[size, False]](
        #     BenchId("bench_array_contains[" + str(size) + "]")
        # )
        # # m.bench_function[bench_array_contains[size, True]](
        # #     BenchId("bench_array_contains_static[" + str(size) + "]")
        # # )
        # m.bench_function[bench_array_count[size, False]](
        #     BenchId("bench_array_count[" + str(size) + "]")
        # )
        # # m.bench_function[bench_array_count[size, True]](
        # #     BenchId("bench_array_count_static[" + str(size) + "]")
        # # )
        # m.bench_function[bench_array_sum[size]](
        #     BenchId("bench_array_sum[" + str(size) + "]")
        # )
        # m.bench_function[bench_array_filter[size, False]](
        #     BenchId("bench_array_filter[" + str(size) + "]")
        # )
        # # m.bench_function[bench_array_filter[size, True]](
        # #     BenchId("bench_array_filter_static[" + str(size) + "]")
        # # )
        # m.bench_function[bench_array_apply[size, True]](
        #     BenchId("bench_array_apply[" + str(size) + "]")
        # )
        # # m.bench_function[bench_array_apply[size, True]](
        # #     BenchId("bench_array_apply_static[" + str(size) + "]")
        # # )
        # m.bench_function[bench_array_multiply[size]](
        #     BenchId("bench_array_multiply[" + str(size) + "]")
        # )
        m.bench_function[bench_array_reverse[size]](
            BenchId("bench_array_reverse[" + str(size) + "]")
        )
        m.bench_function[bench_array_dot[size]](
            BenchId("bench_array_dot[" + str(size) + "]")
        )
        m.bench_function[bench_array_cross](BenchId("bench_array_cross"))

    print("")
    var values = Dict[String, List[Float64]]()
    for i in m.info_vec:
        var res = i[].result.mean()
        var val = values.get(i[].name, List[Float64](0, 0))
        values[i[].name] = List[Float64](res + val[0], val[1] + 1)
    for i in values.items():
        print(i[].key, ":", i[].value[0] / i[].value[1])
