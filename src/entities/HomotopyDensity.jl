

##==============================================================================
## Abstract Types
##==============================================================================

abstract type AbstractStateType{N} end
const StateType = AbstractStateType


"""
    AbstractHomotopyTopology

Describes the physical layout of the nodes within a `HomotopyDensityDFG`.

Since all beliefs in the Caesar ecosystem are fundamentally Homotopy densities, 
this trait acts as a lightweight dispatch hint (a "Lens Selector"). It indicates 
which parts of the tree (Roots vs. Leaves) are currently populated and how they 
are wired, without requiring downstream packages to inspect the underlying vectors.

**Role of the Topology Trait:**
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
abstract type AbstractHomotopyTopology end

# --- 1. The Roots ---
"L1 structural nodes only. No L2 samples. (Schema: `means`, `weights`, `shapes` populated. `points` empty.)"
struct RootsOnlyTopology <: AbstractHomotopyTopology end

# --- 2. The Leaves ---
"L2 raw samples only. No L1 structure. (Schema: `points`, `bandwidths` populated. `means` empty.)"
struct LeavesOnlyTopology <: AbstractHomotopyTopology end

# --- 3. The Full Trees ---
"Tree packed in arrays using 2i, 2i+1 math.(Schema: L1 and L2 populated. Parent arrays empty.)"
struct ImplicitTreeTopology <: AbstractHomotopyTopology end

"Full tree using adjacency lists. (Schema: L1, L2, and Parent arrays fully populated.)"
struct ExplicitTreeTopology <: AbstractHomotopyTopology end

function StructUtils.lower(::StructUtils.StructStyle, p::AbstractHomotopyTopology)
    return StructUtils.lower(Packed(p))
end
@choosetype AbstractHomotopyTopology resolvePackedType

abstract type AbstractDensityForm end
function StructUtils.lower(::StructUtils.StructStyle, p::AbstractDensityForm)
    return StructUtils.lower(Packed(p))
end
@choosetype AbstractDensityForm resolvePackedType

# TBD for best future looking structure here
abstract type AbstractPartialTrait end
function StructUtils.lower(::StructUtils.StructStyle, p::AbstractPartialTrait)
    return StructUtils.lower(Packed(p))
end
@choosetype AbstractPartialTrait resolvePackedType


struct DefaultFormKind <: AbstractDensityForm end

struct DefaultTopologyKind <: AbstractHomotopyTopology end

struct DefaultPartialKind <: AbstractPartialTrait end

# ==============================================================================
#  HomotopyDensityDFG
# ==============================================================================


# FROM AMP
# abstract type AbstractBinaryTreeDensity <: AbstractHomotopyTopology end
# const BinaryTreeDensity = AbstractBinaryTreeDensity
# struct BinaryTruncFixedDepth{N} <: AbstractBinaryTreeDensity end


# abstract type AbstractKernel <: AbstractDensityForm end
# @kwdef struct ConcentratedGaussianKernel{
#     partial, # partial info for compiler, usually a value e.g. nothing or (1,3)
#     K <: Distributions.MvNormal, # kernel info for compiler
#     T  # additional parameters
# } <: AbstractKernel



# Go with Option A in DFG v0.29, 
# Acknowledge design compromises (previous DFG v0.29 objective was to collect breaking changes on types, get as close to DFG v1-alpha):
# - HomotopyDensityDFG/Live converters/packers (DataLevel 3.5)
# - HomotopyDensityDFG.reprkind::HomotopyReprDFG
# - HomotopyReprDFG/Live converters/packers (DataLevel 3.5)
# - HomotopyReprDFG.partial has Legacy in AMP v0.15 through Caesar that needs something better by DFG v0.30
#   - DFG v0.29 will JSON ignore HomotopyReprDFG.partial field
##OPTION A
#  Pros 
#   - state container is type stable, 
#   - fields can be singleton so easier to serde
#  Cons 
#   - not itself a singleton type (not important?)
# DOCS FORCE FIELDS TO BE SINGLETON
@tags mutable struct HomotopyReprDFG{T <: StateType}
  topologykind::AbstractHomotopyTopology  # bitmap, jpeg, png
  reprkind::AbstractDensityForm           # RGB24, YCbCr, fullcov, uppercov, LieExpGaussianWrappedKind, ConcentrGaussKernelKind
  statekind::T                            # Position{2}
  partial::AbstractPartialTrait #& (json = (ignore = true,),)          # partials field needed for AMP v0.15, will be JSON ignored in DFG v0.29, needs better solution by DFG v0.30
end

# # UX -- DataLevel 3 if OPTION A
# X1 = getState(:naive).belief      ::HomotopyDensityDFG{Pose2}
# X1 = getState(:research1).belief  ::HomotopyDensityDFG{Pose2}   # principals look completely different
# # is this dynamic -- 
# plot(X1::HomotopyDensityDFG) = plot(what_topology(X1), X1)


# struct HomotopyReprLive{O <: AbstractHomotopyTopology, R <: AbstractDensityForm, T <: StateType}
#   ...
# end

# struct FancyStats{S}
#     x::Vector{Float64}
#     y::Vector{S}
# end

# struct SecondOrderStats{P, S} 
#     m0::Vector{Float64}
#     m1::Vector{P}
#     m2::Vector{S}
# end
# struct HomotopyDensityDFG{T <: StateType, A, B}
#     principal::A
#     trailing::B
#     ....
# end

# struct FancyPrincipalTrailingSecondOrder <: AbstractHomotopyTopology end
# repr = HomotopyDensityLive{HomotopyReprLive{FancyPrincipalTrailingSecondOrder, , }}
# dothis(getReprType(repr), repr)  -->  (prinicipal::FancyStats, trailing::SecondOrderStats)



# typeof(Pose2()) = Pose2
# getKind(...) -> Pose2()

# getType(::Kind) = ....
# getType(ConcentratedGaussianKernelKind) = ConcentratedGaussianKernel

# ConcentratedGaussianKernel(w...; kw...)  # this calls the constructor to make a new object
# # AbstractDensityForm tells compiler what to do here
# howthis(ConcGaussKind)(w...; kw...) -->  ::ConcentratedGaussianKernel{A,B,C} # this is functional programming to call the constructor
# howthis(ConcGaussKind, w...; kw...) -->  ::ConcentratedGaussianKernel{A,B,C} # this is manual dispatch to create a new object

# # 

# dothis(::ConcGaussKind, w...; kw...) -->  ::ConcentratedGaussianKernel{A,B,C} # this is manual dispatch to create a new object
# dothis(repr::HomotopyReprDFG) = dothis(getReprType(repr), repr)

# dothis(getReprType(belief), belief)
# dothis(getReprType(belief))(belief) # manual obj constructor rather than using JSON for details

# LieExpWrappedKind <: AbstractDensityForm
# ConcGaussianKernelKind <: AbstractDensityForm
# SecondOrderStatsKind <: AbstractDensityForm


# # this is a good "reprtype", what Dehann is trying
# {
#     "topology": "BinaryTruncFixedDepth{3}",
#     "reprtype": "ConcentratedGaussianKernelKind",
#     "statetype": "Pose2",
# }


# # this is a bad "reprtype", what Dehann already avoided
# {
#     "topology": "BinaryTruncFixedDepth{3}",
#     "reprtype": "ConcentratedGaussianKernel{this, that, whatever}",
#     "statetype": "Pose2",
# }




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
@kwdef struct HomotopyDensityDFG{T <: StateType, P}
    statekind::T = T()# NOTE duplication for serialization and self description.
    reprkind::HomotopyReprDFG{T} = HomotopyReprDFG{T}(
        DefaultTopologyKind(), 
        DefaultFormKind(), 
        T(), 
        DefaultPartialKind()
    ) # NOTE duplication for serialization and self description. FIXME this is redundant with statekind, but we need it to be a struct for serde, so we duplicate the statekind info here for now. Future refactor could unify these concepts better.
    """A hint for downstream solvers on how to interpret this data (The 'How')"""
    topologykind::AbstractHomotopyTopology = LeavesOnlyTopology()

    points::Vector{P} = P[] # previously `val`
    weights::Vector{Float64} = Float64[]
    """
    In model order reduction, PCA, and modal analysis, the terms for the eigenvectors associated with the largest and smallest eigenvalues are commonly:
      Major eigenvectors are often called "dominant eigenvectors," or simply "leading modes." In Principal Component Analysis (PCA), these are the "principal components."
      Minor eigenvectors are sometimes called "trailing eigenvectors," or "residual modes." In PCA, these correspond to the components with the smallest variance.
    """
    principal_coeffs::Vector{Float64} = Vector{Float64}() # FIXME getMajorsLength(reprkind))
    principal_elements::Vector{P} = P[] # previously `val[1]` for Gaussian
    principal_forms::Vector{Matrix{Float64}} = Matrix{Float64}[] # previously `covar` existed but was stored in `bw` (hacky)
    """
    Store minor eigenvalue details such as leaf bandwidth or reconstruction vectors.
    - When lifted for compute efficiency, this field is likely to hold something like PDMats.
    - When lowered or for serde, this field is likely to hold Dict{Int, Vector{Float64}}.
    """
    trailing_forms::Dict{Int,Matrix{Float64}} = Dict(
      # 1 => Matrix{Float64}(I, manifold_dimension(getManifold(statekind)), manifold_dimension(getManifold(statekind)))
    )
        #Matrix{Float64}[] #previously `bw` ---
    """
    Geometric points permute field, allows fast binary tree operations and geometric points splits for manellic (ball) trees. 
    - Geometric split reqs at least 2*(N+1)-1 points -- e.g. when nodes have only right children, points=[1,2,-3].
    """
    structure::Dict{Int,Vector{Int}} = Dict(
      1 => collect(1:length(points))
    )
end

JSON.omit_empty(::Type{<:HomotopyDensityDFG}) = true

function HomotopyDensityDFG(T::AbstractStateType)
    return HomotopyDensityDFG{typeof(T), getPointType(T)}(; statekind = T)
end

function HomotopyDensityDFG(::LeavesOnlyTopology, T::AbstractStateType; kwargs...)
    return HomotopyDensityDFG{typeof(T), getPointType(T)}(;
        statekind = T,
        topologykind = LeavesOnlyTopology(),
        trailing_forms = Dict{Int, Matrix{Float64}}(),
        kwargs...,
    )
end

function HomotopyDensityDFG(::RootsOnlyTopology, T::AbstractStateType; kwargs...)
    return HomotopyDensityDFG{typeof(T), getPointType(T)}(;
        statekind = T,
        topologykind = RootsOnlyTopology(),
        kwargs...,
    )
end

function StructUtils.fielddefaults(
    ::StructUtils.StructStyle,
    ::Type{HomotopyDensityDFG{T, P}},
) where {T, P}
    return (
        statekind = T(),
        topologykind = LeavesOnlyTopology(),
        principal_coeffs = Float64[],
        principal_elements = P[],
        principal_forms = Matrix{Float64}[],
        weights = Float64[],
        points = P[],
        trailing_forms = Dict{Int, Matrix{Float64}}(),
    )
end

function resolveHomotopyDensityDFGType(lazyobj)
    statekind = liftStateKind(lazyobj.statekind[])
    return HomotopyDensityDFG{typeof(statekind), getPointType(statekind)}
end

@choosetype HomotopyDensityDFG resolveHomotopyDensityDFGType

