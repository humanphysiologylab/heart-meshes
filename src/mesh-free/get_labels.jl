function get_labels(filename::String)

    f = splitpath(filename) |> last
    f = chop(f, head=0, tail=length(".csv"))
    map(split(f, "-")) do x
        tail = 0
        head = isletter(x[1]) ? 1 : 0
        parse(Int, chop(x; head, tail))
    end
end
