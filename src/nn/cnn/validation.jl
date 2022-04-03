using DataFrames, CSV
using Statistics
using Flux: DataLoader

include("split_train_test.jl")
include("load_train_data.jl")

##

folder_validation = "/Users/andrey/Work/HPL/data/rotors-marked-up-v2"
folder_validation = "/Users/andrey/Work/HPL/data/rotors-predict-v3"

filenames = readdir(folder_validation, join=false)
# filenames_test, filenames_train = split_train_test(filenames, 0.33)

mask_test = occursin.("M13-G2", filenames) .| occursin.("M15-G3", filenames)

filenames_train = filenames[.!mask_test]
filenames_test = filenames[mask_test]

##

let

    X, Y = load_train_data(filenames_train, folder_validation; L=10 * 160, step=10 * 160 ÷ 3)
    global train_loader = DataLoader((X, Y), batchsize=32, shuffle=true)

    X, Y = load_train_data_zip(filenames_test, folder_validation)
    global test_loader = zip(X, Y)

end
##

weight_rotor = [y for (x, y) in train_loader] |> Iterators.flatten |> mean

##
