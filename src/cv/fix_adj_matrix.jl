points = permutedims(points, (2, 1))
I, J, _ = findnz(adj_matrix)
mask_upper = I .> J

I_up = I[mask_upper]
J_up = J[mask_upper]

using Distances
W_up = colwise(
    Euclidean(),
    transpose(points[I_up, :]),
    transpose(points[J_up, :])
)

##

filename_I = joinpath(folder, "I.int32")
open(filename_I, "w") do f
    write(f, I_up)
end

filename_J = joinpath(folder, "J.int32")
open(filename_J, "w") do f
    write(f, J_up)
end

filename_V = joinpath(folder, "V.float32")
open(filename_V, "w") do f
    write(f, W_up)
end
