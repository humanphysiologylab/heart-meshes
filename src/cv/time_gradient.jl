include("../io/load_adj_matrix.jl")
include("../rotors/ActivatedGraphs.jl")
# include("../misc/pyplot.jl")
include("../misc/load_things.jl")
include("../rotors/extend_area.jl")
include("calculate_time_gradient.jl")


using SparseArrays
using LinearAlgebra
using Graphs
using JSON3
using DataFrames, CSV
using StatsBase
using UnicodePlots

using .ActivatedGraphs
# using .ActivatedGraphs: find_vertex_id  # this is not exported

##
i_heart = 13
i_group = 2
i_stim = 38

##
i_heart = 13
i_group = 1
i_stim = 13

##

ag = load_activated_graph((i_heart, i_group, i_stim))
ag.scalars[:points] = load_points(i_heart)

##

triplet_string = "M$i_heart-G$i_group-S$(string(i_stim, pad = 2))"
filename = joinpath("../../data/rotors/trajectories/", "$triplet_string.json")

rotors = JSON3.read(read(filename, String))
rotor = rotors[1]

times_ids = rotor["times_ids"]
vertex_ids = rotor["vertex_ids"]

##

vertices_unique = unique(vertex_ids)
indices_area = extend_area(ag.graph, vertices_unique, 1e3)
# is_border = find_border(ag.graph, indices_area)

##

include("find_trajectory.jl")

i = indices_area[findmax(ag[:times][indices_area])[2]]
trajectory = find_trajectory(i, g=ag, ∇t_max=0.1)
vertices = [find_vertex_id(ag, i) for i in trajectory]
X = ag[:points][vertices, :]

lineplot(X[:, 1], X[:, 3])

##

times = ag[:times][trajectory]

result = Dict(zip(["x", "y", "z"], eachcol(X)))
result["t"] = times
result["v"] = vertices
result["i_t"] = trajectory

##

df = DataFrame(result)
filename_save = "/home/andrey/WORK/HPL/projects/rheeda/publication/data/rotor-trajectory-feb22/latest.csv"
CSV.write(filename_save, df)

##

# vertices_unique = unique(vertex_ids)
# indices_area = extend_area(ag.graph, vertices_unique[1:10], 1e4)

##

ag_rotor = ActivatedGraphs.induced_subgraph(ag, indices_area)

##

# ag_rotor[:is_available] = 6000 .< ag_rotor[:times] .< Inf
# indices_available = findall(reduce(ag_rotor, :is_available) .> 0)
# ag_rotor = ActivatedGraphs.induced_subgraph(ag_rotor, indices_available)


##

i = findmax(ag_rotor[:times])[2]
trajectory = find_trajectory(i, g=ag_rotor, ∇t_max=0.1)
vertices = [find_vertex_id(ag_rotor, i) for i in trajectory]
X = ag_rotor[:points][vertices, :]

lineplot(X[:, 1], X[:, 3])

##

i = findmax(ag[:times][times_ids])[2]
trajectory = find_trajectory(i, g=ag, ∇t_max=0.1)
vertices = [find_vertex_id(ag, i) for i in trajectory]
X = ag[:points][vertices, :]

lineplot(X[:, 1], X[:, 3])

##

trace = scatter3d(;
    x=X[:, 1],
    y=X[:, 2],        
    z=X[:, 3],
    mode="lines",
    line_width=3,
    line_color="black",
    # line_color=cm[i_root % length(cm) + 1], # "black",
    showlegend=false
)
plot([trace_bg, trace])

##

trace = scatter3d(;
    x=X[:, 1],
    y=X[:, 3],        
    z=ag_rotor[:times][trajectory],
    mode="lines",
    line_width=3,
    # line_color="black",
    # line_color=cm[i_root % length(cm) + 1], # "black",
    showlegend=false
)
plot(trace)

##
include("./visit_breaks.jl")

ag_rotor[:is_available] = ag_rotor[:times] .> 7000.
indices_available = findall(ag_rotor[:is_available])
i = indices_available[findmin(ag_rotor[:times][indices_available])[2]]

##

# i = 42000

# i = findmin(ag_rotor[:points][:, 1])[2]
# i = get_vertex_vector(ag_rotor, i, :times)

_clear_graph(ag_rotor)
s = visit_breaks!(i, g=ag_rotor, dt_max=20.)

##
include("./visit_breaks.jl")

ag_rotor[:is_available] = ag_rotor[:times] .> 7000.
indices_available = findall(ag_rotor[:is_available])

i = indices_available[500]

_clear_graph(ag_rotor)
s = follow_∇t(i, g=ag_rotor, is_forward=false)

##

rotor_max = s
##

summary_info_list = fill_rotor_arrays!(ag_rotor)

## 

lifetime_max, i = findmax(x -> x[:lifetime_max], summary_info_list)
rotor_max = summary_info_list[i]

##

vertex_ids = ag_rotor.vectors_type[]
times = eltype(ag_rotor[:times])[]

# i = s[:index_times_finish]
i = rotor_max[:index_times_finish]

data = []

while i ≠ -1
    v = find_vertex_id(ag_rotor, i)
    t = ag_rotor[:times][i]
    push!(vertex_ids, v)
    push!(times, t)
    i = ag_rotor[:parents][i]

    # push!(
    #     data,
    #     Dict(
    #         :v => v,
    #         :t => t,
    #         :x => ag_rotor[:points][v, 1],
    #         :y => ag_rotor[:points][v, 2],
    #         :z => ag_rotor[:points][v, 3],
    #     )
    # )
end

reverse!(vertex_ids)
reverse!(times)

##

# df = DataFrame(data)
# CSV.write(
#     joinpath("../../data/", triplet_string * "_trajectory.csv"),
#     df
# )

##

X = ag_rotor[:points][vertex_ids, :]

# plot(ag_rotor[:points][:, 1], ag_rotor[:points][:, 2], ",")
# plot(X[:, 1], X[:, 2])

##

ix, iy = 1, 2

times_last = ag_rotor[:times][ag_rotor.stops]
mask = times .> quantile(times_last, 0.05)

scatter(
    ag_rotor[:points][:, ix],
    ag_rotor[:points][:, iy],
    c=times_last,
    vmin=quantile(times_last, 0.05),
    s=1
)

plot(X[:, ix], X[:, iy], lw=3, color="w")
plot(X[1, ix], X[1, iy], "or")

# plot(X[mask, ix], X[mask, iy], ".-", lw=1, color="r")

title(triplet_string)

##


for i in vertices(ag_rotor.graph)[1:10:end]
    ∇t_norm, CV_norm, ∇t_unit = calculate_time_gradient(i, ag_rotor, ag_rotor[:points]; dt_threshold=100.)
    x = ag_rotor[:points][i, ix]
    y = ag_rotor[:points][i, iy]

    scale = 1e2 * CV_norm
    plot(
        [x, x + scale * ∇t_unit[ix]],
        [y, y + scale * ∇t_unit[iy]],
        color="k",
        lw=0.25
    )

end

##

ix = 2
iy = 3

for i in vertex_ids
    ∇t_norm, CV_norm, ∇t_unit = calculate_time_gradient(i, ag_rotor, ag_rotor[:points]; dt_threshold=100.)
    x = ag_rotor[:points][i, ix]
    y = ag_rotor[:points][i, iy]

    scale = 1e2 * CV_norm
    plot(
        [x, x + scale * ∇t_unit[ix]],
        [y, y + scale * ∇t_unit[iy]],
        color="k",
        lw=0.25
    )

end

plot(X[1, ix], X[1, iy], "o", lw=1, color="r")
plot(X[:, ix], X[:, iy], ".-", lw=1, color="r")

##






##
ag.arrays[:∇_unit] = fill(fill(NaN, 3), ag.len_array)
ag.arrays[:∇t_norm] = fill(NaN, ag.len_array)
ag.arrays[:CV_norm] = fill(NaN, ag.len_array)

##
# t_start, index_start = findfirs(ag[:times])

# index_start = 42
indices_break = findall(ag[:conduction] .< 0.8)
index_start = indices_break[2302]

v = find_vertex_id(ag, index_start)
us = neighbors(ag, v)

##

using ProgressMeter

dt_threshold = 20.

@showprogress for v in vertices(ag.graph)

    us = neighbors(ag, v)
    dts = Vector(undef, length(us))
    dhs = [ag.graph.weights[v, u] for u in us]

    X = points[us, :]
    y = points[v, :]
    dX = X .- y'
    dX_norm = dhs  # norm.(eachrow(dX))

    U = hcat(map(dx -> dx ./ dX_norm, eachcol(dX))...)
    # ∇_matrix = Matrix{Float64}(undef, size(U))
        
    for v_t_i in ag.starts[v]: ag.stops[v]
        v_t = ag[:times][v_t_i]

        if v_t > 500
            continue
        end

        dts .= Inf
        for (u_i, u) in enumerate(us)
            u_times = get_vertex_array(ag, u, :times)
            for u_t in u_times
                dt = u_t - v_t
                if abs(dt) < abs(dts[u_i])
                    dts[u_i] = dt
                    # println(v, " ", u, " ", dt)
                    # break
                end
            end
        end

        # if any(abs.(dts) .> dt_threshold)
        #     println("found")
        #     break
        # end

        b = dts ./ dX_norm
        mask_threshold = @. abs(dts) < dt_threshold
        ∇t = U[mask_threshold, :] \ b[mask_threshold] # .* scaler

        ∇t_norm = norm(∇t)
        CV_norm = 1 / ∇t_norm / 10  # cm / s
        ∇t_unit = ∇t / ∇t_norm

        ag[:∇_unit][v_t_i] = ∇t_unit
        ag[:∇t_norm][v_t_i] = ∇t_norm
        ag[:CV_norm][v_t_i] = CV_norm

    end

    # break

end


##

data = map(
    v -> ActivatedGraphs.slice_arrays(ag, ag.starts[v]),
    vertices(ag.graph)
)

using DataFrames
using CSV

df = DataFrame(data)

CSV.write("../../data/CV_vtk_data.csv", df)


##
scaler = 1e4
ix = 1
iy = 2

mask_threshold = @. abs(dts) < dt_threshold
dt_abs_max = maximum(abs.(dts[mask_threshold]))

scatter(
    dX[mask_threshold, ix],
    dX[mask_threshold, iy],
    c=dts[mask_threshold],
    zorder=10,
    vmin=-dt_abs_max,
    vmax=dt_abs_max,
    cmap="RdBu_r",
    s=64
)

plot(
    dX[.!mask_threshold, ix],
    dX[.!mask_threshold, iy],
    "xk"
)

b = dts ./ dX_norm
∇t = U[mask_threshold, :] \ b[mask_threshold] .* scaler
@show CV = (scaler ./ norm(∇t) ./ 10)

plot([0, ∇t[ix]], [0, ∇t[iy]], c="k", ls="--", lw=2)

grid()

indices_valid = findall(mask_threshold)
for n in 3: length(indices_valid)
    ∇t = U[indices_valid[1:n], :] \ b[indices_valid[1:n]] .* scaler
    plot([0, ∇t[ix]], [0, ∇t[iy]], c="C$(n-3)", lw=0.5)
end


##

include("../cv/calculate_time_gradient.jl")
times_ids = rotor["times_ids"]
vertex_ids = rotor["vertex_ids"]

##

arrays = Dict(
    :∇t_norm => fill(NaN, length(times_ids)), 
    :CV_norm => fill(NaN, length(times_ids)), 
    # :∇t_unit => fill(fill(NaN, 3), length(times_ids)),
    :t => rotor["times"],
    :v => rotor["vertex_ids"]
)

for (i, key) in enumerate((:x, :y, :z))
    arrays[key] = fill(NaN, length(times_ids))
    arrays[Symbol("∇t_" * string(key))] = fill(NaN, length(times_ids))
end

for (i, (i_t, v)) in enumerate(zip(times_ids, rotor["vertex_ids"]))
    x = calculate_time_gradient(i_t, ag, points)
    arrays[:∇t_norm][i] = x[:∇t_norm]
    arrays[:CV_norm][i] = x[:CV_norm]

    arrays[:∇t_x][i] = x[:∇t_unit][1]
    arrays[:∇t_y][i] = x[:∇t_unit][2]
    arrays[:∇t_z][i] = x[:∇t_unit][3]

    for (j, key) in enumerate((:x, :y, :z))
        arrays[key][i] = points[v, j]
        
    end

end

##

df = DataFrame(arrays)
CSV.write(
    joinpath("../../data/", triplet * "_grad.csv"),
    df
)

##

times_last = map(
    i -> get_vertex_array(ag, i, :times) |> last,
    indices_area
)

##

times_last = ag_rotor[:times][ag_rotor.stops]
indices_area = vertices(ag_rotor.graph)

##

include("./calculate_time_gradient.jl")

data = Dict{Symbol, Number}[]

for (i, t) in zip(indices_area, times_last)
    x = Dict(
        :v => i,
        :t => t,
        :x => ag_rotor[:points][i, 1],
        :y => ag_rotor[:points][i, 2],
        :z => ag_rotor[:points][i, 3]
    )

    time_index = ag.stops[i]
    ∇t = calculate_time_gradient(time_index, ag_rotor, ag_rotor[:points]; dt_threshold=20.)
    x[:grad_x_unit] = ∇t[:∇t_unit][1]
    x[:grad_y_unit] = ∇t[:∇t_unit][2]
    x[:grad_z_unit] = ∇t[:∇t_unit][3]

    x[:grad_norm] = ∇t[:∇t_norm]

    push!(data, x)
end

##

df = DataFrame(data)
CSV.write(
    joinpath("../../data/", triplet * "_actmap.csv"),
    df
)
