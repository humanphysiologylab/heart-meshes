using ProgressMeter
using DataFrames, CSV

include("../io/read_binary.jl")
include("../io/load_adj_matrix.jl")

include("../ActivatedMeshes/ActivatedMeshes.jl")
include("../ActArrays/ActArrays.jl")

include("run_gradient_descent.jl")
include("find_period.jl")
include("load_mesh.jl")
include("get_labels.jl")

##

disk_path = "samsung-T5/HPL/Rheeda"
folders_try = [
    joinpath("/Volumes", disk_path),
    joinpath("/media/andrey", disk_path)
]
folder = folders_try[findfirst(isdir.(folders_try))]

heart = 13

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

folder_meta = "/Volumes/samsung-T5/HPL/Rheeda/rotors/cc-4d"

folder_save = joinpath(folder, "rotors", "trajectories-cc-4d")
mkpath(folder_save)

rows_threads = [[] for i in 1:Threads.nthreads()]

Threads.@threads for filename_meta in readdir(folder_meta)

    t_id = Threads.threadid()

    tag = split(filename_meta, ".") |> first

    h, g, s = map(
        x -> parse(Int, x),
        split(tag, "-")
    )

    h ≠ heart && continue

    println(t_id, ":", tag)

    mesh = load_mesh(
        h,
        g,
        s;
        A_vertices,
        A_elements,
        elements,
        points,
        folder_activation
    )

    filename_meta_full = joinpath(folder_meta, filename_meta)
    df_cc = CSV.read(filename_meta_full, DataFrame)

    lifetime_min = 1000.
    df_cc = df_cc[df_cc.lifetime .> lifetime_min, :]

    for (i_row, row) in enumerate(eachrow(df_cc))

        filename_save = joinpath(folder_save, "$(tag)-$(i_row).csv")
        # isfile(filename_save) && continue

        # @show row

        i_time = row.i_max
        v = get_major_index(mesh.arrays, i_time)
        i = point2element[v] |> first
    
        time_start = row.t_max
    
        df = nothing
        try
            df, metainfo = run_gradient_descent(mesh, i; time_start)
        catch
            continue
        end

        # @show metainfo

        t_start, t_end = minimum(df.t), maximum(df.t)
        lifetime = t_end - t_start
        lifetime < lifetime_min && continue

        period = find_period(df, mesh)

        row_thread = Dict(
            :heart => h,
            :group => g,
            :stim => s,
            :thread_id => t_id,
            :lifetime => lifetime,
            :t_start => t_start,
            :t_end => t_end,
            :period => period,
            :i_row => i_row
        )
        push!(rows_threads[Threads.threadid()], row_thread)
        
        CSV.write(filename_save, df)
            
    end

    # break

end

##

df_params = DataFrame(
    Iterators.flatten(rows_threads)
)
filename_write = joinpath(folder, "rotors", "M$heart-rotor-params-cc-4d.csv")
CSV.write(filename_write, df_params)
