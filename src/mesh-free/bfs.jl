using DataStructures

include("../ActArrays/ActArrays.jl")
include("../ActivatedGraphs/ActivatedGraphs.jl")
include("../ActivatedMeshes/ActivatedMeshes.jl")


function bfs(i::Integer, mesh::ActivatedMesh{T}, velocity_min=10.) where T
    bfs(i, mesh.arrays, mesh.graph_vertices, velocity_min)
end


function bfs(i::Integer, ag::ActivatedGraph{T}, velocity_min=10.) where T
    bfs(i, ag.a, ag.graph, velocity_min)
end


function bfs(i::Integer, a::ActArray{T}, graph, velocity_min=10.) where T
    # velocity = 10 um / ms = 1 cm / s

    i = T(i)

    q = Queue{T}()

    is_visited = falses(a.len)
    is_visited[i] = true
    enqueue!(q, i)

    metainfo = Dict{Symbol, Any}()

    metainfo[:n] = 1

    metainfo[:i_start] = i
    metainfo[:t_start] = a[:times][i]
    metainfo[:v_start] = get_major_index(a, i)

    metainfo[:i_max] = i
    metainfo[:t_max] = metainfo[:t_start]
    metainfo[:v_max] = metainfo[:v_start]

    metainfo[:i_min] = i
    metainfo[:t_min] = metainfo[:t_start]
    metainfo[:v_min] = metainfo[:v_start]

    result = nothing

    while !isempty(q)

        i = dequeue!(q)
        v = get_major_index(a, i)
        v_time = a[:times][i]

        if a[:conduction][i] == 1
            result = (v=v, i=i, time=v_time)
            break
        end

        for u in neighbors(graph, v)

            dist = graph.weights[v, u]
            u_start, u_stop = a.starts[u], a.stops[u]

            for j in u_start: u_stop

                is_visited[j] && continue

                u_time = a[:times][j]
                dt = abs(v_time - u_time)
                velocity = dist / dt

                velocity < velocity_min && continue

                enqueue!(q, j)
                is_visited[j] = true

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
    result, metainfo

end
