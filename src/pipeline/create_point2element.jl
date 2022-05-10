using ProgressMeter


function create_point2element(elements, n_points)

    point2element = [Int[] for _ in 1:n_points]

    @showprogress "indexing..." for (i_element, element) in enumerate(eachrow(elements))
        for i_point in element
            push!(point2element[i_point], i_element)
        end
    end

    point2element

end
