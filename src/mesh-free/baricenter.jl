function calculate_baricentric_coordinates(point, tetrahedron)
    size(tetrahedron) ≠ (4, 3) && error("tetrahedron has wrong dimension: must be (vertices, dims)")
    t = tetrahedron'
    t4 = t[:, 4]
    point .- t4
    T = t[:, 1: 3] .- t4    
    λ⃗ = inv(T) * (point .- t4)
end


function interpolate_baricentric(point, tetrahedron, y)
    size(tetrahedron, 1) ≠ length(y)  && error("tetrahedron and y has different lengths")
    λ⃗ = calculate_baricentric_coordinates(point, tetrahedron)
    λ4 = 1 - sum(λ⃗)
    y_interp = λ⃗[1:3] ⋅ y[1:3] + λ4 * y[4]
end
