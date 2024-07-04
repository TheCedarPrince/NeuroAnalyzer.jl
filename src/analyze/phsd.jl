export phsd

"""
    phsd(s; fs)

Calculate phase spectral density.

# Arguments
- `s::Vector{Float64}`
- `fs::Int64`: sampling rate

# Returns

Named tuple containing:
- `ph::Vector{Float64}`: phases
- `f::Vector{Float64}`: frequencies
"""
function phsd(s::AbstractVector; fs::Int64)

    @assert fs >= 1 "fs must be ≥ 1."

    _, _, _, sph = spectrum(s)
    f, _ = freqs(s, fs)

    return (ph=sph, f=f)

end

"""
    phsd(s; fs)

Calculate phase spectral density.

# Arguments

- `s::AbstractMatrix`
- `fs::Int64`: sampling rate

# Returns

Named tuple containing:
- `ph::Array{Float64, 2}`: phases
- `f::Vector{Float64}`: frequencies
"""
function phsd(s::AbstractMatrix; fs::Int64)

    ch_n = size(s, 1)
    _, f = phsd(s[1, :], fs=fs)

    ph = zeros(ch_n, length(f))

    @inbounds for ch_idx in 1:ch_n
        ph[ch_idx, :], _ = phsd(s[ch_idx, :], fs=fs)
    end

    return (ph=ph, f=f)

end

"""
    phsd(s; fs)

Calculate phase spectral density.

# Arguments
- `s::AbstractArray`
- `fs::Int64`: sampling rate

# Returns

Named tuple containing:
- `ph::Array{Float64, 3}`: phases
- `f::Vector{Float64}`: frequencies
"""
function phsd(s::AbstractArray; fs::Int64)

    ch_n = size(s, 1)
    ep_n = size(s, 3)

    _, f = phsd(s[1, :, 1], fs=fs)

    ph = zeros(ch_n, length(f), ep_n)

    @inbounds for ep_idx in 1:ep_n
        Threads.@threads for ch_idx in 1:ch_n
            ph[ch_idx, :, ep_idx], _ = phsd(s[ch_idx, :, ep_idx], fs=fs)
        end
    end

    return (ph=ph, f=f)

end

"""
    phsd(obj; ch)

Calculate phase spectral density.

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `ch::Union{Int64, Vector{Int64}, <:AbstractRange}=signal_channels(obj)`: index of channels, default is all signal channels

# Returns

Named tuple containing:
- `ph::Array{Float64, 3}`: phases
- `f::Vector{Float64}`: frequencies
"""
function phsd(obj::NeuroAnalyzer.NEURO; ch::Union{Int64, Vector{Int64}, <:AbstractRange}=signal_channels(obj))

    _check_channels(obj, ch)
    isa(ch, Int64) && (ch = [ch])

    ph, f = phsd(obj.data[ch, :, :], fs=sr(obj))

    return (ph=ph, f=f)

end
