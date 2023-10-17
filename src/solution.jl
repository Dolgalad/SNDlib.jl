"""Exception for badly formated network files
"""
struct BadSNDSolutionFile <: Exception end

"""Check if a SNDlib solution file is valid
"""
function is_valid_solution_file(filename::String; version="1.0", format="native")
    f = open(filename, "r")
    first_line = readline(f)
    close(f)
    return first_line == "?SNDlib $format format; type: solution; version: $version"
end

struct SNDLinkConfiguration
    link_id
    data
end

function link_configuration_from_line(line::String)
    line_data = split(strip(line), " ")
    line_data = filter(e->e!="(" && e!=")", line_data)
    if length(line_data)>1
        return SNDLinkConfiguration(line_data[1], map(e->parse(Float64, e), line_data[2:end]))
    else
        return SNDLinkConfiguration(line_data[1], [])
    end
end

struct SNDSolution
    link_configurations
    link_configuration_fields
end

function get_link_configuration(solution::SNDSolution, link_id::String)
    for i in 1:length(solution.link_configurations)
        if solution.link_configurations[i].link_id == link_id
            return solution.link_configurations[i]
        end
    end
    return SNDLinkConfiguration(link_id, [])
end

function parse_fields(line::String)
    fields = remove_special_characters(line)
    fields = replace(fields, "  "=>" ")
    return split(fields, " ")
end

function load_solution(filename::String)
    if !is_valid_solution_file(filename)
        throw(BadSNDSolutionFile("File $filename is not a valid SND solution file."))
    end

    f = open(filename,"r")
    line_num = 0
    current_section = "none" # can take values in node, link, meta, demand, none
    name = splitext(basename(filename))[1]
    link_configurations, link_configuration_fields = [], []
    links, link_fields = [], []
    demands, demand_fields = [], []
    metadata = Dict()
    while !eof(f)
        l = readline(f)
        line_num += 1
        # commented lines start with #
        if !startswith(l, "#")
            if startswith(l, "LINK-CONFIGURATIONS (")
                current_section = "link-configuration"
            elseif startswith(l, ")")
                current_section = "none"
            else
                if current_section == "link-configuration"
                    push!(link_configurations, link_configuration_from_line(l))
                else
                end
            end
        else # comment line, may contain a description of the node, link, demand attributes
            if startswith(l, "# <link_id>")
                link_configuration_fields = parse_fields(l)[2:end]
            end
        end

    end
    close(f)
    return SNDSolution(link_configurations, link_configuration_fields)
end
