__precompile__()

module NeuroAnalyzer

if VERSION < v"1.7.0"
    @error("This version of NeuroAnalyzer requires Julia 1.7.0 or above.")
end

const na_ver = v"0.23.3"

# initialize preferences
use_cuda = nothing
progress_bar = nothing
plugins_path = nothing
verbose = nothing

using ColorSchemes
using CSV
using CubicSplines
using CUDA
using Dates
using DataFrames
using Deconvolution
using DICOM
using Distances
using DSP
using FFTW
using FileIO
using FindPeaks1D
using FourierTools
using GeometryBasics
using Git
using GLM
using GLMakie
using HypothesisTests
using InformationMeasures
using Interpolations
using Jacobi
using JLD2
using LinearAlgebra
using Loess
using MAT
using MultivariateStats
using Pkg
using Plots
using Plots.PlotMeasures
using Polynomials
using Preferences
using ProgressMeter
using Random
using SavitzkyGolay
using ScatteredInterpolation
using Simpson
using StatsFuns
using StatsKit
using StatsModels
using StatsPlots
using TOML
using Wavelets
using WaveletsExt
using ContinuousWavelets

mutable struct HEADER
    subject::Dict
    recording::Dict
    experiment::Dict
    markers::Bool
    components::Vector{Symbol}
    locations::Bool
    history::Vector{String}
end

mutable struct NEURO
    header::NeuroAnalyzer.HEADER
    time_pts::Vector{Float64}
    epoch_time::Vector{Float64}
    data::Union{Array{<:Number, 1}, Array{<:Number, 2}, Array{<:Number, 3}}
    components::Vector{Any}
    events::DataFrame
    locs::DataFrame
end

mutable struct EEG
    eeg_header::Dict
    eeg_time::Vector{Float64}
    eeg_epoch_time::Vector{Float64}
    eeg_signals::Array{Float64, 3}
    eeg_components::Vector{Any}
    eeg_markers::DataFrame
    eeg_locs::DataFrame
end

mutable struct MEG
    meg_header::Dict
    meg_time::Vector{Float64}
    meg_epoch_time::Vector{Float64}
    meg_signals::Array{Float64, 3}
    meg_components::Vector{Any}
    meg_markers::DataFrame
    meg_locs::DataFrame
end

mutable struct STUDY
    study_header::Dict{Symbol, Any}
    study_eeg::Vector{NeuroAnalyzer.NEURO}
    study_group::Vector{Symbol}
end

mutable struct DIPOLE
    loc::Tuple{Real, Real, Real}
end

FFTW.set_provider!("mkl")
FFTW.set_num_threads(Sys.CPU_THREADS)
BLAS.set_num_threads(Sys.CPU_THREADS)

# NA functions
include("na.jl")
export na_info
export na_plugins_reload
export na_plugins_list
export na_plugins_remove
export na_plugins_install
export na_plugins_update
export na_set_use_cuda
export na_set_progress_bar
export na_set_plugins_path
export na_set_prefs
export na_set_verbose
export na_version

function __init__()

    @info "NeuroAnalyzer v$na_ver"

    # load preferences
    @info "Loading preferences..."
    if Sys.isunix() || Sys.isapple()
        def_plugins_path = "$(homedir())/NeuroAnalyzer/plugins/"
    elseif Sys.iswindows()
        def_plugins_path = "$(homedir())\\NeuroAnalyzer\\plugins\\"
    end
    global use_cuda = @load_preference("use_cuda", false)
    global progress_bar = @load_preference("progress_bar", true)
    global plugins_path = @load_preference("plugins_path", def_plugins_path)
    global verbose = @load_preference("verbose", true)
    na_set_prefs(use_cuda=use_cuda, plugins_path=plugins_path, progress_bar=progress_bar, verbose=verbose)

    # load plugins
    @info "Loading plugins..."
    isdir(plugins_path) || mkdir(plugins_path)
    na_plugins_reload()

end

# internal functions are not available outside NA
include("internal/reflect_chop.jl")
include("internal/create_header.jl")
include("internal/io.jl")
include("internal/check.jl")
include("internal/select.jl")
include("internal/len.jl")
include("internal/plots.jl")
include("internal/draw_head.jl")
include("internal/fir_response.jl")
include("internal/make_epochs.jl")
include("internal/locs.jl")
include("internal/interpolate.jl")
include("internal/fiff.jl")
include("internal/gpu.jl")
include("internal/time.jl")
include("internal/labels.jl")
include("internal/markers.jl")
include("internal/labeled_matrix.jl")
include("internal/ml.jl")
include("internal/ch_idx.jl")
include("internal/map_channels.jl")
include("internal/misc.jl")
include("internal/tester.jl")

# load sub-modules
include("low_level/locs_convert.jl")
include("low_level/normalize.jl")

include("analyze/total_power.jl")
include("analyze/band_power.jl")
include("analyze/covm.jl")
include("analyze/corm.jl")

include("io/import_edf.jl")
include("io/import_locs.jl")
include("io/import_fiff.jl")
include("io/fiff.jl")

include("locs/flip.jl")
include("locs/convert.jl")
include("locs/scale.jl")
include("locs/rotate.jl")
include("locs/swap.jl")

include("plots/misc.jl")
include("plots/plot_connections.jl")
include("plots/plot_dipole3d.jl")
include("plots/plot_electrodes.jl")
include("plots/plot_erp.jl")
include("plots/plot_filter_response.jl")
include("plots/plot_psd.jl")
include("plots/plot_save.jl")
include("plots/plot_signal.jl")
include("plots/plot_spectrogram.jl")
include("plots/plot_topo.jl")
include("plots/plot_weights.jl")

include("statistics/dprime.jl")
include("statistics/effsize.jl")
include("statistics/hildebrand_rule.jl")
include("statistics/jaccard_similarity.jl")
include("statistics/linreg.jl")
include("statistics/means.jl")
include("statistics/misc.jl")
include("statistics/ml.jl")
include("statistics/norminv.jl")
include("statistics/outliers.jl")
include("statistics/pred_int.jl")
include("statistics/ranks.jl")
include("statistics/res_norm.jl")
include("statistics/s2cmp.jl")
include("statistics/s2cor.jl")
include("statistics/segments.jl")
include("statistics/sem_diff.jl")
include("utils/components.jl")
include("utils/info.jl")

include("study/create.jl")
include("study/info.jl")

include("stim/tes.jl")
include("stim/ect.jl")

include("low_level.jl")
export linspace
export logspace
export m_pad0
export cmax
export cmin
export vsearch
export generate_window
export fft0
export fft2
export ifft0
export nextpow2
export vsplit
export s_rms
export generate_sine
export generate_csine
export s_freqs
export m_sortperm
export m_sort
export pad0
export pad2
export hz2rads
export rads2hz
export generate_sinc
export generate_morlet
export generate_gaussian
export tuple_order
export s2_rmse
export m_norm
export s_dft
export s_msci95
export s2_mean
export s2_difference
export s_acov
export s2_xcov
export s_spectrum
export s_taper
export s_detrend
export s_demean
export s_add_noise
export s_resample
export s_invert_polarity
export s_derivative
export s_tconv
export s_filter
export s_filter_create
export s_filter_apply
export s_psd
export s_stationarity_hilbert
export s_stationarity_mean
export s_stationarity_var
export s_trim
export s2_mi
export s_entropy
export s_negentropy
export s_average
export s2_average
export s2_tcoherence
export s_pca
export s_pca_reconstruct
export s_fconv
export s_ica
export s_ica_reconstruct
export s_spectrogram
export s_detect_channel_flat
export s_snr
export s_snr2
export s_findpeaks
export s_wdenoise
export s2_ispc
export s_itpc
export s2_pli
export s2_ged
export s_frqinst
export s_hspectrum
export t2f
export f2t
export s_wspectrogram
export s_fftdenoise
export s_gfilter
export s_ghspectrogram
export s_tkeo
export s_mwpsd
export a2_cmp
export s_fcoherence
export s2_fcoherence
export a2_l1
export a2_l2
export s_cums
export s_gfp
export s_gfp_norm
export s2_diss
export generate_morlet_fwhm
export f_nearest
export s_band_mpower
export s_rel_psd
export s_wbp
export s_cbp
export s_specseg
export s_denoise_wien
export s2_cps
export s2_phdiff
export s_phases
export s_cwtspectrogram
export s_dwt
export s_idwt
export normalize_invroot
export s_cwt
export s_icwt
export t2s
export s2t
export generate_noise

include("eeg_io.jl")
export eeg_load
export eeg_save
export eeg_load_electrodes
export eeg_load_electrodes!
export eeg_save_electrodes
export eeg_add_electrodes
export eeg_add_electrodes!
export eeg_import
export eeg_import_bdf
export eeg_import_digitrack
export eeg_import_bv
export eeg_import_alice4
export eeg_import_csv
export eeg_import_set
export eeg_export_csv

include("eeg_edit.jl")
export eeg_copy
export eeg_delete_channel
export eeg_delete_channel!
export eeg_keep_channel
export eeg_keep_channel!
export eeg_get_channel
export eeg_rename_channel
export eeg_rename_channel!
export eeg_extract_channel
export eeg_epoch
export eeg_epoch!
export eeg_erp
export eeg_erp!
export eeg_extract_epoch
export eeg_trim
export eeg_trim!
export eeg_edit_header
export eeg_edit_header!
export eeg_show_header
export eeg_delete_epoch
export eeg_delete_epoch!
export eeg_keep_epoch
export eeg_keep_epoch!
export eeg_detect_bad
export eeg_add_labels
export eeg_add_labels!
export eeg_edit_channel
export eeg_edit_channel!
export eeg_keep_channel_type
export eeg_keep_channel_type!
export eeg_view_note
export eeg_epoch_time
export eeg_epoch_time!
export eeg_add_note
export eeg_add_note!
export eeg_delete_note
export eeg_delete_note!
export eeg_replace_channel
export eeg_replace_channel!
export eeg_plinterpolate_channel
export eeg_plinterpolate_channel!
export eeg_channel_type
export eeg_channel_type!
export eeg_edit_electrode
export eeg_edit_electrode!
export eeg_electrode_loc
export eeg_view_marker
export eeg_delete_marker
export eeg_delete_marker!
export eeg_add_marker
export eeg_add_marker!
export eeg_get_channel_bytype
export eeg_vch
export eeg_edit_marker
export eeg_edit_marker!
export eeg_channel_cluster
export eeg_lrinterpolate_channel
export eeg_lrinterpolate_channel!
export eeg_reflect
export eeg_reflect!
export eeg_chop
export eeg_chop!
export eeg_extract_data
export eeg_extract_time
export eeg_extract_etime

include("eeg_process.jl")
export eeg_reference_ch
export eeg_reference_ch!
export eeg_reference_car
export eeg_reference_car!
export eeg_reference_a
export eeg_reference_a!
export eeg_reference_m
export eeg_reference_m!
export eeg_derivative
export eeg_derivative!
export eeg_detrend
export eeg_detrend!
export eeg_taper
export eeg_taper!
export eeg_demean
export eeg_demean!
export eeg_normalize
export eeg_normalize!
export eeg_add_noise
export eeg_add_noise!
export eeg_filter
export eeg_filter!
export eeg_pca
export eeg_pca_reconstruct
export eeg_pca_reconstruct!
export eeg_ica
export eeg_ica_reconstruct
export eeg_ica_reconstruct!
export eeg_average
export eeg_average!
export eeg_average
export eeg_invert_polarity
export eeg_invert_polarity!
export eeg_resample
export eeg_resample!
export eeg_upsample
export eeg_upsample!
export eeg_downsample
export eeg_downsample!
export eeg_wdenoise
export eeg_wdenoise!
export eeg_fftdenoise
export eeg_fftdenoise!
export eeg_reference_plap
export eeg_reference_plap!
export eeg_zero
export eeg_zero!
export eeg_wbp
export eeg_wbp!
export eeg_cbp
export eeg_cbp!
export eeg_denoise_wien
export eeg_denoise_wien!
export eeg_scale
export eeg_scale!
export eeg_gfilter
export eeg_slaplacian
export eeg_slaplacian!

include("eeg_analyze.jl")
export xcov
export psd
export stationarity
export mi
export mi
export entropy
export negentropy
export band
export tcoherence
export freqs
export difference
export channel_pick
export epoch_stats
export spectrogram
export spectrum
export s2t
export t2s
export channel_stats
export snr
export standardize
export standardize!
export fconv
export tconv
export dft
export mean
export msci95
export difference
export acov
export tenv
export tenv_mean
export tenv_median
export penv
export penv_mean
export penv_median
export senv
export senv_mean
export senv_median
export ispc
export itpc
export pli
export ispc_m
export ec
export ged
export frqinst
export itpc_s
export tkeo
export mwpsd
export fcoherence
export vartest
export band_mpower
export rel_psd
export fbsplit
export chdiff
export cps
export phdiff
export ampdiff
export dwt
export cwt
export psdslope
export henv
export henv_mean
export henv_median
export apply
export erp_peaks
export bands_dwt

end # NeuroAnalyzer