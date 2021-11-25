using SparseArrays
using ProgressMeter

include("../src/read_binary.jl")

n_points = 1958268

##

heart_id = 13
folder = joinpath("/media/andrey/ssd2/WORK/HPL/Data/rheeda/", "M$heart_id")

filename_I = joinpath(folder, "I.int32")
filename_J = joinpath(folder, "J.int32")

I = read_binary(filename_I, Int32)
J = read_binary(filename_J, Int32)

adj_matrix = sparse(vcat(I, J), vcat(J, I), trues(length(I) * 2))

## 

filename = "/media/andrey/1TBlob/HPL/Data/Rheeda/bins/G4_M13_bin/S13.bin"

a = read_binary(filename, Float32, (2, :))
a = permutedims(a)

vertices = convert.(Int, a[:, 1]) .+ 1
times = a[:, 2]

indices_sortperm = sortperm(vertices)
vertices_sorted = vertices[indices_sortperm]
times_sorted = times[indices_sortperm]

##

starts = map(i -> searchsortedfirst(vertices_sorted, i), 1:n_points)

stops = starts[2:end] .- 1
append!(stops, length(vertices_sorted))


##

@showprogress for (start, stop) ∈ zip(starts, stops)
    times_sorted[start:stop] .= sort(times_sorted[start:stop])
end

##

write(replace(filename, ".bin" => "_starts.int32"), convert.(Int32, starts))
write(replace(filename, ".bin" => "_times.float32"), times_sorted)

##

conduction_percent = fill(NaN32, size(times_sorted))
dt_max = 10.0
stride = 1

calculate_conduction_map(
    adj_matrix,
    times_sorted,
    starts,
    dt_max = dt_max,
    output_prealloc = conduction_percent,
)

##

write(
    replace(filename, ".bin" => "_conduction_percent.float32"),
    convert.(Float32, conduction_percent),
)

##
start_stop = fill(0, (n_points, 2))

@showprogress for i_vertex ∈ 1:n_points
    r = searchsorted(vertices_sorted, i_vertex)
    searchsortedfirst(vertices_sorted, i_vertex)
    start_stop[i_vertex, :] .= r.start, r.stop
end

write(replace(filename, ".bin" => "_start_stop.int32"), convert.(Int32, start_stop))
