include("../io/load_adj_matrix.jl")
include("../io/load_things.jl")
include("../io/load_arrays.jl")

include("../ActivatedGraphs/ActivatedGraphs.jl")
include("../ActArrays/ActArrays.jl")

include("process_component.jl")

using Graphs
using StatsBase
using Base.Iterators
using DataFrames

op_reduce(x) = takewhile(isfinite, x) |> mean

##

folder_rheeda = "/Volumes/samsung-T5/HPL/Rheeda/"

heart = 15
folder_adj_matrix = joinpath(folder_rheeda, "geometry", "M$heart", "adj-vertices")
A = load_adj_matrix(folder_adj_matrix)
a = load_arrays(heart, 1, 13; folder_rheeda)

##

c_mean = reduce(a, :conduction, op_reduce)
indices_breaks = findall(c_mean .< 1.)
g = SimpleGraph(A)
cc = connected_components(g[indices_breaks])
cc = sort(cc, by=length, rev=true)
cc = [indices_breaks[c] for c in cc]

##

rows = []
component_length_min = 100
for (i, component) in enumerate(cc)
    length(component) < component_length_min && continue
    rows_component = process_component(component, a, dt_max=50.)
    isnothing(rows_component) && continue
    for row in rows_component
        row[:component_id] = i
    end
    append!(rows, rows_component)
end
df = DataFrame(rows)


##
############################################
##

using JSON

t_onset = 3000
t_terminate_min = 7450
len_times_min = 10

hearts_ids = (15,)
group_ids = (3,)
stim_ids = (27,) # 0: 39

folder_heart = "/media/andrey/ssd2/WORK/HPL/Data/rheeda/"

folder_save = "/home/andrey/WORK/HPL/projects/rheeda/publication/data/rotor_CL_cc"

for i_heart in hearts_ids

    folder_adj_matrix = joinpath(folder_heart, "M$i_heart", "adj_matrix")
    adj_matrix = load_adj_matrix(folder_adj_matrix)

    for i_group in group_ids, i_stim in stim_ids

        @show i_heart, i_group, i_stim

        ag = nothing

        try
            ag = load_activated_graph((i_heart, i_group, i_stim); adj_matrix)
        catch e
            @warn "loading failed"
            continue
        end

        (maximum(ag[:times]) < t_terminate_min) && continue

        indices_breaks = find_indices_breaks(ag)
        ag_breaks = ActivatedGraphs.induced_subgraph(ag, indices_breaks)
        cc = connected_components(ag_breaks.graph)

        n_rotors_found = 0

        for (i_component, component) in enumerate(cc)

            times = map(component) do i
                ts = get_vertex_vector(ag_breaks, i, :times)
                ts = ts[searchsortedfirst(ts .> t_onset, true) : end]
            end
        
            times = vcat(times...)
            (length(times) < len_times_min) && continue
        
            dtimes = diff(times)
            dtimes = dtimes[0 .< dtimes .< 1000]

            isempty(dtimes) && continue
            
            CL = mode(dtimes)
        
            times = sort(times)

            lifetime = last(times) - first(times)
            (lifetime < 1000) && continue

            dt_max = maximum(diff(times))
            (dt_max > 50) && continue
        
            # dt_max_array[i] = dt_max
            # lifetime_array[i] = lifetime
            # CL_array[i] = CL

            result = Dict(
                :heart => i_heart,
                :group => i_group,
                :stim => i_stim,
                :rotor => n_rotors_found,
                :dt_max => dt_max,
                :lifetime => lifetime,
                :CL => CL,
                :vertices => indices_breaks[component]
            )

            filename_stem = "M$i_heart-G$i_group-S$i_stim-$n_rotors_found.json"
            filename_save = joinpath(
                folder_save,
                filename_stem
            )
            write(filename_save, json(result))

            @show n_rotors_found += 1
            @show CL, lifetime, dt_max

        end

    end

end
