from benchmark import (
    Bench,
    BenchConfig,
    Bencher,
    BenchId,
    Unit,
    keep,
    run,
)
from random import seed

from forge_tools.collections import Array


# ===----------------------------------------------------------------------===#
# Benchmark Data
# ===----------------------------------------------------------------------===#
fn make_array[
    capacity: Int, static: Bool
]() -> Array[DType.int64, capacity, static]:
    var a = Array[DType.int64, capacity, static]()
    for i in range(0, capacity):
        a[i] = random.random_si64(0, capacity).value
    a.capacity_left = 0
    return a


# ===----------------------------------------------------------------------===#
# Benchmark Array init
# ===----------------------------------------------------------------------===#


@parameter
fn bench_array_init[capacity: Int](inout b: Bencher) raises:
    @always_inline
    @parameter
    fn call_fn():
        var res = Array[DType.int64, capacity]()
        keep(res)

    b.iter[call_fn]()


@parameter
fn bench_array_init_static[capacity: Int](inout b: Bencher) raises:
    @always_inline
    @parameter
    fn call_fn():
        var res = Array[DType.int64, capacity, True]()
        keep(res)

    b.iter[call_fn]()


# ===----------------------------------------------------------------------===#
# Benchmark Array Insert
# ===----------------------------------------------------------------------===#
@parameter
fn bench_array_insert[capacity: Int](inout b: Bencher) raises:
    var arr = make_array[capacity, False]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(0, capacity):
            arr.insert(i, random.random_si64(0, capacity).value)

    b.iter[call_fn]()
    keep(arr)


@parameter
fn bench_array_insert_static[capacity: Int](inout b: Bencher) raises:
    var arr = make_array[capacity, True]()

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
fn bench_array_lookup[capacity: Int](inout b: Bencher) raises:
    var arr = make_array[capacity, False]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(0, capacity):
            var res = arr.index(i)
            keep(res)

    b.iter[call_fn]()
    keep(arr)


@parameter
fn bench_array_lookup_static[capacity: Int](inout b: Bencher) raises:
    var arr = make_array[capacity, True]()

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
fn bench_array_contains[capacity: Int](inout b: Bencher) raises:
    @always_inline
    @parameter
    fn call_fn() raises:
        # FIXME: no idea why but if I take this out of the func it segfaults
        # for Array, so to keep comparisons fair every benchmark has this until
        # fixed
        var arr = make_array[capacity, False]()
        for i in range(0, capacity):
            var res = i in arr
            keep(res)
        keep(arr)

    b.iter[call_fn]()


@parameter
fn bench_array_contains_static[capacity: Int](inout b: Bencher) raises:
    @always_inline
    @parameter
    fn call_fn() raises:
        # FIXME: no idea why but if I take this out of the func it segfaults
        # for Array, so to keep comparisons fair every benchmark has this until
        # fixed
        var arr = make_array[capacity, True]()
        for i in range(0, capacity):
            var res = i in arr
            keep(res)
        keep(arr)

    b.iter[call_fn]()


# ===----------------------------------------------------------------------===#
# Benchmark Array count
# ===----------------------------------------------------------------------===#
@parameter
fn bench_array_count[capacity: Int](inout b: Bencher) raises:
    var arr = make_array[capacity, False]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(0, capacity):
            var res = arr.count(i)
            keep(res)

    b.iter[call_fn]()
    keep(arr)


@parameter
fn bench_array_count_static[capacity: Int](inout b: Bencher) raises:
    var arr = make_array[capacity, True]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(0, capacity):
            var res = arr.count(i)
            keep(res)

    b.iter[call_fn]()
    keep(arr)


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
        m.bench_function[bench_array_init[size]](
            BenchId("bench_array_init[" + str(size) + "]")
        )
        # FIXME: for some reason, static does not appear faster in these benchmarks
        # m.bench_function[bench_array_init_static[size]](
        #     BenchId("bench_array_init_static[" + str(size) + "]")
        # )
        m.bench_function[bench_array_insert[size]](
            BenchId("bench_array_insert[" + str(size) + "]")
        )
        # m.bench_function[bench_array_insert_static[size]](
        #     BenchId("bench_array_insert_static[" + str(size) + "]")
        # )
        m.bench_function[bench_array_lookup[size]](
            BenchId("bench_array_lookup[" + str(size) + "]")
        )
        # m.bench_function[bench_array_lookup_static[size]](
        #     BenchId("bench_array_lookup_static[" + str(size) + "]")
        # )
        m.bench_function[bench_array_contains[size]](
            BenchId("bench_array_contains[" + str(size) + "]")
        )
        # m.bench_function[bench_array_contains_static[size]](
        #     BenchId("bench_array_contains_static[" + str(size) + "]")
        # )
        m.bench_function[bench_array_count[size]](
            BenchId("bench_array_count[" + str(size) + "]")
        )
        # m.bench_function[bench_array_count_static[size]](
        #     BenchId("bench_array_count_static[" + str(size) + "]")
        # )
    print("")
    var values = Dict[String, List[Float64]]()
    for i in m.info_vec:
        var res = i[].result.mean()
        var val = values.get(i[].name, List[Float64](0, 0))
        values[i[].name] = List[Float64](res + val[0], val[1] + 1)
    for i in values.items():
        print(i[].key, ":", i[].value[0] / i[].value[1])
