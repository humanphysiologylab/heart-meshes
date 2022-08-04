using ArgParse

using Graphs, SimpleWeightedGraphs
using DataFrames, CSV

include("../ActArrays/ActArrays.jl")
include("../ActivatedGraphs/ActivatedGraphs.jl")

include("../cc-4d/get_component.jl")
include("../cc-4d/get_components.jl")

include("../io/read_binary.jl")
include("../io/load_adj_matrix.jl")

include("find_folders_times.jl")
include("load_arrays.jl")


function parse_cl()

    s = ArgParseSettings()

    @add_arg_table s begin
        "--folder-times"
            help = "WARNING! These are processed times. Ex.: path/to/times/"
            required = true
        "--adj-vertices"
            help = "folder with I, J and V files. Ex.: path/to/adj-vertices/"
            required = true
        "--overwrite"
            help = "overwrite existing files, ignore them otherwise"
            action = :store_true
    end

    return parse_args(s)

end


function main()

    parsed_args = parse_cl()

    folder_adj_matrix = parsed_args["adj-vertices"]
    A = load_adj_matrix(folder_adj_matrix, false)
    g = SimpleWeightedGraph(A)

    folder_times = parsed_args["folder-times"]

    overwrite = parsed_args["overwrite"]

    folders = find_folders_times(folder_times)

    Threads.@threads for folder in folders

        filename_save = joinpath(
            folder,
            "meta.csv"
        )
        !overwrite && isfile(filename_save) && continue

        tid = Threads.threadid()
        msg = "thread $tid -> $folder"
        @info msg

        a = load_arrays(folder)
        ag = ActivatedGraph(g, a)
        try
            df = get_components(ag)
            CSV.write(filename_save, df)
        catch
            @warn "FAILED " * msg
        end

    end

end


main()
