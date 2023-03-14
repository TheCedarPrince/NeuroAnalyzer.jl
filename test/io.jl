using NeuroAnalyzer
using Test
using DataFrames

eeg = import_bdf("eeg-test-bdf.bdf")
@test typeof(eeg) == NeuroAnalyzer.NEURO
eeg = import_bdf("eeg-test-bdfplus.bdf")
@test typeof(eeg) == NeuroAnalyzer.NEURO
eeg = import_edf("eeg-test-edf.edf")
@test typeof(eeg) == NeuroAnalyzer.NEURO
eeg = import_edf("eeg-test-edfplus.edf")
@test typeof(eeg) == NeuroAnalyzer.NEURO
eeg = import_digitrack("eeg-test-digitrack.txt")
@test typeof(eeg) == NeuroAnalyzer.NEURO
eeg = import_bv("eeg-test-bv.vhdr")
@test typeof(eeg) == NeuroAnalyzer.NEURO
eeg = import_csv("eeg-test_txch.csv.gz")
@test typeof(eeg) == NeuroAnalyzer.NEURO
eeg = import_csv("eeg-test_chxt.csv.gz")
@test typeof(eeg) == NeuroAnalyzer.NEURO
eeg = import_set("eeg-test.set")
@test typeof(eeg) == NeuroAnalyzer.NEURO

eeg = import_recording("eeg-test-edf.edf")
ecg = extract_channel(eeg, channel=24)
delete_channel!(eeg, channel=24)
eog2 = extract_channel(eeg, channel=23)
delete_channel!(eeg, channel=23)
eog1 = extract_channel(eeg, channel=22)
delete_channel!(eeg, channel=22)
a2 = extract_channel(eeg, channel=21)
delete_channel!(eeg, channel=21)
a1 = extract_channel(eeg, channel=20)
delete_channel!(eeg, channel=20)

@test eeg.header.recording[:file_type] == "EDF"
@test channel_n(eeg) == 19
@test eeg.header.has_locs == false

s = import_locs_ced("test.ced")
@test typeof(s) == DataFrame
s = import_locs_locs("test.locs")
@test typeof(s) == DataFrame
s = import_locs_elc("test.elc")
@test typeof(s) == DataFrame
s = import_locs_tsv("test.tsv")
@test typeof(s) == DataFrame
s = import_locs_sfp("test.sfp")
@test typeof(s) == DataFrame
s = import_locs_csd("test.csd")
@test typeof(s) == DataFrame
s = import_locs_geo("test.geo")
@test typeof(s) == DataFrame
s = import_locs_mat("test.mat")
@test typeof(s) == DataFrame

eeg = load_locs(eeg, file_name="standard-10-20-cap19-elmiko.ced")
@test typeof(eeg) == NeuroAnalyzer.NEURO
@test eeg.header.has_locs == true

isfile("test.hdf5") && rm("test.hdf5")
save(eeg, file_name="test.hdf5")
@test isfile("test.hdf5") == true

new = load("test.hdf5")
@test typeof(new) == NeuroAnalyzer.NEURO
isfile("test.hdf5") && rm("test.hdf5")

isfile("eeg.csv") && rm("eeg.csv")
export_csv(eeg, file_name="eeg.csv", header=false)
@test isfile("eeg.csv") == true
isfile("eeg.csv") && rm("eeg.csv")

isfile("test_out.ced") && rm("test_out.ced")
export_locs(eeg, file_name="test_out.ced")
@test isfile("test_out.ced") == true
isfile("test_out.ced") && rm("test_out.ced")

isfile("test_out.locs") && rm("test_out.locs")
export_locs(eeg, file_name="test_out.locs")
@test isfile("test_out.locs") == true
isfile("test_out.locs") && rm("test_out.locs")

locs = import_locs_ced("standard-10-20-cap19-elmiko.ced")
eeg2 = add_locs(eeg, locs=locs)
@test typeof(eeg2) == NeuroAnalyzer.NEURO
add_locs!(eeg, locs=locs)
@test typeof(eeg) == NeuroAnalyzer.NEURO

true