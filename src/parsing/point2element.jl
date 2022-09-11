using ProgressMeter
using LinearAlgebra

include("../io/read_binary.jl")
include("../misc/create_stops.jl")
include("../ActArrays/ActArrays.jl")

##

folder_rheeda = "/Volumes/samsung-T5/HPL/Rheeda/"
heart = 15

filename_points = joinpath(folder_rheeda, "geometry", "M$heart", "points.float32")
points = read_binary(filename_points, Float32, (3, :))
points = permutedims(points, (2, 1))

filename_elements = joinpath(folder_rheeda, "geometry", "M$heart", "elements.int32")
elements = read_binary(filename_elements, Int32, (4, :))
elements .+= 1
elements = permutedims(elements, (2, 1))

##

function create_point2element(elements)

    n = length(elements)

    i = 1
    indices_points = zeros(eltype(elements), n)
    indices_elements = zeros(eltype(elements), n)

    for (i_element, element) in enumerate(eachrow(elements))
        for i_point in element
            indices_points[i] = i_point
            indices_elements[i] = i_element
            i += 1
        end
    end

    n_points = maximum(indices_points)

    indices_sortperm = sortperm(indices_points)
    indices_points = indices_points[indices_sortperm]
    indices_elements = indices_elements[indices_sortperm]

    starts = map(i -> searchsortedfirst(indices_points, i), 1:n_points)
    stops = create_stops(starts, n)

    for (start, stop) ∈ zip(starts, stops)
        indices_elements[start:stop] .= sort(indices_elements[start:stop])
    end

    starts = eltype(indices_points).(starts)

    return starts, indices_elements

end

##

starts, indices_elements = create_point2element(elements)

idx_mapper = ActArray(starts, Dict(:el => indices_elements))

##

folder_save = joinpath(
    folder_rheeda,
    "geometry",
    "M$heart",
    "v2e"
)

filename_save = joinpath(folder_save, "starts.int32")

open(filename_save, "w") do f
    write(f, starts)
end

filename_save = joinpath(folder_save, "indices_elements.int32")

open(filename_save, "w") do f
    write(f, indices_elements)
end


##

function calculate_volume(tetrahedron)

    a = tetrahedron[1, :]
    b = tetrahedron[2, :]
    c = tetrahedron[3, :]
    d = tetrahedron[4, :]

    volume = norm((a - d) .* ((b - d) × (c - d))) / 6

end

t = points[elements[1, :], :]

t = [
    0 0 0;
    0 0 1;
    0 1 0;
    1 0 0
]

@assert calculate_volume(t) == 1/6

##

n_elements = size(elements, 1)
volumes = zeros(n_elements)

@showprogress for i in 1: n_elements
    t = points[elements[i, :], :]
    v = calculate_volume(t)
    volumes[i] = v
end

##

filename_save = joinpath(folder_rheeda, "geometry", "M$heart", "element_volume.float32")

open(filename_save, "w") do f
    write(f, Float32.(volumes))
end
