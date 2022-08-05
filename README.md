# Required Inputs
- `tetra.int32`
- `points.float32`
- folder of `times.tsv`

Ask Andrey (pikunov@phystech.edu) for `data-sample`.

# Steps

## 0. Instantiate 

Install all the dependencies.

```shell
cd src/pipeline  
# and stay here for all next steps

julia \
    --project=./env \
    instantiate.jl
```

## 1. Parse geometry
*< 10 minutes*

From now on, for every step there is a short help. For example:
```shell
julia \
    --project=./env \
    parse_geometry.jl \
    --help  # <- this flag helps
```

Needs to run only once for every heart geometry.
```shell
julia \
    --project=./env \
    parse_geometry.jl \
    --tetra "data-sample/M13_IRC_tetra.int32" \
    --points "data-sample/M13_IRC_3Dpoints.float32" \
    --output "./output"
```

Results in this structure:
```
output
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
*< 10 sec per file*

Works recursevely.
Result will have the same folder structure as the input folder.
The root folder will be named `times/`.

Input folder (`some-folder`) can be like that:
```
some-folder
├── S00
│   └── vm_act-thresh.dat
├── S01
│   └── vm_act-thresh.dat
└── foo-bar
    ├── 42
    │   └── some.dat
    └── 42-copy
        └── another.dat
```
It's important to have only one `times`-file per subfolder. All `times`-files MUST be valid `tsv`-files inside.

The is `--overwrite` flag for obvious purpose. Next commands have this flag too.

```shell
julia \
    --project=./env \
    --threads auto \
    parse_times.jl \
    --folder-times "data-sample/activation-times/" \
    --ext ".dat" \
    --points "./output/points.float32" \
    --output "./output"
```

Results in:
```
output/times
├── S00
│   ├── starts.int32
│   └── times.float32
├── S01
│   ├── starts.int32
│   └── times.float32
└── foo-bar
    ├── 42
    │   ├── starts.int32
    │   └── times.float32
    └── 42-copy
        ├── starts.int32
        └── times.float32
```

## Important!
All next commands will save results into this newly created `times/` folder.

## 3. Collect conduction
*< 10 sec per file*

```shell
julia \
    --project=./env \
    --threads auto \
    collect_conduction.jl \
    --folder-times "./output/times/" \
    --adj-vertices "./output/adj-vertices"
```

Creates `conduction.float32`.


## 4. Connected components

```shell
julia \
    --project=./env \
    --threads auto \
    connected_component.jl \
    --folder-times "./output/times/" \
    --adj-vertices "./output/adj-vertices"
```

Creates `meta.csv`.

## 5. Collect trajectories

I recommend to run this script at least two times.
This is because of some steps of the algorithm's with stochasticity inside.
In rare cases some rotors can be ommited.

```shell
julia \
    --project=./env \
    --threads auto \
    collect_trajectories.jl \
    --folder-times "./output/times/" \
    --folder-geometry "./output"
```

Creates `trajectories/` folders and populates them if any rotors found.

## 6. Predict rotors

This final step is in [different repository](https://github.com/humanphysiologylab/nn-rotor/tree/master) (specifically, [this notebook](https://github.com/humanphysiologylab/nn-rotor/blob/master/notebooks/017-Predict-pipeline.ipynb)).
