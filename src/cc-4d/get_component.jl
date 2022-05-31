using DataStructures

include("../ActArrays/ActArrays.jl")


function get_component(
    i::Integer,
    ag::ActivatedGraph{T},
    velocity_min=10.,
    component_id=nothing
) where T

    # velocity = 10 um / ms = 1 cm / s

    i = T(i)

    !ag[:is_wb][i] && error("no wb here")

    q = Queue{T}()
    ag[:is_visited][i] = true
    enqueue!(q, i)

    !isnothing(component_id) && (ag[:cc_id][i] = component_id)

    metainfo = Dict{Symbol, Any}()

    metainfo[:n] = 1

    metainfo[:i_start] = i
    metainfo[:t_start] = ag[:times][i]
    metainfo[:v_start] = get_major_index(ag, i)

    metainfo[:i_max] = i
    metainfo[:t_max] = metainfo[:t_start]
    metainfo[:v_max] = metainfo[:v_start]

    metainfo[:i_min] = i
    metainfo[:t_min] = metainfo[:t_start]
    metainfo[:v_min] = metainfo[:v_start]

    while !isempty(q)

        i = dequeue!(q)
        v = get_major_index(ag, i)
        v_time = ag[:times][i]

        !isnothing(component_id) && (ag[:cc_id][i] = component_id)

        for u in neighbors(ag, v)

            dist = ag.graph.weights[v, u]
            u_start, u_stop = ag.a.starts[u], ag.a.stops[u]

            for j in u_start: u_stop

                ag[:is_visited][j] && continue
                !ag[:is_wb][j] && continue

                u_time = ag[:times][j]
                dt = abs(v_time - u_time)
                velocity = dist / dt

                velocity < velocity_min && continue

                enqueue!(q, j)
                ag[:is_visited][j] = true

                metainfo[:n] += 1

                if u_time > metainfo[:t_max]
                    metainfo[:t_max] = u_time
                    metainfo[:i_max] = j
                    metainfo[:v_max] = u
                elseif u_time < metainfo[:t_min]
                    metainfo[:t_min] = u_time
                    metainfo[:i_min] = j
                    metainfo[:v_min] = u
                end
            end

        end

    end     

    metainfo[:lifetime] = metainfo[:t_max] - metainfo[:t_min]
    metainfo

end
