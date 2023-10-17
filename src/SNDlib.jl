module SNDlib

include("network.jl")
include("download.jl")
include("solution.jl")

export SNDNetwork,
       is_valid_network_file,
       load_network,
       SNDSolution,
       load_solution,
       get_link_configuration

function Base.show(io::IO, network::SNDNetwork)
    println(io, "SNDNetwork")
    println(io, "\tname    = $(network.name)")
    println(io, "\tnodes   = $(length(network.nodes))")
    println(io, "\tlinks   = $(length(network.links))")
    println(io, "\tdemands = $(length(network.demands))")
end

function Base.print(io::IO, network::SNDNetwork)
    Base.show(io, network)
end

end # module
