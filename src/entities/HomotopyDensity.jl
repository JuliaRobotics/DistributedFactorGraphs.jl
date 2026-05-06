
# ==============================================================================
#  HomotopyDensityDFG
# ==============================================================================



export 
  AbstractPartialTraits,
  AbstractHomotopyTruncation,
  MajorMaxDepth

export 
  getStateType, 
  getManifold, 
  getReprType, 
  getTruncation, 
  getPartial


# Forward looking abstract for DFG v1.x development of partials using traits, but not yet implemented
abstract type AbstractPartialTraits end

abstract type AbstractHomotopyTruncation end

abstract type AbstractDensityBasis end



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
  truncation <: AbstractHomotopyTruncation,
  reprtype <: AbstractDensityBasis, 
  statetype <: Union{<:AbstractManifold, <:AbstractStateType},
  L <: AbstractPartialLegacyCompat, # Future use <:AbstractPartialTraits
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


struct MajorMaxDepth{
  N
} <: AbstractHomotopyTruncation end


getMajorsLength(::Type{<:AbstractHomotopyTruncation}) = 1
getMajorsLength(repr::HomotopyRepr) = getMajorsLength(getTruncation(repr))

# Binary tree with N major levels
getMajorsLength(::Type{MajorMaxDepth{N}}) where {N} = N^2 - 1

# trivial case -- should be in DFG instead FIXME
getManifold(manif::AbstractManifold) = manif

getStateType(::HomotopyRepr{T,R,statetype}) where {T,R,statetype} = statetype
getPartial(hr::HomotopyRepr) = hr.partial
getReprType(::HomotopyRepr{T,reprtype}) where {T, reprtype} = reprtype
getTruncation(::HomotopyRepr{truncation}) where {truncation} = truncation
# supports both DFG and ManifoldsBase
getManifold(repr::HomotopyRepr) = getManifold(repr.statekind) 





# # --- 1. The Roots ---
# "L1 structural nodes only. No L2 samples. (Schema: `means`, `weights`, `shapes` populated. `points` empty.)"
# struct RootsOnlyTopology <: AbstractHomotopyTopology end

# # --- 2. The Leaves ---
# "L2 raw samples only. No L1 structure. (Schema: `points`, `bandwidths` populated. `means` empty.)"
# struct LeavesOnlyTopology <: AbstractHomotopyTopology end

# # --- 3. The Full Trees ---
# "Tree packed in arrays using 2i, 2i+1 math.(Schema: L1 and L2 populated. Parent arrays empty.)"
# struct ImplicitTreeTopology <: AbstractHomotopyTopology end

# "Full tree using adjacency lists. (Schema: L1, L2, and Parent arrays fully populated.)"
# struct ExplicitTreeTopology <: AbstractHomotopyTopology end

# function StructUtils.lower(::StructUtils.StructStyle, p::AbstractHomotopyTopology)
#     return StructUtils.lower(Packed(p))
# end
# @choosetype AbstractHomotopyTopology resolvePackedType

"""
    HomotopyDensityDFG{H <: HomotopyRepr, P}

Hybrid belief representation with natural transition between (non)parametric representations.

These are the internal raw beliefs and need to be viewed through a lens such as 
provided by AMP for features like pdf evaluation. 

Notes:
- Refactoring and renaming of ManellicTree + ManifoldKernelDensity
- Replaces kernel density estimate, Gaussian mixture models, Principle component analysis, Homotopy methods, Model order reduction
- Allows partials as identified by list of coordinate dimensions e.g. `partial = [1;3]`
  - When building a partial belief, use full points with necessary information in the specified partial coords.

In model order reduction, PCA, and modal analysis, the terms for the eigenvectors associated with the largest and smallest eigenvalues are commonly:
Major eigenvectors are often called "dominant eigenvectors," or simply "leading modes." In Principal Component Analysis (PCA), these are the "principal components."
Minor eigenvectors are sometimes called "trailing eigenvectors," or "residual modes." In PCA, these correspond to the components with the smallest variance.

!!! warning "Raw Data Container"
    `HomotopyDensityDFG` is the raw data schema used for database storage and serialization.
    Mutating this structure in-place is discouraged. Rather, construct a new `State` object 
    and call `addState!` or `mergeState!`.
"""
@kwdef struct HomotopyDensityDFG{
  H <: HomotopyRepr, # serde friendly when using DFG.statekind representation, but also supports Manifolds.jl direclty
  # parameters below auto generate during JSON lift, only above needs to be serde friendly
  P, # serde relies on DFG statekind mechanism, does not guarantee serde when directly using Manifolds wo DFG.statekind
}
    reprkind::H
    observability::Vector{Float64} = zeros(manifold_dimension(getManifold(reprkind)))
    points::Vector{P}
    weights::Vector{Float64} = Vector{Float64}(ones(length(points))) ./ length(points)
    majors_coeff::Vector{Float64} = Vector{Float64}(undef, getMajorsLength(reprkind))
    majors_element::Vector{P} = Vector{P}(undef, getMajorsLength(reprkind))
    majors_detail::Vector{Matrix{Float64}} = Vector{SMatrix{Float64}}(undef, getMajorsLength(reprkind))
    """
    Store minor details such as leaf bandwidth or eigenvectors associated with minor eigenvalues.
    - When lifted for compute efficiency, this field is likely to hold something like PDMats.
    - When lowered or for serde, this field is likely to hold Dict{Int, Vector{Float64}}.
    """
    minors_detail::SparseArrays.SparseVector{SMatrix{Float64}, Int} = SparseArrays.sparsevec(
      Dict(1 => Matrix{Float64}(I, manifold_dimension(getManifold(reprkind)), manifold_dimension(getManifold(reprkind))),),
      1
    )
    """ 
    Geometric points permute field, allows fast binary tree operations and geometric points splits for manellic (ball) trees. 
    - Geometric split reqs at least 2*(N+1)-1 points -- e.g. when nodes have only right children, points=[1,2,-3].
    """
    structure::SparseArrays.SparseVector{Vector{Int}, Int} = SparseArrays.sparsevec(
      Dict(1 => collect(1:length(points))), 
      5*(length(points)) # large buffer space where impact on resources mitigated via sparsevec
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

function HomotopyDensityDFG(T::AbstractStateType)
    return HomotopyDensityDFG{typeof(T), getPointType(T)}(; statekind = T)
end

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

function StructUtils.fielddefaults(
    ::StructUtils.StructStyle,
    ::Type{HomotopyDensityDFG{T, P}},
) where {T, P}
    return (
        statekind = T(),
        means = P[],
        shapes = Matrix{Float64}[],
        weights = Float64[],
        points = P[],
        bandwidths = Matrix{Float64}[],
        mean_parents = Int[],
        point_parents = Int[],
    )
end

function resolveStoredBeliefType(lazyobj)
    statekind = liftStateKind(lazyobj.statekind[])
    return HomotopyDensityDFG{typeof(statekind), getPointType(statekind)}
end

@choosetype HomotopyDensityDFG resolveStoredBeliefType
