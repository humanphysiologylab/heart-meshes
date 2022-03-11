using LinearAlgebra


function select_outer_facet(point, element)
    n_vertices = size(element, 1)
    n_dims = size(element, 2)
    
    outerness_best = 0.
    indices_best = zeros(Int, 3)
    nothing_found = true

    for i in 1:n_vertices
        indices = 1 .+ collect((i: i + n_dims)) .% n_vertices
        vertices = element[indices, :]
        outerness = calculate_outerness(point, vertices)
        if outerness < outerness_best
            indices_best .= indices[1: end-1]
            nothing_found = false
        end
        # if is_outer_facet(point, vertices)
        #     return indices[1: end-1]
        # end    
    end

    if !nothing_found
        return indices_best
    end

end

function calculate_facet_norm(facet)
    o = facet[1, :]
    n = cross(facet[2, :] - o, facet[3, :] - o)
end


function is_outer_facet(point, vertices)
    outerness = calculate_outerness(point, vertices)
    outerness < 0
end


function calculate_outerness(point, vertices)
    o = vertices[1, :]
    n = cross(vertices[2, :] - o, vertices[3, :] - o)
    a = n ⋅ (vertices[4, :] - o)
    b = n ⋅ (point - o)
    outerness = a * b
end
