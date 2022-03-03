# using Colors
using ColorSchemes
using PlotlyJS
# cm = colormap("Blues")

cm = ColorSchemes.okabe_ito;

##
times_stop = ag_rotor[:times][ag_rotor.stops]
times_stop[times_stop .< quantile(times_stop, 0.1)] .= NaN
# times_colors = get(ColorSchemes.viridis, times_stop, (7300, 7500));

##

stride = 10

trace_bg = scatter3d(;
    x=ag_rotor[:points][1: stride: end, 1],
    y=ag_rotor[:points][1: stride: end, 2],
    z=ag_rotor[:points][1: stride: end, 3],
    mode="markers",
    marker_size=1,
    # marker_color="grey"
    colorscale="Greys",
    marker_color=times_stop[1: stride: end]
)

##

plot(trace_bg)

##

traces = []
traces_sticks = []

for (i_root, (k, v)) in enumerate(root_dict[1:1])

    if v == 1
        continue
    end

    indices = findall(roots .== k)
    times = ag_rotor[:times][indices]

    vertices = map(i -> find_vertex_id(ag_rotor, i), indices)
    vertices_unique = unique(vertices)
    X = ag_rotor[:points][vertices_unique, :]

    # times_last = ag_rotor[:times][ag_rotor.stops]
    # mask = times .> quantile(times_last, 0.01)

    trace = PlotlyJS.scatter3d(;
        x=X[:, 1],
        y=X[:, 2],
        z=X[:, 3],
        mode="markers",
        marker_size=2,
        showlegend=false,
        # marker_color="grey"
        marker_color=times
    )
    
    push!(traces, trace)

    for i in indices
        v = find_vertex_id(ag_rotor, i)
        u = find_vertex_id(ag_rotor, ag_rotor[:successor][i])
        if u == 0
            continue
        end

        xv = ag_rotor[:points][v, :]
        xu = ag_rotor[:points][u, :]

        stick = scatter3d(;
            x=[xv[1], xu[1]],
            y=[xv[2], xu[2]],        
            z=[xv[3], xu[3]],
            mode="lines",
            line_color=cm[i_root % length(cm) + 1], # "black",
            showlegend=false
        )

        push!(traces_sticks, stick)
    end

end
traces = [t for t in traces]
traces_sticks = [t for t in traces_sticks]

##

plot(
    [
        trace_bg,
        traces...,
        #traces_sticks[1: 100: end]...
    ]
)
