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

from collections import InlineList


# ===----------------------------------------------------------------------===#
# Benchmark Data
# ===----------------------------------------------------------------------===#
fn make_inlinelist[capacity: Int]() -> InlineArray[Int64, capacity]:
    var a = InlineArray[Int64, capacity](unsafe_uninitialized=True)
    for i in range(0, capacity):
        a[i] = random.random_si64(0, capacity).value
    return a^


# ===----------------------------------------------------------------------===#
# Benchmark inlinelist init
# ===----------------------------------------------------------------------===#


@parameter
fn bench_inlinelist_init[capacity: Int](inout b: Bencher) raises:
    @always_inline
    @parameter
    fn call_fn():
        var res = InlineArray[Int64, capacity](0)
        keep(res._array)

    b.iter[call_fn]()


# ===----------------------------------------------------------------------===#
# Benchmark inlinelist Insert
# ===----------------------------------------------------------------------===#
@parameter
fn bench_inlinelist_insert[capacity: Int](inout b: Bencher) raises:
    var items = make_inlinelist[capacity]()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(0, capacity):
            var previous = random.random_si64(0, capacity)
            for i in range(i, capacity):
                var tmp = items[i]
                items[i] = previous
                previous = tmp

    b.iter[call_fn]()
    keep(items._array)


# ===----------------------------------------------------------------------===#
# Benchmark inlinelist Lookup
# ===----------------------------------------------------------------------===#
@parameter
fn bench_inlinelist_lookup[capacity: Int](inout b: Bencher) raises:
    var items = make_inlinelist[capacity]()

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
    keep(items._array)


# ===----------------------------------------------------------------------===#
# Benchmark inlinelist contains
# ===----------------------------------------------------------------------===#
@parameter
fn bench_inlinelist_contains[capacity: Int](inout b: Bencher) raises:
    @always_inline
    @parameter
    fn call_fn() raises:
        # FIXME: no idea why but if I take this out of the func it segfaults
        # for Array, so to keep comparisons fair every benchmark has this until
        # fixed
        var items = make_inlinelist[capacity]()
        for i in range(0, capacity):
            var res = False
            for idx in range(len(items)):
                if items[idx] == i:
                    res = True
                    break
            keep(res)
        keep(items._array)

    b.iter[call_fn]()


# ===----------------------------------------------------------------------===#
# Benchmark inlinelist count
# ===----------------------------------------------------------------------===#
@parameter
fn bench_inlinelist_count[capacity: Int](inout b: Bencher) raises:
    var items = make_inlinelist[capacity]()

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
    keep(items._array)


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
        m.bench_function[bench_inlinelist_init[size]](
            BenchId("bench_inlinelist_init[" + str(size) + "]")
        )
        m.bench_function[bench_inlinelist_insert[size]](
            BenchId("bench_inlinelist_insert[" + str(size) + "]")
        )
        m.bench_function[bench_inlinelist_lookup[size]](
            BenchId("bench_inlinelist_lookup[" + str(size) + "]")
        )
        m.bench_function[bench_inlinelist_contains[size]](
            BenchId("bench_inlinelist_contains[" + str(size) + "]")
        )
        m.bench_function[bench_inlinelist_count[size]](
            BenchId("bench_inlinelist_count[" + str(size) + "]")
        )
    print("")
    var values = Dict[String, List[Float64]]()
    for i in m.info_vec:
        var res = i[].result.mean()
        var val = values.get(i[].name, List[Float64](0, 0))
        values[i[].name] = List[Float64](res + val[0], val[1] + 1)
    for i in values.items():
        print(i[].key, ":", i[].value[0] / i[].value[1])
