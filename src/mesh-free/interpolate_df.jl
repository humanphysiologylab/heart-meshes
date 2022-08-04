using DataFrames, CSV
using DataInterpolations


function interpolate_df(df, dt=10; columns=[:x, :y, :z])

    df = sort(df, :t)

    t = minimum(df.t): dt: maximum(df.t) |> collect

    data = Dict(:t => t)

    for c in columns
        interp = ConstantInterpolation(df[!, c], df.t)
        data[c] = interp.(t)
    end

    DataFrame(data)

end

##

# filename = "/Users/andrey/Work/HPL/projects/rheeda/heart-meshes/tmp/times/S10/trajectories/1.csv"
# df = CSV.read(filename, DataFrame)
# df_interp = interpolate_df(df)
