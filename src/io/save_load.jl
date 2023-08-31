export save
export load

"""
    save(obj; file_name, overwrite)

Save `obj` to `file_name` file (HDF5-based).

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `file_name::String`: name of the file to save to
- `overwrite::Bool=false`
"""
function save(obj::NeuroAnalyzer.NEURO; file_name::String, overwrite::Bool=false)

    @assert !(isfile(file_name) && overwrite == false) "File $file_name cannot be saved, to overwrite use overwrite=true."

    obj.header.recording[:file_name] = file_name

    JLD2.save("/tmp/$(basename(file_name))", obj)
    obj.header.recording[:file_size_mb] = round(filesize("/tmp/$(basename(file_name))") / 1024, digits=2)
    rm("/tmp/$(basename(file_name))")

    JLD2.save(file_name, obj)

end

"""
    load(file_name)

Load `NeuroAnalyzer.NEURO` from `file_name` file (HDF5-based).

# Arguments

- `file_name::String`: name of the file to load

# Returns

- `obj::NeuroAnalyzer.NEURO`
"""
function load(file_name::String)

    @assert isfile(file_name) "File $file_name cannot be loaded."

    obj = JLD2.load(file_name)

    _info("Loaded: " * uppercase(obj.header.recording[:data_type]) * " ($(channel_n(obj)) × $(epoch_len(obj)) × $(epoch_n(obj)); $(round(obj.time_pts[end], digits=1)) s)")

    return obj

end
