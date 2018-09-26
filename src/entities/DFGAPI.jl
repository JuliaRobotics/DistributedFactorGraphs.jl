
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
