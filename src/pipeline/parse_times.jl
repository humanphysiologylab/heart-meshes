using ArgParse

include("../io/read_binary.jl")
include("../parsing/read_dat.jl")
include("../parsing/compress_activation_times.jl")


function parse_cl()

    s = ArgParseSettings()

    @add_arg_table s begin
        "--folder-times"
            help = "Ex.: path/to/times/"
            required = true
        "--points"
            help = "filename. Ex.: points.float32"
            required = true
        "--ext"
            help = "file extention of 'times' files. however, 'times' MUST be tsv-files inside."
            default = ".tsv"
        "--output"
            help = "folder to save the results"
            default = "./"
        "--overwrite"
            help = "overwrite existing files, ignore them otherwise"
            action = :store_true
    end

    return parse_args(s)

end


function parse_times_worker(
    filename_full,
    folder_save_current,
    n_points;
    overwrite=false
)

    filename_starts = joinpath(folder_save_current, "starts.int32")
    filename_times = joinpath(folder_save_current, "times.float32")

    all_found = isfile.([filename_starts, filename_times]) |> all
    !overwrite && all_found && return

    vs, times = read_dat(filename_full)
    starts, times, n_points_found = compress_activation_times(vs, times, n_points)

    mkpath(folder_save_current)

    write(filename_starts, starts)
    write(filename_times, times)

end


function find_filenames(folder_times, ext)

    filenames_full = []

    for (root, _, filenames) in walkdir(folder_times)

        for filename in filenames
            !endswith(filename, ext) && continue

            filename_full = joinpath(root, filename)
            push!(filenames_full, filename_full)

        end
    
    end

    return filenames_full

end


function main()

    parsed_args = parse_cl()

    filename_points = parsed_args["points"]
    points = read_binary(filename_points, Float32, (3, :))
    points = permutedims(points, (2, 1))
    n_points = size(points, 1)

    ext = parsed_args["ext"]
    folder_save = joinpath(
        parsed_args["output"],
        "times"
    )

    folder_times = parsed_args["folder-times"]
    overwrite = parsed_args["overwrite"]

    filenames_full = find_filenames(folder_times, ext)

    Threads.@threads for filename_full in filenames_full

        filename_rel = relpath(
            filename_full,
            folder_times
        )

        dir = dirname(filename_rel)
        folder_save_current = joinpath(folder_save, dir)

        tid = Threads.threadid()
        msg = "thread $tid -> $filename_rel"
        @info msg

        parse_times_worker(filename_full, folder_save_current, n_points; overwrite)
        
    end

end


main()
