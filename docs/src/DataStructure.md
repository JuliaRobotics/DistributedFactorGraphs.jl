# Data Structure

Variables and factors can potentially contain a lot of data, so DFG has
different structures that are specialized for each use-case and level of detail.
For example, if you  want to retrieve just a simple summary of the structure,
you can use the summary or skeleton structures to identify variables and factors
of interest and then retrieve more detail on the subset.

Note that drivers support all of the structures.

The following section discusses the datastructures for each level. A quick
summary of the types and the available properties:

[Table of Variable Properties]

[Table of Factor Properties]

## DFG Skeleton

```@docs
SkeletonDFGVariable
SkeletonDFGFactor
```

## DFG Summary

```@docs
DFGVariableSummary
DFGFactorSummary
```

## Full DFG Node

```@docs
DFGVariable
DFGFactor
```

## Additional Offloaded Data

Additional, larger data can be associated with variables using keyed big data entries.  
