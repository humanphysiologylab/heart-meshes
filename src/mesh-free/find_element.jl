using LinearAlgebra


function select_outer_facet(point, element)
    n_vertices = size(element, 1)
    n_dims = size(element, 2)
    for i in 1:n_vertices
        indices = 1 .+ collect((i: i + n_dims)) .% n_vertices
        vertices = element[indices, :]
        if is_outer_facet(point, vertices)
            return indices[1: end-1]
        end    
    end
end


function is_outer_facet(point, vertices)
    o = vertices[1, :]
    n = cross(vertices[2, :] - o, vertices[3, :] - o)
    a = n ⋅ (vertices[4, :] - o)
    b = n ⋅ (point - o)
    sign(a) ≠ sign(b)
end
