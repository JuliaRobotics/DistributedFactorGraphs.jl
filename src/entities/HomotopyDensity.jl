
# ==============================================================================
#  StoredHomotopyBelief
# ==============================================================================
"""
    AbstractHomotopyTopology

Describes the physical layout of the nodes within a `StoredHomotopyBelief`.

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

"""
    StoredHomotopyBelief{T <: StateType, P}

A multi-resolution "Grove of Trees" representing a manifold belief.
Each tree can be as deep (ExplicitTreeTopology) or as shallow (RootsOnlyTopology) 
as the evidence requires, but they all speak the same language of Nodes and Parents.

These are the internal raw beliefs and need to be viewed through a lens such as 
provided by AMP for features like pdf evaluation. Organized into structural 
Tree/Branch layers (L1) and empirical Leaf layers (L2).

!!! warning "Raw Data Container"
    `StoredHomotopyBelief` is the raw data schema used for database storage and serialization.
    Mutating this structure in-place is discouraged. Rather, construct a new `State` object 
    and call `addState!` or `mergeState!`.
"""
@kwdef struct StoredHomotopyBelief{T <: StateType, P}
    statekind::T = T()# NOTE duplication for serialization and self description.
    """A hint for downstream solvers on how to interpret this data (The 'How')"""
    topologykind::AbstractHomotopyTopology = LeavesOnlyTopology()

    # L1 Nodes
    """
    [Order 0] The relative importance or probability of each node in L1.
    """
    weights::Vector{Float64} = Float64[]
    """
    [Order 1] The location/center of each node, stored directly on the manifold.
    """
    means::Vector{P} = P[] # previously `val[1]` for Gaussian
    """
    [Order 2] The spread/curvature of each node (e.g., Covariance or Precision matrix). 
    """
    shapes::Vector{Matrix{Float64}} = Matrix{Float64}[] # previously `covar` existed but was stored in `bw` (hacky)

    # L2 Nodes
    """
    The raw empirical samples on the manifold. Used for KDE and particle representations.
    """
    points::Vector{P} = P[] # previously `val`
    """
    The second-order bandwidths for the non-parametric points, supports variable bandwidth kernels.
    """
    bandwidths::Vector{Matrix{Float64}} = Matrix{Float64}[] #previously `bw` ---

    # --- Topology (The Hierarchy) ---
    """
    L1 Internal Topology: mean_parents[i] = j means means[i] is a child of means[j]. A value of 0 indicates a Root node.
    """
    mean_parents::Vector{Int} = Int[]
    """
    L2-to-L1 Bridge: point_parents[i] = j means points[i] is governed by means[j]. Points are leaves.
    """
    point_parents::Vector{Int} = Int[]
end

JSON.omit_empty(::Type{<:StoredHomotopyBelief}) = true

function StoredHomotopyBelief(T::AbstractStateType)
    return StoredHomotopyBelief{typeof(T), getPointType(T)}(; statekind = T)
end

function StoredHomotopyBelief(::LeavesOnlyTopology, T::AbstractStateType; kwargs...)
    return StoredHomotopyBelief{typeof(T), getPointType(T)}(;
        statekind = T,
        topologykind = LeavesOnlyTopology(),
        bandwidths = [zeros(getDimension(T), getDimension(T))],
        kwargs...,
    )
end

function StoredHomotopyBelief(::RootsOnlyTopology, T::AbstractStateType; kwargs...)
    return StoredHomotopyBelief{typeof(T), getPointType(T)}(;
        statekind = T,
        topologykind = RootsOnlyTopology(),
        kwargs...,
    )
end

function StructUtils.fielddefaults(
    ::StructUtils.StructStyle,
    ::Type{StoredHomotopyBelief{T, P}},
) where {T, P}
    return (
        statekind = T(),
        topologykind = LeavesOnlyTopology(),
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
    return StoredHomotopyBelief{typeof(statekind), getPointType(statekind)}
end

@choosetype StoredHomotopyBelief resolveStoredBeliefType
