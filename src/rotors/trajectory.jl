using JSON

include("../io/load_adj_matrix.jl")
include("./ActivatedGraphs.jl")
include("../misc/pyplot.jl")
include("./extend_area.jl")

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
stim_ids = (10,)

##

# folder_root = "/media/andrey/easystore/Rheeda/activation/"
folder_root = "/media/andrey/Samsung_T5/Rheeda/activation"

# i_heart = first(heart_ids)
i_group = first(group_ids)
i_stim = first(stim_ids)

triplet = "M$i_heart-G$i_group-S$(string(i_stim, pad = 2))"
filename = joinpath("../../data/rotors/jsons/", "$triplet.json")

wavebreaks = JSON.parsefile(filename)

rotors = wavebreaks["rotors"]
@info length(rotors)

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

rotor = rotors[1]
indices_rotor = convert.(Int, rotor["indices_points"])


##

indices_rotor_extended = extend_area(ag.graph, indices_rotor, 2000.)
ag_rotor = ActivatedGraphs.induced_subgraph(ag, indices_rotor_extended)

##

# dense_graph(ag_rotor.graph, 1500.)

##
include("visit_breaks.jl")
_clear_graph(ag_rotor)

i = findmin(ag_rotor[:times])[2]
rotor_info = visit_breaks!(i, g=ag_rotor, dt_max=20.)

##

include("fill_rotor_arrays.jl")

ag_rotor[:is_available] = ag_rotor[:times] .> 2500.
summary_info = fill_rotor_arrays!(ag_rotor, 20.)

##

lifetime_max, i = findmax(x -> x[:lifetime_max], summary_info)
rotor_max = summary_info[i]

##

mask = ag_rotor[:roots] .== rotor_max[:index_times_start]
times_tree = ag_rotor[:times][mask]
vertex_ids_tree = map(i -> find_vertex_id(ag_rotor, i), findall(mask))
trajectory_tree = points[:, indices_rotor_extended[vertex_ids_tree]]

##

rotors_info = filter(
    x -> x[:lifetime_max] > 500.,
    summary_info
)

n_rotors = length(rotors_info)

##

# i_t_start = 243184
# sinfo = visit_breaks!(i_t_start, g = ag_rotor, dt_max = 20.)

# ##

# i = collect(values(rotors_info))[1][:index_times_finish]
# t_finish, i_max = findmax(
#     x -> ag_rotor[:times][x[:index_times_finish]],
#     summary_info, # rotors_info
# )


##

# i = rotor_info[:index_times_finish]
##

# i = findfirst(0 .< ag_rotor[:lifetime] .<= 2000.)

vertex_ids = ag_rotor.type_array[]
times = Float32[]

i = rotor_max[:index_times_finish]

while i ≠ -1
    v = find_vertex_id(ag_rotor, i)
    push!(vertex_ids, v)
    push!(times, ag_rotor[:times][i])
    i = ag_rotor[:parents][i]
end

##

vertex_ids_native = indices_rotor_extended[vertex_ids]
trajectory = points[:, vertex_ids_native]

##

points_subset = points[:, indices_rotor_extended]

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
plt.scatter(trajectory[1, :], trajectory[3, :], c = times, cmap = "rainbow")

##

ix, iy = 1, 3

plt.plot(
    trajectory[ix, :],
    trajectory[iy, :] .+ collect(1:length(times)),
    "-k",
    lw = 0.1
)

plt.scatter(
    trajectory[ix, :],
    trajectory[iy, :] .+ collect(1:length(times)),
    c=times,
    cmap="rainbow",
    s=4,
)


##

plt.plot(times_tree, transpose(trajectory_tree), ",")
plt.plot(times, transpose(trajectory), ".-")

##

mask = times .> 700.
ix, iy = 1, 2

# plt.plot(times[mask], trajectory[ix, mask])

plt.plot(times[mask], vertex_ids[mask], ".-")
plt.scatter(times[mask], vertex_ids[mask], c=vertex_ids[mask] .% 10, cmap="tab10")

plt.scatter(
    times[mask],
    vertex_ids[mask],
    c=vertex_ids[mask] .== mode(vertex_ids[mask]),
    cmap="tab10"
)

##

plt.plot(trajectory[ix, mask], trajectory[iy, mask], ".-")

dts = diff(times[mask])

plt.scatter(
    trajectory[ix, mask][1:end-1],
    trajectory[iy, mask][1:end-1],
    c=dts,# .> 0,
    cmap="RdBu",
    vmin=-maximum(abs.(dts)),
    vmax=maximum(abs.(dts))
)

# plt.plot(times[mask], trajectory[iy, mask])

##

function smoothen_trajectory(traj, times, n=100)
    rev = times[1] > times[end]
    indices_sort = sortperm(times; rev)
    times_sorted = times[indices_sort]
    traj_sorted = traj[:, indices_sort]

    traj_roll = transpose(hcat(rolling_mean.(eachrow(traj), n)...))
    times_roll = rolling_mean(times_sorted, n)

    return traj_roll, times_roll

end

##

X_smooth, T_smooth = smoothen_trajectory(trajectory, times, 10)
plt.plot(T_smooth, transpose(X_smooth), "-")
##

plt.plot(trajectory[ix, :], trajectory[iy, :], "-")
plt.plot(X_smooth[ix, :], X_smooth[iy, :], "-")

##

mask = vcat(true, (diff(times) .< 0)...)
plot(times[mask], transpose(trajectory)[mask, :])


##

function rolling_mean(x, n)
    rs = cumsum(x)[n:end] .- cumsum([0.0; x])[1:end-n]
    return rs ./ n
end

##

using FFTW
using DataInterpolations

tspace = first(times): last(times)
traj_interp = map(x -> LinearInterpolation(x, times).(tspace), eachrow(trajectory))
traj_smooth = map(x -> rolling_mean(x, 10), traj_interp)

tspace_smooth = rolling_mean(tspace, 10)
traj_smooth = transpose(hcat(traj_smooth...))
traj_interp = transpose(hcat(traj_interp...))

##

plot(tspace, traj_interp[1, :])
plot(times, trajectory[1, :])

plot(traj_interp[1, :], traj_interp[3, :], "-k", lw = 0.1)
plot(traj_smooth[1, :], traj_smooth[3, :], "-r", lw = 0.1)

##

spectra = abs.(rfft(traj_interp, 2)[:, 2:end])
sp = sum(eachrow(spectra))
fq = rfftfreq(size(traj_interp, 2))[2:end]

plot(fq, sp)
# plot(fq, spectra[2, :])
# plot(fq, spectra[3, :])

fq_max = fq[findmax(sp)[2]]  # 1 / ms
T_max = 1 / fq_max  # ms

##

indices_breaks = findall(ag_rotor[:conduction] .< 1)
times_breaks = ag_rotor[:times][indices_breaks]
vertex_ids = map(i -> find_vertex_id(ag_rotor, i), indices_breaks)

indices_sort = sortperm(times_breaks)
times_breaks = times_breaks[indices_sort]
vertex_ids = vertex_ids[indices_sort]

times = times_breaks

vertex_ids_native = indices_rotor[vertex_ids]
trajectory = points[:, vertex_ids_native]
