include("../rotors/ActivatedGraphs.jl")
include("../misc/load_things.jl")
include("../rotors/extend_area.jl")

using JSON3
using DataFrames, CSV
using UnicodePlots

using .ActivatedGraphs

include("find_trajectory.jl")

##

i_heart = 15
i_group = 4
i_stim = 13

##

ag = load_activated_graph((i_heart, i_group, i_stim))
ag.scalars[:points] = load_points(i_heart)

##

rotor_id = 0
folder_jsons = "../../data/rotor_CL_cc/"
filename_tag = "M$i_heart-G$i_group-S$(string(i_stim, pad = 2))-$rotor_id"
filename_load_full = joinpath(folder_jsons, filename_tag * ".json")

rotor = JSON3.read(read(filename_load_full, String))

vertex_ids = rotor[:vertices]

##

vertices_unique = unique(vertex_ids)
indices_area = extend_area(ag.graph, vertices_unique, 1e3)

##

i = indices_area[findmax(ag[:times][indices_area])[2]]
trajectory = find_trajectory(i, g=ag, ∇t_max=0.1)
vertices = [find_vertex_id(ag, i) for i in trajectory]
X = ag[:points][vertices, :]

##

lineplot(X[:, 1], X[:, 3])

##

times = ag[:times][trajectory]

result = Dict(zip(["x", "y", "z"], eachcol(X)))
result["t"] = times
result["v"] = vertices
result["i_t"] = trajectory

##

df = DataFrame(result)
folder_save = "/home/andrey/WORK/HPL/projects/rheeda/publication/data/rotor-trajectory-feb22"
filename_save = joinpath(folder_save, filename_tag * ".csv")
CSV.write(filename_save, df)


##


hearts_ids = (13,)
group_ids = 1: 4
stim_ids = 0: 39

folder_heart = "/media/andrey/ssd2/WORK/HPL/Data/rheeda/"

folder_save = "/home/andrey/WORK/HPL/projects/rheeda/publication/data/rotor_CL_cc"

for i_heart in hearts_ids

    folder_adj_matrix = joinpath(folder_heart, "M$i_heart", "adj_matrix")
    adj_matrix = load_adj_matrix(folder_adj_matrix)

    for i_group in group_ids, i_stim in stim_ids

        rotor_id = 0
        folder_jsons = "../../data/rotor_CL_cc/"
        filename_tag = "M$i_heart-G$i_group-S$(string(i_stim, pad = 2))-$rotor_id"
        filename_load_full = joinpath(folder_jsons, filename_tag * ".json")

        rotor = JSON3.read(read(filename_load_full, String))

        vertex_ids = rotor[:vertices]

        @show i_heart, i_group, i_stim

        try
            ag = load_activated_graph((i_heart, i_group, i_stim); adj_matrix)
        catch e
            @warn "loading failed"
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
