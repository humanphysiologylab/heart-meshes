include("../io/load_arrays.jl")

# function load_activation(heart, group, stim; folder_activation)

#     stim = string(stim, pad = 2)

#     subfolder = "M$heart/G$group/S$stim"
#     folder = joinpath(folder_activation, subfolder)

#     filename_times = joinpath(folder, "times.float32")
#     times = read_binary(filename_times, Float32)
    
#     filename_starts = joinpath(folder, "starts.int32")
#     starts = read_binary(filename_starts, Int32)

#     a = ActArray(starts, Dict(:times => times))

# end


function load_mesh(heart, group, stim; A_vertices, A_elements, elements, points, folder_activation)
    a = load_activation(heart, group, stim; folder_activation)
    mesh = ActivatedMesh(A_vertices, A_elements, elements, a, Dict(:points => points))
end

##

# load_mesh(heart, 1, 1; A_vertices, A_elements, elements, points, folder_activation);
