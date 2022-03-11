function calculate_baricentric_coordinates(point, tetrahedron; atol=1e-4)
    size(tetrahedron) ≠ (4, 3) && error("tetrahedron has wrong dimension: must be (vertices, dims)")
    t = tetrahedron'
    t4 = t[:, 4]
    point .- t4
    T = t[:, 1: 3] .- t4    
    λ⃗ = zeros(4)
    λ⃗[1: 3] .= inv(T) * (point .- t4)

    λ_sum = sum(λ⃗[1: 3])
    if isapprox(λ_sum, 1.; atol)
        λ⃗[1: 3] ./= λ_sum
        λ⃗[4] = 0.
    else
        λ⃗[4] = 1 - λ_sum
    end

    return λ⃗
end


function interpolate_baricentric(point, tetrahedron, y)
    size(tetrahedron, 1) ≠ length(y)  && error("tetrahedron and y has different lengths")
    λ⃗ = calculate_baricentric_coordinates(point, tetrahedron)
    interpolate_baricentric(λ⃗, y)
end


function is_inside(λ⃗)
    all(λ⃗ .> -1e-4) 
end


function interpolate_baricentric(λ⃗, y)
    if !is_inside(λ⃗)
        @warn "interpolation outside the tetrahedron: $λ⃗"
    end
    y_interp = λ⃗ ⋅ y
end
