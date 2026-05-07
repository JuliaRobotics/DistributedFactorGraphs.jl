
##==============================================================================
## Abstract Types
##==============================================================================

abstract type AbstractStateType{N} end
const StateType = AbstractStateType

"""
AbstractHomotopyTopology
"""
abstract type AbstractHomotopyTopology end # FIXME add parameter{N}?

# Forward looking abstract for DFG v1.x development of partials using traits, but not yet implemented
abstract type AbstractPartialTraits end

abstract type AbstractDensityBasis end


# DO NOT EXPORT AbstractPartialLegacyCompat 
const AbstractPartialLegacyCompat = Union{<:DistributedFactorGraphs.AbstractPartialTraits, Nothing, Tuple, Vector{Int}} 
# FIXME, drop Nothing, <:Tuple for type refactor compat period


# ==============================================================================
#  HomotopyDensityDFG
# ==============================================================================



"""
HomotopyRepr is a struct that encapsulates the representation of a homotopy density.
  HomotopyDensity is a very broad and 99% agnostic serialization type whose method implementations should dispatch
  on the type of the representation, which is expected to be a concrete type with necessary dispatch info.

Comment on future-proofing: at time of writing (26Q2), we anticipate a long and methodic development of 
  hybrid-(non)parametric computational methods which can all fit in the same general LTS framework (i.e. DFG v1).

Future-proofing is achieved by making the representation type a concrete struct which is JSON.jl compliant, barr
- elementary lift and lower implementations for HomotopyRepr.

Describes the physical layout of the nodes within a `HomotopyDensityDFG`.

Since all beliefs in the Caesar ecosystem are fundamentally Homotopy densities, 
HomotopyRepr trait acts as a lightweight dispatch hint (a "Lens Selector"). It indicates 
which parts of the tree (Roots vs. Leaves) are currently populated and how they 
are wired, without requiring downstream packages to inspect the underlying vectors.


Comments on type parameters:
- statetype is the type of the state, 
  which is either a Manifolds.jl manifold type or a DFG statetype
- L is the type of the partial, future expectation is for improved traits-based partials while,
 legacy used tuples to specify coord dims.
- reprtype is the type of the density basis, 
  e.g. ConcentratedGaussianKernel and is expected to evolve into continuous eigen vectors and wavelets.
- truncation type relates to model order reduction technique embedded in the HomotopyDensity, 
  e.g. MajorMaxDepth is a simple binary tree truncation with N major levels.


**Role of the HomotopyRepr Trait:**
- **DFG:** Determines how to serialize and spatial-index the belief in the database.
- **Visualizers:** Decides how to render the data (e.g., drawing ellipses for roots vs. a point cloud for leaves).
- **IIF/AMP:** Selects the correct mathematical view to construct (e.g., `MvNormal` vs. `ManifoldKernelDensity` vs. a full `HomotopyDensity`).

!!! note "State, not Strategy"
    The trait purely describes the *current physical shape* of the data (e.g., "I currently only have Roots populated").
    It does *not* dictate the solver strategy (e.g., "You must use a parametric solver"). 
    The math engine is always free to convert or expand the data based on the graph's needs.

**Extending:**
If the standard tree-based Homotopy model does not fit your specific data layout 
or solver requirements, you are encouraged to extend this abstract type with your 
own custom topology struct. Alternatively, if you believe your use case represents 
a missing core layout, please open an issue to discuss adding it to the 
foundational ecosystem.
"""
struct HomotopyRepr{
  topology <: AbstractHomotopyTopology,
  reprtype <: AbstractDensityBasis, 
  statetype <: AbstractStateType,
  L <: AbstractPartialLegacyCompat, # FIXME use <:AbstractPartialTraits
} 
  """ 
  Used for either DistributedFactorGraphs statetype or Manifolds.jl manifold type, depending on context. 
  Expect official support for serde only for DFG statetypes.  Note, DFG statetypes are built on top of Manifolds.jl.
  Use `getManifold(::HomotopyRepr)` to get the manifold type regardless of context.

  Note, and explicit object `statekind` is needed for the Manifolds.jl only context, but note this field is not serialized
  """
  statekind::statetype
  """
  Future of partials is to use traits, so an abstract type is warranted.
  Legacy is object of either Nothing, Tuple, or Vector{Int}, but something better is needed
  """
  partial::L
end



getMajorsLength(::Type{<:AbstractHomotopyTopology}) = 1
getMajorsLength(repr::HomotopyRepr) = getMajorsLength(getTopology(repr))

# trivial case -- should be in DFG instead FIXME
getManifold(manif::AbstractManifold) = manif

getStateType(::HomotopyRepr{T,R,statetype}) where {T,R,statetype} = statetype
getPartial(hr::HomotopyRepr) = hr.partial
getReprType(::HomotopyRepr{T,reprtype}) where {T, reprtype} = reprtype
getTopology(::HomotopyRepr{truncation}) where {truncation} = truncation
# supports both DFG and ManifoldsBase
getManifold(repr::HomotopyRepr) = getManifold(repr.statekind) 



function StructUtils.lower(::StructUtils.StructStyle, p::AbstractHomotopyTopology)
    return StructUtils.lower(Packed(p))
end
@choosetype AbstractHomotopyTopology resolvePackedType

"""
    HomotopyDensityDFG{H <: HomotopyRepr, P}

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
@kwdef struct HomotopyDensityDFG{
  H <: HomotopyRepr, # serde friendly when using DFG.statekind representation, but also supports Manifolds.jl direclty
  P, # serde relies on reprkind.statekind <: StateKind mechanism
}
    reprkind::H
    observability::Vector{Float64} = zeros(manifold_dimension(getManifold(reprkind)))
    points::Vector{P}
    weights::Vector{Float64} = Vector{Float64}(ones(length(points))) ./ length(points)
    """
    In model order reduction, PCA, and modal analysis, the terms for the eigenvectors associated with the largest and smallest eigenvalues are commonly:
      Major eigenvectors are often called "dominant eigenvectors," or simply "leading modes." In Principal Component Analysis (PCA), these are the "principal components."
      Minor eigenvectors are sometimes called "trailing eigenvectors," or "residual modes." In PCA, these correspond to the components with the smallest variance.
    """
    principal_coeffs::Vector{Float64} = Vector{Float64}(undef, getMajorsLength(reprkind))
    # FIXME, future proof with Vector{Matrix{Float64}} instead, using affine_matrix
    principal_elements::Vector{P} = Vector{P}(undef, getMajorsLength(reprkind))  
    principal_details::Vector{Matrix{Float64}} = Vector{Matrix{Float64}}(undef, getMajorsLength(reprkind))
    """
    Store minor eigenvalue details such as leaf bandwidth or reconstruction vectors.
    - When lifted for compute efficiency, this field is likely to hold something like PDMats.
    - When lowered or for serde, this field is likely to hold Dict{Int, Vector{Float64}}.
    """
    trailing_details::Dict{Int, Matrix{Float64}} = Dict(
      1 => Matrix{Float64}(I, manifold_dimension(getManifold(reprkind)), manifold_dimension(getManifold(reprkind)))
    )
    """
    Geometric points permute field, allows fast binary tree operations and geometric points splits for manellic (ball) trees. 
    - Geometric split reqs at least 2*(N+1)-1 points -- e.g. when nodes have only right children, points=[1,2,-3].
    """
    structure::Dict{Int,Vector{Int}} = Dict(
      1 => collect(1:length(points))
    )
end

# UPGRADE WISHLIST, REPLACE WITH SMatrix over Matrix, or SparseVector over Dict
function StructUtils.fielddefaults(
    ::StructUtils.StructStyle,
    ::Type{HomotopyDensityDFG{T, P}},
) where {T, P}
    return (
        reprkind = T(),
        observability = Float64[],
        points = P[],
        weights = Float64[],
        principal_coeffs = Float64[],
        principal_elements = P[], # FIXME convert to Vector{Matrix{Float64}} instead, using affine_matrix
        principal_details = Matrix{Float64}[], # TODO, upgrade to SMatrix, needs dimension
        trailing_details = Dict{Int,Matrix{Float64}}(), # TODO, upgrade to sparsevec
        mean_parents = Int[],
        structure = Dict{Int,Vector{Int}}(), # TODO, upgrade to sparsevec of Vector{Int}
    )
end

# @kwdef struct HomotopyDensityDFG{T <: StateType, P}
#     statekind::T = T()# NOTE duplication for serialization and self description.
#     """A hint for downstream solvers on how to interpret this data (The 'How')"""
#     topologykind::AbstractHomotopyTopology = LeavesOnlyTopology()

#     # L1 Nodes
#     """
#     [Order 0] The relative importance or probability of each node in L1.
#     """
#     weights::Vector{Float64} = Float64[]
#     """
#     [Order 1] The location/center of each node, stored directly on the manifold.
#     """
#     means::Vector{P} = P[] # previously `val[1]` for Gaussian
#     """
#     [Order 2] The spread/curvature of each node (e.g., Covariance or Precision matrix). 
#     """
#     shapes::Vector{Matrix{Float64}} = Matrix{Float64}[] # previously `covar` existed but was stored in `bw` (hacky)

#     # L2 Nodes
#     """
#     The raw empirical samples on the manifold. Used for KDE and particle representations.
#     """
#     points::Vector{P} = P[] # previously `val`
#     """
#     The second-order bandwidths for the non-parametric points, supports variable bandwidth kernels.
#     """
#     bandwidths::Vector{Matrix{Float64}} = Matrix{Float64}[] #previously `bw` ---

#     # --- Topology (The Hierarchy) ---
#     """
#     L1 Internal Topology: mean_parents[i] = j means means[i] is a child of means[j]. A value of 0 indicates a Root node.
#     """
#     mean_parents::Vector{Int} = Int[]
#     """
#     L2-to-L1 Bridge: point_parents[i] = j means points[i] is governed by means[j]. Points are leaves.
#     """
#     point_parents::Vector{Int} = Int[]
# end

JSON.omit_empty(::Type{<:HomotopyDensityDFG}) = true

# function HomotopyDensityDFG(T::AbstractStateType)
#     return HomotopyDensityDFG{typeof(T), getPointType(T)}(; statekind = T)
# end

# function HomotopyDensityDFG(::LeavesOnlyTopology, T::AbstractStateType; kwargs...)
#     return HomotopyDensityDFG{typeof(T), getPointType(T)}(;
#         statekind = T,
#         topologykind = LeavesOnlyTopology(),
#         bandwidths = [zeros(getDimension(T), getDimension(T))],
#         kwargs...,
#     )
# end

# function HomotopyDensityDFG(::RootsOnlyTopology, T::AbstractStateType; kwargs...)
#     return HomotopyDensityDFG{typeof(T), getPointType(T)}(;
#         statekind = T,
#         topologykind = RootsOnlyTopology(),
#         kwargs...,
#     )
# end




function resolveHomotopyDensityDFGType(lazyobj)
    reprkind = liftReprKind(lazyobj.reprkind[])
    # statekind = liftStateKind(lazyobj.statekind[])
    return HomotopyDensityDFG{typeof(reprkind), getPointType(reprkind.statekind)}
end

@choosetype HomotopyDensityDFG resolveStoredBeliefType
