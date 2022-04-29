using DataStructures  # CircularBuffer
using DataFrames
using StatsBase  # mean

include("gradient_descent_step.jl")
include("find_nearest_times.jl")

function terminate(cb, threshold = 1.)
    !isfull(cb) && return false
    n = capacity(cb)
    head = mean(cb[1: n ÷ 2])
    tail = mean(cb[n ÷ 2: end])
    return head - tail < threshold
end


function create_step_dict(i, t, p)

    letters = (:x, :y, :z)

    step_dict = Dict{Symbol, Real}(
        :i => i,
        :t => t,
    )

    p_dict = Dict{Symbol, Real}(
        zip(letters, p)
    )

    merge!(step_dict, p_dict)

    return step_dict

end


function run_gradient_descent(
    mesh,
    index_element = nothing,;
    time_start = 7500.,
    cb_capacity = 100,
    cb_threshold = 1e-3,
    step = -100,
    time_stop = nothing,
    strategy = :random
)

    n_elements = nv(mesh.graph_elements)

    if isnothing(index_element)
        index_element = rand(1:n_elements)
    end
    
    element = mesh.elements[index_element, :]
    element_coords = get_element_points(mesh, index_element)
    element_times = find_nearest_times(mesh, element, time_start)

    time_next = mean(element_times)
    p_next = mean(element_coords, dims=1)[1, :]

    cb = CircularBuffer{typeof(time_start)}(cb_capacity)

    rows = []
    row = create_step_dict(index_element, time_next, p_next)
    push!(rows, row)

    metainfo = Dict{Symbol, Any}()

    while true
        time_next, p_next, index_element = gradient_descent_step(time_next, p_next, index_element, mesh; step, strategy)
        push!(cb, time_next)
        if terminate(cb, cb_threshold)
            metainfo[:reason] = "CircularBuffer"
            metainfo[:time] = time_next
            break
        end

        row = create_step_dict(index_element, time_next, p_next)
        push!(rows, row)

        isnothing(time_stop) && continue
        if step * time_next > step * time_stop
            metainfo[:reason] = "time_stop"
            metainfo[:time] = time_next
            break
        end

    end

    DataFrame(rows), metainfo

end
