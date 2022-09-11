include("../pipeline/load_arrays.jl")

##

function calculate_p_wb(a, t_max=2500., n_stim=12)
    n = length(a.starts)
    result = map(1: n) do i
        c = get_subarray(a, i, :conduction) 
        t = get_subarray(a, i, :times)
        mask = t .< t_max
        p_wb = sum(c[mask] .< 1) / n_stim
    end
end

##

heart = 15
group = 1

stims = "05", "15" # "02"
# S05 (roof RA on RAA)
# S15 (roof LA on LAA)

##

folder_wb = joinpath(
    "/Volumes/samsung-T5/HPL/Rheeda/pipeline",
    "M$heart",
    "G$group"
)

##

for stim in stims

    folder_stim = joinpath(
        folder_wb,
        "S$stim"
    )

    a = load_arrays(folder_stim)

    p_wb = calculate_p_wb(a)
    p_wb = Float32.(p_wb)
    clamp!(p_wb, 0, 1)

    filename_save = joinpath(
        "/Volumes/samsung-T5/HPL/Rheeda/wavebreaks-stims",
        "$(heart)-$(group)-$(stim).float32"
    )

    open(filename_save, "w") do f
        write(f, p_wb)
    end

    println(filename_save)

end
