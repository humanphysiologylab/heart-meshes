using SparseArrays

include("calculate_conduction_map.jl")
include("../src/read_binary.jl")


function load_adj_matrix(folder::String)
    filename_I = joinpath(folder, "I.int32")
    filename_J = joinpath(folder, "J.int32")

    I = read_binary(filename_I, Int32)
    J = read_binary(filename_J, Int32)

    adj_matrix = sparse(vcat(I, J), vcat(J, I), trues(length(I) * 2))
end


function parse_activation_times(filename_bin::String)

    a = read_binary(filename_bin, Float32, (2, :))
    a = permutedims(a)

    vertices = convert.(Int, a[:, 1]) .+ 1
    times = a[:, 2]

    indices_sortperm = sortperm(vertices)
    vertices_sorted = vertices[indices_sortperm]
    times_sorted = times[indices_sortperm]

    n_points = last(vertices_sorted)

    starts = map(i -> searchsortedfirst(vertices_sorted, i), 1:n_points)
    stops = similar(starts)
    @views stops[1:end-1] = starts[2:end] .- 1
    stops[end] = length(times)

    for (start, stop) ∈ zip(starts, stops)
        times_sorted[start:stop] .= sort(times_sorted[start:stop])
    end

    return times_sorted, starts

end


function process_folder_bin(folder_bin::String, adj_matrix::SparseMatrixCSC)

    folder_prefix = chop(folder_bin, tail = length("_bin"))

    folder_output_light = folder_prefix * "_light"
    folder_output_results = folder_prefix * "_results"

    for folder in (folder_output_light, folder_output_results)
        if !isdir(folder)
            mkdir(folder)
        else
            @info "output folder exists: $folder"
        end
    end

    for filename_bin in readdir(folder_bin)

        if !endswith(filename_bin, ".bin")
            continue
        end

        stim_prefix = chop(filename_bin, tail = length(".bin"))

        folder_output_light_stim = joinpath(folder_output_light, stim_prefix)
        if isdir(folder_output_light_stim)
            @info "$folder_output_light_stim exists"
        else
            mkdir(folder_output_light_stim)
        end

        folder_output_results_stim = joinpath(folder_output_results, stim_prefix)
        if isdir(folder_output_results_stim)
            @info "$folder_output_results_stim exists"
        else
            mkdir(folder_output_results_stim)
        end

        filename_output_conduction = joinpath(
            folder_output_results_stim,
            "conduction.float32"
        )

        if isfile(filename_output_conduction)
            @info "$filename_output_conduction found, continue..."
            continue
        end

        filename_output_starts = joinpath(
            folder_output_light_stim,
            "indices_start.int32"
        )
        filename_output_times = joinpath(
            folder_output_light_stim,
            "times.float32"
        )

        if all(isfile.([filename_output_times, filename_output_starts]))
            @info "$filename_output_times and $filename_output_starts are exist"
            times = read_binary(filename_output_times, Float32)
            starts = read_binary(filename_output_starts, Int32)
        else
            msg = [
                "$stim_prefix is not complete",
                "\tcreating:",
                "\t$filename_output_starts",
                "\t$filename_output_times"
            ]
            @info join(msg, "\n")
            times, starts = parse_activation_times(joinpath(folder_bin, filename_bin))
            write(
                filename_output_times,
                convert.(Float32, times)
            )
            write(
                filename_output_starts,
                convert.(Int32, starts)
            )
        end

        conduction_percent = fill(NaN32, size(times))
        dt_max = 10.0

        calculate_conduction_map(
            adj_matrix,
            times,
            starts,
            dt_max = dt_max,
            output_prealloc = conduction_percent,
        )

        write(
            filename_output_conduction,
            convert.(Float32, conduction_percent),
        )

        @info "$filename_output_conduction is done!"

    end

end

function run(folder_root = ".", folder_with_indices = nothing)

    if isnothing(folder_with_indices)
        folder_with_indices = "/media/andrey/ssd2/WORK/HPL/Data/rheeda/"
    end

    adj_matrices = Dict{Int, SparseMatrixCSC}()

    for heart_id in (13, 15)
        folder = joinpath(folder_with_indices, "M$heart_id")
        adj_matrices[heart_id] = load_adj_matrix(folder)
    end

    for folder_bin in readdir(folder_root)

        if !isdir(folder_bin) 
            continue
        end

        if !endswith(folder_bin, "_bin") 
            continue
        end

        if occursin("M13", folder_bin)
            adj_matrix = adj_matrices[13]
        elseif occursin("M15", folder_bin)
            adj_matrix = adj_matrices[15]
        else
            @warn "invalid $(folder_bin)!"
            continue
        end

        @info "moving to $folder_bin"

        process_folder_bin(folder_bin, adj_matrix)

    end

end
            