using LinearAlgebra


function find_rotation_matrix(a, b)

    a_unit = a / norm(a)
    b_unit = b / norm(b)

    ν = a_unit × b_unit
    s = norm(ν)
    c = a_unit ⋅ b_unit
    # c = √(1 - s^2)
    
    M = [
         0    -ν[3]  ν[2];
         ν[3]  0    -ν[1];
        -ν[2]  ν[1]  0
        ]

    I + M + M^2 * (1 - c) / (s^2)

end


function align_segments(x1, x2)

    a = x1[end, :] - x1[end - 1, :]
    b = x2[2, :] - x2[1, :]

    a ./= norm(a)
    b ./= norm(b)

    R = find_rotation_matrix(b, a)  # R * b .≈ a

    result = transpose(R * transpose(x2))
    result .+= (x1[end, :] - result[1, :])'

end
