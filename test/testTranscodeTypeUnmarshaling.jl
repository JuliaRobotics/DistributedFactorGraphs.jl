
# test transcoding and unmarshal util


using Test
using DistributedFactorGraphs
using DataStructures
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