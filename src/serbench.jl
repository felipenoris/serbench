module serbench

import BSONqs
import BSON

export do_bench, Foo, Bar, Baz

chars = [x for x in '0':'z']
strings = [String([rand(chars) for _ in 1:20]) for _ in 1:1000]
rstr(n::Int)::String = rand(strings)[1:n]

struct Baz
  going::String
  deeper::String
end

Baz() = Baz(rstr(20), rstr(1))

struct Bar
  level::Int64
  bazes::Vector{Baz}
  salty::AbstractDict{<:AbstractString, <:Unsigned}
end

Bar() = Bar(rand(Int64), [Baz() for _ in 1:50],
            Dict(s => hash(s, UInt64(0xdeadbeef)) for s in (rstr(x) for x in 10:13)))

struct Foo
  agile::String
  software::String
  management::Union{String, Symbol}
  consultant::String
  training::Union{String, Missing}
  projects::Vector{Bar}
end

Foo() = [Foo(rstr(5), rstr(7), rstr(17), rstr(11), rstr(13),
             [Bar() for _ in 1:2000]) for _ in 1:3]

struct Result
  elapsed::Float64
  allocated::Int64
end

const history_file = "./benchmark-history.bson"

macro bench(hist, msg, ex)
  sex = "$ex"
  quote
    GC.gc()
    @info $msg
    local val, t1, bytes, gctime, memallocs = @timed $(esc(ex))
    local mb = ceil(bytes / (1024 * 1024))
    if $sex in keys($(esc(hist)))
      local t0 = $(esc(hist))[$sex].elapsed
      @info $sex elapsed=t1 speedup=t0/t1 allocatedMb=mb gctime
    else
      @info $sex elapsed=t1 allocatedMb=mb gctime
    end
    $(esc(hist))[$sex] = Result(t1, bytes)
    val
  end
end

function do_bench()
  hist = if isfile(history_file)
    BSONqs.load(history_file)::Dict{String, Result}
  else
    Dict{String, Result}()
  end

  foos = Dict(:Foo => Foo(), :Foo2 => Foo(), :Foo3 => Foo())

  #@bench hist "Roundtrip from cold start (ignore)" BSON.roundtrip(foos)

  io = IOBuffer()

  @bench hist "Bench Save BSONqs" BSONqs.bson(io, foos)
  seek(io, 0)
  #@bench hist "Bench Save BSON" BSON.bson(io, foos)

  seek(io, 0)
  doc = @bench hist "Bench load_compat BSONqs Document" BSONqs.load_compat(io)
  seek(io, 0)
  rfoos = @bench hist "Bench load BSONqs Document" BSONqs.load(io)

  # Sanity check the results
  rfoos[:Foo][1]::Foo
  rfoos[:Foo][1].projects[1]::Bar
  rfoos[:Foo][1].projects[1].bazes[1]::Baz

  seek(io, 0)
  rfoos = @bench hist "Bench load BSON Document" BSON.load(io)

  # Sanity check the results
  rfoos[:Foo][1]::Foo
  rfoos[:Foo][1].projects[1]::Bar
  rfoos[:Foo][1].projects[1].bazes[1]::Baz

  BSONqs.bson(history_file, hist)
end


end # module
