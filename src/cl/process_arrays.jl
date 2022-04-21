using Graphs

include("process_component.jl")


function process_arrays(
    heart::Integer,
    group::Integer,
    stim::Integer;
    graph::SimpleGraph,
    folder_rheeda=folder_rheeda,
    component_length_min = 100
)

    a = load_arrays(heart, group, stim; folder_rheeda)

    c_mean = reduce(a, :conduction, op_reduce)
    indices_breaks = findall(c_mean .< 1.)
    cc = connected_components(graph[indices_breaks])
    cc = sort(cc, by=length, rev=true)
    cc = [indices_breaks[c] for c in cc]

    rows = []
    for (i, component) in enumerate(cc)
        length(component) < component_length_min && continue
        rows_component = process_component(component, a, dt_max=50.)
        isnothing(rows_component) && continue
        for row in rows_component
            row[:heart] = heart
            row[:group] = group
            row[:stim] = stim
            row[:component_id] = i
            row[:thread_id] = threadid()
        end
        append!(rows, rows_component)
    end

    rows

end
