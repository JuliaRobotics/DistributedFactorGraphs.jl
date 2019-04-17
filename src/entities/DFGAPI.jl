### Discussion
# * How can we implement function signatures here?
# * addV has a few implementations and all can be used by the single reference (nice work Julia!)
# * Where do we incorporate sessions/robot/user? Can be intrinsically, or in the configuration (children)
# * The philosophy of dealing atomically with factors and vertices should
#   simplify things. Creation of a factor or variable should be atomic and in
#   transaction. This to be discussed.

import Base: show


mutable struct LightDFGraph <: DFG
end


# Assuming our base types are variables and factors.
# May refactor this soon back to vertices and edges, depending on
# how the experiment goes.
struct DFGAPI
    configuration::Any
    description::String
    validateConfig::Function
    # Base functions
    addV!::Function
    addF!::Function
    getV::Function
    getVs::Function
    getF::Function
    getFs::Function
    updateV!::Function
    updateF!::Function
    deleteV!::Function
    deleteF!::Function
    getProp::Function
    setProp!::Function
    deleteProp!::Function
    getProps::Function
    setProps!::Function
    # Query functions
    neighbors::Function
    ls::Function
    lsf::Function
    subGraph::Function
    adjacencyMatrix::Function
    # Additional parameters for extensibility
    additionaProperties::Dict{String, Any}
end

function show(io::IO, d::DFGAPI)
    println(io, "DFG API: $(d.description)")
end
