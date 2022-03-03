function find_colors(array, cm)

    a_max = maximum(array)
    a_min = minimum(array)

    a_ptp = a_max - a_min

    i_min, i_max = 1, length(cm)
    i_ptp = i_max - i_min

    indices = @. round(Int, (array - a_min) / a_ptp * i_ptp + i_min)

    cm[indices]
        
end
