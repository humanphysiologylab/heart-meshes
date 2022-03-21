filename_csv_old = joinpath(folder, "data/rotor-trajectory-feb22/M13-G1-S13-0.csv")
df_old = DataFrame(CSV.File(filename_csv_old))

trace_old = create_trajectories_traces([df_old])[1]

##

plot([[t for t in traces]..., trace_bg, trace_old])
