# Serializer benchmarks

Some benchmarks for serializers which can serialize arbitrary Julia
structures. Currently just [BSON](https://github.com/MikeInnes/BSON.jl) and
[BSONqs](https://github.com/richiejp/BSONqs.jl).

For now the benchmark is biased towards highly nested composite data
types (structs).

## Usage

To run the benchmark yourself. Clone the repo then `cd` into its
directory and do

```
# julia --project
julia> using serbench
julia> do_bench()
```

## Results

The save benchmark for the original BSON library is disabled because it didn't
complete after a few minutes most likely due to
[this](https://github.com/MikeInnes/BSON.jl/pull/33). Performance should be
very similar if that is merged. The largest differences are in reading.

In summary `BSONqs.load` is about 3.5x faster and uses 4.4x less memory than
`BSON.load` after the second run. During the first run it is only about 2x
faster, most likely because `BSONqs` makes heavy use of `@generated` methods.

```
julia> do_bench()
[ Info: Bench Save BSONqs
┌ Info: BSONqs.bson(io, foos)
│   elapsed = 9.270388092
│   allocatedMb = 2735.0
└   gctime = 3.046428065
[ Info: Bench load_compat BSONqs Document
┌ Info: BSONqs.load_compat(io)
│   elapsed = 2.610610094
│   allocatedMb = 499.0
└   gctime = 0.632833662
[ Info: Bench load BSONqs Document
┌ Info: BSONqs.load(io)
│   elapsed = 2.019496837
│   allocatedMb = 409.0
└   gctime = 0.204799674
[ Info: Bench load BSON Document
┌ Info: BSON.load(io)
│   elapsed = 3.926433859
│   allocatedMb = 1514.0
└   gctime = 1.247946657

julia> do_bench()
[ Info: Bench Save BSONqs
┌ Info: BSONqs.bson(io, foos)
│   elapsed = 7.343643741
│   speedup = 1.2623689845196153
│   allocatedMb = 2525.0
└   gctime = 2.728705096
[ Info: Bench load_compat BSONqs Document
┌ Info: BSONqs.load_compat(io)
│   elapsed = 2.013142543
│   speedup = 1.2967835303453723
│   allocatedMb = 419.0
└   gctime = 0.63647315
[ Info: Bench load BSONqs Document
┌ Info: BSONqs.load(io)
│   elapsed = 0.921116403
│   speedup = 2.192444766397239
│   allocatedMb = 328.0
└   gctime = 0.173687222
[ Info: Bench load BSON Document
┌ Info: BSON.load(io)
│   elapsed = 3.474502083
│   speedup = 1.1300709469167411
│   allocatedMb = 1454.0
└   gctime = 1.226204899
```
