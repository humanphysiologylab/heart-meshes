summary_info_sorted = sort(summary_info, by=x->x[:time_finish], rev=true)
summary_info_sorted = summary_info

# trees = []

for i_tree in 1: 100 # length(summary_info_sorted)

    s_info = summary_info_sorted[i_tree]

    # s_info[:n_visited] < 100 && continue
    # s_info[:time_finish] < 6500 && continue

    mask = ag_rotor[:roots] .== s_info[:index_times_start]
    indices = findall(mask)
    vertex_ids_tree = map(i -> find_vertex_id(ag_rotor, i), indices)

    j = 0
    ix = 3

    println(i_tree, " ", s_info[:n_visited])

    # tree = []

    for (i_child, v_child) in zip(indices, vertex_ids_tree)

        t_child = ag_rotor[:times][i_child]
        # if t_child > 3500
        #     continue
        # end

        # j += 1

        # if j % 10 > 0
        #     continue
        # end


        i_parent = ag_rotor[:parents][i_child]
        if i_parent == -1
            continue
        end

        v_parent = find_vertex_id(ag_rotor, i_parent)

        x_child = points[ix, indices_rotor_extended[v_child]]
        x_parent = points[ix, indices_rotor_extended[v_parent]]

        # push!(tree, points[:, indices_rotor_extended[v_child]])

        t_parent = ag_rotor[:times][i_parent]

        plt.plot(
            [t_parent, t_child],
            [x_parent, x_child],
            color="C$i_tree",
            lw=0.5,
        )

    end

    # push!(trees, hcat(tree...))

end

##

plot(trees[2][1, :], trees[2][3, :], ".")
plot(trees[3][1, :], trees[3][3, :], ".")

##

i1 = 270
i2 = 225
s1 = summary_info_sorted[i1]
s2 = summary_info_sorted[i2]

mask = ag_rotor[:roots] .== s1[:index_times_start]
indices = findall(mask)
vlist1 = map(i -> find_vertex_id(ag_rotor, i), indices)

mask = ag_rotor[:roots] .== s2[:index_times_start]
indices = findall(mask)
vlist2 = map(i -> find_vertex_id(ag_rotor, i), indices)

I, J, V = findnz(ag_rotor.graph.weights[vlist1, vlist2])

dt_max = 10

for (i, j) in zip(I, J)
    ti = get_vertex_array(ag_rotor, i, :times)
    tj = get_vertex_array(ag_rotor, j, :times)
    dts = ti .- tj'
    println(any(0 .< dts .< dt_max), " ", any(0 .< -dts .< dt_max))
end

##

# s_info = summary_info[2]
s_info = rotor_info

mask = ag_rotor[:roots] .== s_info[:index_times_start]

indices_leafs_times = findall(mask .& ag_rotor[:is_leaf])
indices_leafs_vertices = map(i -> find_vertex_id(ag_rotor, i), indices_leafs_times)

times_leafs = ag_rotor[:times][indices_leafs_times]

dt_max = 20.

for (i_t_v, v) in zip(indices_leafs_times, indices_leafs_vertices)
    t_v = ag_rotor[:times][i_t_v]
    @show v, t_v

    for u in neighbors(ag_rotor, v)
        # ti = get_vertex_array(ag_rotor, u, :times)

        for i_t_u = ag_rotor.starts[u]: ag_rotor.stops[u]

            t_u = ag_rotor[:times][i_t_u]
            dt = t_u - t_v

            if 0 < dt < dt_max
                println("### $v -> $u")
                println("    $t_v -> $t_u    ($dt)")

                for i in (i_t_v, i_t_u)
                    s = slice_arrays(ag_rotor, i)
                    println("   $s")
                end
                println("\n")

            else
                # println("    $v -x $u")
                # println("    $t_v -> $t_u    ($dt)")

            end
        end
    end
end

##

function slice_arrays(g, index_array)
    Dict(key => array[index_array] for (key, array) in g.arrays)
end
