using ArgParse
using DataFrames, CSV

include("../ActivatedMeshes/ActivatedMeshes.jl")

include("../mesh-free/run_gradient_descent.jl")
include("../mesh-free/bfs.jl")
include("../mesh-free/find_period.jl")

include("load_geometry.jl")
include("load_arrays.jl")
include("create_point2element.jl")
include("find_folders_times.jl")


function parse_cl()

    s = ArgParseSettings()

    @add_arg_table s begin
        "--folder-times"
            help = "WARNING! These are processed times. Ex.: path/to/times/"
            required = true
        "--folder-geometry"
            help = "folder with tetra, points and adj-*"
            required = true
        "--overwrite"
            help = "overwrite existing files, ignore them otherwise"
            action = :store_true
    end

    return parse_args(s)

end



function main()

    parsed_args = parse_cl()

    folder_geometry = parsed_args["folder-geometry"]
    folder_times = parsed_args["folder-times"]
    overwrite = parsed_args["overwrite"]

    A_vertices, A_tetra, tetra, points = load_geometry(folder_geometry)
    point2element = create_point2element(tetra, size(points, 1))

    folders = find_folders_times(folder_times)

    rows_threads = [[] for i in 1:Threads.nthreads()]

    Threads.@threads for folder in folders

        filename_trajectories = joinpath(
            folder,
            "trajectories"
        )

        !overwrite && isdir(filename_trajectories) && continue

        rm(filename_trajectories, force=true, recursive=true)
        mkpath(filename_trajectories)

        a = load_arrays(folder)
        mesh = ActivatedMesh(A_vertices, A_tetra, tetra, a, Dict(:points => points))

        tid = Threads.threadid()
        msg = "thread $tid -> $folder"
        @info msg

        filename_meta = joinpath(folder, "meta.csv")
        if !isfile(filename_meta)
            @warn "no such file: $filename_meta\ncontinue..."
            continue
        end

        df_meta = CSV.read(filename_meta, DataFrame)

        lifetime_min = 200.
        df_meta = df_meta[df_meta.lifetime .> lifetime_min, :]

        for (i_row, row) in enumerate(eachrow(df_meta))

            component_id = row[:component_id]
            filename_save = joinpath(filename_trajectories, "$component_id.csv")
            # isfile(filename_save) && continue

            # @show row

            i_time = row.i_max

            bfs_result = bfs(i_time, mesh)[1]
            i_time = bfs_result.i

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
                :thread_id => tid,
                :lifetime => lifetime,
                :t_start => t_start,
                :t_end => t_end,
                :period => period,
                :i_row => i_row
            )
            push!(rows_threads[Threads.threadid()], row_thread)
            
            CSV.write(filename_save, df)
                
        end

    end

    df_params = DataFrame(
        Iterators.flatten(rows_threads)
    )
    filename_write = joinpath(folder_times, "rotor-params.csv")
    CSV.write(filename_write, df_params)

end


main()
