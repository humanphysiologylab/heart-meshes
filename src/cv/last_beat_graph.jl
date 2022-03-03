times_stop = ag_rotor[:times][ag_rotor.stops]
starts = Int32.(1:nv(ag_rotor))

ag_rotor_last = ActivatedGraph(
    Graphs.weights(ag_rotor.graph),
    starts,
    Dict(:times => times_stop, :is_available => collect(trues(size(times_stop)))),
    Dict(:points => ag_rotor[:points])
)

ag_rotor = ag_rotor_last
