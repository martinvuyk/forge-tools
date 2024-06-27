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

from collections import List


# ===----------------------------------------------------------------------===#
# Benchmark Data
# ===----------------------------------------------------------------------===#
fn make_list[capacity: Int]() -> List[Int64]:
    var a = List[Int64](capacity=capacity)
    for i in range(0, capacity):
        a[i] = random.random_si64(0, capacity).value
    return a


# ===----------------------------------------------------------------------===#
# Benchmark list init
# ===----------------------------------------------------------------------===#


@parameter
fn bench_list_init[capacity: Int](inout b: Bencher) raises:
    @always_inline
    @parameter
    fn call_fn():
        var res = List[Int64](capacity=capacity)
        keep(res)

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

    b.iter[call_fn]()
    keep(items)


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
            for idx in range(len(items)):
                if items[idx] == i:
                    res = idx
                    break
            keep(res)

    b.iter[call_fn]()
    keep(items)


# ===----------------------------------------------------------------------===#
# Benchmark list contains
# ===----------------------------------------------------------------------===#
@parameter
fn bench_list_contains[capacity: Int](inout b: Bencher) raises:
    @always_inline
    @parameter
    fn call_fn() raises:
        # FIXME: no idea why but if I take this out of the func it segfaults
        # for Array, so to keep comparisons fair every benchmark has this until
        # fixed
        var items = make_list[capacity]()
        for i in range(0, capacity):
            var res = False
            for idx in range(len(items)):
                if items[idx] == i:
                    res = True
                    break
            keep(res)
        keep(items)

    b.iter[call_fn]()


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
            for idx in range(len(items)):
                if items[idx] == i:
                    res += 1
            keep(res)

    b.iter[call_fn]()
    keep(items)


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
        m.bench_function[bench_list_init[size]](
            BenchId("bench_list_init[" + str(size) + "]")
        )
        m.bench_function[bench_list_insert[size]](
            BenchId("bench_list_insert[" + str(size) + "]")
        )
        m.bench_function[bench_list_lookup[size]](
            BenchId("bench_list_lookup[" + str(size) + "]")
        )
        m.bench_function[bench_list_contains[size]](
            BenchId("bench_list_contains[" + str(size) + "]")
        )
        m.bench_function[bench_list_count[size]](
            BenchId("bench_list_count[" + str(size) + "]")
        )
    print("")
    var values = Dict[String, List[Float64]]()
    for i in m.info_vec:
        var res = i[].result.mean()
        var val = values.get(i[].name, List[Float64](0, 0))
        values[i[].name] = List[Float64](res + val[0], val[1] + 1)
    for i in values.items():
        print(i[].key, ":", i[].value[0] / i[].value[1])
