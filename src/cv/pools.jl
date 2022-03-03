using StatsBase
# using PyPlot

include("connect_grads.jl")

# ag_rotor[:is_available] = trues(size(ag_rotor[:times]))  #7200 .< ag_rotor[:times] .< 7450
# ag_rotor[:is_available] = 7450 .< ag_rotor[:times] .< Inf

# ag_rotor[:times] .*= -1

pools = find_pools(
    ag_rotor;
    is_forward=false, ∇t_min = 0, ∇t_max = 0.05 # Inf
)

roots = map(i -> find_root!(pools, i), Int32.(1: ag_rotor.vectors_len))
root_dict = sort(collect(countmap(roots)), by=x->x[2], rev=true)
# root_dict = filter(x -> last(x) > 100, root_dict)

##

r = first(root_dict[1])
indices = findall(roots .== r)

successors = [find_successor(i; g=ag_rotor, is_forward=false, ∇t_min = 0, ∇t_max = 0.05) for i in indices]



##


##
is_ended_on_border = falses(length(root_dict))

@showprogress for (i, (k, v)) in enumerate(root_dict)
    indices_root = findall(roots .== k)
    i_t_max = indices_root[
        findmax(ag_rotor[:times][indices_root])[2]
    ]
    v = find_vertex_id(ag_rotor, i_t_max)
    is_ended_on_border[i] = v ∈ is_border
end

##

for (k, v) in root_dict[1:20]

    plt.plot(ag_rotor[:times][roots .== k] |> sort, "--.")

end

##

ix, iy = 1, 3

fig, axes_ = subplots(ncols=3)

for ax in axes_
    ax.plot(
        ag_rotor[:points][:, ix],
        ag_rotor[:points][:, iy],
        ",", color="0.8", zorder=-10
    )

    # ax.plot(
    #     ag_rotor[:points][is_border, ix],
    #     ag_rotor[:points][is_border, iy],
    #     ".k",
    #     ms=2
    # )

    times_stop = ag_rotor[:times][ag_rotor.stops]
    vs = findall(times_stop .> quantile(times_stop, 0.99))
    # vs = map(indices) do i
    #     find_vertex_id(ag_rotor, i)
    # end

    ax.plot(
        ag_rotor[:points][vs, ix],
        ag_rotor[:points][vs, iy],
        ".", color="0.3",
        ms=2
    )  

end


for (i, (k, v)) in enumerate(root_dict[1:20])

    # (v < 100) && continue

# k = first(root_dict[2])
    indices = findall(roots .== k)
    times = ag_rotor[:times][indices]

    # (length(times) < 200) && continue
    # !all(6800 .< times .< 7100) && continue
    # (maximum(times) < 7450) && continue


    indices_t_max = indices[
        findall(times .> quantile(times, 0.99))
    ]
    vertices_t_max = map(indices_t_max) do i
        find_vertex_id(ag_rotor, i)
    end

    flag = false #  any(is_border[vertices_t_max])

    color = flag ? "C3" : "C0"
    axes_[2].plot(
        ag_rotor[:points][vertices_t_max, ix],
        ag_rotor[:points][vertices_t_max, iy],
        ".",
        ms=10,
        color=color,
        zorder=100
    )


    vertices = map(i -> find_vertex_id(ag_rotor, i), indices)

    vertices_unique = unique(vertices)

    X = ag_rotor[:points][vertices_unique, :]

    ##

    times_last = ag_rotor[:times][ag_rotor.stops]
    mask = times .> quantile(times_last, 0.01)

    axes_[1].scatter(
        ag_rotor[:points][vertices, ix],
        ag_rotor[:points][vertices, iy],
        c=times,
        # vmin=quantile(times_last, 0.05),
        s=10,
        marker=string("s^ox"[i % 3 + 1]),
    )

    axes_[2].plot(
        ag_rotor[:points][vertices, ix],
        ag_rotor[:points][vertices, iy],
        # ".",
        color="C$i",
        ls="none",
        marker=string("s^ox"[i % 3 + 1]),
        # vmin=quantile(times_last, 0.05),
        ms=4,
        alpha=0.1,
        zorder=10
    )

    axes_[3].plot(
        ag_rotor[:points][vertices, ix],
        ag_rotor[:points][vertices, iy],
        # ".",
        color = flag ? "C3" : "C0",
        ls="none",
        marker=string("s^ox"[i % 3 + 1]),
        # vmin=quantile(times_last, 0.05),
        ms=4,
        alpha=0.1,
        zorder=10
    )

    # plot(X[:, ix], X[:, iy], lw=3, color="w")
    # plot(X[1, ix], X[1, iy], "or")

    # plot(X[mask, ix], X[mask, iy], ".-", lw=1, color="r")

end

# title(triplet_string)
# axis("equal")

##

# plot(ag_rotor[:points][:, ix], ag_rotor[:points][:, iy], ",", color="0.8", zorder=-10)
