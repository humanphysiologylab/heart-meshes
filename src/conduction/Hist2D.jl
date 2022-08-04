struct Hist2D

    bins_x
    bins_y
    counts
    sums

    function Hist2D(bins_x, bins_y)

        !issorted(bins_x) && error()
        !issorted(bins_y) && error()

        nx = length(bins_x) + 1
        ny = length(bins_y) + 1

        counts = zeros(Int, (nx, ny))
        sums = zeros(Float64, (nx, ny))

        new(bins_x, bins_y, counts, sums)

    end

end


function update_bin(x, y, value, H::Hist2D)

    ix = searchsortedfirst(H.bins_x, x)
    iy = searchsortedfirst(H.bins_y, y)

    H.counts[ix, iy] += 1
    H.sums[ix, iy] += value

    nothing

end
