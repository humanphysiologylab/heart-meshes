using DataFrames, CSV
using Flux: DataLoader

include("../utils/split_train_test.jl")
include("../utils/load_train_data.jl")

##

folder_dataset = "/Users/andrey/Work/HPL/projects/rheeda/rotor-dataset"

filenames = readdir(folder_dataset, join=false)
mask_test = occursin.("M13-G2", filenames) .| occursin.("M15-G3", filenames)

filenames_train = filenames[.!mask_test]
filenames_test = filenames[mask_test]

let

    X, Y = load_train_data(filenames_train, folder_dataset; L=10 * 160, step=10 * 160 ÷ 3)
    global train_loader = DataLoader((X, Y), batchsize=32, shuffle=true)

    X, Y = load_train_data_zip(filenames_test, folder_dataset)
    global test_loader = zip(X, Y)

end

@info "dataset is loaded"
