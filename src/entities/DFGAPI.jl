### Discussion
# * How do we implement function signatures here?
# * How do we easily overload functions? E.g. addV has a few implementations
# * Where do we incorporate sessions/robot/user? Can be intrinsically, or in the configuration (children)
# * The philosophy of dealing atomically with factors and vertices should
#   simplify things. Creation of a factor or variable should be atomic and in
#   transaction. This to be discussed.


# Assuming our base types are variables and factors.
# May refactor this soon back to vertices and edges, depending on
# how the experiment goes.
type DFGAPI
    configuration::Any
    # Base functions
    addV!::Function
    addF!::Function
    getV::Function
    getF::Function
    updateV!::Function
    updateF!::Function
    deleteV!::Function
    deleteF!::Function
    # Query functions
    neighbors::Function
    ls::Function
    subGraph::Function
    adjacencyMatrix::Function
    # Additional parameters for extensibility
    additionaProperties::Dict{String, Any}
end
