using NeuroAnalyzer
using Test
using Wavelets
using ContinuousWavelets

@info "Initializing"
eeg = import_edf("files/eeg-test-edf.edf")
e10 = epoch(eeg, ep_len=10*sr(eeg))
keep_epoch!(e10, ep=1:10)
v = [1, 2, 3, 4, 5]
v1 = [1, 2, 3, 4, 5]
v2 = [6, 5, 4, 3, 2]
m = [1 2 3; 4 5 6]
m1 = [1 2 3; 4 5 6]
m2 = [7 6 5; 4 3 2]
a1 = ones(2, 3, 2)
a0 = zeros(2, 3, 2)

@info "test 1/47: channel_type()"
@test e10.header.recording[:channel_type][1] == "eeg"
e10_tmp = channel_type(e10, ch=1, type="???")
@test e10_tmp.header.recording[:channel_type][1] == "???"
channel_type!(e10_tmp, ch=1, type="eeg")
@test e10_tmp.header.recording[:channel_type][1] == "eeg"

@info "test 2/47: get_channel()"
@test get_channel(e10, ch=1) == "Fp1"
@test get_channel(e10, ch="Fp1") == 1

@info "test 3/47: get_channel()"
e10_tmp = rename_channel(e10, ch=1, name="FP1")
@test get_channel(e10_tmp, ch=1) == "FP1"
rename_channel!(e10_tmp, ch=1, name="Fp1")
@test get_channel(e10_tmp, ch=1) == "Fp1"

@info "test 4/47: replace_channel()"
e10_tmp = replace_channel(e10, ch=1, s=ones(1, epoch_len(e10), epoch_n(e10)));
@test e10_tmp.data[1, :, :] == ones(epoch_len(e10), epoch_n(e10))
replace_channel!(e10_tmp, ch=1, s=zeros(1, epoch_len(e10), epoch_n(e10)));
@test e10_tmp.data[1, :, :] == zeros(epoch_len(e10), epoch_n(e10))

@info "test 5/47: add_labels()"
l = string.(1:24)
e10_tmp = add_labels(e10, clabels=l)
@test labels(e10_tmp) == l
add_labels!(e10_tmp, clabels=l)
@test labels(e10_tmp) == l

@info "test 6/47: add_labels()"
e10_tmp = delete_channel(e10, ch=1)
@test channel_n(e10_tmp) == 23
delete_channel!(e10_tmp, ch=1)
@test channel_n(e10_tmp) == 22

@info "test 7/47: keep_channel()"
e10_tmp = keep_channel(e10, ch=10:24)
@test channel_n(e10_tmp) == 15
keep_channel!(e10_tmp, ch=5:15)
@test channel_n(e10_tmp) == 11

@info "test 8/47: keep_channel_type()"
e10_tmp = keep_channel_type(e10, type=:eog)
@test channel_n(e10_tmp) == 2
e10_tmp = deepcopy(e10)
keep_channel_type!(e10_tmp, type=:eog)
@test channel_n(e10_tmp) == 2

@info "test 9/47: delete_epoch()"
e10_tmp = delete_epoch(e10, ep=1)
@test epoch_n(e10_tmp) == 9
@test length(e10.time_pts) == 25600
@test length(e10_tmp.time_pts) == 23040 # 25600 - 2560
e10_tmp = deepcopy(e10)
delete_epoch!(e10_tmp, ep=1)
@test epoch_n(e10_tmp) == 9
@test length(e10.time_pts) == 25600
@test length(e10_tmp.time_pts) == 23040 # 25600 - 2560

@info "test 10/47: keep_epoch()"
e10_tmp = keep_epoch(e10, ep=1:2)
@test epoch_n(e10_tmp) == 2
@test length(e10.time_pts) == 25600
@test length(e10_tmp.time_pts) == 5120 # 2 × 2560
e10_tmp = deepcopy(e10)
keep_epoch!(e10_tmp, ep=1:2)
@test epoch_n(e10_tmp) == 2
@test length(e10.time_pts) == 25600
@test length(e10_tmp.time_pts) == 5120 # 2 × 2560

@info "test 11/47: detect_bad()"
bm, be = detect_bad(e10)
@test bm == Bool[1 1 1 1 1 1 1 1 1 1; 
                 1 1 1 1 1 1 1 1 1 1; 
                 0 0 0 0 1 1 1 1 1 1; 
                 0 1 0 0 1 1 1 1 1 1; 
                 1 1 1 1 1 1 1 1 1 1; 
                 1 1 1 1 1 1 1 1 1 1; 
                 1 1 1 1 1 1 1 1 1 1; 
                 1 1 1 1 1 1 0 0 0 0; 
                 1 1 1 1 1 1 1 1 1 1; 
                 1 1 1 1 1 1 1 1 1 1; 
                 1 1 1 1 1 1 1 1 1 1; 
                 1 1 1 1 1 1 1 1 1 1; 
                 1 0 1 1 1 1 1 1 1 1; 
                 1 1 1 1 1 0 0 0 0 0; 
                 1 1 1 1 1 1 1 0 1 1; 
                 0 0 0 1 0 0 1 1 1 1; 
                 1 1 1 1 0 0 0 1 1 1; 
                 0 1 1 1 1 1 1 1 1 1; 
                 1 1 1 1 1 1 1 1 1 1]
@test be == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

@info "test 12/47: epoch()"
eeg = import_edf("files/eeg-test-edf.edf")
e10 = epoch(eeg, ep_len=10*sr(eeg))
@test epoch_len(e10) == 10*sr(eeg)
e10 = epoch(eeg, ep_n=10)
@test epoch_n(e10) == 10

@info "test 13/47: epoch_time()"
eeg = import_edf("files/eeg-test-edf.edf")
e10 = epoch(eeg, ep_len=10*sr(eeg))
@test e10.epoch_time[1] == 0.0
e10_tmp = epoch_time(e10, ts=-1.0)
@test e10_tmp.epoch_time[1] == -1.0
epoch_time!(e10_tmp, ts=-2.0)
@test e10_tmp.epoch_time[1] == -2.0

@info "test 14/47: extract_channel()"
eeg = import_edf("files/eeg-test-edf.edf")
e10 = epoch(eeg, ep_len=10*sr(eeg))
s = extract_channel(e10, ch=1)
@test size(s) == (1, 2560, 121)

@info "test 15/47: extract_epoch()"
e10_tmp = extract_epoch(e10, ep=1)
@test size(e10_tmp.data) == (24, 2560, 1)
@test length(e10_tmp.time_pts) == 2560
@test length(e10_tmp.epoch_time) == 2560

@info "test 16/47: extract_data()"
d = extract_data(e10)
@test size(d) == (19, 2560, 121)

@info "test 17/47: extract_time()"
tpts = extract_time(e10)
@test length(tpts) == 309760

@info "test 18/47: extract_eptime()"
et = extract_eptime(e10)
@test length(et) == 2560

true