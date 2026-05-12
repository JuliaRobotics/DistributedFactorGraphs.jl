
##==============================================================================
## Abstract Types
##==============================================================================

abstract type AbstractStateType{N} end
const StateType = AbstractStateType

abstract type AbstractHomotopyTopology end
struct DefaultTopologyKind <: AbstractHomotopyTopology end

function StructUtils.lower(::StructUtils.StructStyle, p::AbstractHomotopyTopology)
    return StructUtils.lower(Packed(p))
end
@choosetype AbstractHomotopyTopology resolvePackedType

abstract type AbstractDensityForm end
struct DefaultFormKind <: AbstractDensityForm end
function StructUtils.lower(::StructUtils.StructStyle, p::AbstractDensityForm)
    return StructUtils.lower(Packed(p))
end
@choosetype AbstractDensityForm resolvePackedType

# TBD for best future looking structure here. ignore = true, so no serialization
abstract type AbstractPartialTrait end

# ==============================================================================
#  HomotopyDensityDFG
# ==============================================================================
# @kwarg struct HomotopyReprDFG{
@defaults struct HomotopyReprDFG{
    T <: StateType,
    HT <: AbstractHomotopyTopology,
    RF <: AbstractDensityForm,
    PT <: Union{Nothing, <:AbstractPartialTrait},
}
    topologykind::HT
    formkind::RF
    statekind::T
    partial::PT = nothing & (ignore = true,) #TODO deprecated field, still needed for AMP.  
    # partials field needed for AMP v0.15, will be JSON ignored in DFG v0.29, needs better solution by DFG v0.30
end

StructUtils.structlike(::StructUtils.StructStyle, ::Type{<:HomotopyReprDFG}) = true

function resolveHomotopyReprDFGType(lazyobj)
    topo = resolveType(lazyobj.topologykind[])
    form = resolveType(lazyobj.formkind[])
    statekind = liftStateKind(lazyobj.statekind[])
    return HomotopyReprDFG{typeof(statekind), topo, form, Nothing}
end
@choosetype HomotopyReprDFG resolveHomotopyReprDFGType

"""
    HomotopyDensityDFG{T <: StateType, P}

Hybrid belief representation with natural transition between (non)parametric representations.

**THIS IS IMPORTANT**: Fundamentally related to `HomotopyDensity` definition in AMP.jl.

!!! warning "Raw Data Container"
    `HomotopyDensityDFG` is the raw data schema used for database storage and serialization.
    Mutating this structure in-place is discouraged. Rather, construct a new `State` object 
    and call `addState!` or `mergeState!`.

Notes:
- These are the internal raw beliefs and need to be viewed through a lens such as 
provided by AMP for features like pdf evaluation. 
- Allows partials as identified by list of coordinate dimensions via `.reprkind{...L}.partial`
  - e.g. legacy `partial = [1;3] or (1,3)`
    - When building a partial belief, use full points with necessary information in the specified partial coords.
- Replaces ManellicTree, ManifoldKernelDensity, KernelDensityEstimate, GaussianMixtureModel, PCA, Mixtures
  - a.k.a. model order reduction given a topology selection
"""
@kwdef struct HomotopyDensityDFG{T <: StateType, P}
    reprkind::HomotopyReprDFG{T} =
        HomotopyReprDFG(DefaultTopologyKind(), DefaultFormKind(), T(), nothing)
    """A hint for downstream solvers on how to interpret this data (The 'How')"""
    topologykind::AbstractHomotopyTopology = DefaultTopologyKind()
    """Stores the amount of information captured in each coordinate dimension."""
    observability::Vector{Float64} = Float64[] #zeros(getDimension(T)) #TODO renamed from infoPerCoord in v0.29
    """Hard decision that input data are sample points from some manifold, but note the reconstruction might not use points at all."""
    points::Vector{P} = P[] # previously `val`
    """Input points may be weighted, and/or reused as part of reconstruction in the trailing forms."""
    weights::Vector{Float64} = Float64[]
    """
    In model order reduction, PCA, and modal analysis, the terms for the eigenvectors associated with the largest and smallest eigenvalues are commonly:
      Principal/major/dominant/leading recon-basis/eigen vectors. In Principal Component Analysis (PCA), these are the "principal components."
      Trailing/minor/residual recon-basis/eigen vectors. In PCA, these correspond to the components with the smallest variance.
    """
    principal_coeffs::Vector{Float64} = Vector{Float64}() # FIXME getMajorsLength(reprkind))
    principal_elements::Vector{P} = P[] # previously `val[1]` for Gaussian
    principal_forms::Vector{Matrix{Float64}} = Matrix{Float64}[] # previously `covar` existed but was stored in `bw` (hacky)
    """
    Store minor eigenvalue details such as leaf bandwidth or reconstruction vectors.
    - Live compute version may hold something like PDMats/Cholesky.
    """
    trailing_forms::SparseVector{Matrix{Float64}, Int} = spzeros(Matrix{Float64}, 1) #previously `bw`
    """
    Geometric points permute field, allows fast binary tree operations and geometric points splits for manellic (ball) trees. 
    - Balanced split reqs at least 2*(N+1)-1 points, incl. right-only case -- e.g. when nodes have only right children, points=[1,2,-3].
    - Unclear at time of writing whether DFG v1.X will exceed binary tree representations, but at least `.structure` allows for e.g. n-many child topologies.
    """
    structure::SparseVector{Vector{Int}, Int} = spzeros(Vector{Int}, 1)
end

JSON.omit_empty(::Type{<:HomotopyDensityDFG}) = true

function HomotopyDensityDFG(T::AbstractStateType)
    return HomotopyDensityDFG{typeof(T), getPointType(T)}()
end

function StructUtils.fielddefaults(
    ::StructUtils.StructStyle,
    ::Type{HomotopyDensityDFG{T, P}},
) where {T, P}
    return (
        topologykind = DefaultTopologyKind(),
        observability = Float64[],
        principal_coeffs = Float64[],
        principal_elements = P[],
        principal_forms = Matrix{Float64}[],
        weights = Float64[],
        points = P[],
        trailing_forms = sparsevec(Int[], Matrix{Float64}[]),
    )
end

function StructUtils.fieldtags(::StructUtils.StructStyle, ::Type{<:HomotopyDensityDFG})
    return (reprkind = (choosetype = resolveHomotopyReprDFGType,),)
end

function resolveHomotopyDensityDFGType(lazyobj)
    statekind = liftStateKind(lazyobj.reprkind.statekind[])
    return HomotopyDensityDFG{typeof(statekind), getPointType(statekind)}
end

@choosetype HomotopyDensityDFG resolveHomotopyDensityDFGType
