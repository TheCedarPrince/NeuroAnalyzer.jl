"""
    eeg_import(file_name; detect_type)

Load EEG file and return `NeuroAnalyzer.NEURO` object. Supported formats:
- EDF/EDF+
- BDF/BDF+
- BrainVision
- CSV
- SET (EEGLAB dataset)
- FIFF

This is a meta-function that triggers appropriate `eeg_import_*()` function. File format is detected based on file extension (.edf|.bdf|.vhdr|.csv|.csv.gz|.set|.fif|.fiff).

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
    splitext(file_name)[2] == ".csv" && return eeg_import_csv(file_name, detect_type=detect_type)
    (splitext(file_name)[2] == ".gz" && splitext(splitext(file_name)[1])[2] == ".csv") && return eeg_import_csv(file_name, detect_type=detect_type)
    splitext(file_name)[2] == ".set" && return eeg_import_set(file_name, detect_type=detect_type)
    splitext(file_name)[2] == ".fif" && return eeg_import_fiff(file_name, detect_type=detect_type)
    splitext(file_name)[2] == ".fiff" && return eeg_import_fiff(file_name, detect_type=detect_type)
end

"""
    eeg_load_electrodes(eeg; file_name)

Load electrode positions from `file_name` and return `NeuroAnalyzer.NEURO` object with `eeg_locs` data frame. 

Accepted formats:
- CED
- LOCS
- ELC
- TSV
- SFP
- CSD
- GEO
- MAT

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

- `obj::NeuroAnalyzer.NEURO`
- `file_name::String`
- `maximize::Bool=true`: maximize locations after importing

# Returns

- `eeg:EEG`
"""
function eeg_load_electrodes(obj::NeuroAnalyzer.NEURO; file_name::String, maximize::Bool=true)

    isfile(file_name) || throw(ArgumentError("File $file_name cannot be loaded."))
    length(obj.header[:labels]) > 0 || throw(ArgumentError("EEG does not contain labels, use eeg_add_labels() first."))

    if splitext(file_name)[2] == ".ced"
        locs = locs_import_ced(file_name)
    elseif splitext(file_name)[2] == ".elc"
        locs = locs_import_elc(file_name)
    elseif splitext(file_name)[2] == ".locs"
        locs = locs_import_locs(file_name)
    elseif splitext(file_name)[2] == ".tsv"
        locs = locs_import_tsv(file_name)
    elseif splitext(file_name)[2] == ".sfp"
        locs = locs_import_sfp(file_name)
    elseif splitext(file_name)[2] == ".csd"
        locs = locs_import_csd(file_name)
    elseif splitext(file_name)[2] == ".geo"
        locs = locs_import_geo(file_name)
    elseif splitext(file_name)[2] == ".mat"
        locs = locs_import_mat(file_name)
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

    e_labels = lowercase.(obj.header[:labels])
    no_match = setdiff(e_labels, lowercase.(f_labels))
    length(no_match) > 0 && _info("Labels: $(uppercase.(no_match)) not found in $file_name.")

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
    eeg_new.eeg_locs = DataFrame(:channel => 1:length(f_labels[labels_idx]),
                                 :labels => f_labels[labels_idx],
                                 :loc_theta => loc_theta[labels_idx],
                                 :loc_radius => loc_radius[labels_idx],
                                 :loc_x => loc_x[labels_idx],
                                 :loc_y => loc_y[labels_idx],
                                 :loc_z => loc_z[labels_idx],
                                 :loc_radius_sph => loc_radius_sph[labels_idx],
                                 :loc_theta_sph => loc_theta_sph[labels_idx],
                                 :loc_phi_sph => loc_phi_sph[labels_idx])

    maximize == true && locs_maximize!(eeg_new.eeg_locs)

    # add entry to :history field
    push!(eeg_new.eeg_header[:history], "eeg_load_electrodes(EEG, file_name=$file_name)")

    return eeg_new
end

"""
    eeg_load_electrodes!(eeg; file_name)

Load electrode positions from `file_name` and return `NeuroAnalyzer.NEURO` object with `eeg_locs` data frame. 

Accepted formats:
- CED
- LOCS
- ELC
- TSV
- SFP
- CSD
- GEO
- MAT

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

- `obj::NeuroAnalyzer.NEURO`
- `file_name::String`
- `maximize::Bool=true`: maximize locations after importing
"""
function eeg_load_electrodes!(obj::NeuroAnalyzer.NEURO; file_name::String, maximize::Bool=true)

    eeg_tmp = eeg_load_electrodes(eeg, file_name=file_name, maximize=maximize)
    obj.locs = eeg_tmp.eeg_locs
    obj.header[:channel_locations] = true

    nothing
 end

"""
    eeg_save(eeg; file_name, overwrite)

Save `eeg` to `file_name` file (HDF5-based).

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `file_name::String`: file name
- `overwrite::Bool=false`

# Returns

- `success::Bool`
"""
function eeg_save(obj::NeuroAnalyzer.NEURO; file_name::String, overwrite::Bool=false)

    (isfile(file_name) && overwrite == false) && throw(ArgumentError("File $file_name cannot be saved, to overwrite use overwrite=true."))

    obj.header[:eeg_filename] = file_name

    save_object("/tmp/$(basename(file_name))", eeg)
    obj.header[:eeg_filesize_mb] = round(filesize("/tmp/$(basename(file_name))") / 1024, digits=2)
    rm("/tmp/$(basename(file_name))")

    save_object(file_name, eeg)
end

"""
    eeg_load(file_name)

Load `eeg` from `file_name` file (HDF5-based).

# Arguments

- `file_name::String`: file name

# Returns

- `obj::NeuroAnalyzer.NEURO`
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

- `obj::NeuroAnalyzer.NEURO`
- `file_name::String`
- `header::Bool=false`: export header
- `components::Bool=false`: export components
- `markers::Bool=false`: export markers
- `locs::Bool=false`: export locations
- `overwrite::Bool=false`

# Returns

- `success::Bool`
"""
function eeg_export_csv(obj::NeuroAnalyzer.NEURO; file_name::String, header::Bool=false, components::Bool=false, markers::Bool=false, locs::Bool=false, overwrite::Bool=false)

    (isfile(file_name) && overwrite == false) && throw(ArgumentError("File $file_name cannot be saved, to overwrite use overwrite=true."))
    obj.header[:components] == [""] && throw(ArgumentError("EEG does not contain components."))

    # DATA
    # unsplit epochs
    s_merged = reshape(obj.data,
                       size(obj.data, 1),
                       size(obj.data, 2) * size(obj.data, 3))
    s = s_merged[:, :, 1]'
    s = hcat(obj.time_pts, s)
    l = vcat("time", eeg_labels(eeg))
    CSV.write(file_name, DataFrame(s, l))

    # HEADER
    if header
        file_name = replace(file_name, ".csv" => "_header.csv")
        (isfile(file_name) && overwrite == false) && throw(ArgumentError("File $file_name cannot be saved, to overwrite use overwrite=true."))
        f = open(file_name, "w")
        for (key, value) in obj.header
            println(f, key, ": ", value)
        end
        close(f)
    end

    # COMPONENTS
    if components
        file_name = replace(file_name, ".csv" => "_components.csv")
        (isfile(file_name) && overwrite == false) && throw(ArgumentError("File $file_name cannot be saved, to overwrite use overwrite=true."))
        f = open(file_name, "w")
        for idx in eachindex(obj.header[:components])
            println(f, "component: $(obj.header[:components][idx])")
            println(f, obj.components[idx])
            println(f, "---")
        end
        close(f)
    end

    # MARKERS
    if markers
        file_name = replace(file_name, ".csv" => "_markers.csv")
        (isfile(file_name) && overwrite == false) && throw(ArgumentError("File $file_name cannot be saved, to overwrite use overwrite=true."))
        CSV.write(file_name, obj.markers)
    end

    # LOCS
    if locs
        file_name = replace(file_name, ".csv" => "_locs.csv")
        (isfile(file_name) && overwrite == false) && throw(ArgumentError("File $file_name cannot be saved, to overwrite use overwrite=true."))
        CSV.write(file_name, obj.locs)
    end
end

"""
    eeg_save_electrodes(eeg; file_name, overwrite)

Export EEG channel locations data, format is based on `file_name` extension (.ced, .locs or .tsv)

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `file_name::String`
- `overwrite::Bool=false`
"""
function eeg_save_electrodes(obj::NeuroAnalyzer.NEURO; file_name::String, overwrite::Bool=false)

    (isfile(file_name) && overwrite == false) && throw(ArgumentError("File $file_name cannot be saved, to overwrite use overwrite=true."))

    channels = obj.locs[!, :channel]
    labels = obj.locs[!, :labels]
    theta = obj.locs[!, :loc_theta]
    radius = obj.locs[!, :loc_radius]
    x = obj.locs[!, :loc_x]
    y = obj.locs[!, :loc_y]
    z = obj.locs[!, :loc_z]
    radius_sph = obj.locs[!, :loc_radius_sph]
    theta_sph = obj.locs[!, :loc_theta_sph]
    phi_sph = obj.locs[!, :loc_phi_sph]

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

- `obj::NeuroAnalyzer.NEURO`
- `locs::DataFrame`

# Returns

- `eeg:EEG`
"""
function eeg_add_electrodes(obj::NeuroAnalyzer.NEURO; locs::DataFrame)

    f_labels = lowercase.(locs[!, :labels])

    e_labels = lowercase.(obj.header[:labels])
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

Load electrode positions from `locs` and return `NeuroAnalyzer.NEURO` object with metadata: `:channel_locations`, `:loc_theta`, `:loc_radius`, `:loc_x`, `:loc_x`, `:loc_y`, `:loc_radius_sph`, `:loc_theta_sph`, `:loc_phi_sph`. 

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

- `obj::NeuroAnalyzer.NEURO`
- `locs::DataFrame`
"""
function eeg_add_electrodes!(obj::NeuroAnalyzer.NEURO; locs::DataFrame)
    
    f_labels = lowercase.(locs[!, :labels])

    e_labels = lowercase.(obj.header[:labels])
    no_match = setdiff(e_labels, f_labels)
    length(no_match) > 0 && throw(ArgumentError("Labels: $(uppercase.(no_match)) not found in the locs object."))

    labels_idx = zeros(Int64, length(e_labels))
    for idx1 in eachindex(e_labels)
        for idx2 in eachindex(f_labels)
            e_labels[idx1] == f_labels[idx2] && (labels_idx[idx1] = idx2)
        end
    end
    
    # create new dataset
    obj.locs = locs

    # add entry to :history field
    push!(obj.header[:history], "eeg_add_electrodes!(EEG, locs)")
    nothing
 end

"""
    eeg_import_bdf(file_name; detect_type)

Load BDF/BDF+ file and return `NeuroAnalyzer.NEURO` object.

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

    fid = ""
    try
        fid = open(file_name, "r")
    catch
        error("File $file_name cannot be loaded.")
    end

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
    ch_n  = parse(Int, strip(header[253:256]))

    labels = Vector{String}(undef, ch_n)
    transducers = Vector{String}(undef, ch_n)
    physical_dimension = Vector{String}(undef, ch_n)
    physical_minimum = Vector{Float64}(undef, ch_n)
    physical_maximum = Vector{Float64}(undef, ch_n)
    digital_minimum = Vector{Float64}(undef, ch_n)
    digital_maximum = Vector{Float64}(undef, ch_n)
    prefiltering = Vector{String}(undef, ch_n)
    samples_per_datarecord = Vector{Int64}(undef, ch_n)

    header = zeros(UInt8, ch_n * 16)
    readbytes!(fid, header, ch_n * 16)
    header = String(Char.(header))
    for idx in 1:ch_n
        labels[idx] = strip(header[1 + ((idx - 1) * 16):(idx * 16)])
    end

    header = zeros(UInt8, ch_n * 80)
    readbytes!(fid, header, ch_n * 80)
    header = String(Char.(header))
    for idx in 1:ch_n
        transducers[idx] = strip(header[1 + ((idx - 1) * 80):(idx * 80)])
    end

    header = zeros(UInt8, ch_n * 8)
    readbytes!(fid, header, ch_n * 8)
    header = String(Char.(header))
    for idx in 1:ch_n
        physical_dimension[idx] = strip(header[1 + ((idx - 1) * 8):(idx * 8)])
    end

    header = zeros(UInt8, ch_n * 8)
    readbytes!(fid, header, ch_n * 8)
    header = String(Char.(header))
    for idx in 1:ch_n
        physical_minimum[idx] = parse(Float64, strip(header[1 + ((idx - 1) * 8):(idx * 8)]))
    end

    header = zeros(UInt8, ch_n * 8)
    readbytes!(fid, header, ch_n * 8)
    header = String(Char.(header))
    for idx in 1:ch_n
        physical_maximum[idx] = parse(Float64, strip(header[1 + ((idx - 1) * 8):(idx * 8)]))
    end

    header = zeros(UInt8, ch_n * 8)
    readbytes!(fid, header, ch_n * 8)
    header = String(Char.(header))
    for idx in 1:ch_n
        digital_minimum[idx] = parse(Float64, strip(header[1 + ((idx - 1) * 8):(idx * 8)]))
    end

    header = zeros(UInt8, ch_n * 8)
    readbytes!(fid, header, ch_n * 8)
    header = String(Char.(header))
    for idx in 1:ch_n
        digital_maximum[idx] = parse(Float64, strip(header[1 + ((idx - 1) * 8):(idx * 8)]))
    end

    header = zeros(UInt8, ch_n * 80)
    readbytes!(fid, header, ch_n * 80)
    header = String(Char.(header))
    for idx in 1:ch_n
        prefiltering[idx] = strip(header[1 + ((idx - 1) * 80):(idx * 80)])
    end

    header = zeros(UInt8, ch_n * 8)
    readbytes!(fid, header, ch_n * 8)
    header = String(Char.(header))
    for idx in 1:ch_n
        samples_per_datarecord[idx] = parse(Int, strip(header[1 + ((idx - 1) * 8):(idx * 8)]))
    end

    close(fid)

    labels = _clean_labels(labels)
    if detect_type == true
        channel_type = _set_channel_types(labels)
    else
        channel_type = repeat(["???"], ch_n)
    end
    channel_order = _sort_channels(copy(channel_type))
    has_markers, markers_channel = _has_markers(channel_type)

    sampling_rate = round(Int64, samples_per_datarecord[1] / data_records_duration)
    gain = Vector{Float64}(undef, ch_n)
    for idx in 1:ch_n
        gain[idx] = (physical_maximum[idx] - physical_minimum[idx]) / (digital_maximum[idx] - digital_minimum[idx])
    end

    fid = ""
    try
        fid = open(file_name, "r")
    catch
        error("File $file_name cannot be loaded.")
    end

    header = zeros(UInt8, data_offset)
    readbytes!(fid, header, data_offset)
    eeg_signals = zeros(ch_n, samples_per_datarecord[1] * data_records, 1)
    markers = repeat([""], data_records)
    for idx1 in 1:data_records
        for idx2 in 1:ch_n
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
        eeg_signals = eeg_signals[setdiff(1:ch_n, markers_channel), :, :]
        deleteat!(channel_type, markers_channel)
        deleteat!(labels, markers_channel)
        deleteat!(transducers, markers_channel)
        deleteat!(physical_dimension, markers_channel)
        deleteat!(prefiltering, markers_channel)
        deleteat!(gain, markers_channel)
        ch_n -= 1
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

    eeg_header = Dict(:signal_type => "eeg",
                      :eeg_filename => file_name,
                      :eeg_filesize_mb => eeg_filesize_mb,
                      :eeg_filetype => eeg_filetype,
                      :patient => string(patient),
                      :recording => string(recording),
                      :recording_date => recording_date,
                      :recording_time => recording_time,
                      :ch_n => ch_n,
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
                      :units => physical_dimension[channel_order],
                      :prefiltering => prefiltering[channel_order],
                      :sampling_rate => sampling_rate,
                      :gain => gain[channel_order],
                      :note => "",
                      :markers => has_markers)

    eeg_components = Vector{Any}()
    eeg_epoch_time = eeg_time
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

    eeg = NeuroAnalyzer.NEURO(eeg_header, eeg_time, eeg_epoch_time, eeg_signals[channel_order, :, :], eeg_components, eeg_markers, eeg_locs)

    return eeg
end

"""
    eeg_import_digitrack(file_name; detect_type)

Load Digitrack ASCII file and return `NeuroAnalyzer.NEURO` object.

# Arguments

- `file_name::String`: name of the file to load
- `detect_type::Bool=true`: detect channel type based on its label

# Returns

- `eeg:EEG`

# Notes
"""
function eeg_import_digitrack(file_name::String; detect_type::Bool=true)
 
    isfile(file_name) || throw(ArgumentError("File $file_name cannot be loaded."))

    fid = ""
    try
        fid = open(file_name, "r")
    catch
        error("File $file_name cannot be loaded.")
    end

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
    ch_n  = length(channels)

    labels = Vector{String}(undef, ch_n)
    prefiltering = Vector{String}(undef, ch_n)
    for idx in 1:ch_n
        labels[idx] = split(channels[idx], "\t")[1]
        prefiltering[idx] = split(channels[idx], "\t")[2]
        prefiltering[idx] = prefiltering[idx][1:(length(prefiltering[idx]) - 1)]
    end

    transducers = repeat([""], ch_n)
    physical_dimension = repeat([""], ch_n)
    gain = repeat([-1.0], ch_n)
    
    labels = _clean_labels(labels)
    if detect_type == true
        channel_type = _set_channel_types(labels)
    else
        channel_type = repeat(["???"], ch_n)
    end
    channel_order = _sort_channels(copy(channel_type))
    has_markers, markers_channel = _has_markers(channel_type)

    data = readlines(fid)

    close(fid)

    eeg_signals = zeros(ch_n, length(data), 1)
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

    eeg_header = Dict(:signal_type => "eeg",
                      :eeg_filename => file_name,
                      :eeg_filesize_mb => eeg_filesize_mb,
                      :eeg_filetype => eeg_filetype,
                      :patient => string(patient),
                      :recording => string(recording),
                      :recording_date => recording_date,
                      :recording_time => recording_time,
                      :ch_n => ch_n,
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
                      :units => physical_dimension[channel_order],
                      :prefiltering => prefiltering[channel_order],
                      :sampling_rate => sampling_rate,
                      :gain => gain[channel_order],
                      :note => "",
                      :markers => has_markers)

    eeg_components = Vector{Any}()
    eeg_epoch_time = eeg_time
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

    eeg = NeuroAnalyzer.NEURO(eeg_header, eeg_time, eeg_epoch_time, eeg_signals[channel_order, :, :], eeg_components, eeg_markers, eeg_locs)

    return eeg
end

"""
    eeg_import_bv(file_name; detect_type)

Load BrainVision BVCDF file and return `NeuroAnalyzer.NEURO` object. At least two files are required: .vhdr (header) and .eeg (signal data). If available, markers are loaded from .vmrk file.

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
    ch_n = 0
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
        startswith(lowercase(replace(vhdr[idx], " " => "")), "numberofchannels=") && (ch_n = parse(Int64, split(vhdr[idx], '=')[2])) # 32
        startswith(lowercase(replace(vhdr[idx], " " => "")), "dataorientation=") && (data_orientation = lowercase(split(vhdr[idx], '=')[2])) # MULTIPLEXED
        startswith(lowercase(replace(vhdr[idx], " " => "")), "samplinginterval=") && (sampling_interval = parse(Float64, split(vhdr[idx], '=')[2])) # 1000
        startswith(lowercase(replace(vhdr[idx], " " => "")), "binaryformat=") && (binary_format = lowercase(split(vhdr[idx], '=')[2])) # INT_16
        startswith(lowercase(replace(vhdr[idx], " " => "")), "averaged=") && (averaged = lowercase(split(vhdr[idx], '=')[2]) == "yes" ? true : false) # YES|NO
        startswith(lowercase(replace(vhdr[idx], " " => "")), "averagedsegments=") && (averaged_segments = parse(Int64, split(vhdr[idx], '=')[2]))
        startswith(lowercase(replace(vhdr[idx], " " => "")), "averageddatapoints=") && (averaged_points = parse(Int64, split(vhdr[idx], '=')[2]))
        startswith(lowercase(replace(vhdr[idx], " " => "")), "segmentation=") && (segmentation = lowercase(split(vhdr[idx], '=')[2]) == "markerbased" ? true : false) # YES|NO
        startswith(lowercase(replace(vhdr[idx], " " => "")), "[channelinfos]") && (channels_idx = idx)
        startswith(lowercase(replace(vhdr[idx], " " => "")), "[coordinates]") && (locs_idx = idx)
        startswith(lowercase(replace(vhdr[idx], " " => "")), "softwarefilters") && _info("Software filters are not supported yet.")
    end

    patient = ""
    recording = ""
    recording_date = ""
    recording_time = ""
    transducers = repeat([""], ch_n)
    physical_dimension = repeat([""], ch_n)
    gain = repeat([1.0], ch_n)
    prefiltering = repeat([""], ch_n)

    labels = repeat([""], ch_n)
    for idx in 1:ch_n
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
        channel_type = repeat(["???"], ch_n)
    end
    channel_order = _sort_channels(copy(channel_type))

    # read locs
    loc_theta = zeros(ch_n)
    loc_radius = zeros(ch_n)
    loc_x = zeros(ch_n)
    loc_y = zeros(ch_n)
    loc_z = zeros(ch_n)
    loc_radius_sph = zeros(ch_n)
    loc_theta_sph = zeros(ch_n)
    loc_phi_sph = zeros(ch_n)
    if locs_idx != 0
        channel_locations = true
        for idx in 1:ch_n
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

        fid = ""
        try
            fid = open(file_name, "r")
        catch
            error("File $file_name cannot be loaded.")
        end

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
            eeg_signals = zeros(ch_n, length(signal) ÷ ch_n, 1)
            idx2 = 1
            for idx1 in 1:ch_n:length(signal)
                eeg_signals[:, idx2, 1] = signal[idx1:(idx1 + (ch_n - 1))]
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

    eeg_header = Dict(:signal_type => "eeg",
                      :eeg_filename => file_name,
                      :eeg_filesize_mb => eeg_filesize_mb,
                      :eeg_filetype => eeg_filetype,
                      :patient => string(patient),
                      :recording => string(recording),
                      :recording_date => recording_date,
                      :recording_time => recording_time,
                      :ch_n => ch_n,
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
                      :units => physical_dimension[channel_order],
                      :prefiltering => prefiltering[channel_order],
                      :sampling_rate => sampling_rate,
                      :gain => gain[channel_order],
                      :note => "",
                      :markers => has_markers)

    eeg_components = Vector{Any}()
    eeg_epoch_time = eeg_time
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
        eeg_locs = DataFrame(:ch_n => 1:ch_n,
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

    eeg = NeuroAnalyzer.NEURO(eeg_header, eeg_time, eeg_epoch_time, eeg_signals[channel_order, :, :], eeg_components, eeg_markers, eeg_locs)

    return eeg
end

"""
    eeg_import_alice4(file_name; detect_type)

Load EDF exported from Alice 4 return `NeuroAnalyzer.NEURO` object.

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
function eeg_import_alice4(file_name::String; detect_type::Bool=true)

    isfile(file_name) || throw(ArgumentError("File $file_name cannot be loaded."))

    eeg_filetype = ""

    fid = ""
    try
        fid = open(file_name, "r")
    catch
        error("File $file_name cannot be loaded.")
    end

    header = zeros(UInt8, 256)
    readbytes!(fid, header, 256)
    header = String(Char.(header))

    eeg_filetype = parse(Int, strip(header[1:8]))
    eeg_filetype == 0 && (eeg_filetype = "EDF")
    eeg_filetype !== "EDF" && throw(ArgumentError("File $file_name is not a EDF file."))

    patient = strip(header[9:88])
    recording = strip(header[89:168])
    occursin("Alice 4", recording) == false && throw(ArgumentError("This is not Alice 4 EDF file."))
    recording_date = header[169:176]
    recording_time = header[177:184]
    data_offset = parse(Int, strip(header[185:192]))
    reserved = strip(header[193:236])
    reserved == "EDF+D" && throw(ArgumentError("EDF+D format (interrupted recordings) is not supported."))
    reserved == "EDF+C" && (eeg_filetype = "EDF+")
    # we get -1 here
    data_records = parse(Int, strip(header[237:244]))
    # we get 1.0 here
    data_records_duration  = parse(Float64, strip(header[245:252]))
    ch_n  = parse(Int, strip(header[253:256]))

    labels = Vector{String}(undef, ch_n)
    transducers = Vector{String}(undef, ch_n)
    physical_dimension = Vector{String}(undef, ch_n)
    physical_minimum = Vector{Float64}(undef, ch_n)
    physical_maximum = Vector{Float64}(undef, ch_n)
    digital_minimum = Vector{Float64}(undef, ch_n)
    digital_maximum = Vector{Float64}(undef, ch_n)
    prefiltering = Vector{String}(undef, ch_n)
    samples_per_datarecord = Vector{Int64}(undef, ch_n)

    header = zeros(UInt8, ch_n * 16)
    readbytes!(fid, header, ch_n * 16)
    header = String(Char.(header))
    for idx in 1:ch_n
        labels[idx] = strip(header[1 + ((idx - 1) * 16):(idx * 16)])
    end

    header = zeros(UInt8, ch_n * 80)
    readbytes!(fid, header, ch_n * 80)
    header = String(Char.(header))
    for idx in 1:ch_n
        transducers[idx] = strip(header[1 + ((idx - 1) * 80):(idx * 80)])
    end

    header = zeros(UInt8, ch_n * 8)
    readbytes!(fid, header, ch_n * 8)
    header = String(Char.(header))
    for idx in 1:ch_n
        physical_dimension[idx] = strip(header[1 + ((idx - 1) * 8):(idx * 8)])
    end

    header = zeros(UInt8, ch_n * 8)
    readbytes!(fid, header, ch_n * 8)
    header = String(Char.(header))
    for idx in 1:ch_n
        physical_minimum[idx] = parse(Float64, strip(header[1 + ((idx - 1) * 8):(idx * 8)]))
    end

    header = zeros(UInt8, ch_n * 8)
    readbytes!(fid, header, ch_n * 8)
    header = String(Char.(header))
    for idx in 1:ch_n
        physical_maximum[idx] = parse(Float64, strip(header[1 + ((idx - 1) * 8):(idx * 8)]))
    end

    header = zeros(UInt8, ch_n * 8)
    readbytes!(fid, header, ch_n * 8)
    header = String(Char.(header))
    for idx in 1:ch_n
        digital_minimum[idx] = parse(Float64, strip(header[1 + ((idx - 1) * 8):(idx * 8)]))
    end

    header = zeros(UInt8, ch_n * 8)
    readbytes!(fid, header, ch_n * 8)
    header = String(Char.(header))
    for idx in 1:ch_n
        digital_maximum[idx] = parse(Float64, strip(header[1 + ((idx - 1) * 8):(idx * 8)]))
    end

    header = zeros(UInt8, ch_n * 80)
    readbytes!(fid, header, ch_n * 80)
    header = String(Char.(header))
    for idx in 1:ch_n
        prefiltering[idx] = strip(header[1 + ((idx - 1) * 80):(idx * 80)])
    end

    header = zeros(UInt8, ch_n * 8)
    readbytes!(fid, header, ch_n * 8)
    header = String(Char.(header))
    for idx in 1:ch_n
        samples_per_datarecord[idx] = parse(Int, strip(header[1 + ((idx - 1) * 8):(idx * 8)]))
    end

    close(fid)

    labels = _clean_labels(labels)
    if detect_type == true
        channel_type = _set_channel_types(labels)
    else
        channel_type = repeat(["???"], ch_n)
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

    gain = Vector{Float64}(undef, ch_n)
    for idx in 1:ch_n
        gain[idx] = (physical_maximum[idx] - physical_minimum[idx]) / (digital_maximum[idx] - digital_minimum[idx])
    end

    if length(unique(samples_per_datarecord)) == 1
        sampling_rate = round(Int64, samples_per_datarecord[1] / data_records_duration)

        fid = ""
        try
            fid = open(file_name, "r")
        catch
            error("File $file_name cannot be loaded.")
        end

        header = zeros(UInt8, data_offset)
        readbytes!(fid, header, data_offset)
        eeg_signals = zeros(ch_n, samples_per_datarecord[1] * data_records, 1)
        for idx1 in 1:data_records
            for idx2 in 1:ch_n
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
    else
        sampling_rate = round.(Int64, samples_per_datarecord / data_records_duration)
        max_sampling_rate = maximum(sampling_rate)

        fid = ""
        try
            fid = open(file_name, "r")
        catch
            error("File $file_name cannot be loaded.")
        end

        header = zeros(UInt8, data_offset)
        readbytes!(fid, header, data_offset)

        data_size = filesize(file_name) - data_offset
        data = zeros(UInt8, data_size)
        readbytes!(fid, data, data_size, all=true)
        signal = map(ltoh, reinterpret(Int16, data))
        data_records = length(signal) ÷ sum(sampling_rate)        
        eeg_signals = zeros(ch_n, data_records * max_sampling_rate)
        data_segment = max_sampling_rate

        @inbounds for idx1 in 1:data_records            
            for idx2 in 1:ch_n
                tmp = Vector{Float64}()
                for idx3 in 1:sampling_rate[idx2]
                    push!(tmp, popat!(signal, 1))
                end
                tmp = @. (tmp - digital_minimum[idx2]) * gain[idx2] + physical_minimum[idx2]
                if sampling_rate[idx2] == max_sampling_rate
                    eeg_signals[idx2, ((idx1 - 1) * data_segment + 1):idx1 * data_segment] = tmp
                else
                    tmp_upsampled = FourierTools.resample(tmp, max_sampling_rate)
                    eeg_signals[idx2, ((idx1 - 1) * data_segment + 1):idx1 * data_segment] = tmp_upsampled
                end
            end
        end

        # reject weird channels

        for idx1 in 1:ch_n
            if idx1 != markers_channel
                if channel_type[idx1] == "markers"
                    for idx2 in 1:size(eeg_signals, 2)
                        if signal[idx1, idx2] == digital_minimum[idx1]
                            signal[idx1, idx2] = 0
                        else
                            signal[idx1, idx2] = 1
                        end
                    end
                end
                if occursin("mV", physical_dimension[idx1])
                    eeg_signals ./= 1000
                end
            else
                markers[idx1] = String(Char.(signal))
            end
        end
        _info("Channels upsampled to $max_sampling_rate Hz.")
        sampling_rate = max_sampling_rate
        close(fid)
    end

    if has_markers
        deleteat!(channel_order, vsearch(markers_channel, channel_order))
        eeg_signals = eeg_signals[setdiff(1:ch_n, markers_channel), :, :]
        deleteat!(labels, markers_channel)
        deleteat!(transducers, markers_channel)
        deleteat!(physical_dimension, markers_channel)
        deleteat!(prefiltering, markers_channel)
        deleteat!(gain, markers_channel)
        ch_n -= 1
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

    eeg_header = Dict(:signal_type => "eeg",
                      :eeg_filename => file_name,
                      :eeg_filesize_mb => eeg_filesize_mb,
                      :eeg_filetype => eeg_filetype,
                      :patient => string(patient),
                      :recording => string(recording),
                      :recording_date => recording_date,
                      :recording_time => recording_time,
                      :ch_n => ch_n,
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
                      :units => physical_dimension[channel_order],
                      :prefiltering => prefiltering[channel_order],
                      :sampling_rate => sampling_rate,
                      :gain => gain[channel_order],
                      :note => "",
                      :markers => has_markers)

    eeg_components = Vector{Any}()
    eeg_epoch_time = eeg_time
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

    eeg = NeuroAnalyzer.NEURO(eeg_header, eeg_time, eeg_epoch_time, eeg_signals[channel_order, :, :], eeg_components, eeg_markers, eeg_locs)

    return eeg
end

"""
    eeg_import_csv(file_name; detect_type)

Load CSV file (e.g. exported from EEGLAB) and return `NeuroAnalyzer.NEURO` object.

# Arguments

- `file_name::String`: name of the file to load
- `detect_type::Bool=true`: detect channel type based on its label

# Returns

- `eeg:EEG`

# Notes

CSV first row or first column must contain channel names.
Shape of data array will be detected automatically. Sampling rate will be detected.
If file is gzip-ed, it will be uncompressed automatically while reading.
"""
function eeg_import_csv(file_name::String; detect_type::Bool=true)

    isfile(file_name) || throw(ArgumentError("File $file_name cannot be loaded."))

    eeg_filetype = "CSV"

    df = CSV.read(file_name, DataFrame)

    if typeof(df[:, 1]) == Vector{Float64}
        # time by channels
        eeg_time = df[:, 1]
        eeg_signals = Array(df[:, 2:end])'
        ch_n = ncol(df) - 1
        labels = String.(names(df)[2:end])
    else
        # channels by time
        eeg_time = parse.(Float64, names(df)[2:end])
        eeg_signals = Array(df[:, 2:end])
        ch_n = nrow(df)
        labels = String.(df[:, 1])
    end
    eeg_signals = reshape(eeg_signals, size(eeg_signals, 1), size(eeg_signals, 2), 1)

    labels = _clean_labels(labels)
    if detect_type == true
        channel_type = _set_channel_types(labels)
    else
        channel_type = repeat(["???"], ch_n)
    end
    channel_order = _sort_channels(copy(channel_type))

    has_markers = false
    eeg_markers = DataFrame(:id => String[], :start => Int64[], :length => Int64[], :description => String[], :channel => Int64[])
    sampling_rate = round(Int64, 1 / eeg_time[2] * 1000)
    gain = ones(ch_n)
    eeg_markers = DataFrame(:id => String[], :start => Int64[], :length => Int64[], :description => String[], :channel => Int64[])

    eeg_duration_samples = size(eeg_signals, 2)
    eeg_duration_seconds = size(eeg_signals, 2) / sampling_rate
    eeg_time = collect(0:(1 / sampling_rate):eeg_duration_seconds)
    eeg_time = eeg_time[1:end - 1]
    eeg_filesize_mb = round(filesize(file_name) / 1024^2, digits=2)

    eeg_header = Dict(:signal_type => "eeg",
                      :eeg_filename => file_name,
                      :eeg_filesize_mb => eeg_filesize_mb,
                      :eeg_filetype => eeg_filetype,
                      :patient => "",
                      :recording => "",
                      :recording_date => "",
                      :recording_time => "",
                      :ch_n => ch_n,
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
                      :transducers => repeat([""], ch_n),
                      :units => repeat([""], ch_n),
                      :prefiltering => repeat([""], ch_n),
                      :sampling_rate => sampling_rate,
                      :gain => gain[channel_order],
                      :note => "",
                      :markers => has_markers)

    eeg_components = Vector{Any}()
    eeg_epoch_time = eeg_time
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

    eeg = NeuroAnalyzer.NEURO(eeg_header, eeg_time, eeg_epoch_time, eeg_signals[channel_order, :, :], eeg_components, eeg_markers, eeg_locs)

    return eeg
end

"""
    eeg_import_set(file_name; detect_type)

Load SET file (exported from EEGLAB) and return `NeuroAnalyzer.NEURO` object.

# Arguments

- `file_name::String`: name of the file to load
- `detect_type::Bool=true`: detect channel type based on its label

# Returns

- `eeg:EEG`
"""
function eeg_import_set(file_name::String; detect_type::Bool=true)

    isfile(file_name) || throw(ArgumentError("File $file_name cannot be loaded."))

    eeg_filetype = "SET"

    dataset = matread(file_name)
    eeg_time = dataset["times"][:]
    eeg_signals = dataset["data"]

    # there are no epochs if signal is matrix, not array
    ndims(eeg_signals) == 2 && (eeg_signals = reshape(eeg_signals, size(eeg_signals, 1), size(eeg_signals, 2), 1))

    ch_n = size(eeg_signals, 1)
    
    # get channel labels
    if length(dataset["chanlocs"]["labels"][:]) == ch_n
        labels = String.(dataset["chanlocs"]["labels"][:])
    else
        labels = repeat([""], ch_n)
    end

    labels = _clean_labels(labels)
    if detect_type == true
        channel_type = _set_channel_types(labels)
    else
        channel_type = repeat(["???"], ch_n)
    end
    channel_order = _sort_channels(copy(channel_type))

    # TODO: import locations, events and other data
    # keys(dataset) = ["event", "icawinv", "chaninfo", "epoch", "stats", "chanlocs", "reject", "icaact", "icaweights", "ref", "eventdescription", "urchanlocs", "urevent", "nbchan", "icachansind", "specicaact", "icasplinefile", "splinefile", "condition", "dipfit", "group", "icasphere", "session", "datfile", "trials", "epochdescription", "setname", "specdata", "run"]
    # epochs data: dataset["epoch"]
    # events data: dataset["event"]
    # channel data: dataset["chaninfo"]
    # locs data: dataset["chanlocs"]
    # ICA weights: dataset["icaweights"]
    # ICA weights: dataset["icaweights"]
    # ignore: xmin, xmax, filename, filepath, etc, setname, saved, pnts

    # EEGLAB metadata
    patient = dataset["subject"]
    note = dataset["comments"]
    history = split(dataset["history"], "\n")
    # remove first two entries, 1st is empty, second is EEGLAB version
    length(history) > 2 && (history = history[3:end])

    sampling_rate = round(Int64, dataset["srate"])

    has_markers = false
    eeg_markers = DataFrame(:id => String[], :start => Int64[], :length => Int64[], :description => String[], :channel => Int64[])
    gain = ones(ch_n)
    eeg_markers = DataFrame(:id => String[], :start => Int64[], :length => Int64[], :description => String[], :channel => Int64[])

    eeg_duration_samples = size(eeg_signals, 2)
    eeg_duration_seconds = size(eeg_signals, 2) / sampling_rate
    eeg_time = collect(0:(1 / sampling_rate):eeg_duration_seconds)
    eeg_time = eeg_time[1:end - 1]
    eeg_filesize_mb = round(filesize(file_name) / 1024^2, digits=2)

    eeg_header = Dict(:signal_type => "eeg",
                      :eeg_filename => file_name,
                      :eeg_filesize_mb => eeg_filesize_mb,
                      :eeg_filetype => eeg_filetype,
                      :patient => patient,
                      :recording => "",
                      :recording_date => "",
                      :recording_time => "",
                      :channel_n => ch_n,
                      :channel_type => channel_type[channel_order],
                      :reference => "",
                      :channel_locations => false,
                      :history => history,
                      :components => Symbol[],
                      :eeg_duration_samples => eeg_duration_samples,
                      :eeg_duration_seconds => eeg_duration_seconds,
                      :epoch_n => 1,
                      :epoch_duration_samples => eeg_duration_samples,
                      :epoch_duration_seconds => eeg_duration_seconds,
                      :labels => labels[channel_order],
                      :transducers => repeat([""], ch_n),
                      :units => repeat([""], ch_n),
                      :prefiltering => repeat([""], ch_n),
                      :sampling_rate => sampling_rate,
                      :gain => gain[channel_order],
                      :note => note,
                      :markers => has_markers)

    eeg_components = Vector{Any}()
    eeg_epoch_time = eeg_time
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

    eeg = NeuroAnalyzer.NEURO(eeg_header, eeg_time, eeg_epoch_time, eeg_signals[channel_order, :, :], eeg_components, eeg_markers, eeg_locs)

    return eeg
end
