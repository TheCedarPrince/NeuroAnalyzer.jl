![neuroj](images/neuroj.png)

Welcome fellow researcher!

NeuroJ.jl is a [Julia](https://julialang.org) package for analyzing of EEG data. Future versions will also process MEG and NIRS data and use MRI data for source localization techniques. Also, various methods for modelling non-invasive brain stimulation protocols (tDCS/tACS/tRNS/tPCS/TMS) will be included.

NeuroJ.jl contains a set of separate (high-level) functions, it does not have a graphical user interface (although one could built it upon these). NeuroJ.jl functions can be combined into an analysis pipeline, i.e. a Julia script containing all steps of your analysis. This combined with processing power of Julia language and easiness of distributing calculations across computing cluster, will make NeuroJ.jl particularly useful for processing large amounts of research data.

NeuroJ.jl is a non-commercial project, developed for researchers in psychiatry, neurology and neuroscience.

Currently NeuroJ.jl is focused on resting-state EEG analysis. ERP and other type of analyses will be developed in future versions. The goal is to make a powerful, expandable and flexible environment for EEG/MEG/NIRS/NIBS processing workflows.

Every contribution (bug reports, fixes, new ideas, feature requests or additions, documentation improvements, etc.) to the project is highly welcomed.

## Installation

First, download [Julia](https://julialang.org/downloads/) 1.0 or later. 

There are two branches of NeuroJ.jl:
- [stable](https://codeberg.org/AdamWysokinski/NeuroJ.jl/src/branch/master): released once per month, recommended for research tasks
- [devel](https://codeberg.org/AdamWysokinski/NeuroJ.jl/src/branch/dev): a rolling release for NeuroJ.jl developers, not for production use

You can add NeuroJ.jl using Julia package manager, by typing:

```Julia
using Pkg
Pkg.update()
Pkg.add(url="https://codeberg.org/AdamWysokinski/Simpson.jl")
# for master branch:
Pkg.add(url="https://codeberg.org/AdamWysokinski/NeuroJ.jl#master")
# for development branch:
Pkg.add(url="https://codeberg.org/AdamWysokinski/NeuroJ.jl#devel")
# activate the package
using NeuroJ
# check if correctly installed
neuroj_version()
```

Another option is to initialize a new Julia environment for the package:
```shell
git clone https://codeberg.org/AdamWysokinski/NeuroJ.jl
cd NeuroJ.jl
```

Next, start Julia and do the following:
```Julia
using Pkg
Pkg.add(url="https://codeberg.org/AdamWysokinski/Simpson.jl")
Pkg.activate(".")
Pkg.resolve()
Pkg.instantiate()
Pkg.update()
# activate the package
using NeuroJ
# check if NeuroJ has been correctly installed
neuroj_version()
```

## Requirements

Julia version ≥ 1.7.0 is required. Julia [current stable version](https://julialang.org/downloads/#current_stable_release) is recommended, as NeuroJ.jl is only tested against it.

The following packages are required:
- CSV
- CubicSplines
- CUDA
- DataFrames
- Deconvolution
- Distances
- DSP
- FFTW
- FileIO
- FindPeaks1D
- Git
- GLM
- GLMakie
- HypothesisTests
- InformationMeasures
- Interpolations
- JLD2
- LinearAlgebra
- Loess
- MultivariateStats
- Pkg
- Plots
- Polynomials
- ScatteredInterpolation
- [Simpson](https://codeberg.org/AdamWysokinski/Simpson.jl)
- StatsFuns
- StatsKit
- StatsModels
- StatsPlots
- Wavelets

Wherever possible, NeuroJ.jl will be 100% Julia based. If required, external open-source applications may be called for certain tasks.

## General remarks

NeuroJ.jl functions operate on NeuroJ objects.

For EEG this is NeuroJ.EEG (EEG metadata header + time + epoched signals + components). EEG signal is `Array{Float64, 3}` (channels × signals × epochs). If epochs are not defined, the whole signal is an epoch, i.e. there is always at least one epoch.

Functions name prefix:
- `eeg_` functions taking EEG object as an argument
- `eeg_plot_` plotting functions

There are also low level functions operating on single-/multi-channel signal vector/matrix/array (`s_` and `s2_`).

The majority of `eeg_` functions will process all channels and epochs of the input EEG object. To process individual channels/epochs, you need to extract them from the EEG object first (`eeg_keep_epoch()`, `eeg_keep_channel()` to process as NeuroJ.EEG object or `eeg_extract_channel()`, `eeg_extract_epoch()` to process as multi-channel array).

`eeg_` functions use named arguments for all arguments other than input signal(s), e.g. `eeg_delete_epoch!(my_eeg, epoch=12)`.

EEG object (headers + time + epochs time + EEG signal + (optional) components) is stored in the EEG structure:
```julia
mutable struct EEG
    eeg_header::Dict
    eeg_time::Vector{Float64}
    eeg_epochs_time::Vector{Float64}
    eeg_signals::Array{Float64, 3}
    eeg_components::Vector{Any}
end
```

Many `eeg_` functions have a mutator variant (e.g. `eeg_delete_epoch!()`). These functions modifies the input EEG object in-place, e.g. you may use `eeg_delete_channel!(my_eeg, channel=1)` instead of `my_eeg = eeg_delete_channel(my_eeg, channel=1)`.

For some low-level operations (e.g. FFT and IFFT) CUDA acceleration is used automatically if compatible NVIDIA card and drivers are installed. To disable CUDA, set the variable `use_cuda` to false in the NeurojJ.jl file.

## Documentation

Complete NeuroJ.jl documentation is available [here](https://codeberg.org/AdamWysokinski/NeuroJ.jl/src/master/Documentation.md).

Tutorial introducing NeuroJ.jl functions is [here](https://codeberg.org/AdamWysokinski/NeuroJ.jl/src/master/Tutorial.md).

Changelog is [here](https://codeberg.org/AdamWysokinski/NeuroJ.jl/src/master/Changelog.md).

## Plugins (extensions)

Plugins are git repositories, default location is `~/Documents/NeuroJ/plugins`. Each plugin must be in a separate folder, in `src/` subdirectory. To modify the plugins path, set the variable `plugins_path` in the NeurojJ.jl file.

Run `neuroj_reload_plugins()` to refresh plugins.

```julia
neuroj_plugins_reload()
neuroj_plugins_list()
neuroj_plugins_add()
neuroj_plugins_remove()
neuroj_plugins_update()
```

## Known bugs

- ignore non-eeg channels for processing, analysis and plotting; currently NeuroJ does not analyze/process/plot EEG containing non-eeg channels, you have to manually extract these to another EEG object 
- check for wrong epoch number in plots

## What's next

The lists below are not complete and not in any particular order.

General:
- further performance optimizations
- Pluto/Interact interface

EEG:
- analysis, plots: brain topography
- analysis, plots: connectome graph
- analysis, plots: PSD plot line slope over frequencies (adjusted power)
- analysis: amplitude turbulence
- analysis: ANOVA test for segments
- analysis: beamforming, leakage correction
- analysis: CDR: current density reconstruction (GCDR, CDR spectrum), activity within specified band
- analysis: continuous wavelet transform (using ContinuousWavelets.jl)
- analysis: cross-frequency phase-amplitude coupling
- analysis: dipoles
- analysis: EEG bands: medial vs left vs right channels within each band
- analysis: FOOOF
- analysis: Hilbert envelope computation → oscillatory envelopes → correlations → connectivity map
- analysis: ML/DL
- analysis: multitaper: generate frequency-band-selective tapers to increase sensitivity, varying the length of time segments, varying the number of tapers and central frequency of the spectral representation of the tapers
- analysis: non-phase-locked part of the signal (= total - phase-locked)
- analysis: phase synchronization measurements: weighted PLI, phase coherence (PC), imaginary component of coherency (IC)
- analysis: phase-amplitude cross-frequency coupling (PAC)
- analysis: power envelope connectivity
- analysis: probability maps: the local likelihood of belonging to a given population
- analysis: signals/PSD comparison
- analysis: source localization
- analysis: tensor and other statistical maps (magnitude and direction, probabilistic regions, regions of high vs low variability)
- analysis: wavelets
- edit: add/delete markers, view markers on plots
- edit: automated channel rejection
- edit: automated epoch rejection
- edit: automated cleaning of artifacts
- edit: automated DC line cleaning
- edit: bad channel marking / rejection
- edit: bad epoch marking / rejection
- edit: create EEG object
- edit: events markers
- edit: epoch by event markers
- edit: automated epoching (by markers)
- edit: insert channel
- edit: replace channel
- edit: merge EEG objects
- edit: virtual channels (e.g. F3 + 2.5 × Fp1 - 3 × Cz / 4)
- edit: add epochs flag to mark if signal has been split into epochs, use it for plotting
- edit: locs rotate
- edit: concatenate many EEG files into larger one
- io: ipmcomort from CSV
- io: import from EDF+, BDF and other formats
- misc: reports in .md format
- misc: update tutorial.md
- plots: 3d head/brain plots
- plots: add user-defined voltage scale for eeg signal plots
- plots: asymmetric color bars to highlight increase/decrease in activity in topoplots
- plots: coherence spectrum (y: relative amplitude, x: frequencies)
- plots: complex kernel convolution: plot magnitude and phase of the convoluted signal
- plots: ITPC topoplot
- plots: plot two EEG one over another for comparison
- plots: PSD of multi channels signal like eeg_plot_signal(), using normalized power (a.u.)
- plots: ERP amplitude plots at electrode locations (eeg_plot_erp_topomap())
- plots: topoplot colorbar: :lin, -log, :-log10, :negative, :positive
- plots: topoplot of amplitude differences between channel and the rest of the scalp
- plots: topoplot of phase differences (-πrad..+πrad) between channel and the rest of the scalp
- plots: topoplot of which electrode at a given time exhibits statistically significant difference between two signals
- process: custom reference (e.g. bipolar longitudinal/horizontal)
- process: detect artifacts using TKEO
- process: more re-referencing methods: spherical Laplacian, REST
- process: set baseline
- trial: multi-trial data

- ERPs
- visual / auditory stimuli presentation module (via Raspberry Pi)
- use eyetracker to detect eye movement and blink artifacts
- use 3D scanner for head mesh, e.g. [Polhemus](https://polhemus.com/scanning-digitizing/fastscan)
- use 3D tracker for electrode locations, e.g. [Polhemus](https://polhemus.com/motion-tracking/all-trackers/g4)
- AMD ROCm acceleration
- IEEG/ECoG/MEG/SEEG

NIRS
- import and process data

MRI
- import and process data for EEG source localization

NSTIM
- TES modelling
- removal of TES artifacts from EEG

## Contributors

If you've contributed, add your name below!

[Adam Wysokiński](mailto:adam.wysokinski@umed.lodz.pl)

![umed](images/umed.jpg)

## License

The program is licensed under [GPL-2.0-only](LICENSE).