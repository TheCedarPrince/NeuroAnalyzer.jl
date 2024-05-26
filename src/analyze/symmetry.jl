export symmetry

"""
    symmetry(s)

Calculate signal symmetry (ratio of positive to negative amplitudes). Perfectly symmetrical signal has symmetry of 1.0. Symmetry above 1.0 indicates there are more positive amplitudes.

# Arguments

- `s::AbstractVector`

# Returns

- `sym::Float64`: signal symmetry
"""
function symmetry(s::AbstractVector)

    if sum(s .< 0) == 0
        return sum(s .>= 0)
    else
        return sum(s .>= 0) / sum(s .< 0)
    end

end

"""
    symmetry(s)

Calculate signal symmetry (ratio of positive to negative amplitudes). Perfectly symmetrical signal has symmetry of 1.0. Symmetry above 1.0 indicates there are more positive amplitudes.

# Arguments

- `s::AbstractArray`

# Returns

- `sym::Matrix{Float64}`: signal symmetry
"""
function symmetry(s::AbstractArray)

    ch_n = size(s, 1)
    ep_n = size(s, 3)

    sym = zeros(ch_n, ep_n)

    @inbounds for ep_idx in 1:ep_n
        for ch_idx in 1:ch_n
            sym[ch_idx, ep_idx] = @views symmetry(s[ch_idx, :, ep_idx])
        end
    end

    return sym

end

"""
    symmetry(obj; ch)

Calculate signal symmetry (ratio of positive to negative amplitudes). Perfectly symmetrical signal has symmetry of 1.0. Symmetry above 1.0 indicates there are more positive amplitudes.

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `ch::Union{Int64, Vector{Int64}, <:AbstractRange}=signal_channels(obj)`: index of channels, default is all signal channels

# Returns

- `sym::Matrix{Float64}`: signal symmetry
"""
function symmetry(obj::NeuroAnalyzer.NEURO; ch::Union{Int64, Vector{Int64}, <:AbstractRange}=signal_channels(obj))

    _check_channels(obj, ch)
    length(ch) == 1 && (ch = [ch])

    sym = @views symmetry(obj.data[ch, :, :])

    return sym

end
