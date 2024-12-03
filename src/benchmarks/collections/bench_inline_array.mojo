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
from random import seed, random_float64, random_float64


# ===----------------------------------------------------------------------===#
# Benchmark Data
# ===----------------------------------------------------------------------===#
fn make_inlinearray[
    capacity: Int, T: DType = DType.int64
]() -> InlineArray[Scalar[T], capacity]:
    a = InlineArray[Scalar[T], capacity](unsafe_uninitialized=True)
    for i in range(0, capacity):

        @parameter
        if T == DType.int64:
            a[i] = rebind[Scalar[T]](random.random_si64(0, capacity))
        elif T == DType.float64:
            a[i] = rebind[Scalar[T]](random.random_float64(0, capacity))
        else:
            a[i] = 0
    return a^


# ===----------------------------------------------------------------------===#
# Benchmark inlinearray init
# ===----------------------------------------------------------------------===#


@parameter
fn bench_inlinearray_init[capacity: Int](mut b: Bencher) raises:
    @always_inline
    @parameter
    fn call_fn():
        res = InlineArray[Int64, capacity](0)
        keep(res._array)

    b.iter[call_fn]()


# ===----------------------------------------------------------------------===#
# Benchmark inlinearray Insert
# ===----------------------------------------------------------------------===#
@parameter
fn bench_inlinearray_insert[capacity: Int](mut b: Bencher) raises:
    items = make_inlinearray[capacity]()
    p = items.unsafe_ptr()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(0, capacity):
            previous = random.random_si64(0, capacity)
            for i in range(i, capacity):
                tmp = p[i]
                p[i] = previous
                previous = tmp

    b.iter[call_fn]()
    keep(items._array)


# ===----------------------------------------------------------------------===#
# Benchmark inlinearray Lookup
# ===----------------------------------------------------------------------===#
@parameter
fn bench_inlinearray_lookup[capacity: Int](mut b: Bencher) raises:
    items = make_inlinearray[capacity]()
    p = items.unsafe_ptr()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(0, capacity):
            res = 0
            for idx in range(len(items)):
                if p[idx] == i:
                    res = idx
                    break
            keep(res)

    b.iter[call_fn]()
    keep(items._array)


# ===----------------------------------------------------------------------===#
# Benchmark inlinearray contains
# ===----------------------------------------------------------------------===#
@parameter
fn bench_inlinearray_contains[capacity: Int](mut b: Bencher) raises:
    items = make_inlinearray[capacity]()
    p = items.unsafe_ptr()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(0, capacity):
            res = False
            for idx in range(len(items)):
                if p[idx] == i:
                    res = True
                    break
            keep(res)

    b.iter[call_fn]()
    keep(items._array)


# ===----------------------------------------------------------------------===#
# Benchmark inlinearray count
# ===----------------------------------------------------------------------===#
@parameter
fn bench_inlinearray_count[capacity: Int](mut b: Bencher) raises:
    items = make_inlinearray[capacity]()
    p = items.unsafe_ptr()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(0, capacity):
            res = 0
            for idx in range(len(items)):
                if p[idx] == i:
                    res += 1
            clobber_memory()
            keep(res)

    b.iter[call_fn]()
    keep(items._array)


# ===----------------------------------------------------------------------===#
# Benchmark inlinearray sum
# ===----------------------------------------------------------------------===#
@parameter
fn bench_inlinearray_sum[capacity: Int](mut b: Bencher) raises:
    items = make_inlinearray[capacity]()
    p = items.unsafe_ptr()

    @always_inline
    @parameter
    fn call_fn() raises:
        res: Int64 = 0
        for i in range(len(items)):
            res += p[i]
        clobber_memory()
        keep(res)

    b.iter[call_fn]()
    keep(items._array)


# ===----------------------------------------------------------------------===#
# Benchmark inlinearray filter
# ===----------------------------------------------------------------------===#
@parameter
fn bench_inlinearray_filter[capacity: Int](mut b: Bencher) raises:
    items = make_inlinearray[capacity]()
    p = items.unsafe_ptr()

    fn filterfn(a: Int64) -> Scalar[DType.bool]:
        return a < (capacity // 2)

    @always_inline
    @parameter
    fn call_fn() raises:
        res = InlineArray[Int64, capacity](unsafe_uninitialized=True)
        amnt = 0
        for i in range(len(items)):
            if filterfn(p[i]):
                res[amnt] = p[i]
                amnt += 1
        clobber_memory()
        keep(res._array)

    b.iter[call_fn]()
    keep(items._array)


# ===----------------------------------------------------------------------===#
# Benchmark inlinearray apply
# ===----------------------------------------------------------------------===#
@parameter
fn bench_inlinearray_apply[capacity: Int](mut b: Bencher) raises:
    items = make_inlinearray[capacity]()
    p = items.unsafe_ptr()

    fn applyfn(a: Int64) -> Scalar[DType.int64]:
        if a < Int64.MAX_FINITE // 2:
            return a * 2
        return a

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(len(items)):
            p[i] = applyfn(p[i])
        clobber_memory()

    b.iter[call_fn]()
    keep(items._array)


# ===----------------------------------------------------------------------===#
# Benchmark inlinearray multiply
# ===----------------------------------------------------------------------===#
@parameter
fn bench_inlinearray_multiply[capacity: Int](mut b: Bencher) raises:
    items = make_inlinearray[capacity]()
    p = items.unsafe_ptr()

    @always_inline
    @parameter
    fn call_fn() raises:
        for i in range(len(items)):
            p[i] = p[i] * 2
        clobber_memory()

    b.iter[call_fn]()
    keep(items._array)


# ===----------------------------------------------------------------------===#
# Benchmark inlinearray reverse
# ===----------------------------------------------------------------------===#
@parameter
fn bench_inlinearray_reverse[capacity: Int](mut b: Bencher) raises:
    items = make_inlinearray[capacity, DType.uint8]()
    p = items.unsafe_ptr()

    @always_inline
    @parameter
    fn call_fn() raises:
        for _ in range(1_000):
            for i in range(len(items)):
                tmp = p[i]
                p[i] = p[len(items) - (i + 1)]
                p[len(items) - (i + 1)] = tmp
            clobber_memory()

    b.iter[call_fn]()
    keep(items._array)


# ===----------------------------------------------------------------------===#
# Benchmark inlinearray dot
# ===----------------------------------------------------------------------===#
@parameter
fn bench_inlinearray_dot[capacity: Int](mut b: Bencher) raises:
    arr1 = make_inlinearray[capacity, T = DType.float64]()
    arr2 = make_inlinearray[capacity, T = DType.float64]()
    p1 = arr1.unsafe_ptr()
    p2 = arr2.unsafe_ptr()

    @always_inline
    @parameter
    fn call_fn() raises:
        for _ in range(1_000):
            res: Float64 = 0
            for i in range(len(arr1)):
                res += p1[i] * p2[i]
            clobber_memory()
            keep(res)

    b.iter[call_fn]()
    keep(arr1._array)
    keep(arr2._array)


# ===----------------------------------------------------------------------===#
# Benchmark inlinearray cross
# ===----------------------------------------------------------------------===#
@parameter
fn bench_inlinearray_cross(mut b: Bencher) raises:
    arr1 = InlineArray[Float64, 3](
        random_float64(0, 500), random_float64(0, 500), random_float64(0, 500)
    )
    arr2 = InlineArray[Float64, 3](
        random_float64(0, 500), random_float64(0, 500), random_float64(0, 500)
    )
    p1 = arr1.unsafe_ptr()
    p2 = arr2.unsafe_ptr()

    @always_inline
    @parameter
    fn call_fn() raises:
        for _ in range(1_000):
            res = InlineArray[Float64, 3](
                p1[1] * p2[2] - p1[2] * p2[1],
                p1[2] * p2[0] - p1[0] * p2[2],
                p1[0] * p2[1] - p1[1] * p2[0],
            )
            keep(res._array)

    b.iter[call_fn]()
    keep(arr1._array)
    keep(arr2._array)


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
        m.bench_function[bench_inlinearray_init[size]](
            BenchId("bench_inlinearray_init[" + str(size) + "]")
        )
        # m.bench_function[bench_inlinearray_insert[size]](
        #     BenchId("bench_inlinearray_insert[" + str(size) + "]")
        # )
        m.bench_function[bench_inlinearray_lookup[size]](
            BenchId("bench_inlinearray_lookup[" + str(size) + "]")
        )
        m.bench_function[bench_inlinearray_contains[size]](
            BenchId("bench_inlinearray_contains[" + str(size) + "]")
        )
        m.bench_function[bench_inlinearray_count[size]](
            BenchId("bench_inlinearray_count[" + str(size) + "]")
        )
        # m.bench_function[bench_inlinearray_sum[size]](
        #     BenchId("bench_inlinearray_sum[" + str(size) + "]")
        # )
        # m.bench_function[bench_inlinearray_filter[size]](
        #     BenchId("bench_inlinearray_filter[" + str(size) + "]")
        # )
        # m.bench_function[bench_inlinearray_apply[size]](
        #     BenchId("bench_inlinearray_apply[" + str(size) + "]")
        # )
        # m.bench_function[bench_inlinearray_multiply[size]](
        #     BenchId("bench_inlinearray_multiply[" + str(size) + "]")
        # )
        # m.bench_function[bench_inlinearray_reverse[size]](
        #     BenchId("bench_inlinearray_reverse[" + str(size) + "]")
        # )
        # m.bench_function[bench_inlinearray_dot[size]](
        #     BenchId("bench_inlinearray_dot[" + str(size) + "]")
        # )
        # m.bench_function[bench_inlinearray_cross](
        #     BenchId("bench_inlinearray_cross")
        # )
    print("")
    values = Dict[String, List[Float64]]()
    for i in m.info_vec:
        res = i[].result.mean()
        val = values.get(i[].name, List[Float64](0, 0))
        values[i[].name] = List[Float64](res + val[0], val[1] + 1)
    for i in values.items():
        print(i[].key, ":", i[].value[0] / i[].value[1])
