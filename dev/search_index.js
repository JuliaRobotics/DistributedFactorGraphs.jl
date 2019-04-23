var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "#GraffSDK.jl-Documentation-1",
    "page": "Home",
    "title": "GraffSDK.jl Documentation",
    "category": "section",
    "text": "This package is a Julia SDK for SlamInDb/Graff."
},

{
    "location": "#Installation-1",
    "page": "Home",
    "title": "Installation",
    "category": "section",
    "text": "This package is not yet registered with JuliaLang/METADATA.jl, but can be easily installed in Julia 0.6 with:Pkg.clone(\"https://github.com/GearsAD/GraffSDK.jl.git\")\nPkg.build(\"GraffSDK\")"
},

{
    "location": "#Manual-Outline-1",
    "page": "Home",
    "title": "Manual Outline",
    "category": "section",
    "text": "Pages = [\n    \"index.md\"\n    \"getting_started.md\"\n    \"variables_and_factors.md\"\n    \"ref_api.md\"\n    \"example.md\"\n    \"func_ref.md\"\n]"
},

{
    "location": "getting_started/#",
    "page": "Introduction",
    "title": "Introduction",
    "category": "page",
    "text": ""
},

{
    "location": "getting_started/#Getting-Started-1",
    "page": "Introduction",
    "title": "Getting Started",
    "category": "section",
    "text": ""
},

{
    "location": "variables_and_factors/#",
    "page": "Variables and Factors",
    "title": "Variables and Factors",
    "category": "page",
    "text": ""
},

{
    "location": "variables_and_factors/#Variables-and-Factors-1",
    "page": "Variables and Factors",
    "title": "Variables and Factors",
    "category": "section",
    "text": ""
},

{
    "location": "ref_api/#",
    "page": "Common API Interface",
    "title": "Common API Interface",
    "category": "page",
    "text": ""
},

{
    "location": "ref_api/#Common-API-Interface-1",
    "page": "Common API Interface",
    "title": "Common API Interface",
    "category": "section",
    "text": ""
},

{
    "location": "example/#",
    "page": "Example",
    "title": "Example",
    "category": "page",
    "text": ""
},

{
    "location": "example/#Example-1",
    "page": "Example",
    "title": "Example",
    "category": "section",
    "text": ""
},

{
    "location": "apis/graphs/#",
    "page": "Graphs.jl",
    "title": "Graphs.jl",
    "category": "page",
    "text": ""
},

{
    "location": "apis/graphs/#The-Graphs.jl-DistributedFactorGraph-API-1",
    "page": "Graphs.jl",
    "title": "The Graphs.jl DistributedFactorGraph API",
    "category": "section",
    "text": ""
},

{
    "location": "apis/graphs/#",
    "page": "MetaGraph.jl",
    "title": "MetaGraph.jl",
    "category": "page",
    "text": ""
},

{
    "location": "apis/graphs/#The-Graphs.jl-DistributedFactorGraph-API-1",
    "page": "MetaGraph.jl",
    "title": "The Graphs.jl DistributedFactorGraph API",
    "category": "section",
    "text": ""
},

{
    "location": "apis/graphs/#",
    "page": "GraffSDK.jl",
    "title": "GraffSDK.jl",
    "category": "page",
    "text": ""
},

{
    "location": "apis/graphs/#The-Graphs.jl-DistributedFactorGraph-API-1",
    "page": "GraffSDK.jl",
    "title": "The Graphs.jl DistributedFactorGraph API",
    "category": "section",
    "text": ""
},

{
    "location": "apis/graphs/#",
    "page": "CloudGraphs.jl",
    "title": "CloudGraphs.jl",
    "category": "page",
    "text": ""
},

{
    "location": "apis/graphs/#The-Graphs.jl-DistributedFactorGraph-API-1",
    "page": "CloudGraphs.jl",
    "title": "The Graphs.jl DistributedFactorGraph API",
    "category": "section",
    "text": ""
},

{
    "location": "func_ref/#",
    "page": "Reference",
    "title": "Reference",
    "category": "page",
    "text": ""
},

{
    "location": "func_ref/#Function-Reference-1",
    "page": "Reference",
    "title": "Function Reference",
    "category": "section",
    "text": "Pages = [\n    \"func_ref.md\"\n]\nDepth = 3"
},

{
    "location": "func_ref/#DistributedFactorGraphs.GraphsJl.GraphsDFG",
    "page": "Reference",
    "title": "DistributedFactorGraphs.GraphsJl.GraphsDFG",
    "category": "type",
    "text": "GraphsDFG()\n\n\nCreate a new in-memory Graphs.jl-based DFG factor graph.\n\n\n\n\n\n"
},

{
    "location": "func_ref/#Graph-Types-1",
    "page": "Reference",
    "title": "Graph Types",
    "category": "section",
    "text": "GraphsDFG"
},

{
    "location": "func_ref/#DistributedFactorGraphs.GraphsJl.addVariable!",
    "page": "Reference",
    "title": "DistributedFactorGraphs.GraphsJl.addVariable!",
    "category": "function",
    "text": "addVariable!(dfg, variable)\n\n\nAdd a DFGVariable to a DFG.\n\n\n\n\n\n"
},

{
    "location": "func_ref/#DistributedFactorGraphs.GraphsJl.addFactor!",
    "page": "Reference",
    "title": "DistributedFactorGraphs.GraphsJl.addFactor!",
    "category": "function",
    "text": "addFactor!(dfg, variables, factor)\n\n\nAdd a DFGFactor to a DFG.\n\n\n\n\n\n"
},

{
    "location": "func_ref/#Creating-DFG-Factor-Graphs-1",
    "page": "Reference",
    "title": "Creating DFG Factor Graphs",
    "category": "section",
    "text": "addVariable!\naddFactor!"
},

{
    "location": "func_ref/#DistributedFactorGraphs.GraphsJl.getVariables",
    "page": "Reference",
    "title": "DistributedFactorGraphs.GraphsJl.getVariables",
    "category": "function",
    "text": "getVariables(dfg)\ngetVariables(dfg, regexFilter)\n\n\nList the DFGVariables in the DFG. Optionally specify a label regular expression to retrieves a subset of the variables.\n\n\n\n\n\n"
},

{
    "location": "func_ref/#DistributedFactorGraphs.GraphsJl.getFactors",
    "page": "Reference",
    "title": "DistributedFactorGraphs.GraphsJl.getFactors",
    "category": "function",
    "text": "getFactors(dfg)\ngetFactors(dfg, regexFilter)\n\n\nList the DFGFactors in the DFG. Optionally specify a label regular expression to retrieves a subset of the factors.\n\n\n\n\n\n"
},

{
    "location": "func_ref/#DistributedFactorGraphs.GraphsJl.getVariable",
    "page": "Reference",
    "title": "DistributedFactorGraphs.GraphsJl.getVariable",
    "category": "function",
    "text": "getVariable(dfg, variableId)\n\n\nGet a DFGVariable from a DFG using its underlying integer ID.\n\n\n\n\n\ngetVariable(dfg, label)\n\n\nGet a DFGVariable from a DFG using its label.\n\n\n\n\n\n"
},

{
    "location": "func_ref/#DistributedFactorGraphs.GraphsJl.getFactor",
    "page": "Reference",
    "title": "DistributedFactorGraphs.GraphsJl.getFactor",
    "category": "function",
    "text": "getFactor(dfg, factorId)\n\n\nGet a DFGFactor from a DFG using its underlying integer ID.\n\n\n\n\n\ngetFactor(dfg, label)\n\n\nGet a DFGFactor from a DFG using its label.\n\n\n\n\n\n"
},

{
    "location": "func_ref/#DistributedFactorGraphs.GraphsJl.getNeighbors",
    "page": "Reference",
    "title": "DistributedFactorGraphs.GraphsJl.getNeighbors",
    "category": "function",
    "text": "getNeighbors(dfg, node)\n\n\nRetrieve a list of labels of the immediate neighbors around a given variable or factor.\n\n\n\n\n\ngetNeighbors(dfg, label)\n\n\nRetrieve a list of labels of the immediate neighbors around a given variable or factor specified by its label.\n\n\n\n\n\n"
},

{
    "location": "func_ref/#DistributedFactorGraphs.GraphsJl.ls",
    "page": "Reference",
    "title": "DistributedFactorGraphs.GraphsJl.ls",
    "category": "function",
    "text": "ls(dfg)\nls(dfg, regexFilter)\n\n\nList the DFGVariables in the DFG. Optionally specify a label regular expression to retrieves a subset of the variables.\n\n\n\n\n\nRetrieve a list of labels of the immediate neighbors around a given variable or factor.\n\n\n\n\n\nls(dfg, label)\n\n\nRetrieve a list of labels of the immediate neighbors around a given variable or factor specified by its label.\n\n\n\n\n\n"
},

{
    "location": "func_ref/#DistributedFactorGraphs.GraphsJl.lsf",
    "page": "Reference",
    "title": "DistributedFactorGraphs.GraphsJl.lsf",
    "category": "function",
    "text": "lsf(dfg)\nlsf(dfg, regexFilter)\n\n\nList the DFGFactors in the DFG. Optionally specify a label regular expression to retrieves a subset of the factors.\n\n\n\n\n\n"
},

{
    "location": "func_ref/#Getting-Factor-Graph-Nodes-1",
    "page": "Reference",
    "title": "Getting Factor Graph Nodes",
    "category": "section",
    "text": "getVariables\ngetFactors\ngetVariable\ngetFactor\ngetNeighbors\nls\nlsf"
},

{
    "location": "func_ref/#DistributedFactorGraphs.GraphsJl.updateVariable!",
    "page": "Reference",
    "title": "DistributedFactorGraphs.GraphsJl.updateVariable!",
    "category": "function",
    "text": "updateVariable!(dfg, variable)\n\n\nUpdate a complete DFGVariable in the DFG.\n\n\n\n\n\n"
},

{
    "location": "func_ref/#DistributedFactorGraphs.GraphsJl.updateFactor!",
    "page": "Reference",
    "title": "DistributedFactorGraphs.GraphsJl.updateFactor!",
    "category": "function",
    "text": "updateFactor!(dfg, factor)\n\n\nUpdate a complete DFGFactor in the DFG.\n\n\n\n\n\n"
},

{
    "location": "func_ref/#Updating-Factor-Graph-Nodes-1",
    "page": "Reference",
    "title": "Updating Factor Graph Nodes",
    "category": "section",
    "text": "updateVariable!\nupdateFactor!"
},

{
    "location": "func_ref/#DistributedFactorGraphs.GraphsJl.deleteVariable!",
    "page": "Reference",
    "title": "DistributedFactorGraphs.GraphsJl.deleteVariable!",
    "category": "function",
    "text": "deleteVariable!(dfg, label)\n\n\nDelete a DFGVariable from the DFG using its label.\n\n\n\n\n\ndeleteVariable!(dfg, variable)\n\n\nDelete a referenced DFGVariable from the DFG.\n\n\n\n\n\n"
},

{
    "location": "func_ref/#DistributedFactorGraphs.GraphsJl.deleteFactor!",
    "page": "Reference",
    "title": "DistributedFactorGraphs.GraphsJl.deleteFactor!",
    "category": "function",
    "text": "deleteFactor!(dfg, label)\n\n\nDelete a DFGFactor from the DFG using its label.\n\n\n\n\n\ndeleteFactor!(dfg, factor)\n\n\nDelete the referened DFGFactor from the DFG.\n\n\n\n\n\n"
},

{
    "location": "func_ref/#Deleting-Factor-Graph-Nodes-1",
    "page": "Reference",
    "title": "Deleting Factor Graph Nodes",
    "category": "section",
    "text": "deleteVariable!\ndeleteFactor!"
},

{
    "location": "func_ref/#DistributedFactorGraphs.GraphsJl.getAdjacencyMatrix",
    "page": "Reference",
    "title": "DistributedFactorGraphs.GraphsJl.getAdjacencyMatrix",
    "category": "function",
    "text": "getAdjacencyMatrix(dfg)\n\n\nGet an adjacency matrix for the DFG, returned as a Matrix{Union{Nothing, Symbol}}. Rows are all factors, columns are all variables, and each cell contains either nothing or the symbol of the relating factor. The first row and first column are factor and variable headings respectively.\n\n\n\n\n\n"
},

{
    "location": "func_ref/#Getting-Adjacency-Matrix-1",
    "page": "Reference",
    "title": "Getting Adjacency Matrix",
    "category": "section",
    "text": "getAdjacencyMatrix"
},

{
    "location": "func_ref/#DistributedFactorGraphs.GraphsJl.isFullyConnected",
    "page": "Reference",
    "title": "DistributedFactorGraphs.GraphsJl.isFullyConnected",
    "category": "function",
    "text": "isFullyConnected(dfg)\n\n\nChecks if the graph is fully connected, returns true if so.\n\n\n\n\n\n"
},

{
    "location": "func_ref/#DistributedFactorGraphs.GraphsJl.hasOrphans",
    "page": "Reference",
    "title": "DistributedFactorGraphs.GraphsJl.hasOrphans",
    "category": "function",
    "text": "hasOrphans(dfg)\n\n\nChecks if the graph is not fully connected, returns true if it is not contiguous.\n\n\n\n\n\n"
},

{
    "location": "func_ref/#Validating-Factor-Graph-Connectivity-1",
    "page": "Reference",
    "title": "Validating Factor Graph Connectivity",
    "category": "section",
    "text": "isFullyConnected\nhasOrphans"
},

{
    "location": "func_ref/#DistributedFactorGraphs.GraphsJl.getSubgraphAroundNode",
    "page": "Reference",
    "title": "DistributedFactorGraphs.GraphsJl.getSubgraphAroundNode",
    "category": "function",
    "text": "getSubgraphAroundNode(dfg, node)\ngetSubgraphAroundNode(dfg, node, distance)\ngetSubgraphAroundNode(dfg, node, distance, includeOrphanFactors)\ngetSubgraphAroundNode(dfg, node, distance, includeOrphanFactors, addToDFG)\n\n\nRetrieve a deep subgraph copy around a given variable or factor. Optionally provide a distance to specify the number of edges should be followed. Optionally provide an existing subgraph addToDFG, the extracted nodes will be copied into this graph. By default a new subgraph will be created. Note: By default orphaned factors (where the subgraph does not contain all the related variables) are not returned. Set includeOrphanFactors to return the orphans irrespective of whether the subgraph contains all the variables.\n\n\n\n\n\n"
},

{
    "location": "func_ref/#DistributedFactorGraphs.GraphsJl.getSubgraph",
    "page": "Reference",
    "title": "DistributedFactorGraphs.GraphsJl.getSubgraph",
    "category": "function",
    "text": "getSubgraph(dfg, variableFactorLabels)\ngetSubgraph(dfg, variableFactorLabels, includeOrphanFactors)\ngetSubgraph(dfg, variableFactorLabels, includeOrphanFactors, addToDFG)\n\n\nGet a deep subgraph copy from the DFG given a list of variables and factors. Optionally provide an existing subgraph addToDFG, the extracted nodes will be copied into this graph. By default a new subgraph will be created. Note: By default orphaned factors (where the subgraph does not contain all the related variables) are not returned. Set includeOrphanFactors to return the orphans irrespective of whether the subgraph contains all the variables.\n\n\n\n\n\n"
},

{
    "location": "func_ref/#Copying-Subgraphs-1",
    "page": "Reference",
    "title": "Copying Subgraphs",
    "category": "section",
    "text": "getSubgraphAroundNode\ngetSubgraph"
},

{
    "location": "func_ref/#DistributedFactorGraphs.GraphsJl.toDot",
    "page": "Reference",
    "title": "DistributedFactorGraphs.GraphsJl.toDot",
    "category": "function",
    "text": "toDot(dfg)\n\n\nProduces a dot-format of the graph for visualization.\n\n\n\n\n\n"
},

{
    "location": "func_ref/#DistributedFactorGraphs.GraphsJl.toDotFile",
    "page": "Reference",
    "title": "DistributedFactorGraphs.GraphsJl.toDotFile",
    "category": "function",
    "text": "toDotFile(dfg, fileName)\n\n\nProduces a dot file of the graph for visualization. Download XDot to see the data\n\n\n\n\n\n"
},

{
    "location": "func_ref/#Visualization-1",
    "page": "Reference",
    "title": "Visualization",
    "category": "section",
    "text": "toDot\ntoDotFile"
},

{
    "location": "func_ref/#DataFrame-Extension-Functions-1",
    "page": "Reference",
    "title": "DataFrame Extension Functions",
    "category": "section",
    "text": "getAdjacencyMatrixDataFrame"
},

]}
