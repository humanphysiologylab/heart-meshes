using ProgressMeter
using DataFrames, CSV

include("../io/read_binary.jl")
include("../io/load_adj_matrix.jl")

include("../ActivatedMeshes/ActivatedMeshes.jl")
include("../ActArrays/ActArrays.jl")

include("run_gradient_descent.jl")
include("find_period.jl")
include("load_mesh.jl")

##

heart = 15

disk_path = "samsung-T5/HPL/Rheeda"
folders_try = [
    joinpath("/Volumes", disk_path),
    joinpath("/media/andrey", disk_path)
]
folder = folders_try[findfirst(isdir.(folders_try))]

folder_geometry_heart = joinpath(folder, "geometry", "M$heart")
folder_activation = joinpath(folder, "activation-times")

##

filename_elements = joinpath(folder_geometry_heart, "elements.int32")
elements = read_binary(filename_elements, Int32, (4, :))
elements = permutedims(elements, (2, 1))
elements .+= 1

filename_points = joinpath(folder_geometry_heart, "points.float32")
points = read_binary(filename_points, Float32, (3, :))
points = permutedims(points, (2, 1))

folder_adj_vertices = joinpath(folder_geometry_heart, "adj-vertices")
A_vertices = load_adj_matrix(folder_adj_vertices, false)

folder_adj_elements = joinpath(folder_geometry_heart, "adj-elements")
A_elements = load_adj_matrix(folder_adj_elements)

##

point2element = [Int[] for i in 1:size(points, 1)]

@showprogress for (i_element, element) in enumerate(eachrow(elements))
    for i_point in element
        push!(point2element[i_point], i_element)
    end
end

##

filename_csv = joinpath(folder, "rotors", "connected_components.csv")
df_meta = CSV.read(filename_csv, DataFrame)

##

folder_save = joinpath(folder, "rotors", "trajectories")

rows_threads = [[] for i in 1:Threads.nthreads()]

Threads.@threads for row in eachrow(df_meta)
# for row in eachrow(df_meta)

    filename_save = joinpath(
        folder_save,
        "M$(row.heart)-G$(row.group)-S$(row.stim)-$(row.component_id).csv"
    )

    # isfile(filename_save) && continue
    # row.t_end < 7490 && continue
    # row.group ≠ 4 && continue
    row.heart ≠ heart && continue

    i_element_start = point2element[row.v_start] |> first

    mesh = load_mesh(
        row.heart,
        row.group,
        row.stim;
        A_vertices,
        A_elements,
        elements,
        points,
        folder_activation
    )

    t_stop = row.t_start + 50.
    step = -100.
    df = run_gradient_descent(mesh, i_element_start; step, t_stop)

    lifetime_min = 1000.
    t_start, t_end = minimum(df.t), maximum(df.t)
    lifetime = t_end - t_start
    lifetime < lifetime_min && continue

    period = find_period(df, mesh)

    t_id = Threads.threadid()
    row = Dict(
        :heart => row.heart,
        :group => row.group,
        :stim => row.stim,
        :component_id => row.component_id,
        :thread_id => t_id,
        :lifetime => lifetime,
        :t_start => t_start,
        :t_end => t_end,
        :period => period
    )
    push!(rows_threads[Threads.threadid()], row)

    CSV.write(filename_save, df)

end

##

df_params = DataFrame(
    Iterators.flatten(rows_threads)
)

filename_write = joinpath(folder, "rotors", "M$heart-rotor-params.csv")
CSV.write(filename_write, df_params)
