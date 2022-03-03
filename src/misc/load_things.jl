include("../io/load_adj_matrix.jl")


function load_activated_graph(
    triplet;
    adj_matrix=nothing,
    folder_heart="/media/andrey/ssd2/WORK/HPL/Data/rheeda/",
    folder_arrays="/media/andrey/Samsung_T5/Rheeda/activation"
    )

    i_heart, i_group, i_stim = triplet

    if isnothing(adj_matrix)
        folder_adj_matrix = joinpath(folder_heart, "M$i_heart", "adj_matrix")
        adj_matrix = load_adj_matrix(folder_adj_matrix, false)
    end

    triplet_path = "M$i_heart/G$i_group/S$(string(i_stim, pad = 2))"

    folder_data = joinpath(folder_arrays, "data-light", triplet_path)
    folder_results = joinpath(folder_arrays, "results", triplet_path)

    filename_times = joinpath(folder_data, "times.float32")
    filename_starts = joinpath(folder_data, "indices_start.int32")
    filename_conduction = joinpath(folder_results, "conduction.float32")

    starts = read_binary(filename_starts, Int32)
    times = read_binary(filename_times, Float32)
    # conduction = read_binary(filename_conduction, Float32)

    arrays = Dict(:times => times) # , :conduction => conduction)
    ActivatedGraph(adj_matrix, starts, arrays)

end


function load_points(i_heart; folder="/media/andrey/ssd2/WORK/HPL/Data/rheeda/")
    filename_points = joinpath(folder, "M$(i_heart)", "M$(i_heart)_IRC_3Dpoints.float32")
    points = read_binary(filename_points, Float32, (3, :),)
    points = permutedims(points, (2, 1))
end
