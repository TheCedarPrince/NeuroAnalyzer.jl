export import_nirs

"""
    import_nirs(file_name)

Load NIRS file and return `NeuroAnalyzer.NEURO` object.

# Arguments

- `file_name::String`: name of the file to load

# Returns

- `obj::NeuroAnalyzer.NEURO`

# Source

https://github.com/BUNPC/Homer3/wiki/HOMER3-file-formats
"""
function import_nirs(file_name::String)

    isfile(file_name) || throw(ArgumentError("File $file_name cannot be loaded."))
    splitext(file_name)[2] == ".nirs" || throw(ArgumentError("This is not a NIRS file."))

    nirs = nothing
    try
        nirs = matread(file_name)
    catch
        throw(ArgumentError("File $file_name cannot be loaded."))
    end

    file_type = "NIRS"

    "d" in keys(nirs) || _info("This is not a NIRS file.")
    "t" in keys(nirs) || _info("This is not a NIRS file.")

    # time points
    time_pts = nirs["t"][:]
    epoch_time = time_pts
    sampling_rate = round(Int64, 1 / (time_pts[2] - time_pts[1]))

    userdata = nirs["userdata"]

    # probes
    probes = nirs["SD"]
    # ch_n × 4
    # col1: source index
    # col2: detector index
    # col3: unused
    # col4: wavelength index
    tmp = Int.(probes["MeasList"])
    ch_n = size(tmp, 1)
    ch_pairs=zeros(Int64, size(tmp, 1), 2)
    for idx in 1:size(tmp, 1)
        ch_pairs[idx, 1] = tmp[idx, 1]
        ch_pairs[idx, 2] = tmp[idx, 2]
    end
    # probes["SpringList"]
    # probes["SrcMap"]
    # probes["vrnum"]
    # probes["MeasListVis"]
    # probes["SpatialUnit"]
    # probes["AnchorList"]
    # probes["MeasListAct"]
    # probes["xmax"]
    # probes["xmin"]
    # probes["ymax"]
    # probes["ymin"]
    # probes["nDummys"]
    # probes["DummyPos"]

    #list of wavelengths (in nm)
    wavelengths = probes["Lambda"][:]
    wavelength_index = Int.(probes["MeasList"])[:, 4]

    # sources and detectors labels
    opt_labels = String[]
    for idx in 1:Int(probes["nSrcs"])
        push!(opt_labels, "S$idx")
    end
    for idx in 1:Int(probes["nDets"])
        push!(opt_labels, "D$idx")
    end

    # channel labels
    clabels = repeat([""], ch_n)
    for idx in 1:ch_n
        clabels[idx] = "S" * string(Int.(probes["MeasList"])[idx, 1]) * "_D" * string(Int.(probes["MeasList"])[idx, 2]) * " " * string(wavelengths[wavelength_index[idx]])
    end
    clabels = replace.(clabels, ".0"=>"")

    # data contains intensity (RAW) data
    data_unit = repeat(["V"], ch_n)

    # measurements
    data = Matrix(nirs["d"]')
    ch_type = repeat(["nirs_int"], ch_n)

    # stimuli
    s = nirs["s"][:]
    if s == zeros(length(time_pts))    
        markers = DataFrame(:id=>String[], :start=>Int64[], :length=>Int64[], :description=>String[], :channel=>Int64[])
    else
        s_n = size(s, 2)
        markers = DataFrame(:id=>String[], :start=>Int64[], :length=>Int64[], :description=>String[], :channel=>Int64[])
        for idx1 in 1:s_n
            s_start = findall(s[:, idx1] .!= 0.0)
            for idx2 in 1:length(s_start)
                push!(markers, ("", s_start[idx2], 0, "stim", 0))
            end
        end
        desc = unique(markers[!, :description])
        for idx1 in 1:nrow(markers), idx2 in 1:length(desc)
            markers[idx1, :description] == desc[idx2] && (markers[idx1, :id] = string(idx2))
        end
    end

    # add auxiliary measurements as AUX components
    aux = Matrix(nirs["aux"]')
    if length(aux) > 0
        data = vcat(data, aux)
        for idx in 1:size(aux, 1)
            push!(clabels, "AUX$idx")
            push!(ch_type, "nirs_aux")
            push!(data_unit, "")
        end
    end

    # locations
    src_pos3d = Matrix(probes["SrcPos"]')
    detector_pos3d = Matrix(probes["DetPos"]')
    pos3d = hcat(src_pos3d, detector_pos3d)
    x = pos3d[1, :]
    y = pos3d[2, :]
    z = pos3d[3, :]
    # swap x and y
    # x, y = y, x
    # normalize to a unit-sphere
    if z != zeros(length(opt_labels))
        x, y, z = _locnorm(x, y, z)
    else
        x, y = _locnorm(x, y)
    end
    radius = zeros(length(opt_labels))
    theta = zeros(length(opt_labels))
    radius_sph = zeros(length(opt_labels))
    theta_sph = zeros(length(opt_labels))
    phi_sph = zeros(length(opt_labels))
    locs = DataFrame(:channel=>1:length(opt_labels), :labels=>opt_labels, :loc_theta=>theta, :loc_radius=>radius, :loc_x=>x, :loc_y=>y, :loc_z=>z, :loc_radius_sph=>radius_sph, :loc_theta_sph=>theta_sph, :loc_phi_sph=>phi_sph)
    locs = locs_cart2sph(locs)
    locs = locs_cart2pol(locs)

    file_size_mb = round(filesize(file_name) / 1024^2, digits=2)
    
    s = _create_subject(id="",
                        first_name="",
                        middle_name="",
                        last_name="",
                        handedness="",
                        weight=-1,
                        height=-1)
    r = _create_recording_nirs(data_type="nirs",
                               file_name=file_name,
                               file_size_mb=file_size_mb,
                               file_type=file_type,
                               recording="",
                               recording_date="",
                               recording_time="",
                               recording_notes="",
                               wavelengths=wavelengths,
                               wavelength_index=wavelength_index,
                               channel_pairs=ch_pairs,
                               ch_type=ch_type,
                               clabels=clabels,
                               units=data_unit,
                               opt_labels=opt_labels,
                               sampling_rate=sampling_rate)
    e = _create_experiment(name="", notes="", design="")

    hdr = _create_header(s,
                         r,
                         e)

    components = Dict()

    history = String[]

    obj = NeuroAnalyzer.NEURO(hdr, time_pts, epoch_time, data[:, :, :], components, markers, locs, history)

        _info("Imported: " * uppercase(obj.header.recording[:data_type]) * " ($(channel_n(obj)) × $(epoch_len(obj)) × $(epoch_n(obj)); $(signal_len(obj) / sr(obj)) s)")

    return obj

end
