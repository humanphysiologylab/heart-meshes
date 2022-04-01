using DataFrames, CSV
using Statistics

include("split_train_test.jl")
include("load_train_data.jl")

##

folder_validation = "/Users/andrey/Work/HPL/data/rotors-marked-up-v2"

filenames = readdir(folder_validation, join=false)
filenames_test, filenames_train = split_train_test(filenames)

##

train_loader = zip(load_train_data(filenames_train, folder_validation)...)
test_loader = zip(load_train_data(filenames_test, folder_validation)...)

##

weight_rotor = [y for (x, y) in train_loader] |> Iterators.flatten |> mean

##
