using ArgParse

include("../io/read_binary.jl")
include("../io/load_adj_matrix.jl")
include("../conduction/calculate_conduction_map.jl")


const filenames_required = ("times.float32", "starts.int32")


function parse_cl()

    s = ArgParseSettings()

    @add_arg_table s begin
        "--folder-times"
            help = "WARNING! These are processed times. Ex.: path/to/times/"
            required = true
        "--adj-vertices"
            help = "folder with I, J and V files. Ex.: path/to/adj-vertices/"
            required = true
        "--rewrite"
            default = false
    end

    return parse_args(s)

end


function find_folders(folder_times)

    folders = []

    for (root, _, filenames) in walkdir(folder_times)

        if  all(filenames_required .∈ (filenames, ))

            dir = dirname(
                joinpath(root, first(filenames))
            )
            push!(folders, dir)

        end

    end

    return folders

end


function main()

    parsed_args = parse_cl()

    folder_adj_matrix = parsed_args["adj-vertices"]
    A = load_adj_matrix(folder_adj_matrix, false)

    folder_times = parsed_args["folder-times"]

    is_rewrite = parsed_args["rewrite"]

    folders = find_folders(folder_times)

    Threads.@threads for folder in folders

        tid = Threads.threadid()
        msg = "thread $tid -> $folder"
        @info msg

        filename_starts = joinpath(folder, "starts.int32")
        filename_times = joinpath(folder, "times.float32")

        filename_conduction = joinpath(folder, "conduction.float32")

        !is_rewrite && isfile(filename_conduction) && continue

        starts = read_binary(filename_starts, Int32)
        times = read_binary(filename_times, Float32)

        conduction = calculate_conduction_map(A, times, starts)
        
        write(filename_conduction, conduction)

    end

end


main()
