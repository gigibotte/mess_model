module ProcessYaml

export create_system

using CSV, YAML, DataFrames, Main.SystemStructMess, Main.Exceptions
using Main.Dirs: path

"""
    get_locations_links(input_loc::Dict)

Given a dictionary generated by reading the file locations.yaml, it generates two
dictionaries one only with the locations and one with the information on the links between locations.
"""
function get_locations_links(input_loc::Dict)
    locations = Dict()
    links = Dict()
    for i in keys(input_loc)
        if i == "locations"
            locations = input_loc[i]
            #return locations
        elseif i == "links"
            links = input_loc[i]
            #return links
        else
            throw(WrongInputLevel("One of the level is neither a locations nor a links"))
            break
        end
    end
    return locations, links
end

"""
    get_coordinates(coord::Dict)

Given a dictionary of coordinates:
"coordinates"    => Dict{Any,Any}("x"=>5,"y"=>3)

it return a struct Coordinates with fields lat and long
"""
function get_coordinates(coord::Dict)
    latitude = 0.0
    longitude = 0.0
    for i in keys(coord)
        if i == "x"
            latitude = coord[i]
        elseif i == "y"
            longitude = coord[i]
        else
            throw(WrongCoordinate("Wrong Coordinate declaration"))
            break
        end
    end
    location_coordinates = Coordinates(latitude,longitude)
    return location_coordinates
end

"""
    get_techs_techgroups(input_loc::Dict)

Given a dictionary obtained from the techs.yaml file it returns two dictionaries:
one representing the technologies and one the technologies group.

"""
function get_techs_techgroups(input_loc::Dict)
    techs = Dict()
    techgroups = Dict()
    for i in keys(input_loc)
        if i == "techs"
            techs = input_loc[i]
            #return locations
        elseif i == "tech_groups"
            techgroups = input_loc[i]
            #return links
        else
            throw(WrongInputLevel("One of the level is neither a tech nor a tech group"))
            break
        end
    end
    return techs, techgroups
end

"""
    get_essentials(essential::Dict)

Given a dictionary representing the essentials of a technology it generates the struct
Essential with the entries available. If a value is not defined it will have the default
`missing` attribute.

"""
function get_essentials(essential::Dict)
    essentials = Essential()
    for i in keys(essential)
        if Symbol(i) in fieldnames(Essential)
            setproperty!(essentials,Symbol(i),essential[i])
        else
            throw(WrongEssentialLevel("Wrong essential name declared"))
        end
    end
    return essentials
end

"""
    process_timeserie(name)

Given a string containing the filename it extrapolate the respective dataframe in the timeseries folder
"""
function process_timeseries(name)
        filename = split(name,"=")[2]
        timeseries_df = CSV.read(joinpath(path, "..", "data","timeseries_data",filename),DataFrame)
    return timeseries_df
end

"""
    process_timeserie(name)

Given a string containing the filename the parent of teh technology in exam and the location in exam
it extrapolate the respective dataframe in the timeseries folder.
Used when checking locations constraints.
"""
function process_timeseries_location(name,parent,location)
    if parent != "demand"
        filename = split(name,"=")[2]
        timeseries_df = CSV.read(joinpath(path, "..", "data","timeseries_data",filename),DataFrame)
    else
        filename = split(name,"=")[2]
        timeseries_df = CSV.read(joinpath(path, "..", "data","timeseries_data",filename),DataFrame)
        timeseries_df = timeseries_df[!,Symbol(location)]
    end
    return timeseries_df
end

"""
    get_constraints(constraint::Dict,parentname)

Given a dictionary representing the constraints of a technology and a string representin the parent type
of that technology it generates the equivalent `Constraint_parentname` struct based on available entries.
If a value is not defined it will have the default `missing` attribute.

"""
function get_constraints(constraint::Dict,parentname)
    struct_name = "Constraint_"*parentname
    trial = getfield(Main,Symbol(struct_name))()
    carrier = Carrier_ratios()
    for i in keys(constraint)
        if Symbol(i) in fieldnames(typeof(trial))
            if typeof(constraint[i])== String
                if occursin("file=",constraint[i])
                    setproperty!(trial,Symbol(i),process_timeseries(constraint[i]))
                else
                    setproperty!(trial,Symbol(i),constraint[i])
                end
            else
                setproperty!(trial,Symbol(i),constraint[i])
            end
        elseif occursin(".",i)
            if count(k->(k=='.'), i) == 1
                splitted_string = split(i,".")
                if Symbol(splitted_string[1]) in fieldnames(typeof(trial))
                    if splitted_string[1] == "carrier_ratios"
                        setproperty!(carrier,Symbol(splitted_string[2]),constraint[i])
                        setproperty!(trial,Symbol(splitted_string[1]),carrier)
                    else
                        field = splitted_string[2]*" = "*constraint[i]
                        setproperty!(trial,Symbol(splitted_string[1]),field)
                    end
                else
                    throw(WrongConstraint("Wrong constraint name of a ",parentname, " technology declared"))
                end
            else
                throw(WrongConstraint("Wrong constraint name of a ",name, " technology declared"))
            end
        else
            throw(WrongConstraint("Wrong constraint name of a ",name, " technology declared"))
        end
    end
    return trial
end
    
"""
    get_monetary(cost::Dict,parentname)

Given a dictionary representing the monetary costs of a technology and a string representin the parent type
of that technology it generates the equivalent `Monetary_parentname` struct based on available entries.
If a value is not defined it will have the default `missing` attribute.

"""
function get_monetary(cost::Dict,parentname)
    struct_name = "Monetary_"*parentname
    costs = getfield(Main,Symbol(struct_name))()
    for i in keys(cost)
        if Symbol(i) in fieldnames(typeof(costs))
            if typeof(cost[i])== String
                if occursin("file=",cost[i])
                    setproperty!(costs,Symbol(i),process_timeseries(cost[i]))
                else
                    setproperty!(costs,Symbol(i),cost[i])
                end
            else
                setproperty!(costs,Symbol(i),cost[i])
            end
        elseif occursin(".",i)
            if count(k->(k=='.'), i) == 1
                splitted_string = split(i,".")
                if Symbol(splitted_string[1]) in fieldnames(typeof(costs))
                    field = splitted_string[2]*" = "*cost[i]
                    setproperty!(costs,Symbol(splitted_string[1]),field)
                else
                    throw(WrongCost("Wrong costs name of a ",parentname, " technology declared"))
                    break
                end
            elseif count(k->(k=='.'), i) == 2
                splitted_string = split(i,".")
                if Symbol(splitted_string[1]) in fieldnames(typeof(costs))
                    field = splitted_string[2]*" "*splitted_string[3]*"="*string(cost[i])
                    setproperty!(costs,Symbol(splitted_string[1]),field)
                else
                    throw(WrongCost("Wrong costs name of a ",parentname,"  technology declared"))
                    break
                end
            end
        elseif i == "export"
            if occursin("file=",cost[i])
                costs.export_ = process_timeseries(cost[i])
            else
                costs.export_ = cost[i]
            end
        else
            throw(WrongCost("Wrong costs name of a ",name, "technology plus declared"))
        end
    end
    return costs
end

"""
    get_costs(cost::Dict,parent)

Given a dictionary representing the costs of a technology and a string representin the parent type
of that technology it generates the respective Costs struct by calling the get_monetary() and get_emissions() functions.
If a value is not defined it will have the default `missing` attribute.

"""
function get_costs(cost::Dict,parent)
    costs = Costs()
    for i in keys(cost)
        if i == "monetary"
            costs.monetary = get_monetary(cost[i],parent)
        elseif i == "emissions"
            #get_emissions not yet defined
            costs.emissions = get_emissions(cost[i],parent)
        else
            throw(WrongInputLevel("Wrong costs name defined"))
            break
        end
    end
    return costs
end

"""
    create_struct_tech(techs::Dict)

Given a dictionary representing the technologies and generated by the get_techs_techgroups() function
it generates a Vector of structs Tech with all the technologies available.
The struct will have a name, a struct Essential, a struct Constraints_parentname and a struct Costs.

"""
function create_struct_tech(techs::Dict)
    x = length(keys(techs))
    technologies = Array{Tech,1}(undef,x)
    j=1
    parents = ["supply","supply_plus","demand","storage","transmission","conversion","conversion_plus","supply_grid"]
    for i in keys(techs)
        t = techs[i]
        ess = get_essentials(t["essentials"])
        if ess.parent in parents
            if ess.parent == "demand"
                if haskey(t,"constraints")
                    technologies[j] = Tech(i, ess, get_constraints(t["constraints"],ess.parent),get_costs(t["costs"],ess.parent),t["priority"])
                else
                    cost_demand = Costs(Monetary_demand(),0)
                    constraint_demand = Constraint_demand()
                    technologies[j] = Tech(i, ess,constraint_demand,cost_demand,t["priority"])
                end
            else
                technologies[j] = Tech(i, ess, get_constraints(t["constraints"],ess.parent),get_costs(t["costs"],ess.parent),t["priority"])
            end
        else
            throw(WrongInputLevel("One of the technology has a wrong parent"))
            break
        end
        j+=1
    end
    return technologies
end


"""
    create_arrays_tech(dic_tech::Dict,technologies)

Given a dictionary representing the technologies available in one location, a
vector of struct Tech representing all the possible technologies and the location in exam,
it returns an array of struct Tech representing the technologies available in one location.


"""
function create_arrays_tech(dic_tech::Dict,technologies,loc)
    x = length(keys(dic_tech))
    loc_techs = Array{Tech,1}(undef,x)
    techno = deepcopy(technologies)
    j = 1
    for i in keys(dic_tech)
        for k in 1:length(techno)
            if techno[k].name == i
                if typeof(dic_tech[i]) != Nothing
                    new_dict = convert_to_dict(dic_tech[i])
                    updated_tech = check_locations_constraints(new_dict,techno[k],loc)
                    loc_techs[j] = updated_tech
                else
                    loc_techs[j] = techno[k]
                end
            end
        end
        j +=1
    end
    return loc_techs
end

"""
    check_locations_constraints(dict_tech::Dict,tech::Tech,loc)

Given a dictionary representing a technology, the respective Tech struct and the location under exam
it checks the locations constraints and add them to an updated Tech struct.

"""
function check_locations_constraints(dict_tech::Dict,tech::Tech,loc)
    #remember to deepcopy the tech and return the copied one
    update_tech = deepcopy(tech)
    for i in keys(dict_tech)
        field_dict = dict_tech[i]
        if i == "constraints"
            for j in keys(field_dict)
                if typeof(field_dict[j]) == String
                    if occursin("file=",field_dict[j])
                        setproperty!(update_tech.constraints,Symbol(j),process_timeseries_location(field_dict[j],update_tech.essentials.parent,loc))
                    end
                else
                    setproperty!(update_tech.constraints,Symbol(j),field_dict[j])
                end
            end
        elseif i == "costs"
            for j in keys(field_dict)
                field_dict_second_level = field_dict[j]
                if j == "monetary"
                    for k in keys(field_dict_second_level)
                            if typeof(field_dict[j]) == String
                                if occursin("file=",field_dict_second_level[k])
                                    setproperty!(update_tech.costs.monetary,Symbol(k),process_timeseries_location(field_dict[j],update_tech.essentials.parent,loc))
                                end
                            else
                                if k == "export"
                                    k1 = "export_"
                                    setproperty!(update_tech.costs.monetary,Symbol(k1),field_dict_second_level[k])
                                else
                                    setproperty!(update_tech.costs.monetary,Symbol(k),field_dict_second_level[k])
                                end

                            end
                    end
                end
            end
        end
    end
    return update_tech

end

"""
    convert_to_dict(dict_tech::Dict)

Given a dictionary with the . notation coming from the locations.yaml file, it returns a classic dictionary
with no . notation.
"""
function convert_to_dict(dict_tech::Dict)
    full_dict = Dict()
    for i in keys(dict_tech)
        if count(k->(k=='.'), i) == 1
            split_key = split(i,".")
            partial_dict = Dict(split_key[2] => dict_tech[i])
            full_dict[split_key[1]] = partial_dict
        elseif count(k->(k=='.'),i) == 2
            split_key = split(i,".")
            partial_dict_1 = Dict(split_key[3] => dict_tech[i])
            partial_dict = Dict(split_key[2] => partial_dict_1)
            full_dict[split_key[1]] = partial_dict
        else
            full_dict[i] =  dict_tech[i]
        end
    end
    return full_dict
end
"""
    get_struct_location(locs::Dict)

Given a dictionary of locations it returns an array of structs Location.
each Locations will be characterized by a name, an Array of struct Tech representing
the technologies available in that location, the area and a struct Coordinates representing
the coordinates for that location.

"""
function get_struct_location(locs::Dict,technologies)
    techno = deepcopy(technologies)
    x = length(keys(locs))
    locations = Array{Location,1}(undef,x)
    j=1
    for i in keys(locs)
        single_loc = locs[i]
        if haskey(single_loc, "coordinates")
            coord = get_coordinates(single_loc["coordinates"])
        else
            coord = Coordinates(0,0)
        end
        if haskey(single_loc,"techs")
            loc_techs = create_arrays_tech(single_loc["techs"],techno,i)
            sort!(loc_techs, by = Tech -> Tech.priority)
        else
            loc_techs = 0
        end
        if  haskey(single_loc, "available_area")
            locations[j] = Location(i,loc_techs,single_loc["available_area"],coord)
        else
            locations[j] = Location(i,loc_techs,0,coord)
        end
        j +=1
    end
    sort!(locations, by = Location -> Location.name)
    return locations
end


"""
    create_system(name::String)

Given the name of the system and by calling the functions get_locations_links(),
get_techs_techgroups(), create_struct_tech() and get_struct_location()
it generates a System struct representing the whole energy system
"""
function create_system(name::String,techs::String)
    preliminary_locations = YAML.load(open(joinpath(path, "..", "data", "data_mess", "locations.yaml")))
    preliminary_technologies = YAML.load(open(joinpath(path, "..", "data", "data_mess", "$techs.yaml")))

    locations, links= get_locations_links(preliminary_locations)
    techs, techgroups = get_techs_techgroups(preliminary_technologies)
    tech_res = create_struct_tech(techs)

    system_struct = System(name,get_struct_location(locations,tech_res))
    return system_struct,techs
end

end
