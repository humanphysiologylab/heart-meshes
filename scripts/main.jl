using UnPack: @unpack
using NearestNeighbors: BallTree

include("load_src.jl")
include("load_files.jl")

## load files
heart_id = 13
folder = joinpath("/media/andrey/ssd2/WORK/HPL/Data/rheeda/", "M$heart_id")

@unpack points, tetra, region_points, S = load_files(folder)

axes_fibrosis = [1, 3] # map(x -> region_map[x], [32, 128])
mask_fibrosis = reduce(.|, eachrow(region_points[axes_fibrosis, :]))
indices_fibrosis = findall(mask_fibrosis)

## search tree
btree = BallTree(points; leafsize = 30, reorder = false)

## try find_area
index_center = 450_000
radius = 1e4

k, v = find_area(index_center, radius, points, S, btree)

argsort = sortperm(v)
v = v[argsort]
k = k[argsort]
