include("../io/load_adj_matrix.jl")
include("../rotors/ActivatedGraphs.jl")
include("../misc/pyplot.jl")
include("../misc/load_things.jl")
include("../conduction/collect_counts_n_sums.jl")

using Graphs
using StatsBase
using .ActivatedGraphs
# using .ActivatedGraphs: find_vertex_id  # this is not exported

##

i_heart = 13
adj_matrix = load_adj_matrix("/media/andrey/ssd2/WORK/HPL/Data/rheeda/M$i_heart/adj_matrix", false)
points = read_binary(
    "/media/andrey/ssd2/WORK/HPL/Data/rheeda/M$i_heart/M$(i_heart)_IRC_3Dpoints.float32",
    Float32,
    (3, :),
)

##
i_heart = 13
i_group = 1
i_stim = 0

ag = load_activated_graph((i_heart, i_group, i_stim))
# ag.scalars[:points] = load_points(i_heart)
##

function find_indices_breaks(ag, conduction_threshold = 1)

    ag[:conduction][ag.stops] .= 1

    conduction_percent_sum, conduction_percent_count =
        collect_counts_n_sums(ag[:conduction], ag.starts, ag.stops)

    mask_nonzeros = .!iszero.(conduction_percent_count)

    conduction_percent_mean = zeros(size(conduction_percent_sum))
    conduction_percent_mean[mask_nonzeros] =
        conduction_percent_sum[mask_nonzeros] ./ conduction_percent_count[mask_nonzeros]

    indices_breaks = findall(conduction_percent_mean .< conduction_threshold)

end

##

indices_breaks = find_indices_breaks(ag)
ag_breaks = ActivatedGraphs.induced_subgraph(ag, indices_breaks)
cc = connected_components(ag_breaks.graph)
cc = sort(cc, by=length, rev=true)

##

dt_max_array = fill(NaN, length(cc))
lifetime_array = fill(NaN, length(cc))
CL_array = deepcopy(dt_max_array)

t_onset = 3000
t_terminate_min = 7450
len_times_min = 10

for (i, component) in enumerate(cc)

    times = map(component) do i
        ts = get_vertex_vector(ag_breaks, i, :times)
        ts = ts[searchsortedfirst(ts .> t_onset, true) : end]
    end

    times = vcat(times...)
    (length(times) < len_times_min) && continue

    dtimes = diff(times)
    CL = mode(dtimes[0 .< dtimes .< 1000])
    CL_array[i] = CL

    times = sort(times)
    # (last(times) < t_terminate_min) && continue
    
    # index_onset = findfirst(times .> t_onset)
    # isnothing(index_onset) && continue
    # times = times[index_onset: end]

    dt_max = maximum(diff(times))
    dt_max_array[i] = dt_max

    lifetime = last(times) - first(times)
    lifetime_array[i] = lifetime
end

##

dt_max_min = dt_max_array[dt_max_array .|> isnan .|> !] |> minimum
mask_rotor = (dt_max_array .< 50) .&& (lifetime_array .> 1000)
sum(mask_rotor)

##
plot(dt_max_array[mask_rotor], CL_array[mask_rotor], "o")
plot(dt_max_array, CL_array, ".")

##

plot(dt_max_array[mask_rotor], lifetime_array[mask_rotor], "o")
plot(dt_max_array, lifetime_array, ".")


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
