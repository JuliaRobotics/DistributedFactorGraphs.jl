#TODO maybe mutable
@kwdef mutable struct Agent
    label::Symbol = :DefaultAgent
    description::String = ""
    tags::Set{Symbol} = Set{Symbol}()
    bloblets::Bloblets = Bloblets()
    blobentries::Blobentries = Blobentries()
end

@kwdef mutable struct Graphroot
    label::Symbol = :DefaultFactorgraph
    description::String = ""
    tags::Set{Symbol} = Set{Symbol}()
    bloblets::Bloblets = Bloblets()
    blobentries::Blobentries = Blobentries()
end
