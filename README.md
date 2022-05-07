# Required Inputs
- `tetra.int32`
- `points.float32`
- folder of `times.tsv`

# Steps

## 1. Parse geometry
*~ 10 minutes*
```shell
julia \
    --project=. \
    src/pipeline/parse_geometry.jl \
    --tetra "/Users/andrey/Work/HPL/data/M13/M13_IRC_tetra.int32" \
    --points "/Volumes/samsung-T5/HPL/Rheeda/geometry/M13/points.float32" \
    --output "./tmp"
```

Results in this structure:
```
tmp
├── adj-elements
│   ├── I.int32
│   └── J.int32
├── adj-vertices
│   ├── I.int32
│   ├── J.int32
│   └── V.float32
├── points.float32
└── tetra.int32
```

## 2. Parse times
*~ 10 sec per file*

Works recursevely.
Result will have the same folder structure as the input folder.

```shell
julia \
    --project=. \
    --threads auto \
    src/pipeline/parse_times.jl \
    --folder-times "/Volumes/samsung-T5/HPL/Rheeda/tars/G1_M13" \
    --ext ".dat" \
    --points "./tmp/points.float32" \
    --output "./tmp"
```

## 3. Collect conduction
*~ 10 sec per file*

Works recursevely.
Result will be saved in `folder-times`.

```shell
julia \
    --project=. \
    --threads auto \
    src/pipeline/collect_conduction.jl \
    --folder-times "./tmp/times/" \
    --adj-vertices "./tmp/adj-vertices"
```

## 4. Connected components

```shell
julia  \
    --project=. \
    --threads auto \
    src/pipeline/connected_component.jl \
    --folder-times "./tmp/times/" \
    --adj-vertices "./tmp/adj-vertices"
```

## 5. Collect trajectories

```shell
julia  \
    --project=. \
    --threads auto \
    src/pipeline/collect_trajectories.jl \
    --folder-times "./tmp/times/" \
    --folder-geometry "./tmp"
```
