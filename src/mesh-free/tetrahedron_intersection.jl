using Random
using LinearAlgebra

t = rand(Float64, (4, 3))

t

p_line = rand(Float64, (2, 3))
p_plane = rand(Float64, (3, 2))

function find_intersection(points_plane, points_line)
    # https://en.wikipedia.org/wiki/Line%E2%80%93plane_intersection

    o_plane = points_plane[1, :]
    n_plane = cross(
        points_plane[2, :] - o_plane,
        points_plane[3, :] - o_plane
    )

    o_line = point_line[1, :]
    l_line = points_line[2, :] - o_line

    d = (o_plane - o_line) ⋅ n_plane / (l_line ⋅ n_plane)

    result = o_line + l_line * d

end
