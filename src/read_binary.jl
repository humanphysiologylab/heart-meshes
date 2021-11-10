function read_binary(filename::String, T, shape = nothing)
    array = collect(reinterpret(T, read(filename)))
    if !isnothing(shape)
        array = reshape(array, shape)
    end
    return array
end
