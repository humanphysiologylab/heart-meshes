function convert_dat(filename_input, filename_output)

    f_output = open(filename_output, "w")

    FloatType = Float32
    dlm = "\t"

    for line in eachline(filename_input)
        for s in split(line, dlm)
            value = parse(FloatType, s)
            write(f_output, value)
        end
    end

    close(f_output)

end


function convert_folder(folder_input, folder_output)

    if !isdir(folder_output)
        mkdir(folder_output)
    end

    ext_dat = ".dat"
    ext_bin = ".bin"

    for (dirpath, dirnames, filenames) in walkdir(folder_input)
        @assert length(filenames) <= 1

        for filename in filenames
            if !endswith(filename, ext_dat)
                continue
            end

            filename_full = joinpath(dirpath, filename)

            pacing_site = splitpath(dirpath)[end]
            filename_output = joinpath(folder_output, pacing_site * ext_bin)

            if isfile(filename_output)
                println(" -- FOUND: $filename_output")
                continue
            end

            @info "processing $filename_output ..."

            convert_dat(filename_full, filename_output)

        end
    end
end


function convert_rheeda(folder = ".")

    ext_tar_gz = ".tar.gz"

    for filename in readdir(folder)
        if !endswith(filename, ext_tar_gz)
            continue
        end

        archive_name = joinpath(folder, filename)

        folder_input = chop(archive_name, tail = length(ext_tar_gz))
        folder_output = folder_input * "_bin"

        if isdir(folder_output)
            @info "omitting $folder_output"
            continue
        end

        cmd = `tar -xf $archive_name`
        @info cmd
        run(cmd)

        @info "$folder_input -> $folder_output"
        convert_folder(folder_input, folder_output)

        cmd = `rm -r $folder_input`
        @info cmd
        run(cmd)

    end

end
