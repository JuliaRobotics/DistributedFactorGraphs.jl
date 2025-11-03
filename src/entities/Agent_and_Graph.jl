#TODO maybe mutable
@kwdef mutable struct Agent
    label::Symbol = :DefaultAgent
    description::String = ""
    tags::Set{Symbol} = Set{Symbol}()
    bloblets::Bloblets = Bloblets()
    blobentries::OrderedDict{Symbol, Blobentry} = OrderedDict{Symbol, Blobentry}()
end

@kwdef mutable struct GraphRoot
    label::Symbol = :DefaultFactorgraph
    description::String = ""
    tags::Set{Symbol} = Set{Symbol}()
    bloblets::Bloblets = Bloblets()
    blobentries::OrderedDict{Symbol, Blobentry} = OrderedDict{Symbol, Blobentry}()
end
