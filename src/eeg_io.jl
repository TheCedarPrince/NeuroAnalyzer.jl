"""
    eeg_import(file_name; detect_type)

Load EEG file and return `NeuroAnalyzer.EEG` object. Supported formats:
- EDF/EDF+
- BDF/BDF+
- BrainVision

This is a meta-function that triggers appropriate `eeg_import_*()` function. File format is detected based on file extension (.edf|.bdf|.vhdr).

# Arguments

- `file_name::String`: name of the file to load
- `detect_type::Bool=true`: detect channel type based on its label

# Returns

- `eeg:EEG`
"""
function eeg_import(file_name::String; detect_type::Bool=true)

    isfile(file_name) || throw(ArgumentError("File $file_name cannot be loaded."))

    splitext(file_name)[2] == ".edf" && return eeg_import_edf(file_name, detect_type=detect_type)
    splitext(file_name)[2] == ".bdf" && return eeg_import_bdf(file_name, detect_type=detect_type)
    splitext(file_name)[2] == ".vhdr" && return eeg_import_bv(file_name, detect_type=detect_type)
end

"""
    eeg_import_edf(file_name; detect_type)

Load EDF/EDF+ file and return `NeuroAnalyzer.EEG` object.

# Arguments

- `file_name::String`: name of the file to load
- `detect_type::Bool=true`: detect channel type based on its label

# Returns

- `eeg:EEG`

# Notes

- sampling_rate = n.samples / data.record.duration
- gain = (physical_maximum - physical_minimum) / (digital_maximum - digital_minimum)
- value = (value - digital_minimum ) * gain + physical_minimum

# Source

1. Kemp B, Värri A, Rosa AC, Nielsen KD, Gade J. A simple format for exchange of digitized polygraphic recordings. Electroencephalography and Clinical Neurophysiology. 1992 May;82(5):391–3. 
2. Kemp B, Olivan J. European data format ‘plus’ (EDF+), an EDF alike standard format for the exchange of physiological data. Clinical Neurophysiology 2003;114:1755–61.
3. https://www.edfplus.info/specs/
"""
function eeg_import_edf(file_name::String; detect_type::Bool=true)

    isfile(file_name) || throw(ArgumentError("File $file_name cannot be loaded."))

    eeg_filetype = ""
    fid = open(file_name)
    header = zeros(UInt8, 256)
    readbytes!(fid, header, 256)
    header = String(Char.(header))

    eeg_filetype = parse(Int, strip(header[1:8]))
    eeg_filetype == 0 && (eeg_filetype = "EDF")
    eeg_filetype !== "EDF" && throw(ArgumentError("File $file_name is not a EDF file."))

    patient = strip(header[9:88])
    recording = strip(header[89:168])
    recording_date = header[169:176]
    recording_time = header[177:184]
    data_offset = parse(Int, strip(header[185:192]))
    reserved = strip(header[193:236])
    reserved == "EDF+D" && throw(ArgumentError("EDF+D format (interrupted recordings) is not supported."))
    reserved == "EDF+C" && (eeg_filetype = "EDF+")
    data_records = parse(Int, strip(header[237:244]))
    data_records_duration  = parse(Float64, strip(header[245:252]))
    channel_n  = parse(Int, strip(header[253:256]))

    labels = Vector{String}(undef, channel_n)
    transducers = Vector{String}(undef, channel_n)
    physical_dimension = Vector{String}(undef, channel_n)
    physical_minimum = Vector{Float64}(undef, channel_n)
    physical_maximum = Vector{Float64}(undef, channel_n)
    digital_minimum = Vector{Float64}(undef, channel_n)
    digital_maximum = Vector{Float64}(undef, channel_n)
    prefiltering = Vector{String}(undef, channel_n)
    samples_per_datarecord = Vector{Int64}(undef, channel_n)

    header = zeros(UInt8, channel_n * 16)
    readbytes!(fid, header, channel_n * 16)
    header = String(Char.(header))
    for idx in 1:channel_n
        labels[idx] = strip(header[1 + ((idx - 1) * 16):(idx * 16)])
    end

    header = zeros(UInt8, channel_n * 80)
    readbytes!(fid, header, channel_n * 80)
    header = String(Char.(header))
    for idx in 1:channel_n
        transducers[idx] = strip(header[1 + ((idx - 1) * 80):(idx * 80)])
    end

    header = zeros(UInt8, channel_n * 8)
    readbytes!(fid, header, channel_n * 8)
    header = String(Char.(header))
    for idx in 1:channel_n
        physical_dimension[idx] = strip(header[1 + ((idx - 1) * 8):(idx * 8)])
    end

    header = zeros(UInt8, channel_n * 8)
    readbytes!(fid, header, channel_n * 8)
    header = String(Char.(header))
    for idx in 1:channel_n
        physical_minimum[idx] = parse(Float64, strip(header[1 + ((idx - 1) * 8):(idx * 8)]))
    end

    header = zeros(UInt8, channel_n * 8)
    readbytes!(fid, header, channel_n * 8)
    header = String(Char.(header))
    for idx in 1:channel_n
        physical_maximum[idx] = parse(Float64, strip(header[1 + ((idx - 1) * 8):(idx * 8)]))
    end

    header = zeros(UInt8, channel_n * 8)
    readbytes!(fid, header, channel_n * 8)
    header = String(Char.(header))
    for idx in 1:channel_n
        digital_minimum[idx] = parse(Float64, strip(header[1 + ((idx - 1) * 8):(idx * 8)]))
    end

    header = zeros(UInt8, channel_n * 8)
    readbytes!(fid, header, channel_n * 8)
    header = String(Char.(header))
    for idx in 1:channel_n
        digital_maximum[idx] = parse(Float64, strip(header[1 + ((idx - 1) * 8):(idx * 8)]))
    end

    header = zeros(UInt8, channel_n * 80)
    readbytes!(fid, header, channel_n * 80)
    header = String(Char.(header))
    for idx in 1:channel_n
        prefiltering[idx] = strip(header[1 + ((idx - 1) * 80):(idx * 80)])
    end

    header = zeros(UInt8, channel_n * 8)
    readbytes!(fid, header, channel_n * 8)
    header = String(Char.(header))
    for idx in 1:channel_n
        samples_per_datarecord[idx] = parse(Int, strip(header[1 + ((idx - 1) * 8):(idx * 8)]))
    end

    close(fid)

    sampling_rate = round(Int64, samples_per_datarecord[2] / data_records_duration)
    gain = Vector{Float64}(undef, channel_n)
    for idx in 1:channel_n
        gain[idx] = (physical_maximum[idx] - physical_minimum[idx]) / (digital_maximum[idx] - digital_minimum[idx])
    end

    labels = _clean_labels(labels)
    if detect_type == true
        channel_type = _set_channel_types(labels)
    else
        channel_type = repeat(["???"], channel_n)
    end
    channel_order = _sort_channels(copy(channel_type))

    if eeg_filetype == "EDF"
        has_markers = false
        eeg_markers = DataFrame(:id => String[], :start => Int64[], :length => Int64[], :description => String[], :channel => Int64[])
        markers_channel = -1
    else
        has_markers, markers_channel = _has_markers(channel_type)
        markers = repeat([""], data_records)
    end

    fid = open(file_name)
    header = zeros(UInt8, data_offset)
    readbytes!(fid, header, data_offset)
    eeg_signals = zeros(channel_n, samples_per_datarecord[1] * data_records, 1)
    for idx1 in 1:data_records
        for idx2 in 1:channel_n
            signal = zeros(UInt8, samples_per_datarecord[idx2] * 2)
            readbytes!(fid, signal, samples_per_datarecord[idx2] * 2)
            if idx2 != markers_channel
                signal = map(ltoh, reinterpret(Int16, signal))
                if channel_type[idx2] == "markers"
                    for idx3 in eachindex(signal)
                        if signal[idx3] == digital_minimum[idx2]
                            signal[idx3] = 0
                        else
                            signal[idx3] = 1
                        end
                    end
                    eeg_signals[idx2, ((idx1 - 1) * samples_per_datarecord[idx2] + 1):(idx1 * samples_per_datarecord[idx2]), 1] = signal
                elseif channel_type[idx2] == "events"
                    eeg_signals[idx2, ((idx1 - 1) * samples_per_datarecord[idx2] + 1):(idx1 * samples_per_datarecord[idx2]), 1] = signal
                else
                    if occursin("uV", physical_dimension[idx2]) 
                        eeg_signals[idx2, ((idx1 - 1) * samples_per_datarecord[idx2] + 1):(idx1 * samples_per_datarecord[idx2]), 1] = signal .* gain[idx2]
                    elseif occursin("mV", physical_dimension[idx2])
                        eeg_signals[idx2, ((idx1 - 1) * samples_per_datarecord[idx2] + 1):(idx1 * samples_per_datarecord[idx2]), 1] = signal .* gain[idx2] ./ 1000
                    else
                        eeg_signals[idx2, ((idx1 - 1) * samples_per_datarecord[idx2] + 1):(idx1 * samples_per_datarecord[idx2]), 1] = signal .* gain[idx2]
                    end
                end
            else
                markers[idx1] = String(Char.(signal))
            end
        end
    end
    close(fid)

    if has_markers
        deleteat!(channel_order, vsearch(markers_channel, channel_order))
        eeg_signals = eeg_signals[setdiff(1:channel_n, markers_channel), :, :]
        deleteat!(labels, markers_channel)
        deleteat!(transducers, markers_channel)
        deleteat!(physical_dimension, markers_channel)
        deleteat!(prefiltering, markers_channel)
        deleteat!(gain, markers_channel)
        channel_n -= 1
        eeg_markers = _m2df(markers)
        eeg_markers[!, :start] = t2s.(eeg_markers[!, :start], sampling_rate)
        eeg_markers[!, :length] = t2s.(eeg_markers[!, :length], sampling_rate)
    else
        eeg_markers = DataFrame(:id => String[], :start => Int64[], :length => Int64[], :description => String[], :channel => Int64[])
    end

    eeg_duration_samples = size(eeg_signals, 2)
    eeg_duration_seconds = size(eeg_signals, 2) / sampling_rate
    eeg_time = collect(0:(1 / sampling_rate):eeg_duration_seconds)
    eeg_time = eeg_time[1:end - 1]
    eeg_filesize_mb = round(filesize(file_name) / 1024^2, digits=2)

    signal_type = "eeg"
    "meg" in channel_type && (signal_type = "meg")

    eeg_header = Dict(:signal_type => signal_type,
                      :eeg_filename => file_name,
                      :eeg_filesize_mb => eeg_filesize_mb,
                      :eeg_filetype => eeg_filetype,
                      :patient => string(patient),
                      :recording => string(recording),
                      :recording_date => recording_date,
                      :recording_time => recording_time,
                      :channel_n => channel_n,
                      :channel_type => channel_type[channel_order],
                      :reference => "",
                      :channel_locations => false,
                      :history => String[],
                      :components => Symbol[],
                      :eeg_duration_samples => eeg_duration_samples,
                      :eeg_duration_seconds => eeg_duration_seconds,
                      :epoch_n => 1,
                      :epoch_duration_samples => eeg_duration_samples,
                      :epoch_duration_seconds => eeg_duration_seconds,
                      :labels => labels[channel_order],
                      :transducers => transducers[channel_order],
                      :physical_dimension => physical_dimension[channel_order],
                      :prefiltering => prefiltering[channel_order],
                      :sampling_rate => sampling_rate,
                      :gain => gain[channel_order],
                      :note => "",
                      :markers => has_markers)

    eeg_components = Vector{Any}()
    eeg_epochs_time = eeg_time
    eeg_locs = DataFrame(:channel => Int64,
                         :labels => String[],
                         :loc_theta => Float64[],
                         :loc_radius => Float64[],
                         :loc_x => Float64[],
                         :loc_y => Float64[],
                         :loc_z => Float64[],
                         :loc_radius_sph => Float64[],
                         :loc_theta_sph => Float64[],
                         :loc_phi_sph => Float64[])

    eeg = NeuroAnalyzer.EEG(eeg_header, eeg_time, eeg_epochs_time, eeg_signals[channel_order, :, :], eeg_components, eeg_markers, eeg_locs)

    return eeg
end

"""
    eeg_import_ced(file_name)

Load electrode positions from CED file.

# Arguments

- `file_name::String`

# Returns

- `locs::DataFrame`
"""
function eeg_import_ced(file_name::String)

    isfile(file_name) || throw(ArgumentError("$file_name not found."))
    splitext(file_name)[2] == ".ced" || throw(ArgumentError("Not a CED file."))
    locs = CSV.read(file_name, delim="\t", DataFrame)

    colnames = lowercase.(names(locs))
    DataFrames.rename!(locs, Symbol.(colnames))

    labels = lstrip.(locs[!, "labels"])

    x = zeros(length(labels))
    y = zeros(length(labels))
    z = zeros(length(labels))
    radius = zeros(length(labels))
    theta = zeros(length(labels))
    radius_sph = zeros(length(labels))
    theta_sph = zeros(length(labels))
    phi_sph = zeros(length(labels))

    "x" in colnames && (x = Float64.(locs[!, "x"]))
    "y" in colnames && (y = Float64.(locs[!, "y"]))
    "z" in colnames && (z = Float64.(locs[!, "z"]))
    "theta" in colnames && (theta = Float64.(locs[!, "theta"]))
    "radius" in colnames && (radius = Float64.(locs[!, "radius"]))
    "sph_radius" in colnames && (radius_sph = Float64.(locs[!, "sph_radius"]))
    "sph_theta" in colnames && (theta_sph = Float64.(locs[!, "sph_theta"]))
    "sph_phi" in colnames && (phi_sph = Float64.(locs[!, "sph_phi"]))

    locs = DataFrame(:channel => 1:length(labels), :labels => labels, :loc_theta => theta, :loc_radius => radius, :loc_x => x, :loc_y => y, :loc_z => z, :loc_radius_sph => radius_sph, :loc_theta_sph => theta_sph, :loc_phi_sph => phi_sph)

    return locs
end

"""
    eeg_import_locs(file_name)

Load electrode positions from LOCS file.

# Arguments

- `file_name::String`

# Returns

- `locs::DataFrame`
"""
function eeg_import_locs(file_name::String)

    isfile(file_name) || throw(ArgumentError("$file_name not found."))
    splitext(file_name)[2] == ".locs" || throw(ArgumentError("Not a LOCS file."))
    locs = CSV.read(file_name, header=false, delim="\t", DataFrame)

    DataFrames.rename!(locs, [:number, :theta, :radius, :labels])
    labels = lstrip.(locs[!, "labels"])

    x = zeros(length(labels))
    y = zeros(length(labels))
    z = zeros(length(labels))
    radius = zeros(length(labels))
    theta = zeros(length(labels))
    radius_sph = zeros(length(labels))
    theta_sph = zeros(length(labels))
    phi_sph = zeros(length(labels))

    theta = Float64.(locs[!, "theta"])
    radius = Float64.(locs[!, "radius"])

    locs = DataFrame(:channel => 1:length(labels), :labels => labels, :loc_theta => theta, :loc_radius => radius, :loc_x => x, :loc_y => y, :loc_z => z, :loc_radius_sph => radius_sph, :loc_theta_sph => theta_sph, :loc_phi_sph => phi_sph)

    return locs
end

"""
    eeg_import_elc(file_name)

Load electrode positions from ELC file.

# Arguments

- `file_name::String`

# Returns

- `locs::DataFrame`
"""
function eeg_import_elc(file_name::String)

    isfile(file_name) || throw(ArgumentError("$file_name not found."))
    splitext(file_name)[2] == ".elc" || throw(ArgumentError("Not a ELC file."))
    f = open(file_name, "r")
    elc_file = readlines(f)
    close(f)
    locs_n = 0
    locs_l = 0
    for idx in eachindex(elc_file)
        if occursin("NumberPositions", elc_file[idx]) == true
            locs_n = parse(Int64, replace(elc_file[idx], "NumberPositions=" => ""))
            locs_l = idx + 2
        end
    end
    labels = repeat([""], locs_n)

    x = zeros(length(labels))
    y = zeros(length(labels))
    z = zeros(length(labels))
    theta = zeros(length(labels))
    radius = zeros(length(labels))
    radius_sph = zeros(length(labels))
    theta_sph = zeros(length(labels))
    phi_sph = zeros(length(labels))

    idx2 = 1
    for idx1 in locs_l:(locs_l + locs_n - 1)
        l = elc_file[idx1]
        l[1] == ' ' && (l = l[2:end])
        x[idx2], x[idx2], z[idx2] = parse.(Float64, split(l, ' '))
        idx2 += 1
    end
    idx2 = 1
    for idx1 in (locs_l + 1 + locs_n):(locs_l + (2 * locs_n))
        labels[idx2] = elc_file[idx1]
        idx2 += 1
    end

    locs = DataFrame(:channel => 1:length(labels), :labels => labels, :loc_theta => theta, :loc_radius => radius, :loc_x => x, :loc_y => y, :loc_z => z, :loc_radius_sph => radius_sph, :loc_theta_sph => theta_sph, :loc_phi_sph => phi_sph)

    return locs
end

"""
    eeg_import_tsv(file_name)

Load electrode positions from TSV file.

# Arguments

- `file_name::String`

# Returns

- `locs::DataFrame`
"""
function eeg_import_tsv(file_name::String)

    isfile(file_name) || throw(ArgumentError("$file_name not found."))
    splitext(file_name)[2] == ".tsv" || throw(ArgumentError("Not a TSV file."))
    locs = CSV.read(file_name, header=true, delim="\t", DataFrame)

    colnames = lowercase.(names(locs))
    DataFrames.rename!(locs, Symbol.(colnames))

    "labels" in colnames && (labels = lstrip.(locs[!, "labels"]))
    "label" in colnames && (labels = lstrip.(locs[!, "label"]))
    "site" in colnames && (labels = lstrip.(locs[!, "site"]))

    x = zeros(length(labels))
    y = zeros(length(labels))
    z = zeros(length(labels))
    radius = zeros(length(labels))
    theta = zeros(length(labels))
    radius_sph = zeros(length(labels))
    theta_sph = zeros(length(labels))
    phi_sph = zeros(length(labels))
    
    "x" in colnames && (x = Float64.(locs[!, "x"]))
    "y" in colnames && (y = Float64.(locs[!, "y"]))
    "z" in colnames && (z = Float64.(locs[!, "z"]))
    "theta" in colnames && (theta = Float64.(locs[!, "theta"]))
    "radius" in colnames && (radius = Float64.(locs[!, "radius"]))
    "radius" in colnames && (radius_sph = Float64.(locs[!, "radius"]))
    "radius_sph" in colnames && (radius_sph = locs[!, "radius_sph"])
    "theta" in colnames && (theta_sph = Float64.(locs[!, "theta"]))
    "theta_sph" in colnames && (theta_sph = locs[!, "theta_sph"])
    "phi" in colnames && (phi_sph = locs[!, "phi"])
    "phi_sph" in colnames && (phi_sph = locs[!, "phi_sph"])

    locs = DataFrame(:channel => 1:length(labels), :labels => labels, :loc_theta => theta, :loc_radius => radius, :loc_x => x, :loc_y => y, :loc_z => z, :loc_radius_sph => radius_sph, :loc_theta_sph => theta_sph, :loc_phi_sph => phi_sph)

    return locs
end

"""
    eeg_import_sfp(file_name)

Load electrode positions from SFP file.

# Arguments

- `file_name::String`

# Returns

- `locs::DataFrame`
"""
function eeg_import_sfp(file_name::String)

    isfile(file_name) || throw(ArgumentError("$file_name not found."))
    splitext(file_name)[2] == ".sfp" || throw(ArgumentError("Not a SFP file."))
    locs = CSV.read(file_name, header=false, delim="\t", DataFrame)

    DataFrames.rename!(locs, [:label, :x, :y, :z])

    labels = lstrip.(locs[!, "label"])

    x = zeros(length(labels))
    y = zeros(length(labels))
    z = zeros(length(labels))
    radius = zeros(length(labels))
    theta = zeros(length(labels))
    radius_sph = zeros(length(labels))
    theta_sph = zeros(length(labels))
    phi_sph = zeros(length(labels))
    
    x = Float64.(locs[!, "x"])
    y = Float64.(locs[!, "y"])
    z = Float64.(locs[!, "z"])

    locs = DataFrame(:channel => 1:length(labels), :labels => labels, :loc_theta => theta, :loc_radius => radius, :loc_x => x, :loc_y => y, :loc_z => z, :loc_radius_sph => radius_sph, :loc_theta_sph => theta_sph, :loc_phi_sph => phi_sph)

    return locs
end

"""
    eeg_import_csd(file_name)

Load electrode positions from CSD file.

# Arguments

- `file_name::String`

# Returns

- `locs::DataFrame`
"""
function eeg_import_csd(file_name::String)

    isfile(file_name) || throw(ArgumentError("$file_name not found."))
    splitext(file_name)[2] == ".csd" || throw(ArgumentError("Not a csd file."))
    locs = CSV.read(file_name, skipto=3, delim=' ', header=false, ignorerepeated=true, DataFrame)

    DataFrames.rename!(locs, [:labels, :theta_sph, :phi_sph, :radius_sph, :x, :y, :z, :surface])
    labels = lstrip.(locs[!, "labels"])

    x = Float64.(locs[!, "x"])
    y = Float64.(locs[!, "y"])
    z = Float64.(locs[!, "z"])
    radius = Float64.(locs[!, "radius_sph"])
    theta = Float64.(locs[!, "theta_sph"])
    theta_sph = Float64.(locs[!, "theta_sph"])
    phi_sph = Float64.(locs[!, "phi_sph"])
    radius_sph = Float64.(locs[!, "radius_sph"])

    locs = DataFrame(:channel => 1:length(labels), :labels => labels, :loc_theta => theta, :loc_radius => radius, :loc_x => x, :loc_y => y, :loc_z => z, :loc_radius_sph => radius_sph, :loc_theta_sph => theta_sph, :loc_phi_sph => phi_sph)

    return locs
end

"""
    eeg_load_electrodes(eeg; file_name)

Load electrode positions from `file_name` and return `NeuroAnalyzer.EEG` object with metadata: `:channel_locations`, `:loc_theta`, `:loc_radius`, `:loc_x`, `:loc_x`, `:loc_y`, `:loc_radius_sph`, `:loc_theta_sph`, `:loc_phi_sph`. 

Accepted formats:
- CED
- LOCS
- ELC
- TSV
- SFP
- CSD

Electrode locations:
- `loc_theta`       planar polar angle
- `loc_radius`      planar polar radius
- `loc_x`           spherical Cartesian x
- `loc_y`           spherical Cartesian y
- `loc_z`           spherical Cartesian z
- `loc_radius_sph`  spherical radius
- `loc_theta_sph`   spherical horizontal angle
- `loc_phi_sph`     spherical azimuth angle

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `file_name::String`

# Returns

- `eeg:EEG`
"""
function eeg_load_electrodes(eeg::NeuroAnalyzer.EEG; file_name::String)

    isfile(file_name) || throw(ArgumentError("File $file_name cannot be loaded."))
    length(eeg.eeg_header[:labels]) > 0 || throw(ArgumentError("EEG does not contain labels, use eeg_add_labels() first."))

    if splitext(file_name)[2] == ".ced"
        locs = eeg_import_ced(file_name)
    elseif splitext(file_name)[2] == ".elc"
        locs = eeg_import_elc(file_name)
    elseif splitext(file_name)[2] == ".locs"
        locs = eeg_import_locs(file_name)
    elseif splitext(file_name)[2] == ".tsv"
        locs = eeg_import_tsv(file_name)
    elseif splitext(file_name)[2] == ".sfp"
        locs = eeg_import_sfp(file_name)
    elseif splitext(file_name)[2] == ".csd"
        locs = eeg_import_csd(file_name)
    else
        throw(ArgumentError("Unknown file format."))
    end

    f_labels = locs[!, :labels]

    loc_theta = float.(locs[!, :loc_theta])
    loc_radius = float.(locs[!, :loc_radius])

    loc_radius_sph = float.(locs[!, :loc_radius_sph])
    loc_theta_sph = float.(locs[!, :loc_theta_sph])
    loc_phi_sph = float.(locs[!, :loc_phi_sph])

    loc_x = float.(locs[!, :loc_x])
    loc_y = float.(locs[!, :loc_y])
    loc_z = float.(locs[!, :loc_z])

    e_labels = lowercase.(eeg.eeg_header[:labels])
    no_match = setdiff(e_labels, lowercase.(f_labels))
    length(no_match) > 0 && @info "Labels: $(uppercase.(no_match)) not found in $file_name."

    labels_idx = zeros(Int64, length(e_labels))
    for idx1 in eachindex(e_labels)
        for idx2 in eachindex(f_labels)
            e_labels[idx1] == lowercase.(f_labels)[idx2] && (labels_idx[idx1] = idx2)
        end
    end
    for idx in length(labels_idx):-1:1
        labels_idx[idx] == 0 && deleteat!(labels_idx, idx)
    end

    # create new dataset
    eeg_new = deepcopy(eeg)
    eeg_new.eeg_header[:channel_locations] = true
    eeg_new.eeg_locs = DataFrame(:channel => 1:length(e_labels),
                                 :labels => f_labels[labels_idx],
                                 :loc_theta => loc_theta[labels_idx],
                                 :loc_radius => loc_radius[labels_idx],
                                 :loc_x => loc_x[labels_idx],
                                 :loc_y => loc_y[labels_idx],
                                 :loc_z => loc_z[labels_idx],
                                 :loc_radius_sph => loc_radius_sph[labels_idx],
                                 :loc_theta_sph => loc_theta_sph[labels_idx],
                                 :loc_phi_sph => loc_phi_sph[labels_idx])

    # add entry to :history field
    push!(eeg_new.eeg_header[:history], "eeg_load_electrodes(EEG, file_name=$file_name)")

    return eeg_new
end

"""
    eeg_load_electrodes!(eeg; file_name)

Load electrode positions from `file_name` and return `NeuroAnalyzer.EEG` object with metadata: `:channel_locations`, `:loc_theta`, `:loc_radius`, `:loc_x`, `:loc_x`, `:loc_y`, `:loc_radius_sph`, `:loc_theta_sph`, `:loc_phi_sph`. 

Accepted formats:
- CED
- LOCS
- ELC
- TSV
- SFP

Electrode locations:
- `loc_theta`       planar polar angle
- `loc_radius`      planar polar radius
- `loc_x`           spherical Cartesian x
- `loc_y`           spherical Cartesian y
- `loc_z`           spherical Cartesian z
- `loc_radius_sph`  spherical radius
- `loc_theta_sph`   spherical horizontal angle
- `loc_phi_sph`     spherical azimuth angle

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `file_name::String`
"""
function eeg_load_electrodes!(eeg::NeuroAnalyzer.EEG; file_name::String)
    
    isfile(file_name) || throw(ArgumentError("File $file_name cannot be loaded."))
    length(eeg.eeg_header[:labels]) > 0 || throw(ArgumentError("EEG does not contain labels, use eeg_add_labels() first."))

    if splitext(file_name)[2] == ".ced"
        locs = eeg_import_ced(file_name)
    elseif splitext(file_name)[2] == ".elc"
        locs = eeg_import_elc(file_name)
    elseif splitext(file_name)[2] == ".locs"
        locs = eeg_import_locs(file_name)
    elseif splitext(file_name)[2] == ".tsv"
        locs = eeg_import_tsv(file_name)
    elseif splitext(file_name)[2] == ".sfp"
        locs = eeg_import_sfp(file_name)
    else
        throw(ArgumentError("Unknown file format."))
    end

    f_labels = locs[!, :labels]

    loc_theta = float.(locs[!, :loc_theta])
    loc_radius = float.(locs[!, :loc_radius])

    loc_radius_sph = float.(locs[!, :loc_radius_sph])
    loc_theta_sph = float.(locs[!, :loc_theta_sph])
    loc_phi_sph = float.(locs[!, :loc_phi_sph])

    loc_x = float.(locs[!, :loc_x])
    loc_y = float.(locs[!, :loc_y])
    loc_z = float.(locs[!, :loc_z])

    e_labels = lowercase.(eeg.eeg_header[:labels])
    no_match = setdiff(e_labels, lowercase.(f_labels))
    length(no_match) > 0 && @info "Labels: $(uppercase.(no_match)) were not found in $file_name."

    labels_idx = zeros(Int64, length(e_labels))
    for idx1 in eachindex(e_labels)
        for idx2 in eachindex(f_labels)
            e_labels[idx1] == lowercase.(f_labels)[idx2] && (labels_idx[idx1] = idx2)
        end
    end
    for idx in length(labels_idx):-1:1
        labels_idx[idx] == 0 && deleteat!(labels_idx, idx)
    end

    # create new dataset
    eeg.eeg_locs = DataFrame(:channel => 1:length(f_labels),
                             :labels => f_labels,
                             :loc_theta => loc_theta[labels_idx],
                             :loc_radius => loc_radius[labels_idx],
                             :loc_x => loc_x[labels_idx],
                             :loc_y => loc_y[labels_idx],
                             :loc_z => loc_z[labels_idx],
                             :loc_radius_sph => loc_radius_sph[labels_idx],
                             :loc_theta_sph => loc_theta_sph[labels_idx],
                             :loc_phi_sph => loc_phi_sph[labels_idx])
    eeg.eeg_header[:channel_locations] = true

    # add entry to :history field
    push!(eeg.eeg_header[:history], "eeg_load_electrodes!(EEG, $file_name)")
    nothing
 end

"""
    eeg_save(eeg; file_name, overwrite)

Save `eeg` to `file_name` file (HDF5-based).

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `file_name::String`: file name
- `overwrite::Bool=false`

# Returns

- `success::Bool`
"""
function eeg_save(eeg::NeuroAnalyzer.EEG; file_name::String, overwrite::Bool=false)

    (isfile(file_name) && overwrite == false) && throw(ArgumentError("File $file_name cannot be saved, to overwrite use overwrite=true."))

    eeg.eeg_header[:eeg_filename] = file_name

    save_object("/tmp/$(basename(file_name))", eeg)
    eeg.eeg_header[:eeg_filesize_mb] = round(filesize("/tmp/$(basename(file_name))") / 1024, digits=2)
    rm("/tmp/$(basename(file_name))")

    save_object(file_name, eeg)
end

"""
    eeg_load(file_name)

Load `eeg` from `file_name` file (HDF5-based).

# Arguments

- `file_name::String`: file name

# Returns

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_load(file_name::String)

    isfile(file_name) || throw(ArgumentError("File $file_name cannot be loaded."))

    eeg = load_object(file_name)

    return eeg
end

"""
    eeg_export_csv(eeg; file_name, header, components, markers, overwrite)

Export EEG data as CSV.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `file_name::String`
- `header::Bool=false`: export header
- `components::Bool=false`: export components
- `markers::Bool=false`: export markers
- `locs::Bool=false`: export locations
- `overwrite::Bool=false`

# Returns

- `success::Bool`
"""
function eeg_export_csv(eeg::NeuroAnalyzer.EEG; file_name::String, header::Bool=false, components::Bool=false, markers::Bool=false, locs::Bool=false, overwrite::Bool=false)

    (isfile(file_name) && overwrite == false) && throw(ArgumentError("File $file_name cannot be saved, to overwrite use overwrite=true."))
    eeg.eeg_header[:components] == [""] && throw(ArgumentError("EEG does not contain components."))

    # DATA
    # unsplit epochs
    s_merged = reshape(eeg.eeg_signals,
                       size(eeg.eeg_signals, 1),
                       size(eeg.eeg_signals, 2) * size(eeg.eeg_signals, 3))
    s = s_merged[:, :, 1]'
    s = hcat(eeg.eeg_time, s)
    l = vcat("time", eeg_labels(eeg))
    CSV.write(file_name, DataFrame(s, l))

    # HEADER
    if header
        file_name = replace(file_name, ".csv" => "_header.csv")
        (isfile(file_name) && overwrite == false) && throw(ArgumentError("File $file_name cannot be saved, to overwrite use overwrite=true."))
        f = open(file_name, "w")
        for (key, value) in eeg.eeg_header
            println(f, key, ": ", value)
        end
        close(f)
    end

    # COMPONENTS
    if components
        file_name = replace(file_name, ".csv" => "_components.csv")
        (isfile(file_name) && overwrite == false) && throw(ArgumentError("File $file_name cannot be saved, to overwrite use overwrite=true."))
        f = open(file_name, "w")
        for idx in eachindex(eeg.eeg_header[:components])
            println(f, "component: $(eeg.eeg_header[:components][idx])")
            println(f, eeg.eeg_components[idx])
            println(f, "---")
        end
        close(f)
    end

    # MARKERS
    if markers
        file_name = replace(file_name, ".csv" => "_markers.csv")
        (isfile(file_name) && overwrite == false) && throw(ArgumentError("File $file_name cannot be saved, to overwrite use overwrite=true."))
        CSV.write(file_name, eeg.eeg_markers)
    end

    # LOCS
    if locs
        file_name = replace(file_name, ".csv" => "_locs.csv")
        (isfile(file_name) && overwrite == false) && throw(ArgumentError("File $file_name cannot be saved, to overwrite use overwrite=true."))
        CSV.write(file_name, eeg.eeg_locs)
    end
end

"""
    eeg_save_electrodes(eeg; file_name, overwrite)

Export EEG channel locations data, format is based on `file_name` extension (.ced, .locs or .tsv)

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `file_name::String`
- `overwrite::Bool=false`
"""
function eeg_save_electrodes(eeg::NeuroAnalyzer.EEG; file_name::String, overwrite::Bool=false)

    (isfile(file_name) && overwrite == false) && throw(ArgumentError("File $file_name cannot be saved, to overwrite use overwrite=true."))

    channels = eeg.eeg_locs[!, :channel]
    labels = eeg.eeg_locs[!, :labels]
    theta = eeg.eeg_locs[!, :loc_theta]
    radius = eeg.eeg_locs[!, :loc_radius]
    x = eeg.eeg_locs[!, :loc_x]
    y = eeg.eeg_locs[!, :loc_y]
    z = eeg.eeg_locs[!, :loc_z]
    radius_sph = eeg.eeg_locs[!, :loc_radius_sph]
    theta_sph = eeg.eeg_locs[!, :loc_theta_sph]
    phi_sph = eeg.eeg_locs[!, :loc_phi_sph]

    if splitext(file_name)[2] == ".ced"
        df = DataFrame(Number=channels, labels=labels, theta=theta, radius=radius, X=x, Y=y, Z=z, sph_theta=theta_sph, sph_phi=phi_sph, sph_radius=radius_sph)
        CSV.write(file_name, df, delim="\t", header=true)
    elseif splitext(file_name)[2] == ".locs"
        df = DataFrame(Number=channels, theta=theta, radius=radius, labels=labels)
        CSV.write(file_name, df, delim="\t", header=false)
    elseif splitext(file_name)[2] == ".tsv"
        df = DataFrame(labels=labels, x=x, y=y, z=z, theta=theta, radius=radius, radius_sph=radius_sph, theta_sph=theta_sph, phi_sph=phi_sph)
        CSV.write(file_name, df, delim="\t", header=true)
    else
        throw(ArgumentError("$file_name format must be .ced, .locs or .tsv."))
    end
end

"""
    eeg_save_electrodes(locs; file_name, overwrite)

Export channel locations, format is based on `file_name` extension (.ced, .locs, .tsv)

# Arguments

- `locs::DataFrame`
- `file_name::String`
- `overwrite::Bool=false`

# Returns

- `success::Bool`
"""
function eeg_save_electrodes(locs::DataFrame; file_name::String, overwrite::Bool=false)

    (isfile(file_name) && overwrite == false) && throw(ArgumentError("File $file_name cannot be saved, to overwrite use overwrite=true."))

    channels = locs[!, :channel]
    labels = locs[!, :labels]
    theta = locs[!, :loc_theta]
    radius = locs[!, :loc_radius]
    x = locs[!, :loc_x]
    y = locs[!, :loc_y]
    z = locs[!, :loc_z]
    radius_sph = locs[!, :loc_radius_sph]
    theta_sph = locs[!, :loc_theta_sph]
    phi_sph = locs[!, :loc_phi_sph]

    if splitext(file_name)[2] == ".ced"
        df = DataFrame(Number=channels, labels=labels, theta=theta, radius=radius, X=x, Y=y, Z=z, sph_theta=theta_sph, sph_phi=phi_sph, sph_radius=radius_sph, head=true)
        CSV.write(file_name, df, delim="\t")
    elseif splitext(file_name)[2] == ".locs"
        df = DataFrame(Number=channels, theta=theta, radius=radius, labels=labels)
        CSV.write(file_name, df, delim="\t", header=false)
    elseif splitext(file_name)[2] == ".tsv"
        df = DataFrame(labels=labels, x=x, y=y, z=z, theta=theta, radius=radius, radius_sph=radius_sph, theta_sph=theta_sph, phi_sph=phi_sph)
        CSV.write(file_name, df, delim="\t", header=true)
    else
        throw(ArgumentError("file_name format must be .ced, .locs or .tsv."))
    end
end

"""
    eeg_add_electrodes(eeg; locs)

Add electrode positions from `locs`. 

Electrode locations:
- `channel`         channel number
- `labels`          channel label
- `loc_theta`       planar polar angle
- `loc_radius`      planar polar radius
- `loc_x`           spherical Cartesian x
- `loc_y`           spherical Cartesian y
- `loc_z`           spherical Cartesian z
- `loc_radius_sph`  spherical radius
- `loc_theta_sph`   spherical horizontal angle
- `loc_phi_sph`     spherical azimuth angle

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `locs::DataFrame`

# Returns

- `eeg:EEG`
"""
function eeg_add_electrodes(eeg::NeuroAnalyzer.EEG; locs::DataFrame)

    f_labels = lowercase.(locs[!, :labels])

    e_labels = lowercase.(eeg.eeg_header[:labels])
    no_match = setdiff(e_labels, f_labels)
    length(no_match) > 0 && throw(ArgumentError("Labels: $(uppercase.(no_match)) not found in the locs object."))

    labels_idx = zeros(Int64, length(e_labels))
    for idx1 in eachindex(e_labels)
        for idx2 in eachindex(f_labels)
            e_labels[idx1] == f_labels[idx2] && (labels_idx[idx1] = idx2)
        end
    end
    
    # create new dataset
    eeg_new = deepcopy(eeg)
    eeg_new.eeg_header[:channel_locations] = true
    eeg_new.eeg_locs = locs

    # add entry to :history field
    push!(eeg_new.eeg_header[:history], "eeg_add_electrodes(EEG, locs)")

    return eeg_new
end

"""
    eeg_add_electrodes!(eeg; locs)

Load electrode positions from `locs` and return `NeuroAnalyzer.EEG` object with metadata: `:channel_locations`, `:loc_theta`, `:loc_radius`, `:loc_x`, `:loc_x`, `:loc_y`, `:loc_radius_sph`, `:loc_theta_sph`, `:loc_phi_sph`. 

Electrode locations:
- `channel`         channel number
- `labels`          channel label
- `loc_theta`       planar polar angle
- `loc_radius`      planar polar radius
- `loc_x`           spherical Cartesian x
- `loc_y`           spherical Cartesian y
- `loc_z`           spherical Cartesian z
- `loc_radius_sph`  spherical radius
- `loc_theta_sph`   spherical horizontal angle
- `loc_phi_sph`     spherical azimuth angle

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `locs::DataFrame`
"""
function eeg_add_electrodes!(eeg::NeuroAnalyzer.EEG; locs::DataFrame)
    
    f_labels = lowercase.(locs[!, :labels])

    e_labels = lowercase.(eeg.eeg_header[:labels])
    no_match = setdiff(e_labels, f_labels)
    length(no_match) > 0 && throw(ArgumentError("Labels: $(uppercase.(no_match)) not found in the locs object."))

    labels_idx = zeros(Int64, length(e_labels))
    for idx1 in eachindex(e_labels)
        for idx2 in eachindex(f_labels)
            e_labels[idx1] == f_labels[idx2] && (labels_idx[idx1] = idx2)
        end
    end
    
    # create new dataset
    eeg.eeg_locs = locs

    # add entry to :history field
    push!(eeg.eeg_header[:history], "eeg_add_electrodes!(EEG, locs)")
    nothing
 end

"""
    eeg_import_bdf(file_name; detect_type)

Load BDF/BDF+ file and return `NeuroAnalyzer.EEG` object.

# Arguments

- `file_name::String`: name of the file to load
- `detect_type::Bool=true`: detect channel type based on its label

# Returns

- `eeg:EEG`

# Notes

- sampling_rate = n.samples / data.record.duration
- gain = (physical_maximum - physical_minimum) / (digital_maximum - digital_minimum)
- value = (value - digital_minimum ) * gain + physical_minimum

# Source

https://www.biosemi.com/faq/file_format.htm
"""
function eeg_import_bdf(file_name::String; detect_type::Bool=true)

    isfile(file_name) || throw(ArgumentError("File $file_name cannot be loaded."))

    eeg_filetype = ""
    fid = open(file_name)
    header = zeros(UInt8, 256)
    readbytes!(fid, header, 256)
    header = String(Char.(header))

    eeg_filetype = Int(header[1])
    eeg_filetype == 255 && (eeg_filetype = "BDF")
    (eeg_filetype !== "BDF" && strip(header[3:9]) !== "BIOSEMI") && throw(ArgumentError("File $file_name is not a BDF file."))

    patient = strip(header[10:89])
    recording = strip(header[90:169])
    recording_date = header[170:177]
    recording_time = header[178:185]
    data_offset = parse(Int, strip(header[186:192]))
    reserved  = strip(header[193:236])
    reserved == "BDF+D" && throw(ArgumentError("BDF+D format (interrupted recordings) is not supported yet."))
    reserved == "BDF+C" && (eeg_filetype = "BDF+")
    data_records = parse(Int, strip(header[237:244]))
    data_records_duration  = parse(Float64, strip(header[245:252]))
    channel_n  = parse(Int, strip(header[253:256]))

    labels = Vector{String}(undef, channel_n)
    transducers = Vector{String}(undef, channel_n)
    physical_dimension = Vector{String}(undef, channel_n)
    physical_minimum = Vector{Float64}(undef, channel_n)
    physical_maximum = Vector{Float64}(undef, channel_n)
    digital_minimum = Vector{Float64}(undef, channel_n)
    digital_maximum = Vector{Float64}(undef, channel_n)
    prefiltering = Vector{String}(undef, channel_n)
    samples_per_datarecord = Vector{Int64}(undef, channel_n)

    header = zeros(UInt8, channel_n * 16)
    readbytes!(fid, header, channel_n * 16)
    header = String(Char.(header))
    for idx in 1:channel_n
        labels[idx] = strip(header[1 + ((idx - 1) * 16):(idx * 16)])
    end

    header = zeros(UInt8, channel_n * 80)
    readbytes!(fid, header, channel_n * 80)
    header = String(Char.(header))
    for idx in 1:channel_n
        transducers[idx] = strip(header[1 + ((idx - 1) * 80):(idx * 80)])
    end

    header = zeros(UInt8, channel_n * 8)
    readbytes!(fid, header, channel_n * 8)
    header = String(Char.(header))
    for idx in 1:channel_n
        physical_dimension[idx] = strip(header[1 + ((idx - 1) * 8):(idx * 8)])
    end

    header = zeros(UInt8, channel_n * 8)
    readbytes!(fid, header, channel_n * 8)
    header = String(Char.(header))
    for idx in 1:channel_n
        physical_minimum[idx] = parse(Float64, strip(header[1 + ((idx - 1) * 8):(idx * 8)]))
    end

    header = zeros(UInt8, channel_n * 8)
    readbytes!(fid, header, channel_n * 8)
    header = String(Char.(header))
    for idx in 1:channel_n
        physical_maximum[idx] = parse(Float64, strip(header[1 + ((idx - 1) * 8):(idx * 8)]))
    end

    header = zeros(UInt8, channel_n * 8)
    readbytes!(fid, header, channel_n * 8)
    header = String(Char.(header))
    for idx in 1:channel_n
        digital_minimum[idx] = parse(Float64, strip(header[1 + ((idx - 1) * 8):(idx * 8)]))
    end

    header = zeros(UInt8, channel_n * 8)
    readbytes!(fid, header, channel_n * 8)
    header = String(Char.(header))
    for idx in 1:channel_n
        digital_maximum[idx] = parse(Float64, strip(header[1 + ((idx - 1) * 8):(idx * 8)]))
    end

    header = zeros(UInt8, channel_n * 80)
    readbytes!(fid, header, channel_n * 80)
    header = String(Char.(header))
    for idx in 1:channel_n
        prefiltering[idx] = strip(header[1 + ((idx - 1) * 80):(idx * 80)])
    end

    header = zeros(UInt8, channel_n * 8)
    readbytes!(fid, header, channel_n * 8)
    header = String(Char.(header))
    for idx in 1:channel_n
        samples_per_datarecord[idx] = parse(Int, strip(header[1 + ((idx - 1) * 8):(idx * 8)]))
    end

    close(fid)

    sampling_rate = round(Int64, samples_per_datarecord[1] / data_records_duration)
    gain = Vector{Float64}(undef, channel_n)
    for idx in 1:channel_n
        gain[idx] = (physical_maximum[idx] - physical_minimum[idx]) / (digital_maximum[idx] - digital_minimum[idx])
    end

    labels = _clean_labels(labels)
    if detect_type == true
        channel_type = _set_channel_types(labels)
    else
        channel_type = repeat(["???"], channel_n)
    end
    channel_order = _sort_channels(copy(channel_type))
    has_markers, markers_channel = _has_markers(channel_type)

    fid = open(file_name)
    header = zeros(UInt8, data_offset)
    readbytes!(fid, header, data_offset)
    eeg_signals = zeros(channel_n, samples_per_datarecord[1] * data_records, 1)
    markers = repeat([""], data_records)
    for idx1 in 1:data_records
        for idx2 in 1:channel_n
            signal24 = zeros(UInt8, samples_per_datarecord[idx2] * 3)
            readbytes!(fid, signal24, samples_per_datarecord[idx2] * 3)
            if idx2 != markers_channel
                signal = Vector{Float64}()
                for byte_idx in 1:3:length(signal24)
                    b1 = Int32(signal24[byte_idx]) << 8
                    b2 = Int32(signal24[byte_idx + 1]) << 16
                    b3 = -Int32(-signal24[byte_idx + 2]) << 24
                    push!(signal, Float64(((b1 | b2 | b3) >> 8) * gain[idx2]))
                end
                if channel_type[idx2] == "markers"
                    for idx3 in eachindex(signal)
                        if signal[idx3] == digital_minimum[idx2]
                            signal[idx3] = 0
                        else
                            signal[idx3] = 1
                        end
                    end
                    eeg_signals[idx2, ((idx1 - 1) * samples_per_datarecord[idx2] + 1):(idx1 * samples_per_datarecord[idx2]), 1] = signal
                elseif channel_type[idx2] == "events"
                    eeg_signals[idx2, ((idx1 - 1) * samples_per_datarecord[idx2] + 1):(idx1 * samples_per_datarecord[idx2]), 1] = signal
                else
                    if occursin("uV", physical_dimension[idx2]) 
                        eeg_signals[idx2, ((idx1 - 1) * samples_per_datarecord[idx2] + 1):(idx1 * samples_per_datarecord[idx2]), 1] = signal .* gain[idx2]
                    elseif occursin("mV", physical_dimension[idx2])
                        eeg_signals[idx2, ((idx1 - 1) * samples_per_datarecord[idx2] + 1):(idx1 * samples_per_datarecord[idx2]), 1] = signal .* gain[idx2] ./ 1000
                    else
                        eeg_signals[idx2, ((idx1 - 1) * samples_per_datarecord[idx2] + 1):(idx1 * samples_per_datarecord[idx2]), 1] = signal .* gain[idx2]
                    end
                end
            else
                markers[idx1] = String(Char.(signal24))
            end
        end
    end
    close(fid)

    if has_markers
        deleteat!(channel_order, vsearch(markers_channel, channel_order))
        eeg_signals = eeg_signals[setdiff(1:channel_n, markers_channel), :, :]
        deleteat!(channel_type, markers_channel)
        deleteat!(labels, markers_channel)
        deleteat!(transducers, markers_channel)
        deleteat!(physical_dimension, markers_channel)
        deleteat!(prefiltering, markers_channel)
        deleteat!(gain, markers_channel)
        channel_n -= 1
        eeg_markers = _m2df(markers)
        # convert markers time to samples
        eeg_markers[!, :start] = t2s.(eeg_markers[!, :start], sampling_rate)
        eeg_markers[!, :length] = t2s.(eeg_markers[!, :length], sampling_rate)
    else
        eeg_markers = DataFrame(:id => String[], :start => Int64[], :length => Int64[], :description => String[], :channel => Int64[])
    end

    eeg_duration_samples = size(eeg_signals, 2)
    eeg_duration_seconds = size(eeg_signals, 2) / sampling_rate
    eeg_time = collect(0:(1 / sampling_rate):eeg_duration_seconds)
    eeg_time = eeg_time[1:end - 1]
    eeg_filesize_mb = round(filesize(file_name) / 1024^2, digits=2)

    signal_type = "eeg"
    "meg" in channel_type && (signal_type = "meg")

    eeg_header = Dict(:signal_type => signal_type,
                      :eeg_filename => file_name,
                      :eeg_filesize_mb => eeg_filesize_mb,
                      :eeg_filetype => eeg_filetype,
                      :patient => string(patient),
                      :recording => string(recording),
                      :recording_date => recording_date,
                      :recording_time => recording_time,
                      :channel_n => channel_n,
                      :channel_type => channel_type,
                      :reference => "",
                      :channel_locations => false,
                      :history => String[],
                      :components => Symbol[],
                      :eeg_duration_samples => eeg_duration_samples,
                      :eeg_duration_seconds => eeg_duration_seconds,
                      :epoch_n => 1,
                      :epoch_duration_samples => eeg_duration_samples,
                      :epoch_duration_seconds => eeg_duration_seconds,
                      :labels => labels[channel_order],
                      :transducers => transducers[channel_order],
                      :physical_dimension => physical_dimension[channel_order],
                      :prefiltering => prefiltering[channel_order],
                      :sampling_rate => sampling_rate,
                      :gain => gain[channel_order],
                      :note => "",
                      :markers => has_markers)

    eeg_components = Vector{Any}()
    eeg_epochs_time = eeg_time
    eeg_locs = DataFrame(:channel => Int64,
                         :labels => String[],
                         :loc_theta => Float64[],
                         :loc_radius => Float64[],
                         :loc_x => Float64[],
                         :loc_y => Float64[],
                         :loc_z => Float64[],
                         :loc_radius_sph => Float64[],
                         :loc_theta_sph => Float64[],
                         :loc_phi_sph => Float64[])

    eeg = NeuroAnalyzer.EEG(eeg_header, eeg_time, eeg_epochs_time, eeg_signals[channel_order, :, :], eeg_components, eeg_markers, eeg_locs)

    return eeg
end

"""
    eeg_import_digitrack(file_name; detect_type)

Load Digitrack ASCII file and return `NeuroAnalyzer.EEG` object.

# Arguments

- `file_name::String`: name of the file to load
- `detect_type::Bool=true`: detect channel type based on its label

# Returns

- `eeg:EEG`

# Notes
"""
function eeg_import_digitrack(file_name::String; detect_type::Bool=true)
 
    isfile(file_name) || throw(ArgumentError("File $file_name cannot be loaded."))

    fid = open(file_name)

    buffer = readline(fid)
    occursin("Start time ", buffer) || throw(ArgumentError("File $file_name is not a Digitrack file."))
    eeg_filetype = "Digitrack"

    patient = ""
    recording = ""
    buffer = replace(buffer, "Start time " => "")
    recording_date = split(buffer, " ")[1]
    recording_time = split(buffer, " ")[2]

    buffer = readline(fid)
    buffer = replace(buffer, "Sampling rate " => "")
    buffer = replace(buffer, "," => ".")
    sampling_rate = round(Int64, parse(Float64, replace(buffer, " Hz" => "")))

    data_records = -1
    data_records_duration  = -1

    buffer = readline(fid)

    channels = Vector{String}()
    while buffer !=""
        buffer = readline(fid)
        push!(channels, buffer)
    end
    deleteat!(channels, length(channels))
    channel_n  = length(channels)

    labels = Vector{String}(undef, channel_n)
    prefiltering = Vector{String}(undef, channel_n)
    for idx in 1:channel_n
        labels[idx] = split(channels[idx], "\t")[1]
        prefiltering[idx] = split(channels[idx], "\t")[2]
        prefiltering[idx] = prefiltering[idx][1:(length(prefiltering[idx]) - 1)]
    end

    transducers = repeat([""], channel_n)
    physical_dimension = repeat([""], channel_n)
    gain = repeat([-1.0], channel_n)
    
    labels = _clean_labels(labels)
    if detect_type == true
        channel_type = _set_channel_types(labels)
    else
        channel_type = repeat(["???"], channel_n)
    end
    channel_order = _sort_channels(copy(channel_type))
    has_markers, markers_channel = _has_markers(channel_type)

    data = readlines(fid)

    close(fid)

    eeg_signals = zeros(channel_n, length(data), 1)
    Threads.@threads for idx in eachindex(data)
        signals = split(data[idx], "\t")
        deleteat!(signals, length(signals))
        signals = replace.(signals, "," => ".")
        @inbounds eeg_signals[:, idx, 1] = parse.(Float64, signals)
    end

    eeg_markers = DataFrame(:id => String[], :start => Int64[], :length => Int64[], :description => String[], :channel => Int64[])
    eeg_duration_samples = size(eeg_signals, 2)
    eeg_duration_seconds = size(eeg_signals, 2) / sampling_rate
    eeg_time = collect(0:(1 / sampling_rate):eeg_duration_seconds)
    eeg_time = eeg_time[1:end - 1]
    eeg_filesize_mb = round(filesize(file_name) / 1024^2, digits=2)

    signal_type = "eeg"
    "meg" in channel_type && (signal_type = "meg")

    eeg_header = Dict(:signal_type => signal_type,
                      :eeg_filename => file_name,
                      :eeg_filesize_mb => eeg_filesize_mb,
                      :eeg_filetype => eeg_filetype,
                      :patient => string(patient),
                      :recording => string(recording),
                      :recording_date => recording_date,
                      :recording_time => recording_time,
                      :channel_n => channel_n,
                      :channel_type => channel_type,
                      :reference => "",
                      :channel_locations => false,
                      :history => String[],
                      :components => Symbol[],
                      :eeg_duration_samples => eeg_duration_samples,
                      :eeg_duration_seconds => eeg_duration_seconds,
                      :epoch_n => 1,
                      :epoch_duration_samples => eeg_duration_samples,
                      :epoch_duration_seconds => eeg_duration_seconds,
                      :labels => labels[channel_order],
                      :transducers => transducers[channel_order],
                      :physical_dimension => physical_dimension[channel_order],
                      :prefiltering => prefiltering[channel_order],
                      :sampling_rate => sampling_rate,
                      :gain => gain[channel_order],
                      :note => "",
                      :markers => has_markers)

    eeg_components = Vector{Any}()
    eeg_epochs_time = eeg_time
    eeg_locs = DataFrame(:channel => Int64,
                         :labels => String[],
                         :loc_theta => Float64[],
                         :loc_radius => Float64[],
                         :loc_x => Float64[],
                         :loc_y => Float64[],
                         :loc_z => Float64[],
                         :loc_radius_sph => Float64[],
                         :loc_theta_sph => Float64[],
                         :loc_phi_sph => Float64[])

    eeg = NeuroAnalyzer.EEG(eeg_header, eeg_time, eeg_epochs_time, eeg_signals[channel_order, :, :], eeg_components, eeg_markers, eeg_locs)

    return eeg
end

"""
    eeg_import_bv(file_name; detect_type)

Load BrainVision BVCDF file and return `NeuroAnalyzer.EEG` object. At least two files are required: .vhdr (header) and .eeg (signal data). If available, markers are loaded from .vmrk file.

# Arguments

- `file_name::String`: name of the file to load, should point to .vhdr file.
- `detect_type::Bool=true`: detect channel type based on its label

# Returns

- `eeg:EEG`
"""
function eeg_import_bv(file_name::String; detect_type::Bool=true)

    isfile(file_name) || throw(ArgumentError("File $file_name cannot be loaded."))
    splitext(file_name)[2] == ".vhdr" || throw(ArgumentError("file_name must specify .VHDR file."))

    vhdr = readlines(file_name)
    startswith(lowercase(replace(vhdr[1], " " => "")), "brainvision") == false && throw(ArgumentError("This is not a BrainVision .VHDR file."))

    eeg_filetype = "BrainVision"

    # delete comments
    for idx in length(vhdr):-1:1
        startswith(vhdr[idx], ';') && deleteat!(vhdr, idx)
    end

    # parse header
    eeg_file = ""
    marker_file = ""
    data_format = ""
    data_orientation = ""
    channel_n = 0
    sampling_interval = 0
    binary_format = ""
    averaged = false
    averaged_segments = 0
    averaged_points = 0
    segmentation = false
    channels_idx = 0
    locs_idx = 0
    for idx in eachindex(vhdr)
        startswith(lowercase(replace(vhdr[idx], " " => "")), "datafile=") && (eeg_file = split(vhdr[idx], '=')[2])
        replace(eeg_file, raw"$b" => split(file_name)[1])
        startswith(lowercase(replace(vhdr[idx], " " => "")), "markerfile=") && (marker_file = split(vhdr[idx], '=')[2])
        replace(marker_file, raw"$b" => split(file_name)[1])
        startswith(lowercase(replace(vhdr[idx], " " => "")), "dataformat=") && (data_format = lowercase(split(vhdr[idx], '=')[2])) # BINARY or ASCII
        startswith(lowercase(replace(vhdr[idx], " " => "")), "numberofchannels=") && (channel_n = parse(Int64, split(vhdr[idx], '=')[2])) # 32
        startswith(lowercase(replace(vhdr[idx], " " => "")), "dataorientation=") && (data_orientation = lowercase(split(vhdr[idx], '=')[2])) # MULTIPLEXED
        startswith(lowercase(replace(vhdr[idx], " " => "")), "samplinginterval=") && (sampling_interval = parse(Float64, split(vhdr[idx], '=')[2])) # 1000
        startswith(lowercase(replace(vhdr[idx], " " => "")), "binaryformat=") && (binary_format = lowercase(split(vhdr[idx], '=')[2])) # INT_16
        startswith(lowercase(replace(vhdr[idx], " " => "")), "averaged=") && (averaged = lowercase(split(vhdr[idx], '=')[2]) == "yes" ? true : false) # YES|NO
        startswith(lowercase(replace(vhdr[idx], " " => "")), "averagedsegments=") && (averaged_segments = parse(Int64, split(vhdr[idx], '=')[2]))
        startswith(lowercase(replace(vhdr[idx], " " => "")), "averageddatapoints=") && (averaged_points = parse(Int64, split(vhdr[idx], '=')[2]))
        startswith(lowercase(replace(vhdr[idx], " " => "")), "segmentation=") && (segmentation = lowercase(split(vhdr[idx], '=')[2]) == "markerbased" ? true : false) # YES|NO
        startswith(lowercase(replace(vhdr[idx], " " => "")), "[channelinfos]") && (channels_idx = idx)
        startswith(lowercase(replace(vhdr[idx], " " => "")), "[coordinates]") && (locs_idx = idx)
        startswith(lowercase(replace(vhdr[idx], " " => "")), "softwarefilters") && @info "Software filters are not supported yet."
    end

    patient = ""
    recording = ""
    recording_date = ""
    recording_time = ""
    transducers = repeat([""], channel_n)
    physical_dimension = repeat([""], channel_n)
    gain = repeat([1.0], channel_n)
    prefiltering = repeat([""], channel_n)

    labels = repeat([""], channel_n)
    for idx in 1:channel_n
        tmp = split(split(vhdr[idx + channels_idx], '=')[2], ',')
        # channel label
        labels[idx] = replace(split(split(vhdr[idx + channels_idx], '=')[2], ',')[1], "\1" => ",")
        # reference channel name
        # split(split(vhdr[idx + channels_idx], '=')[2], ',')[2]
        # resolution in units
        length(tmp) >= 3 && (gain[idx] = parse(Float64, split(split(vhdr[idx + channels_idx], '=')[2], ',')[3]))
        # units name, e.g. μV
        length(tmp) >= 4 && (physical_dimension[idx] = split(split(vhdr[idx + channels_idx], '=')[2], ',')[4])
    end
    labels = _clean_labels(labels)
    if detect_type == true
        channel_type = _set_channel_types(labels)
    else
        channel_type = repeat(["???"], channel_n)
    end
    channel_order = _sort_channels(copy(channel_type))

    # read locs
    loc_theta = zeros(channel_n)
    loc_radius = zeros(channel_n)
    loc_x = zeros(channel_n)
    loc_y = zeros(channel_n)
    loc_z = zeros(channel_n)
    loc_radius_sph = zeros(channel_n)
    loc_theta_sph = zeros(channel_n)
    loc_phi_sph = zeros(channel_n)
    if locs_idx != 0
        channel_locations = true
        for idx in 1:channel_n
            loc_radius_sph[idx] = parse(Float64, split(vhdr[locs_idx + idx], '=')[1])
            loc_theta_sph[idx] = parse(Float64, split(vhdr[locs_idx + idx], '=')[2])
            loc_phi_sph[idx] = parse(Float64, split(vhdr[locs_idx + idx], '=')[3])
            loc_theta[idx] = loc_theta_sph[idx]
            loc_radius[idx] = loc_radius_sph[idx]
            loc_x[idx], loc_y[idx], loc_z[idx] = sph2cart(loc_radius_sph[idx], loc_theta_sph[idx], loc_phi_sph[idx])
        end
    else
        channel_locations = false
    end

    # read markers
    if marker_file != ""
        has_markers = true
        if file_name != basename(file_name)
            marker_file = dirname(file_name) * "/" * marker_file
        else
            marker_file = marker_file
        end
        isfile(marker_file) || throw(ArgumentError("File $marker_file cannot be loaded."))
        vmrk = readlines(marker_file)
        # delete comments
        for idx in length(vmrk):-1:1
            startswith(vmrk[idx], ';') && deleteat!(vmrk, idx)
        end
        startswith(lowercase(replace(vmrk[1], " " => "")), "brainvision") == false && throw(ArgumentError("This is not a BrainVision .VMRK file."))
        markers_idx = 0
        for idx in eachindex(vmrk)
            startswith(lowercase(replace(vmrk[idx], " " => "")), "[markerinfos]") && (markers_idx = idx)
        end
        markers = repeat([""], length(vmrk) - markers_idx)
        for idx in eachindex(markers)
            markers[idx] = vmrk[markers_idx + idx]
        end
        # remove non-markers
        for idx in length(markers):-1:1
            startswith(lowercase(markers[idx]), "mk") == false && deleteat!(markers, idx)
        end
        m_id = repeat([""], length(markers))
        m_desc = repeat([""], length(markers))
        m_pos = zeros(Int64, length(markers))
        m_len = zeros(Int64, length(markers))
        m_ch = zeros(Int64, length(markers))
        for idx in eachindex(markers)
            m_id[idx] = replace(split(split(markers[idx], '=')[2], ',')[1], "\1" => ",")
            m_desc[idx] = replace(split(split(markers[idx], '=')[2], ',')[2], "\1" => ",")
            m_pos[idx] = parse(Int64, split(split(markers[idx], '=')[2], ',')[3])
            m_len[idx] = parse(Int64, split(split(markers[idx], '=')[2], ',')[4])
            # 0 = marker is related to all channels
            m_ch[idx] = parse(Int64, split(split(markers[idx], '=')[2], ',')[5])
        end
        eeg_markers = DataFrame(:id => m_id, :start => m_pos, :length => m_len, :description => m_desc, :channel => m_ch)
    else
        has_markers = false
        eeg_markers = DataFrame(:id => String[], :start => Int64[], :length => Int64[], :description => String[], :channel => Int64[])
    end

    # sampling_interval in μs to sampling rate in Hz
    sampling_rate = round(Int64, 1 / (sampling_interval / 10^6))

    # read data
    if file_name != basename(file_name)
        eeg_file = dirname(file_name) * "/" * eeg_file
    else
        eeg_file = eeg_file
    end

    isfile(eeg_file) || throw(ArgumentError("File $eeg_file cannot be loaded."))
    if data_format == "binary"
        if binary_format == "int_16"
            bytes = 2
        elseif binary_format == "ieee_float_32"
            bytes = 4
        else
            @error("Only Float32 and Int16 BVCDF binary formats are supported.")
        end
        fid = open(eeg_file)
        signal = zeros(filesize(eeg_file) ÷ bytes)
        for idx in 1:(filesize(eeg_file) ÷ bytes)
            buf = zeros(UInt8, bytes)
            readbytes!(fid, buf, bytes)
            if bytes == 4
                signal[idx] = Float64(reinterpret(Float32, buf)[1])
            else
                signal[idx] = Float64(reinterpret(Int16, buf)[1])
            end
        end
        close(fid)
        # split signal into channels
        if data_orientation == "multiplexed"
            eeg_signals = zeros(channel_n, length(signal) ÷ channel_n, 1)
            idx2 = 1
            for idx1 in 1:channel_n:length(signal)
                eeg_signals[:, idx2, 1] = signal[idx1:(idx1 + (channel_n - 1))]
                idx2 += 1
            end
        else
            @error "Only MULTIPLEXED data orientation is supported."
        end
    else
        @error "ASCII format is not supported yet."
    end

    eeg_duration_samples = size(eeg_signals, 2)
    eeg_duration_seconds = size(eeg_signals, 2) / sampling_rate
    eeg_time = collect(0:(1 / sampling_rate):eeg_duration_seconds)
    eeg_time = eeg_time[1:end - 1]
    eeg_filesize_mb = round(filesize(eeg_file) / 1024^2, digits=2)

    signal_type = "eeg"
    "meg" in channel_type && (signal_type = "meg")

    eeg_header = Dict(:signal_type => signal_type,
                      :eeg_filename => file_name,
                      :eeg_filesize_mb => eeg_filesize_mb,
                      :eeg_filetype => eeg_filetype,
                      :patient => string(patient),
                      :recording => string(recording),
                      :recording_date => recording_date,
                      :recording_time => recording_time,
                      :channel_n => channel_n,
                      :channel_type => channel_type[channel_order],
                      :reference => "",
                      :channel_locations => channel_locations,
                      :history => String[],
                      :components => Symbol[],
                      :eeg_duration_samples => eeg_duration_samples,
                      :eeg_duration_seconds => eeg_duration_seconds,
                      :epoch_n => 1,
                      :epoch_duration_samples => eeg_duration_samples,
                      :epoch_duration_seconds => eeg_duration_seconds,
                      :labels => labels[channel_order],
                      :transducers => transducers[channel_order],
                      :physical_dimension => physical_dimension[channel_order],
                      :prefiltering => prefiltering[channel_order],
                      :sampling_rate => sampling_rate,
                      :gain => gain[channel_order],
                      :note => "",
                      :markers => has_markers)

    eeg_components = Vector{Any}()
    eeg_epochs_time = eeg_time
    if channel_locations == false
        eeg_locs = DataFrame(:channel => Int64,
                             :labels => String[],
                             :loc_theta => Float64[],
                             :loc_radius => Float64[],
                             :loc_x => Float64[],
                             :loc_y => Float64[],
                             :loc_z => Float64[],
                             :loc_radius_sph => Float64[],
                             :loc_theta_sph => Float64[],
                             :loc_phi_sph => Float64[])
    else
        eeg_locs = DataFrame(:channel_n => 1:channel_n,
                             :labels => labels,
                             :loc_theta => loc_theta,
                             :loc_radius => loc_radius,
                             :loc_x => loc_x,
                             :loc_y => loc_y,
                             :loc_z => loc_z,
                             :loc_radius_sph => loc_radius_sph,
                             :loc_theta_sph => loc_theta_sph,
                             :loc_phi_sph => loc_phi_sph)
    end

    eeg = NeuroAnalyzer.EEG(eeg_header, eeg_time, eeg_epochs_time, eeg_signals[channel_order, :, :], eeg_components, eeg_markers, eeg_locs)

    return eeg
end