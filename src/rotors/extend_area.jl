using Graphs


function extend_area(graph, indices, distance=1000.)

    indices_extended = Int32[]

    for i in indices
        append!(
            indices_extended,
            neighborhood(graph, i, distance)
        )
    end

    unique(union(indices_extended, indices))

end


function find_border(graph, indices)

    map(indices) do i
        !all(neighbors(graph, i) .∈ (indices,))
    end

end
