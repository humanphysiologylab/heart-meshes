function find_folders_times(folder_times)

    filenames_required = ("times.float32", "starts.int32")

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
