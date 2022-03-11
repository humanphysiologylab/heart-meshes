using DataStructures
include("gradient_descent_step.jl")
include("plotly_helpers.jl")

##

function terminate(cb, threshold = 1.)
    !isfull(cb) && return false
    n = capacity(cb)
    head = mean(cb[1: n ÷ 2])
    tail = mean(cb[n ÷ 2: end])
    return head - tail < threshold
end


function run_gradient_descent(
    i = nothing;
    t_start = 7500.,
    cb_capacity = 100,
    cb_threshold = 1e-3,
    step = -100
)

    index_tetrahedron = isnothing(i) ? rand(1:nv(mesh.graph_elements)) : i

    t = mesh.elements[index_tetrahedron, :]
    t_coords = get_tetra_points(mesh, index_tetrahedron)
    t_center = mean(t_coords, dims=1)[1, :]
    t_times = find_nearest_times(mesh, t, t_start)
    t_start = mean(t_times)

    cb = CircularBuffer{typeof(t_start)}(cb_capacity)

    rows = []

    t_next, p_next = t_start, t_center
    i_next = index_tetrahedron

    row = (t = t_next, x = p_next[1], y = p_next[2], z = p_next[3], i = i_next)
    push!(rows, row)

    while true
        t_next, p_next, i_next = gradient_descent_step(t_next, p_next, i_next, mesh; step)
        push!(cb, t_next)
        terminate(cb, cb_threshold) && break
        row = (t = t_next, x = p_next[1], y = p_next[2], z = p_next[3], i = i_next)
        push!(rows, row)
    end

    df = DataFrame(rows)

end

##

dfs = [run_gradient_descent() for _ in 1: 20]

# df = df[end-50:end, :]
# df = df[1 : 1000, :]

##

traces = create_trajectories_traces(dfs)
trace_bg = create_heart_trace(mesh[:points])

##

plot([[t for t in traces]..., trace_bg])

##

filename_csv_old = "/Volumes/Samsung_T5/HPL/rheeda/data/rotor-trajectory-feb22/M13-G1-S13-0.csv"
df_old = DataFrame(CSV.File(filename_csv_old))

trace_old = create_trajectories_traces([df_old])[1]

##

plot([[t for t in traces]..., trace_bg, trace_old])
