using Flux: DataLoader

include("load_data.jl")

##

folder_dataset = "/Users/andrey/Work/HPL/projects/Rheeda/rotor-dataset"

filenames = readdir(folder_dataset, join=false)
mask_test = @. occursin("M13-G2", filenames) | occursin("M15-G3", filenames)

filenames_train = filenames[.!mask_test]
filenames_test = filenames[mask_test]

##

window_size = 128
step = window_size ÷ 4

X_train, Y_train = load_data(filenames_train, folder_dataset; window_size, step)
X_test, Y_test = load_data(filenames_test, folder_dataset; window_size, step)

##

using Flux.Losses: label_smoothing
Y_train_smooth = label_smoothing(Y_train, 0.1)

##

# train_loader = DataLoader((X_train, Y_train_smooth), batchsize=32, shuffle=true)
train_loader = DataLoader((X_train, Y_train), batchsize=32, shuffle=true)
