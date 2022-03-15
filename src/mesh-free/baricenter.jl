function calculate_baricentric_coordinates(point, element; atol=1e-4)
    n_vertices, n_dims = size(element)
    (n_vertices ≠ n_dims + 1) && error("element has wrong dimension: must be (vertices, dims)")
    t = element'
    t_last = t[:, end]
    point .- t_last
    T = t[:, 1: end - 1] .- t_last    
    λ⃗ = zeros(n_vertices)
    λ⃗[1: end - 1] .= inv(T) * (point .- t_last)

    λ_sum = sum(λ⃗[1: end - 1])
    if isapprox(λ_sum, 1.; atol)
        λ⃗[1: end - 1] ./= λ_sum
        λ⃗[end] = 0.
    else
        λ⃗[end] = 1 - λ_sum
    end

    return λ⃗
end


function interpolate_baricentric(point, element, y)
    size(element, 1) ≠ length(y)  && error("element and y has different lengths")
    λ⃗ = calculate_baricentric_coordinates(point, element)
    interpolate_baricentric(λ⃗, y)
end


function is_inside(λ⃗; atol=1e-4)
    all(λ⃗ .> -atol) 
end


function interpolate_baricentric(λ⃗, y)
    if !is_inside(λ⃗)
        @warn "interpolation outside the element: $λ⃗"
    end
    y_interp = λ⃗ ⋅ y
end
