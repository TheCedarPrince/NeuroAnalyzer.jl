using NeuroAnalyzer
using Test
using Wavelets
using ContinuousWavelets

edf = eeg_import_edf("eeg-test-edf.edf")
@test size(edf.eeg_signals) == (24, 309760, 1)

ecg = eeg_extract_channel(edf, channel=24)
eog2 = eeg_extract_channel(edf, channel=23)
eog1 = eeg_extract_channel(edf, channel=22)
eeg_delete_channel!(edf, channel=22:24)

edf1 = eeg_reference_a(edf)
@test size(edf1.eeg_signals) == (21, 309760, 1)
a1 = eeg_extract_channel(edf, channel=20)
a2 = eeg_extract_channel(edf, channel=21)
eeg_delete_channel!(edf, channel=[20, 21])

edf1 = eeg_delete_channel(edf, channel=1)
@test edf1.eeg_header[:channel_n] == 18

edf1 = eeg_keep_channel(edf, channel=1)
@test edf1.eeg_header[:channel_n] == 1

edf1 = eeg_derivative(edf)
@test size(edf1.eeg_signals) == (19, 309760, 1)

tbp = eeg_total_power(edf)
@test size(tbp) == (19, 1)

abp = eeg_band_power(edf, f=(2, 4))
@test size(abp) == (19, 1)

edf1 = eeg_detrend(edf)
@test size(edf1.eeg_signals) == (19, 309760, 1)

edf1 = eeg_reference_ch(edf, channel=1)
@test size(edf1.eeg_signals) == (19, 309760, 1)

edf1 = eeg_reference_car(edf)
@test size(edf1.eeg_signals) == (19, 309760, 1)

edf1 = eeg_extract_channel(edf, channel="Cz")
@test size(edf1) == (1, 309760, 1)

edf1 = eeg_extract_channel(edf, channel=18)
@test size(edf1) == (1, 309760, 1)

@test eeg_get_channel(edf, channel=1) == "Fp1"
@test eeg_get_channel(edf, channel="Fp1") == 1

edf1 = eeg_rename_channel(edf, channel="Cz", name="CZ")
@test edf1.eeg_header[:labels][18] == "CZ"
edf1 = eeg_rename_channel(edf, channel=1, name="FP1")
@test edf1.eeg_header[:labels][1] == "FP1"

edf1 = eeg_taper(edf, taper=edf.eeg_signals[1, :, 1])
@test size(edf1.eeg_signals) == (19, 309760, 1)

edf1 = eeg_demean(edf)
@test size(edf1.eeg_signals) == (19, 309760, 1)

edf1 = eeg_normalize(edf, method=:zscore)
@test size(edf1.eeg_signals) == (19, 309760, 1)
edf1 = eeg_normalize(edf, method=:minmax)
@test size(edf1.eeg_signals) == (19, 309760, 1)
edf1 = eeg_normalize(edf, method=:log)
@test size(edf1.eeg_signals) == (19, 309760, 1)
edf1 = eeg_normalize(edf, method=:gauss)
@test size(edf1.eeg_signals) == (19, 309760, 1)

cov_m = eeg_cov(edf)
@test size(cov_m) == (19, 19, 1)

cor_m = eeg_cor(edf)
@test size(cor_m) == (19, 19, 1)

edf1 = eeg_upsample(edf, new_sr=512)
@test size(edf1.eeg_signals) == (19, 619519, 1)

@test typeof(eeg_history(edf)) == Vector{String}

@test eeg_labels(edf)[1] == "Fp1"

@test eeg_sr(edf) == 256

edf1 = eeg_epoch(edf, epoch_len=1000)
eeg_epoch_avg!(edf1)
@test size(edf1.eeg_signals) == (19, 1000, 1)

edf10 = eeg_epoch(edf, epoch_n=10)
edf1 = eeg_extract_epoch(edf, epoch=1)
@test size(edf1.eeg_signals) == (19, 309760, 1)

f, s = eeg_dft(edf)
@test size(f) == (19, 309760, 1)

m, _, _, _ = eeg_msci95(edf)
@test size(m) == (1, 309760)

m, _, _, _ = eeg_mean(edf, edf)
@test m == zeros(1, 309760)

s, ss, p = eeg_difference(edf, edf)
@test p == [1.0]

edf1 = eeg_filter(edf, fprototype=:butterworth, ftype=:lp, cutoff=2, order=8)
@test size(edf1.eeg_signals) == (19, 309760, 1)
edf1 = eeg_filter(edf, fprototype=:mavg, order=10)
@test size(edf1.eeg_signals) == (19, 309760, 1)
edf1 = eeg_filter(edf, fprototype=:mmed, order=10)
@test size(edf1.eeg_signals) == (19, 309760, 1)
@test size(edf1.eeg_signals) == (19, 309760, 1)

edf1 = eeg_downsample(edf, new_sr=128)
@test size(edf1.eeg_signals) == (19, 154880, 1)

acov_m, _ = eeg_acov(edf)
@test size(acov_m) == (19, 3, 1)
xcov_m, _ = eeg_xcov(edf)
@test size(xcov_m) == (361, 3, 1)

p, f = eeg_psd(edf)
@test size(p, 1) == 19

p = eeg_stationarity(edf, method=:mean)
@test size(p) == (19, 10, 1)
p = eeg_stationarity(edf, method=:var)
@test size(p) == (19, 10, 1)
p = eeg_stationarity(edf, method=:hilbert)
@test size(p) == (19, 309759, 1)
p = eeg_stationarity(edf, window=10000, method=:euclid)
@test size(p) == (32, 1)

e = eeg_trim(edf, segment=(10 * eeg_sr(edf), 20 * eeg_sr(edf)), remove_epochs=false)
@test eeg_signal_len(e) == 307199

m = eeg_mi(edf)
@test size(m) == (19, 19, 1)
m = eeg_mi(edf, edf)
@test size(m) == (19, 19, 1)

e = eeg_entropy(edf)
@test length(e) == 3
e = eeg_negentropy(edf)
@test size(e) == (19, 1)

a = eeg_band(edf, band=:alpha)
@test a == (8, 13)

c, msc, ic = eeg_tcoherence(edf, edf)
@test size(c) == (19, 309760, 1)

hz, nyq = eeg_freqs(edf)
@test nyq == 128.0

e10 = eeg_epoch(edf, epoch_len=2560)
s_conv = eeg_fconv(e10, kernel=generate_window(:hann, 256))
@test size(s_conv) == (19, 2560, 121)
s_conv = eeg_tconv(e10, kernel=generate_window(:hann, 256))
@test size(s_conv) == (19, 2560, 121)

p, v, m, pca = eeg_pca(edf, n=2)
@test size(p) == (2, 309760, 1)
@test size(v) == (2, 1)
e1 = eeg_add_component(edf, c=:pc, v=p)
eeg_add_component!(e1, c=:pca, v=pca)
e2 = eeg_pca_reconstruct(e1)
e2 = eeg_pca_reconstruct(edf, p, pca)
@test size(e2.eeg_signals) == (19, 309760, 1)

e = eeg_edit_header(edf, field=:patient, value="unknown")
@test e.eeg_header[:patient] == "unknown"

e = eeg_epoch(edf, epoch_n=10)
e9 = eeg_delete_epoch(e, epoch=10)
@test size(e9.eeg_signals) == (19, 30976, 9)
e1 = eeg_keep_epoch(e, epoch=1)
@test size(e1.eeg_signals) == (19, 30976, 1)

@test length(eeg_channel_pick(edf, pick=:left)) == 8

e = eeg_epoch(edf, epoch_len=20*256)
v = eeg_epoch_stats(e)
@test length(v) == 10

e = eeg_epoch(edf, epoch_len=20)
eeg_epoch_avg!(e)
i, _ = eeg_ica(e, n=5, tol=1.0)
@test size(i) == (5, 20, 1)

e = eeg_copy(edf)
e_stats = eeg_epoch_stats(e)
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

e = eeg_epoch(edf, epoch_len=2560)
eeg_epoch_avg!(e)
p, f, t = eeg_spectrogram(e)
@test size(p) == (1281, 61, 19, 1)
p, f, t = eeg_spectrogram(e, method=:mt)
@test size(p) == (257, 15, 19, 1)
p, f, t = eeg_spectrogram(e, method=:mw)
@test size(p) == (129, 2560, 19, 1)
p, f, t = eeg_spectrogram(e, method=:stft)
@test size(p) == (1281, 61, 19, 1)
p, f, t = eeg_spectrogram(e, method=:gh)
@test size(p) == (129, 2560, 19, 1)
p, f, t = eeg_spectrogram(e, method=:cwt)
@test size(p) == (18, 2560, 19, 1)

f, a, p, ph = eeg_spectrum(e)
@test size(p) == (19, 1280, 1)

e = eeg_copy(edf)
i, iw = eeg_ica(e, tol=1.0, n=10)
eeg_add_component!(e, c=:ica, v=i)
eeg_add_component!(e, c=:ica_mw, v=iw)
@test size(e.eeg_components[1]) == (10, 309760, 1)
e2 = eeg_ica_reconstruct(e, ic=1)
@test size(e2.eeg_signals) == (19, 309760, 1)

b = eeg_detect_bad(edf)
@test length(b) == 2

@test eeg_t2s(edf, t=10) == 2561
@test eeg_s2t(edf, t=10) == 0.04

e = eeg_keep_channel_type(edf)
@test size(e.eeg_signals) == (19, 309760, 1)
eeg_edit_channel!(e, channel=19, field=:channel_type, value="ecg")
eeg_keep_channel_type!(e, type=:eeg)
@test size(e.eeg_signals) == (18, 309760, 1)

e = eeg_invert_polarity(edf, channel=1)
@test e.eeg_signals[1, 1, 1] == -edf.eeg_signals[1, 1, 1]

v = eeg_channel_stats(edf)
@test length(v) == 10

edf = eeg_import_edf("eeg-test-edf.edf")
eeg_delete_channel!(edf, channel=20:24)
eeg_load_electrodes!(edf, file_name="../locs/standard-10-20-cap19-elmiko.ced")

v = eeg_snr(edf)
@test size(v) == (19, 1)

s, _ = eeg_standardize(edf)
@test size(s.eeg_signals) == (19, 309760, 1)

snr = eeg_snr(edf)
@test length(snr) == 19

edf1 = eeg_epoch_time(edf, ts=-10.0)
edf1.eeg_epoch_time[1, 1] == -10.0

e10 = eeg_epoch(edf, epoch_len=10*256)
@test size(eeg_tenv(e10)[1]) == (19, 2560, 121)
@test size(eeg_tenv_mean(e10, dims=1)[1]) == (2560, 121)
@test size(eeg_tenv_median(e10, dims=1)[1]) == (2560, 121)
@test size(eeg_penv(e10)[1]) == (19, 513, 121)
@test size(eeg_penv_mean(e10, dims=1)[1]) == (513, 121)
@test size(eeg_penv_median(e10, dims=1)[1]) == (513, 121)
@test size(eeg_senv(e10)[1]) == (19, 61, 121)
@test size(eeg_senv_mean(e10, dims=1)[1]) == (61, 121)
@test size(eeg_senv_median(e10, dims=1)[1]) == (61, 121)
@test size(eeg_wdenoise(edf, wt=wavelet(WT.haar)).eeg_signals) == (19, 309760, 1)
@test length(eeg_ispc(e10, e10, channel1=1, channel2=2, epoch1=1, epoch2=1)) == 6
@test length(eeg_itpc(e10, channel=1, t=12)) == 4
@test length(eeg_pli(e10, e10, channel1=1, channel2=2, epoch1=1, epoch2=1)) == 5
@test size(eeg_pli(e10)) == (19, 19, 121)
@test size(eeg_ispc(e10)) == (19, 19, 121)
@test length(eeg_aec(edf, edf, channel1=1, channel2=2, epoch1=1, epoch2=1)) == 2
@test length(eeg_ged(edf, edf)) == 3
@test size(eeg_frqinst(edf)) == size(edf.eeg_signals)
@test size(eeg_fftdenoise(edf).eeg_signals) == (19, 309760, 1)
@test size(eeg_tkeo(edf)) == (19, 309760, 1)
@test length(eeg_mwpsd(edf, frq_lim=(0, 20), frq_n=21)) == 2

c, msc, f = eeg_fcoherence(edf, edf, channel1=1, channel2=2, epoch1=1, epoch2=1)
@test length(c) == 262145

edf1 = eeg_reference_plap(edf)
@test size(edf1.eeg_signals) == (19, 309760, 1)

f, p = eeg_vartest(edf)
@test size(f) == (19, 19, 1)

edf1 = eeg_add_note(edf, note="test")
@test eeg_view_note(edf1) == "test"
eeg_delete_note!(edf1)
@test eeg_view_note(edf1) == ""

edf1 = eeg_epoch(edf, epoch_len=2560)
new_channel = zeros(1, eeg_epoch_len(edf1), eeg_epoch_n(edf1))
edf1 = eeg_replace_channel(edf1, channel=1, signal=new_channel);
@test edf1.eeg_signals[1, :, :] == zeros(eeg_epoch_len(edf1), eeg_epoch_n(edf1))
edf2 = eeg_plinterpolate_channel(edf1, channel=1, epoch=1)
@test edf2.eeg_signals[1, :, 1] != zeros(eeg_epoch_len(edf1))
edf2 = eeg_lrinterpolate_channel(edf1, channel=1, epoch=1)
@test edf2.eeg_signals[1, :, 1] != zeros(eeg_epoch_len(edf1))

@test length(eeg_band_mpower(edf, f=(1,4))) == 3

p, f = eeg_rel_psd(edf, f=(8,12))
@test size(p) == (19, 513, 1)

_, _, ss = eeg_fbsplit(edf)
@test size(ss) == (10, 19, 309760, 1)

edf1 = eeg_zero(edf)
@test edf1.eeg_signals[1, 1, 1] == 0

c = eeg_chdiff(edf, edf, channel1=1, channel2=2)
@test size(c) == (1, 309760, 1)

edf1 = eeg_wbp(edf, frq=10)
@test size(edf1.eeg_signals) == (19, 309760, 1)
edf1 = eeg_cbp(edf, frq=10)
@test size(edf1.eeg_signals) == (19, 309760, 1)
edf1 = eeg_denoise_wien(edf)
@test size(edf1.eeg_signals) == (19, 309760, 1)

p, _, _ = eeg_cps(edf, edf, channel1=1, channel2=2, epoch1=1, epoch2=1)
@test length(p) == 262145

edf2 = eeg_channel_type(edf, channel=1, type="eog")
@test edf2.eeg_header[:channel_type][1] == "eog"
edf2 = eeg_edit_electrode(edf, channel=1, x=2)
@test edf2.eeg_locs[!, :loc_x][1] == 2.0
_, _, x, _, _, _, _, _ = eeg_electrode_loc(edf2, channel=1, output=false)
@test x == 2.0

ch1 = eeg_electrode_loc(edf, channel=1, output=false)
@test ch1[1] == -18.0

locs = eeg_import_ced("../locs/standard-10-20-cap19-elmiko.ced")
locs2 = loc_flipx(locs)
@test locs2[1, 3] == 198.0
locs2 = loc_flipy(locs)
@test locs2[1, 3] == 18.0
locs2 = loc_flipz(locs)
@test locs2[1, 3] == -18.0
locs2 = loc_swapxy(locs)
@test locs2[1, 3] == 72.0
locs2 = loc_sph2cart(locs)
@test locs2[1, 5] == -0.03
locs2 = loc_cart2sph(locs)
@test locs2[1, 3] == -18.0

@test size(eeg_phdiff(edf)) == (19, 309760, 1)
@test size(eeg_scale(edf, channel=1, factor=0.1).eeg_signals) == (19, 309760, 1)

bdf = eeg_import_bdf("eeg-test-bdfplus.bdf")
eeg_delete_marker!(bdf, n=1)
@test size(bdf.eeg_markers) == (1, 5)
eeg_add_marker!(bdf, id="event", start=1, len=1, desc="test", channel=0)
@test size(bdf.eeg_markers) == (2, 5)
eeg_edit_marker!(bdf, n=2, id="event2", start=1, len=1, desc="test2", channel=0)

@test size(eeg_vch(e10, f="fp1 + fp2")) == (1, 2560, 121)
@test size(eeg_dwt(e10, wt=wavelet(WT.haar), type=:sdwt)) == (19, 10, 2560, 121)
@test size(eeg_cwt(e10, wt=wavelet(Morlet(π), β=2))) == (19, 33, 2560, 121)

_, _, f = eeg_psdslope(edf)
@test length(f) == 513

@test size(eeg_henv(e10)[1]) == (19, 2560, 121)
@test size(eeg_henv_mean(e10, dims=1)[1]) == (2560, 121)
@test size(eeg_henv_median(e10, dims=1)[1]) == (2560, 121)
@test size(eeg_apply(e10, f="mean(eeg, dims=1)")) == (19, 1, 121)

@test eeg_channel_cluster(e10, cluster=:f1) == [1, 3, 11]

true