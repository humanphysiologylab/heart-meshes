function terminate(cb, threshold = 1.)
    !isfull(cb) && return false
    n = capacity(cb)
    head = mean(cb[1: n ÷ 2])
    tail = mean(cb[n ÷ 2: end])
    return head - tail < threshold
end
