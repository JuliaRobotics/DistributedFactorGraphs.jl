# DistributedFactorGraphs Functions Reference

```@contents
Pages = [
    "func_ref.md"
]
Depth = 3
```

## DistributedFactorGraphs Module

```@autodocs
Modules = [DistributedFactorGraphs]
Pages = ["DistributedFactorGraphs.jl"]
```

## Entities

### Abstract DFG

```@autodocs
Modules = [DistributedFactorGraphs]
Pages = ["entities/AbstractDFG.jl"]
```

### Summary DFG

```@autodocs
Modules = [DistributedFactorGraphs]
Pages = ["entities/AbstractDFGSummary.jl"]
```

### DFG Variable Nodes

```@autodocs
Modules = [DistributedFactorGraphs]
Pages = ["entities/DFGVariable.jl"]
```

### DFG Factor Nodes

```@autodocs
Modules = [DistributedFactorGraphs]
Pages = ["entities/DFGFactor.jl"]
```

## Services

### Abstract DFG

```@autodocs
Modules = [DistributedFactorGraphs]
Pages = ["services/AbstractDFG.jl"]
```

### Common Accessors

Common Accessors to both variable and factor nodes

```@autodocs
Modules = [DistributedFactorGraphs]
Pages = ["services/CommonAccessors.jl"]
```

### DFG Variable Accessors CRUD and SET opperations

```@autodocs
Modules = [DistributedFactorGraphs]
Pages = ["services/DFGVariable.jl"]
```

### DFG Factor Accessors CRUD and SET opperations

```@autodocs
Modules = [DistributedFactorGraphs]
Pages = ["services/DFGFactor.jl"]
```

### Printing

```@autodocs
Modules = [DistributedFactorGraphs]
Pages = ["services/CustomPrinting.jl"]
```

### Compare Utilities

```@autodocs
Modules = [DistributedFactorGraphs]
Pages = ["services/CompareUtils.jl"]
```

### Common Functions

```@autodocs
Modules = [DistributedFactorGraphs]
Pages = ["src/Common.jl"]
```

### Serialization

```@autodocs
Modules = [DistributedFactorGraphs]
Pages = ["services/Serialization.jl"]
```

## DFG Plots [GraphPlot.jl]

```@autodocs
Modules = [DFGPlots]
```

## Drivers

### GraphsDFGs

```@autodocs
Modules = [GraphsDFGs]
```

### FileDFG

```@autodocs
Modules = [DistributedFactorGraphs]
Pages = ["FileDFG.jl"]
```

### Neo4jDFGs

```@autodocs
Modules = [Neo4jDFGs]
```



## Data Entries and Blobs

```@autodocs
Modules = [DistributedFactorGraphs]

Pages = ["entities/AbstractDataEntries.jl",
        "services/AbstractDataEntries.jl",
        "services/BlobStores.jl",
        "services/DataEntryBlob.jl",
        "services/FileDataEntryBlob.jl",
        "services/InMemoryDataEntryBlob.jl"]

```
