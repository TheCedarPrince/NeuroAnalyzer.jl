module NeuroJ

using ColorSchemes
using CSV
using CubicSplines
using DataFrames
using Distances
using DSP
using FFTW
using FindPeaks1D
using GLM
using HypothesisTests
using InformationMeasures
using Interpolations
using JLD2
using LinearAlgebra
using Loess
using MultivariateStats
using Pkg
using Plots
using Plots.PlotMeasures
using Polynomials
using ScatteredInterpolation
using Simpson
using StatsFuns
using StatsKit
using StatsModels
using StatsPlots
using Wavelets

mutable struct EEG
    eeg_header::Dict
    eeg_time::Vector{Float64}
    eeg_epochs_time::Matrix{Float64}
    eeg_signals::Array{Float64, 3}
    eeg_components::Vector{Any}
end

if VERSION < v"1.0.0"
    @warn("This version of NeuroJ requires Julia 1.0 or above.")
end

include("neuroj.jl")
export neuroj_plugins_reload
export neuroj_plugins_list
export neuroj_version
neuroj_plugins_reload()

include("low_level.jl")
export linspace
export logspace
export m_pad0
export cmax
export cmin
export vsearch
export cart2pol
export pol2cart
export sph2cart
export generate_window
export fft0
export ifft0
export nextpow2
export vsplit
export s_rms
export generate_sine
export s_freqs
export m_sortperm
export m_sort
export pad0
export hz2rads
export rads2hz
export generate_sinc
export generate_morlet
export generate_gaussian
export tuple_order
export s2_rmse
export m_norm
export s_cov
export s2_cov
export s_dft
export s_msci95
export s2_mean
export s2_difference
export s_acov
export s_xcov
export s_spectrum
export s_total_power
export s_band_power
export s_taper
export s_detrend
export s_demean
export s_normalize_zscore
export s_normalize_minmax
export s_normalize_max
export s_normalize_log
export s_add_noise
export s_resample
export s_invert_polarity
export s_derivative
export s_tconv
export s_filter
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
export s_detect_epoch_flat
export s_detect_epoch_rmse
export s_detect_epoch_rmsd
export s_detect_epoch_euclid
export s_detect_epoch_p2p
export s_snr
export s_findpeaks
export s_wdenoise
export s_ispc
export s_itpc
export s_pli
export s_ged
export s_frqinst
export s_hspectrum
export t2f
export f2t
export s_wspectrogram
export s_fftdenoise
export s_gfilter
export s_ghspectrogram
export s_tkeo
export s_wspectrum
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

include("statistic.jl")
export hildebrand_rule
export jaccard_similarity
export z_score
export k_categories
export effsize
export infcrit
export grubbs
export outlier_detect

include("eeg_io.jl")
export eeg_export_csv
export eeg_import_ced
export eeg_import_edf
export eeg_import_elc
export eeg_import_locs
export eeg_load
export eeg_load_electrodes
export eeg_load_electrodes!
export eeg_save

include("eeg_edit.jl")
export eeg_copy
export eeg_add_component
export eeg_add_component!
export eeg_list_components
export eeg_extract_component
export eeg_delete_component
export eeg_delete_component!
export eeg_reset_components
export eeg_reset_components!
export eeg_component_idx
export eeg_component_type
export eeg_rename_component
export eeg_rename_component!
export eeg_delete_channel
export eeg_delete_channel!
export eeg_keep_channel
export eeg_keep_channel!
export eeg_get_channel
export eeg_rename_channel
export eeg_rename_channel!
export eeg_extract_channel
export eeg_history
export eeg_labels
export eeg_sr
export eeg_channel_n
export eeg_epoch_n
export eeg_signal_len
export eeg_epoch_len
export eeg_info
export eeg_epochs
export eeg_epochs!
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
export eeg_detect_bad_epochs
export eeg_add_labels
export eeg_add_labels!
export eeg_edit_channel
export eeg_edit_channel!
export eeg_keep_eeg_channels
export eeg_keep_eeg_channels!
export eeg_comment
export eeg_epochs_time
export eeg_epochs_time!

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
export eeg_normalize_zscore
export eeg_normalize_zscore!
export eeg_normalize_minmax
export eeg_normalize_minmax!
export eeg_normalize_max
export eeg_normalize_max!
export eeg_normalize_log
export eeg_normalize_log!
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

include("eeg_analyze.jl")
export eeg_total_power
export eeg_band_power
export eeg_cov
export eeg_cor
export eeg_crosscov
export eeg_crosscov
export eeg_psd
export eeg_stationarity
export eeg_mi
export eeg_mi
export eeg_entropy
export eeg_negentropy
export eeg_band
export eeg_tcoherence
export eeg_freqs
export eeg_difference
export eeg_pick
export eeg_epochs_stats
export eeg_spectrogram
export eeg_spectrum
export eeg_s2t
export eeg_t2s
export eeg_channels_stats
export eeg_snr
export eeg_standardize
export eeg_standardize!
export eeg_fconv
export eeg_tconv
export eeg_dft
export eeg_msci95
export eeg_mean
export eeg_difference
export eeg_autocov
export eeg_tenv
export eeg_tenv_mean
export eeg_tenv_median
export eeg_penv
export eeg_penv_mean
export eeg_penv_median
export eeg_senv
export eeg_senv_mean
export eeg_senv_median
export eeg_ispc
export eeg_itpc
export eeg_pli
export eeg_pli_m
export eeg_ispc_m
export eeg_aec
export eeg_ged
export eeg_frqinst
export eeg_itpc_s
export eeg_wspectrogram
export eeg_tkeo
export eeg_wspectrum
export eeg_fcoherence

include("eeg_plots.jl")
export eeg_plot_acomponent_topo
export eeg_plot_bands
export eeg_plot_channels
export eeg_plot_component
export eeg_plot_component_avg
export eeg_plot_component_butterfly
export eeg_plot_component_idx
export eeg_plot_component_idx_avg
export eeg_plot_component_idx_butterfly
export eeg_plot_component_idx_psd
export eeg_plot_component_idx_psd_avg
export eeg_plot_component_idx_psd_butterfly
export eeg_plot_component_idx_spectrogram
export eeg_plot_component_idx_spectrogram_avg
export eeg_plot_component_psd
export eeg_plot_component_psd_avg
export eeg_plot_component_psd_butterfly
export eeg_plot_component_spectrogram
export eeg_plot_component_spectrogram_avg
export eeg_plot_compose
export eeg_plot_covmatrix
export eeg_plot_electrodes
export eeg_plot_epochs
export eeg_plot_filter_response
export eeg_plot_histogram
export eeg_plot_ica_topo
export eeg_plot_matrix
export eeg_plot_mcomponent_topo
export eeg_plot_save
export eeg_plot_signal
export eeg_plot_signal_avg
export eeg_plot_signal_avg_details
export eeg_plot_signal_butterfly
export eeg_plot_signal_butterfly_details
export eeg_plot_signal_details
export eeg_plot_signal_psd
export eeg_plot_signal_psd_avg
export eeg_plot_signal_psd_butterfly
export eeg_plot_signal_spectrogram
export eeg_plot_signal_spectrogram_avg
export eeg_plot_signal_topo
export eeg_plot_tile
export eeg_plot_weights_topo
export eeg_plot_env
export plot_bands
export plot_histogram
export plot_ica
export plot_psd
export plot_psd_avg
export plot_psd_butterfly
export plot_signal
export plot_signal_scaled
export plot_signal_avg
export plot_signal_butterfly
export plot_spectrogram
export eeg_plot_ispc
export eeg_plot_itpc
export eeg_plot_pli
export eeg_plot_itpc_s
export eeg_plot_connections
export eeg_plot_itpc_f
export plot_psd_3dw
export plot_psd_3ds
export eeg_plot_signal_psd_3d

include("nstim.jl")
export tes_dose

end
