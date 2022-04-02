using NeuroJ
using Test

edf = eeg_import_edf("eeg-test-edf.edf")

edf1 = eeg_delete_channel(edf, channel=1)
@test edf1.eeg_header[:channel_n] == 18

edf1 = eeg_keep_channel(edf, channel=1)
@test edf1.eeg_header[:channel_n] == 1

edf1 = eeg_derivative(edf)
@test size(edf1.eeg_signals) == (19, 156672, 1)

tbp = eeg_total_power(edf)
@test size(tbp) == (19, 1)

abp = eeg_band_power(edf, f=(2, 4))
@test size(abp) == (19, 1)

edf1 = eeg_detrend(edf)
@test size(edf1.eeg_signals) == (19, 156672, 1)

edf1 = eeg_reference_channel(edf, channel=1)
@test size(edf1.eeg_signals) == (19, 156672, 1)

edf1 = eeg_reference_car(edf)
@test size(edf1.eeg_signals) == (19, 156672, 1)

edf1 = eeg_extract_channel(edf, channel="Cz")
@test size(edf1) == (156672, )

edf1 = eeg_extract_channel(edf, channel=18)
@test size(edf1) == (156672, )

@test eeg_get_channel(edf, channel=1) == "Fp1"
@test eeg_get_channel(edf, channel="Fp1") == 1

edf1 = eeg_rename_channel(edf, channel="Cz", new_name="CZ")
@test edf1.eeg_header[:labels][18] == "CZ"
edf1 = eeg_rename_channel(edf, channel=1, new_name="FP1")
@test edf1.eeg_header[:labels][1] == "FP1"

edf1 = eeg_taper(edf, taper=edf.eeg_signals[1, :, 1])
@test size(edf1.eeg_signals) == (19, 156672, 1)

edf1 = eeg_demean(edf)
@test size(edf1.eeg_signals) == (19, 156672, 1)

edf1 = eeg_normalize_zscore(edf)
@test size(edf1.eeg_signals) == (19, 156672, 1)

edf1 = eeg_normalize_minmax(edf)
@test size(edf1.eeg_signals) == (19, 156672, 1)

cov_m = eeg_cov(edf)
@test size(cov_m) == (19, 19, 1)

cor_m = eeg_cor(edf)
@test size(cor_m) == (19, 19, 1)

edf1 = eeg_upsample(edf, new_sr=512)
@test size(edf1.eeg_signals) == (19, 313343, 1)

@test eeg_history(edf) == String[]

@test eeg_labels(edf)[1] == "Fp1"

@test eeg_sr(edf) == 256

edf1 = eeg_epochs(edf, epoch_len=10, average=true)
@test size(edf1.eeg_signals) == (19, 10, 1)

edf10 = eeg_epochs(edf, epoch_n=10)
edf1 = eeg_extract_epoch(edf, epoch=1)
@test size(edf1.eeg_signals) == (19, 156672, 1)

s_conv = eeg_tconv(edf, kernel=generate_window(:hann, 256))
@test size(s_conv) == (19, 156672, 1)

edf1 = eeg_filter(edf, fprototype=:butterworth, ftype=:lp, cutoff=2, order=8)
@test size(edf1.eeg_signals) == (19, 156672, 1)
edf1 = eeg_filter(edf, fprototype=:mavg, d=10)
@test size(edf1.eeg_signals) == (19, 156672, 1)
edf1 = eeg_filter(edf, fprototype=:mmed, d=10)
@test size(edf1.eeg_signals) == (19, 156672, 1)
edf1 = eeg_filter(edf, fprototype=:mavg, window=generate_gaussian(eeg_sr(edf), 32, 0.01))
@test size(edf1.eeg_signals) == (19, 156672, 1)

edf1 = eeg_downsample(edf, new_sr=128)
@test size(edf1.eeg_signals) == (19, 78336, 1)

acov_m, _ = eeg_autocov(edf)
@test size(acov_m) == (19, 3, 1)

ccov_m, _ = eeg_crosscov(edf)
@test size(ccov_m) == (361, 3, 1)

p, f = eeg_psd(edf1)
@test size(p, 1) == 19

p = eeg_stationarity(edf, method=:mean)
@test size(p) == (19, 10, 1)
p = eeg_stationarity(edf, method=:var)
@test size(p) == (19, 10, 1)
p = eeg_stationarity(edf, method=:hilbert)
@test size(p) == (19, 156671, 1)
p = eeg_stationarity(edf, window=10000, method=:euclid)
@test size(p) == (17, 1)

e = eeg_trim(edf, len=(10 * eeg_sr(edf)), offset=(20 * eeg_sr(edf)), from=:start)
@test size(e.eeg_signals) == (19, 154112, 1)

m = eeg_mi(edf)
@test size(m) == (19, 19, 1)
m = eeg_mi(edf, edf)
@test size(m) == (19, 19, 1)

e = eeg_entropy(edf)
@test size(e) == (19, 1)
e = eeg_negentropy(edf)
@test size(e) == (19, 1)

a = eeg_band(edf, band=:alpha)
@test a == (8, 13)

m = eeg_coherence(edf, edf)
@test size(m) == (19, 156672, 1)

hz, nyq = eeg_freqs(edf)
@test nyq == 128.0

s_conv = eeg_fconv(edf, kernel=[1, 2, 3, 4])
@test size(s_conv) == (19, 156672, 1)

p, v, m = eeg_pca(edf, n=2)
@test size(p) == (2, 156672, 1)
@test size(v) == (2, 1)
e1 = eeg_add_component(edf, c=:pc, v=p)
eeg_add_component!(e1, c=:pc_m, v=m)
e2 = eeg_pca_reconstruct(e1)
@test size(e2.eeg_signals) == (19, 156672, 1)

e = eeg_edit_header(edf, field=:patient, value="unknown")
@test e.eeg_header[:patient] == "unknown"

e = eeg_epochs(edf, epoch_n=10)
e9 = eeg_delete_epoch(e, epoch=10)
@test size(e9.eeg_signals) == (19, 15667, 9)
e1 = eeg_keep_epoch(e, epoch=1)
@test size(e1.eeg_signals) == (19, 15667, 1)

e = eeg_pick(edf, pick=:left)
@test length(e) == 8

e = eeg_epochs(edf, epoch_len=20*256)
v = eeg_epochs_stats(e)
@test length(v) == 10

e = eeg_epochs(edf, epoch_len=20, average=true)
i, _ = eeg_ica(e, n=5, tol=1.0)
@test size(i) == (5, 20, 1)

e = eeg_copy(edf)
e_stats = eeg_epochs_stats(e)
@test length(e_stats) == (10)
eeg_add_component!(e, c=:epochs_mean, v=e_stats[1])
v = eeg_extract_component(e, c=:epochs_mean)
@test size(v) == (1, )
eeg_rename_component!(e, c_old=:epochs_mean, c_new=:epochs_m)
c = eeg_list_components(e)
@test size(c) == (1, )
c = eeg_component_type(e, c=:epochs_m)
@test c == Vector{Float64}
eeg_delete_component!(e, c=:epochs_m)
c = eeg_list_components(e)
@test size(c) == (0, )
eeg_reset_components!(e)
c = eeg_list_components(e)
@test size(c) == (0, )

e = eeg_epochs(edf, epoch_len=2560, average=true)
p, f, t = eeg_spectrogram(e)
@test size(p) == (1281, 61, 19, 1)
f, a, p, ph = eeg_spectrum(e)
@test size(p) == (19, 2560, 1)

e = eeg_copy(edf)
i, iw = eeg_ica(e, tol=1.0, n=10)
eeg_add_component!(e, c=:ica, v=i)
eeg_add_component!(e, c=:ica_mw, v=iw)
@test size(e.eeg_components[1]) == (10, 156672, 1)
e2 = eeg_ica_reconstruct(e, ica=1)
@test size(e2.eeg_signals) == (19, 156672, 1)

e = eeg_epochs(edf, epoch_len=20*256)
b = eeg_detect_bad_epochs(edf)
@test length(b) == 1

@test eeg_t2s(edf, t=10) == 2561
@test eeg_s2t(edf, t=10) == 0.04

e = eeg_keep_eeg_channels(edf)
@test size(e.eeg_signals) == (19, 156672, 1)
eeg_edit_channel!(e, channel=19, field=:channel_type, value="ecg")
eeg_keep_eeg_channels!(e)
@test size(e.eeg_signals) == (18, 156672, 1)

e = eeg_invert_polarity(edf, channel=1)
@test e.eeg_signals[1, 1, 1] == -edf.eeg_signals[1, 1, 1]

c = eeg_comment(edf)
@test c == ""

v = eeg_channels_stats(edf)
@test length(v) == 10

edf = eeg_import_edf("eeg-test-edf.edf")
v = eeg_snr(edf)
@test size(v) == (19, 1)

s, _ = eeg_standardize(edf)
@test size(s.eeg_signals) == (19, 156672, 1)

snr = eeg_snr(edf)
@test length(snr) == 19

edf1 = eeg_epochs_time(edf, ts=-10.0)
edf1.eeg_epochs_time[1, 1] == -10.0

e10 = eeg_epochs(edf, epoch_len=10*256)
@test size(eeg_tenv(e10)[1]) == (19, 2560, 61)
@test size(eeg_tenv_mean(e10, dims=1)[1]) == (2560, 61)
@test size(eeg_tenv_median(e10, dims=1)[1]) == (2560, 61)

@test size(eeg_penv(e10)[1]) == (19, 513, 61)
@test size(eeg_penv_mean(e10, dims=1)[1]) == (513, 61)
@test size(eeg_penv_median(e10, dims=1)[1]) == (513, 61)

@test size(eeg_senv(e10)[1]) == (19, 61, 61)
@test size(eeg_senv_mean(e10, dims=1)[1]) == (61, 61)
@test size(eeg_senv_median(e10, dims=1)[1]) == (61, 61)

true