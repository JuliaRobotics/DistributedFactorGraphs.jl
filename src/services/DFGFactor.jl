##==============================================================================
## Accessors
##==============================================================================

function setTimestamp(f::DFGFactor, ts::DateTime)
    return DFGFactor(f.label, ts, f.tags, f.solverData, f.solvable, f._dfgNodeParams, f._variableOrderSymbols)
end

function setTimestamp(f::DFGFactorSummary, ts::DateTime)
    return DFGFactorSummary(f.label, ts, f.tags, f._internalId, f._variableOrderSymbols)
end

setTimestamp!(f::FactorDataLevel1, ts::DateTime) = f.timestamp = ts


"""
    $SIGNATURES

Retrieve solver data structure stored in a factor.
"""
function getSolverData(f::F) where F <: DFGFactor
  return f.solverData
end

#TODO don't know if this is used, added for completeness
setSolverData!(f::DFGFactor, data::GenericFunctionNodeData) = f.solverData = data

"""
    $SIGNATURES

Return reference to the user factor in `<:AbstractDFG` identified by `::Symbol`.
"""
getFactorFunction(fcd::GenericFunctionNodeData) = fcd.fnc.usrfnc!
getFactorFunction(fc::DFGFactor) = getFactorFunction(getSolverData(fc))
function getFactorFunction(dfg::G, fsym::Symbol) where G <: AbstractDFG
  getFactorFunction(getFactor(dfg, fsym))
end


"""
    $SIGNATURES

Return user factor type from factor graph identified by label `::Symbol`.

Notes
- Replaces older `getfnctype`.
"""
getFactorType(data::GenericFunctionNodeData) = data.fnc.usrfnc!
getFactorType(fct::DFGFactor) = getFactorType(getSolverData(fct))
function getFactorType(dfg::G, lbl::Symbol) where G <: AbstractDFG
  getFactorType(getFactor(dfg, lbl))
end


"""
    $SIGNATURES

Return `::Bool` on whether given factor `fc::Symbol` is a prior in factor graph `dfg`.
"""
function isPrior(dfg::G, fc::Symbol)::Bool where G <: AbstractDFG
  fco = getFactor(dfg, fc)
  getfnctype(fco) isa FunctorSingleton
end



##==============================================================================
## Layer 2 CRUD  (none) and Sets
##==============================================================================

##==============================================================================
## TAGS - See CommonAccessors
##==============================================================================
