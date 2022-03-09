function calculate_baricentric_coordinates(point, tetrahedron)
    size(tetrahedron) ≠ (4, 3) && error("tetrahedron has wrong dimension: must be (vertices, dims)")
    t = tetrahedron'
    t4 = t[:, 4]
    point .- t4
    T = t[:, 1: 3] .- t4    
    λ⃗ = zeros(4)
    λ⃗[1: 3] .= inv(T) * (point .- t4)
    λ⃗[4] = 1 - sum(λ⃗[1: 3])
    return λ⃗
end


function interpolate_baricentric(point, tetrahedron, y; safety_factor=1e-5)
    size(tetrahedron, 1) ≠ length(y)  && error("tetrahedron and y has different lengths")
    λ⃗ = calculate_baricentric_coordinates(point, tetrahedron)
    if any(λ⃗ .< -safety_factor)
        @warn "interpolation outside the tetrahedron: $λ⃗"
    end
    y_interp = λ⃗ ⋅ y
end
