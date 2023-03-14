export delete_epoch
export delete_epoch!
export keep_epoch
export keep_epoch!

"""
    delete_epoch(obj; ep)

Remove epoch(s).

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `ep::Union{Int64, Vector{Int64}, <:AbstractRange}`: epoch number(s) to be removed

# Returns

- `obj::NeuroAnalyzer.NEURO`
"""
function delete_epoch(obj::NeuroAnalyzer.NEURO; ep::Union{Int64, Vector{Int64}, <:AbstractRange})

    epoch_n(obj) == 1 && throw(ArgumentError("You cannot delete the last epoch."))
    typeof(ep) <: AbstractRange && (ep = collect(ep))
    length(ep) == epoch_n(obj) && throw(ArgumentError("You cannot delete all epochs."))
    length(ep) > 1 && (ep = sort!(ep, rev=true))
    _check_epochs(obj, ep)

    obj_new = deepcopy(obj)

    # remove epoch
    obj_new.data = obj_new.data[:, :, setdiff(1:end, (ep))]
    ep_n = size(obj_new.data, 3)

    # remove markers within deleted epochs and shift markers after the deleted epoch
    for ep_idx in ep
        t1, t2 = _epoch2s(obj, ep_idx)
        obj_new.markers = _delete_markers(obj_new.markers, (t1, t2))
        obj_new.markers = _shift_markers(obj_new.markers, t1, length(t1:t2))
    end

    # update time
    time_pts = collect(obj_new.time_pts[1]:(1 / sr(obj_new)):round((ep_n * size(obj.data, 2)) / sr(obj), digits=2))
    time_pts = time_pts[1:(end - 1)]
    obj_new.time_pts = time_pts

    reset_components!(obj_new)
    push!(obj_new.header.history, "delete_epoch(OBJ, $ep)")
    
    return obj_new

end

"""
    delete_epoch!(obj; ep)

Remove epoch(s).

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `ep::Union{Int64, Vector{Int64}, <:AbstractRange}`: epoch number(s) to be removed
"""
function delete_epoch!(obj::NeuroAnalyzer.NEURO; ep::Union{Int64, Vector{Int64}, <:AbstractRange})

    obj_tmp = delete_epoch(obj, ep=ep)
    obj.header = obj_tmp.header
    obj.data = obj_tmp.data
    obj.time_pts = obj_tmp.time_pts
    obj.markers = obj_tmp.markers
    obj.components = obj_tmp.components

    return nothing
end

"""
    keep_epoch(obj; ep)

Keep epoch(s).

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `ep::Union{Int64, Vector{Int64}, <:AbstractRange}`: epoch number(s) to keep

# Returns

- `obj::NeuroAnalyzer.NEURO`
"""
function keep_epoch(obj::NeuroAnalyzer.NEURO; ep::Union{Int64, Vector{Int64}, <:AbstractRange})

    epoch_n(obj) == 1 && throw(ArgumentError("contains only one epoch."))
    typeof(ep) <: AbstractRange && (ep = collect(ep))
    length(ep) > 1 && (ep = sort!(ep, rev=true))
    _check_epochs(obj, ep)

    ep_list = collect(1:epoch_n(obj))
    ep_to_remove = setdiff(ep_list, ep)

    length(ep_to_remove) > 1 && (ep_to_remove = sort!(ep_to_remove, rev=true))

    obj_new = delete_epoch(obj, ep=ep_to_remove)
    reset_components!(obj_new)
    push!(obj_new.header.history, "keep_epoch(OBJ, $ep)")    

    return obj_new
end

"""
    keep_epoch!(obj; ep)

Keep OBJ epoch(s).

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `ep::Union{Int64, Vector{Int64}, <:AbstractRange}`: epoch number(s) to keep
"""
function keep_epoch!(obj::NeuroAnalyzer.NEURO; ep::Union{Int64, Vector{Int64}, <:AbstractRange})

    obj_tmp = keep_epoch(obj, ep=ep)
    obj.header = obj_tmp.header
    obj.data = obj_tmp.data
    obj.time_pts = obj_tmp.time_pts
    obj.markers = obj_tmp.markers
    reset_components!(obj)

    return nothing
end
