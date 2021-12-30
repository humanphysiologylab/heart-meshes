using JSON

include("../io/load_adj_matrix.jl")
include("./ActivatedGraphs.jl")

using .ActivatedGraphs

heart_ids = (13,)
group_ids = (2,)
stim_ids = (13,)

adj_matrices = Dict(
    i_heart =>
        load_adj_matrix("/media/andrey/ssd2/WORK/HPL/Data/rheeda/M$i_heart/adj_matrix")
    for i_heart in heart_ids
)

##

folder_root = "/media/andrey/easystore/Rheeda/activation/"

i_heart = first(heart_ids)
i_group = first(group_ids)
i_stim = first(stim_ids)

triplet = "M$i_heart-G$i_group-S$(string(i_stim, pad = 2))"
filename = joinpath("../../data/rotors/jsons/", "$triplet.json")

wavebreaks = JSON.parsefile(filename)

rotors = wavebreaks["rotors"]

folder_data = joinpath(folder_root, "data-light", replace(triplet, '-' => '/'))
folder_results = joinpath(folder_root, "results", replace(triplet, '-' => '/'))

filename_times = joinpath(folder_data, "times.float32")
filename_starts = joinpath(folder_data, "indices_start.int32")
filename_conduction = joinpath(folder_results, "conduction.float32")

##

adj_matrix = adj_matrices[13]
starts = read_binary(filename_starts, Int32)
times = read_binary(filename_times, Float32)
conduction = read_binary(filename_conduction, Float32)

##

ag = ActivatedGraph(adj_matrix, starts, Dict(:times => times, :conduction => conduction))

##

rotor = rotors[2]
indices_rotor = convert.(Int, rotor["indices_points"])

##

ag_rotor = induced_subgraph(ag, indices_rotor)

##

include("visit_breaks.jl")
n_visited = 1
mask_breaks = ag_rotor[:conduction] .< 1

ag_rotor[:parents] = zeros(ag_rotor.type_array, ag_rotor.len_array)
ag_rotor[:lifetime] = zeros(ag_rotor.len_array)

while true

    mask_discovered = ag_rotor[:parents] .== 0
    mask_available = mask_breaks .& mask_discovered

    !any(mask_available) && break

    indices = findall(mask_available)

    t_min, i_t_min = findmin(ag_rotor[:times][indices])
    i_t_min = convert(eltype(ag_rotor.starts), indices[i_t_min])

    n_visited = visit_breaks!(i_t_min, g = ag_rotor, dt_max = 5.0)

end

##

lifetime_max, i = findmax(ag_rotor[:lifetime])
# i = findfirst(0 .< ag_rotor[:lifetime] .<= 2000.)

vertex_ids = ag_rotor.type_array[]
times = Float32[]

while i ≠ -1
    v = find_vertex_id(ag_rotor, i)
    push!(vertex_ids, v)
    push!(times, ag_rotor[:times][i])
    i = ag_rotor[:parents][i]
end

indices_sort = sortperm(times)
times = times[indices_sort]
vertex_ids = vertex_ids[indices_sort]


##

vertex_ids_native = indices_rotor[vertex_ids]

##

points = read_binary(
    "/media/andrey/ssd2/WORK/HPL/Data/rheeda/M$i_heart/M13_IRC_3Dpoints.float32",
    Float32,
    (3, :),
)

trajectory = points[:, vertex_ids_native]

##

sum(sum(diff(trajectory, dims = 2) .^ 2, dims = 1) .^ 0.5) / 1000.0

##

include("../misc/pyplot.jl")


##

points_subset = points[:, indices_rotor]

plt.plot(
    points[1, 1:100:end],
    points[3, 1:100:end],
    ".",
    lw = 0.1,
    color = "lightblue",
    zorder = -10,
)
plt.plot(
    points_subset[1, :],
    points_subset[3, :],
    ".",
    lw = 0.1,
    color = "0.7",
    zorder = -10,
)

plt.plot(trajectory[1, :], trajectory[3, :], "-k", lw = 0.1)
plt.scatter(trajectory[1, :], trajectory[3, :], c = 1:size(trajectory, 2), cmap = "rainbow")

##

plt.plot(times, trajectory[1, :], ".-")
plt.plot(times, trajectory[2, :], ".-")
