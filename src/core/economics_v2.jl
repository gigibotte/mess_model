module Economicsv2

export build_economic_solution

using Main.SystemStructMess

using Main.ModelConfiguration: timestep, timespan

using Main.Dirs: path

using DataFrames, CSV



function build_economic_solution(sys_results::System_results,sys::System,techs)
    # create a copy of the original System_results object
    economic_solution = deepcopy(sys_results)

    # loop through each Results_locations object and add the economic solution to it
    i=1
    for node in economic_solution.nodes
        print("Node result name is:",node.name, "\n")
        print("Node system name is:",sys.nodes[i].name, "\n")
        
        # add economic solution for electricity
        if !ismissing(node.df_el)
            node.df_el = get_economic_solution(node.df_el,sys.nodes[i],techs)
        end
        
        # add economic solution for thermal energy
        if !ismissing(node.df_th)
            node.df_th = get_economic_solution(node.df_th,sys.nodes[i],techs)
        end
        
        # add economic solution for gas
        if !ismissing(node.df_gas)
            node.df_gas = get_economic_solution(node.df_gas,sys.nodes[i],techs)
        end
        
        # add additional carriers economic solutions
        if !ismissing(node.additional_carriers)
            for carrier in node.additional_carriers
                carrier = get_economic_solution(carrier,sys.nodes[i],techs)
            end
        end
        i+=1
    end

    #add economic solution for the network
    economic_solution.network = get_economic_solution_network(economic_solution.network,techs)

    return economic_solution
end


function get_economic_solution(df,sys_node,techs)

    for col in names(df)
        for tech in sys_node.techs
            if col == tech.name
                if tech.essentials.parent == "conversion" || tech.essentials.parent == "supply" || tech.essentials.parent == "supply_grid"
                    if isa(tech.costs.monetary.om_con,DataFrame)
                        df_price = tech.costs.monetary.om_con
                        df[!,col] = df[!,col] .* convert.(eltype(df[!,col]), df_price[!,"Prices"])
                    else
                        om_cost = tech.costs.monetary.om_con
                        df[!,col] = df[!,col] * om_cost 
                    end
                elseif tech.essentials.parent == "conversion_plus"    
                    if isa(tech.costs.monetary.om_prod,DataFrame)
                        df_price = tech.costs.monetary.om_con
                        df[!,col] = df[!,col] .* convert.(eltype(df[!,col]), df_price[!,"Prices"])
                    else
                        om_cost = tech.costs.monetary.om_prod
                        df[!,col] = df[!,col] * om_cost 
                    end
                elseif tech.essentials.parent == "demand"
                    om_cost = 0  
                    df[!,col] = df[!,col] * om_cost 
                end   
                   
            end
           
        end
    end
    
    return df

end

function get_economic_solution_network(net::Results_networks, techs::Dict{Any, Any})
  
    for col in names(net.df_el)
        if col == "supply_grid"
            net.df_el[!,col] = net.df_el[!,col] * techs["supply_grid_power"]["costs"]["monetary"]["om_con"]
        else
        end
    end
    
   
    return net
end





end