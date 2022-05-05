using ProgressMeter
using DataFrames

include("get_component.jl")


function get_components(ag; show_progress=false)

    rows = []
    ag[:is_visited] = falses(ag.a.len)
    ag[:is_wb] = ag[:conduction] .< 1
    ag[:cc_id] = zeros(Int32, ag.a.len)
    # ag[:is_wb] = @. (ag[:conduction] < 1) | isnan(ag[:conduction])

    prog = ProgressUnknown(;enabled=show_progress)

    component_id = 1

    while true

        available = @. !ag[:is_visited] & ag[:is_wb]
        i = findfirst(available)

        if isnothing(i)
            ProgressMeter.finish!(prog)
            break
        end

        row = get_component(i, ag, 10., component_id)

        row[:n] == 1 && continue

        row[:component_id] = component_id

        push!(rows, row)
        component_id += 1

        percent = sum(ag[:is_visited]) / sum(ag[:is_wb]) * 100
        percent = round(percent)
        ProgressMeter.next!(
            prog; 
            showvalues = [(:percent, percent)]
        )        

    end

    df = DataFrame(rows)
    sort(df, :lifetime, rev=true)

end
