using NeuroAnalyzer
using Test

eeg = import_edf(joinpath(testfiles_path, "eeg-test-edf.edf"))
epoch!(eeg, ep_len=5)

eeg1 = deepcopy(eeg)
eeg2 = deepcopy(eeg)
eeg2.data .*= 0.75

@info "test 1/8: create_study()"
s = create_study([eeg1, eeg2], [:a, :b])
@test s isa NeuroAnalyzer.STUDY

@info "test 2/8: obj_n()"
@test obj_n(s) == 2

@info "test 3/8: nchannels()"
@test nchannels(s) == 24

@info "test 4/8: nepochs()"
@test nepochs(s) == 241

@info "test 5/8: epoch_len()"
@test epoch_len(s) == 1280

@info "test 6/8: sr()"
@test sr(s) == 256

@info "test 7/8: save()"
isfile("test.hdf5") && rm("test.hdf5")
NeuroAnalyzer.save(s, file_name="test.hdf5")
@test isfile("test.hdf5") == true

@info "test 8/8: load()"
s = NeuroAnalyzer.load("test.hdf5")
@test s isa NeuroAnalyzer.STUDY
isfile("test.hdf5") && rm("test.hdf5")

true