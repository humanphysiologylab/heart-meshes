include("../io/load_adj_matrix.jl")
include("../rotors/ActivatedGraphs.jl")
include("../misc/pyplot.jl")

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

group_ids = (1,)
stim_ids = (16,)

##

# folder_root = "/media/andrey/easystore/Rheeda/activation/"
folder_root = "/media/andrey/Samsung_T5/Rheeda/activation"

# i_heart = first(heart_ids)
i_group = first(group_ids)
i_stim = first(stim_ids)

triplet = "M$i_heart-G$i_group-S$(string(i_stim, pad = 2))"

folder_data = joinpath(folder_root, "data-light", replace(triplet, '-' => '/'))
folder_results = joinpath(folder_root, "results", replace(triplet, '-' => '/'))

filename_times = joinpath(folder_data, "times.float32")
filename_starts = joinpath(folder_data, "indices_start.int32")
filename_conduction = joinpath(folder_results, "conduction.float32")

##

starts = read_binary(filename_starts, Int32)
times = read_binary(filename_times, Float32)
conduction = read_binary(filename_conduction, Float32)

##

ag = ActivatedGraph(adj_matrix, starts, Dict(:times => times, :conduction => conduction))

##

## 216203

using LinearAlgebra: norm

# indices_1 = [217946, 168853]
# indices_2 = [161602, 213853]

indices_1 = [217946, 927893]
indices_2 = [881202, 213853]

indices_1 = [1207210, 1173320]
indices_2 = [883656, 1182930]


times_1 = map(i -> get_vertex_array(ag, i, :times)[1], indices_1)
times_2 = map(i -> get_vertex_array(ag, i, :times)[1], indices_2)

dt_1 = times_1 |> diff |> first |> abs
dt_2 = times_2 |> diff |> first |> abs

coords_1 = points[:, indices_1]
coords_2 = points[:, indices_2]

dist_1 = norm(diff(coords_1, dims=2))
dist_2 = norm(diff(coords_2, dims=2))

cv_1 = (dist_1 / 1000 / 10) / (dt_1 / 1000)
cv_2 = (dist_2 / 1000 / 10) / (dt_2 / 1000)
