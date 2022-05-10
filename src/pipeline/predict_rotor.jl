using ArgParse
using DataFrames, CSV

using Flux
using BSON: @load


include("../mesh-free/interpolate_df.jl")
include("../nn/v2/cnn/predict_proba.jl")


function parse_cl()

    s = ArgParseSettings()

    @add_arg_table s begin
        "--folder-trajectories"
            required = true
        "--model"
            required = true
    end

    return parse_args(s)

end


function process_dir(dir, model)

    suffix_add = "-rotor.csv"

    for filename in readdir(dir, join=true)

        !endswith(filename, ".csv") && continue
        endswith(filename, suffix_add) && continue

        df = CSV.read(filename, DataFrame)
        df = interpolate_df(df)

        proba = predict_proba(df, model)
        df[:, :proba] = proba

        filename_save = replace(filename, ".csv" => suffix_add)
        CSV.write(filename_save, df)

    end

end

##
##  M A I N
##
##  This is not a function because of BSON @load

parsed_args = parse_cl()

folder_trajectories = parsed_args["folder-trajectories"]
filename_model = parsed_args["model"]
@load filename_model model

for (root, dirs, _) in walkdir(folder_trajectories)

    for dir in dirs
        dir ≠ "trajectories" && continue
        dir = joinpath(root, dir)
        process_dir(dir, model)
    end

end
