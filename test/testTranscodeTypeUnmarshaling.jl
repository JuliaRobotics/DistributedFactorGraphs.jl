
# test transcoding and unmarshal util


using Test
using DistributedFactorGraphs
using DataStructures: OrderedDict
using Dates

##


Base.@kwdef struct HardType
    name::String
    time::DateTime = now(UTC)
    val::Float64 = 0.0
end

# slight human overhead for each type to ignore extraneous field construction
# TODO, devnote drop this requirement with filter of _names in transcodeType
HardType(;
    name::String,
    time::DateTime = now(UTC),
    val::Float64 = 0.0,
    ignorekws...
) = HardType(name,time,val)

@testset "Test transcoding of Intermediate, Dict, OrderedDict to a HardType" begin

struct IntermediateType
  _version
  _type
  name
  time
  val
end

# somehow one gets an intermediate type
imt = IntermediateType(
    v"1.0",
    "NotUsedYet",
    "test",
    now(UTC),
    1.0
)
# or dict (testing string keys)
imd = Dict(
    "_version" => v"1.0",
    "_type" => "NotUsedYet",
    "name" => "test",
    "time" => now(UTC),
    "val" => 1.0
)
# ordered dict (testing symbol keys)
iod = OrderedDict(
    :_version => v"1.0",
    :_type => "NotUsedYet",
    :name => "test",
    :time => now(UTC),
    # :val => 1.0
)

# do the transcoding to a slighly different hard type
T1 = DistributedFactorGraphs.transcodeType(HardType, imt)
T2 = DistributedFactorGraphs.transcodeType(HardType, imd)
T3 = DistributedFactorGraphs.transcodeType(HardType, iod)

end

Base.@kwdef struct MyType{T <: Real}
  tags::Vector{Symbol} = Symbol[]
  count::Int
  funfun::Complex{T} = 1 + 5im
  somedata::Dict{Symbol,Any} = Dict{Symbol, Any}()
  data::Vector{Float64} = zeros(0)
  binary::Vector{UInt8} = Vector{UInt8}()
end

@testset "More super unmarshaling tests of various test dicts" begin

d = Dict("count" => 3)
DistributedFactorGraphs.transcodeType(MyType, d)

d2 = Dict("count" => 3, "tags" => Any["hi", "okay"])
DistributedFactorGraphs.transcodeType(MyType, d2)

d3 = Dict("count" => "3", "tags" => String["hi", "okay"])
DistributedFactorGraphs.transcodeType(MyType, d3)

d4 = Dict("count" => 3.0, "funfun" => "8 - 3im", "tags" => Any["hi", "okay"])
DistributedFactorGraphs.transcodeType(MyType{Float32}, d4)

d5 = Dict("count" => 3, "somedata" => Dict{String,Any}("calibration"=>[1.1;2.2], "description"=>"this is a test"))
DistributedFactorGraphs.transcodeType(MyType{Float64}, d5)

d6 = Dict("count" => 3.0, "data" => Any[10, 60])
DistributedFactorGraphs.transcodeType(MyType, d6)

d7 = Dict("count" => 3.0, "data" => String["10", "60"])
DistributedFactorGraphs.transcodeType(MyType, d7)

d8 = Dict("count" => 4, "binary" => take!(IOBuffer("hello world")))
DistributedFactorGraphs.transcodeType(MyType, d8)

d9 = Dict("count" => 4, "somedata" => Dict{Symbol,Any}(:test => "no ambiguity"))
DistributedFactorGraphs.transcodeType(MyType, d9)

end