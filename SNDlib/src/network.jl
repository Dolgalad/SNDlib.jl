"""
Routines for reading network files (version 1.0)
"""

"""Exception for badly formated network files
"""
struct BadSNDNetworkFile <: Exception end

"""SNDNode structure
"""
struct SNDNode
    id::String
    longitude::Real
    latitude::Real
end

"""Create a SNDNode from line data
"""
function node_from_line(line::String)
    line = strip(line)
    words = split(line, " ")
    return SNDNode(words[1], parse(Float64, words[3]), parse(Float64, words[4]))
end


"""SNDLink structure
"""
struct SNDLink
    id::String
    src_id::String
    dst_id::String
    data
end

"""Create a SNDLink from line data
"""
function link_from_line(line::String)
    line = strip(line)
    words = split(line, " ")
    data = filter(e->e!="(" && e!=")", words[6:end])
    data = map(e->parse(Float64, e), data)
    return SNDLink(words[1], words[3], words[4], data)
end

"""SNDDemand structure
"""
struct SNDDemand
    id::String
    src_id::String
    dst_id::String
    routing_unit::Int
    value::Real
    max_path_length::String
end

"""Create a SNDDemand from line data
"""
function demand_from_line(line::String)
    line = strip(line)
    words = split(line, " ")
    words = filter(e->e!="(" && e!=")", words)
    return SNDDemand(words[1], words[2], words[3], parse(Int64, words[4]), parse(Float64, words[5]), words[6])
end

"""SNDNetwork structure
"""
struct SNDNetwork
    name
    nodes
    links
    demands
    metadata
    node_fields
    link_fields
    demand_fields
end

"""Check if a SNDlib network file is valid
"""
function is_valid_network_file(filename::String; version="1.0", format="native")
    f = open(filename, "r")
    first_line = readline(f)
    close(f)
    return first_line == "?SNDlib $format format; type: network; version: $version"
end

function remove_special_characters(line::String)
    for c in "#<>[](),*{}+"
        line = replace(line, c=>"")
    end
    return strip(line)
end

function parse_fields(line::String)
    fields = remove_special_characters(line)
    fields = replace(fields, "  "=>" ")
    return split(fields, " ")
end

"""Load a network file
"""
function load_network(filename::String)
    if !is_valid_network_file(filename)
        throw(BadSNDNetworkFile("File $filename is not a valid SND network file."))
    end
    # file is a valid SNDlib network file
    f = open(filename,"r")
    line_num = 0
    current_section = "none" # can take values in node, link, meta, demand, none
    name = splitext(basename(filename))[1]
    nodes, node_fields = [], []
    links, link_fields = [], []
    demands, demand_fields = [], []
    metadata = Dict()
    while !eof(f)
        l = readline(f)
        line_num += 1
        # commented lines start with #
        if !startswith(l, "#")
            if startswith(l, "NODES (")
                current_section = "node"
            elseif startswith(l, "LINKS (")
                current_section = "link"
            elseif startswith(l, "META (")
                current_section = "meta"
            elseif startswith(l, "DEMANDS (")
                current_section = "demand"

            elseif startswith(l, ")")
                current_section = "none"
            else
                if current_section == "node"
                    push!(nodes, node_from_line(l))
                elseif current_section == "link"
                    push!(links, link_from_line(l))
                elseif current_section == "demand"
                    push!(demands, demand_from_line(l))
                elseif current_section == "meta"
                    l = strip(l)
                    md = split(l, " = ")
                    metadata[strip(md[1])] = strip(md[2])
                else
                end
            end
        else # comment line, may contain a description of the node, link, demand attributes
            if startswith(l, "# <node_id>")
                node_fields = parse_fields(l)[2:end]
            elseif startswith(l, "# <link_id>")
                link_fields = parse_fields(l)[2:end]
            elseif startswith(l, "# <demand_id>")
                demand_fields = parse_fields(l)[2:end]
            end
        end

    end
    close(f)
    return SNDNetwork(name, nodes, links, demands, metadata, node_fields, link_fields, demand_fields)
end


