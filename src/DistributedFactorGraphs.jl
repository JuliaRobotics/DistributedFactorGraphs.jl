module DistributedFactorGraphs

using Base
using DocStringExtensions
using Requires
using Dates
using Distributions
using Reexport

# Entities
include("entities/AbstractTypes.jl")
include("entities/DFGFactor.jl")
include("entities/DFGVariable.jl")

export AbstractDFG
export DFGNode
export DFGFactor
export DFGVariable
export label, timestamp, tags, estimates, estimate, solverData, solverDataDict, id, smallData, bigData
export setSolverData
export label, data, id

# Solver (IIF) Exports
export VariableNodeData, PackedVariableNodeData
export GenericFunctionNodeData#, FunctionNodeData
export getSerializationModule, setSerializationModule!
export pack, unpack

# Include the Graphs.jl API.
include("services/GraphsDFG.jl")
include("services/AbstractDFG.jl")
include("services/DFGVariable.jl")

# not sure where to put
include("Common.jl")
include("NeedsAHome.jl")

end
