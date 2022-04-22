using LinearAlgebra


function find_outer_facet(points::Matrix, point::Vector)
    # works for any dimensions
    # `points` -- coordinates of the element
    # `point` -- point outside (or inside) of the element

    element_size = size(points, 1)
    facet_size = element_size - 1
    b = ones(facet_size)

    for i in 1: element_size

        facet = setdiff(1: element_size, i)

        # ax + by + ... + d = 1
        # we find coeffs = (a, b, ..., d)
        X = points[facet, :]
        A = hcat(X, b)

        rank(A) ≠ facet_size && error("invalid facet")

        coeffs = nullspace(A)

        pᵢ = points[i, :]
        d1 = pᵢ ⋅ coeffs[1: end-1] + coeffs[end]
        d2 = point ⋅ coeffs[1: end-1] + coeffs[end]

        sign(d1) ≠ sign(d2) && return facet

    end

end
