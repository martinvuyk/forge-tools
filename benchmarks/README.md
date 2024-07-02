# Benchmarks

## Benchmark Array against List and InlineArray

- mojo `2024.6.2905`
- Using: Intel® i7-7700HQ @2.80 GHz (Instruction Set Extensions
    Intel® SSE4.1, Intel® SSE4.2, Intel® AVX2). 4 cores 8 threads

| Cache    |                   |
|----------|-------------------|
| Cache L1 | 64 KB (per core)  |
| Cache L2 | 256 KB (per core) |
| Cache L3 | 6 MB (shared)     |

- amount items = (3, 8, 16, 32, 64, 128, 256)
- datatype = UInt64
- average of 5 iterations with 100 warmup (several runs had similar results)

#### Results for "standard" sequential collection operations:

![](./benchmarks_array_list_inlinearray_collection_ops.png)



#### Numeric operations

![](./benchmarks_array_list_inlinearray_numeric_ops.png)


#### Vector operations

- 1k times reverse (Int64)
- 1k times dot product (Float64)
- 5k times cross product (Float64)

![](./benchmarks_array_list_inlinearray_vector_ops.png)
