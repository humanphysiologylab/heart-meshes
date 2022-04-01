using BSON: @save, @load

folder_model = "/Users/andrey/Work/HPL/projects/rheeda/heart-meshes/flux-models/"
filename_model = joinpath(folder_model, "model-latest.bson")

##

@save filename_model model_conv

##

@load filename_model model_conv
