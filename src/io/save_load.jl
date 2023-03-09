export save
export load

"""
    save(obj; file_name, overwrite)

Save `obj` to `file_name` file (HDF5-based).

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `file_name::String`: file name
- `overwrite::Bool=false`

# Returns

- `::Bool`
"""
function save(obj::NeuroAnalyzer.NEURO; file_name::String, overwrite::Bool=false)

    (isfile(file_name) && overwrite == false) && throw(ArgumentError("File $file_name cannot be saved, to overwrite use overwrite=true."))

    obj.header.recording[:file_name] = file_name

    save_object("/tmp/$(basename(file_name))", obj)
    obj.header.recording[:file_size_mb] = round(filesize("/tmp/$(basename(file_name))") / 1024, digits=2)
    rm("/tmp/$(basename(file_name))")

    save_object(file_name, obj)
end

"""
    load(file_name)

Load `NeuroAnalyzer.NEURO` from `file_name` file (HDF5-based).

# Arguments

- `file_name::String`: file name

# Returns

- `::NeuroAnalyzer.NEURO`
"""
function load(file_name::String)

    isfile(file_name) || throw(ArgumentError("File $file_name cannot be loaded."))

    return load_object(file_name)
end

