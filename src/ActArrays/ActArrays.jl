include("../misc/create_stops.jl")


struct ActArray{T<:Integer}
    starts::Vector{T}
    stops::Vector{T}
    arrays::Dict{Symbol, Any}
    len::T
    index_type::DataType

    function ActArray(
        starts::Vector{T},
        arrays::Dict{Symbol,<:AbstractArray},
    ) where {T<:Integer}
        lengths = map(x -> size(x, 1), values(arrays))
        first_length = first(lengths)
        any(x -> x ≠ first_length, lengths) && error("arrays have different lengths")
        stops = create_stops(starts, first_length)
        new{T}(starts, stops, arrays, first_length, T)

    end

end


function Base.length(a::ActArray)
    length(a.starts)
end


function Base.getindex(a::ActArray, key::Symbol)
    a.arrays[key]
end


function Base.setindex!(a::ActArray, value::AbstractArray, key::Symbol)
    (size(value, 1) != a.len) && error("invalid array size")
    a.arrays[key] = value
end


function Base.reduce(a::ActArray, key::Symbol, op=sum)

    n = length(a.starts)
    result = map(1: n) do i
        get_subarray(a, i, key) |> op
    end

end


function slice_arrays(a::ActArray, i::Integer)
    Dict(k => v[i] for (k, v) in a.arrays)
end


function get_subarray(a::ActArray, i::Integer, key::Symbol)
    indices = a.starts[i] : a.stops[i]
    selectdim(a.arrays[key], 1, indices)
end


function get_subarrays(a::ActArray, i::Integer)
    result = Dict{Symbol, SubArray}()
    for (k, v) in a.arrays
        indices = a.starts[i] : a.stops[i]
        result[k] = @view v[indices]
    end
    result
end


function get_major_index(a::ActArray{T}, i::Integer) where T
    searchsortedlast(a.starts, i) |> T
end


function get_native_index(a::ActArray{T}, major_index::Integer, minor_index::Integer) where T
    minor_index < 1 && error("minor_index must be > 1")
    native_index = a.starts[major_index] + minor_index - 1 |> T
    native_index > a.stops[major_index] && error("minor_index is too big")
    native_index
end
