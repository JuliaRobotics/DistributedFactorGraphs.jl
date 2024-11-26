# DFG Data Structures

Variables and factors can potentially contain a lot of data, so DFG has
different structures that are specialized for each use-case and level of detail.
For example, if you  want to retrieve just a simple summary of the structure,
you can use the summary or skeleton structures to identify variables and factors
of interest and then retrieve more detail on the subset.

Note that not all drivers support all of the structures.

The following section discusses the datastructures for each level. A quick
summary of the types and the available properties (some of which are derived) is provided below.

Accessible properties for each of the variable structures:

|                     | Label | Timestamp | Tags | Estimates | Soft Type | Solvable | Solver Data | Metadata | Blob Entries |
|---------------------|-------|-----------|------|-----------|-----------|----------|-------------|----------|--------------|
| VariableSkeleton | X     |           | X    |           |           |          |             |          |              |
| VariableSummary  | X     | X         | X    | X         | Symbol    |          |             |          | X            |
| VariableCompute         | X     | X         | X    | X         | X         | X        | X           | X        | X            |

Accessible properties for each of the factor structures:

|                   | Label | Timestamp | Tags | Factor Type | Solvable | Solver Data |
|-------------------|-------|-----------|------|-------------|----------|-------------|
| SkeletonDFGFactor | X     |           | X    |             |          |             |
| DFGFactorSummary  | X     | X         | X    |             |          |             |
| DFGFactor         | X     | X         | X    | X           | X        | X           |

## DFG Skeleton types

- [`VariableSkeleton`](@ref)
- [`SkeletonDFGFactor`](@ref)

## DFG Summary types

- [`VariableSummary`](@ref)
- [`DFGFactorSummary`](@ref)

## DFG Portable and Storeable types

- [`Variable`](@ref)
- [`PackedFactor`](@ref)

## DFG Full solvable types

- [`VariableCompute`](@ref)
- [`DFGFactor`](@ref)

## Additional Offloaded Data

Additional, larger data can be associated with variables and factors using keyed blob entries.  
