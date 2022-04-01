using Statistics: mean


function accuracy_part(classes_true, classes_pred; balanced=true)
    num = 0.
    denom = 0.
    classes = unique(classes_true)

    for class in classes
        mask = classes_true .== class
        n = sum(classes_true[mask] .== classes_pred[mask])
        sum_mask = sum(mask)
        w = balanced ? 1. / sum_mask : 1.
        num += w * n
        denom += w * sum_mask
    end

    num, denom

end

function accuracy(classes_true, classes_pred; balanced=true)
    num, denom = accuracy_part(classes_true, classes_pred; balanced)
    num / denom
end

a = [0, 0, 0, 0, 0, 0, 1, 1]
b = [0, 0, 0, 1, 1, 1, 0, 1]

@assert accuracy(a, a; balanced=false) == 1
@assert accuracy(a, 1 .- a; balanced=false) == 0

@assert accuracy(a, a; balanced=true) == 1
@assert accuracy(a, 1 .- a; balanced=true) == 0

@assert accuracy(a, b; balanced=false) ≈ 0.5
@assert accuracy(a, b; balanced=true) ≈ 0.5

a = [0, 0, 0, 0, 0, 0, 0, 1]
b = [0, 0, 0, 0, 0, 0, 0, 0]

@assert accuracy(a, b; balanced=false) ≈ 1 - 1 / 8
@assert accuracy(a, b; balanced=true) ≈ 0.5

;
