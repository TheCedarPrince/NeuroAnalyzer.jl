export fcoherence

"""
    fcoherence(s; fs, frq_lim)

Calculate coherence (mean over all frequencies) and MSC (magnitude-squared coherence) between channels.

# Arguments

- `s::AbstractArray`
- `fs::Int64`: sampling rate
- `frq_lim::Union{Tuple{Real, Real}, Nothing}=nothing`: return coherence only for the given frequency range

# Returns

Named tuple containing:
- `c::Array{Float64, 3}`: coherence
- `msc::Array{Float64, 3}`: MSC
- `f::Vector{Float64}`: frequencies
"""
function fcoherence(s::AbstractArray; fs::Int64, frq_lim::Union{Tuple{Real, Real}, Nothing}=nothing)

    fs < 1 && throw(ArgumentError("fs must be ≥ 1."))

    c = mt_coherence(s, fs=fs)
    f = Vector(c.freq)
    c = c.coherence

    if frq_lim !== nothing
        frq_lim = tuple_order(frq_lim)
        frq_lim[1] < 0 && throw(ArgumentError("Lower frequency bound must be ≥ 0."))
        frq_lim[2] > fs / 2 && throw(ArgumentError("Upper frequency bound must be ≤ $fs."))
        idx1 = vsearch(frq_lim[1], f)
        idx2 = vsearch(frq_lim[2], f)
        c = c[:, :, idx1:idx2]
        f = f[idx1:idx2]
    end

    return (c=c, msc=c.^2, f=f)

end

"""
    fcoherence(s1, s2; fs, frq_lim::Union{Tuple{Real, Real}, Nothing}=nothing)

Calculate coherence (mean over all frequencies) and MSC (magnitude-squared coherence) between channels of `s1` and `s2`.

# Arguments

- `s1::AbstractArray`
- `s2::AbstractArray`
- `fs::Int64`
- `frq_lim::Union{Tuple{Real, Real}, Nothing}=nothing`: return coherence only for the given frequency range

# Returns

- `c::Array{Float64, 3}`: coherence
- `msc::Array{Float64, 3}`: MSC
- `f::Vector{Float64}`: frequencies
"""
function fcoherence(s1::AbstractArray, s2::AbstractArray; fs::Int64, frq_lim::Union{Tuple{Real, Real}, Nothing}=nothing)

    length(s1) == length(s2) || throw(ArgumentError("s1 and s2 must have the same length."))
    fs < 1 && throw(ArgumentError("fs must be ≥ 1."))

    s = hcat(s1, s2)'

    c = mt_coherence(s, fs=fs)
    f = Vector(c.freq)
    c = c.coherence

    if frq_lim !== nothing
        frq_lim = tuple_order(frq_lim)
        frq_lim[1] < 0 && throw(ArgumentError("Lower frequency bound must be ≥ 0."))
        frq_lim[2] > fs / 2 && throw(ArgumentError("Upper frequency bound must be ≤ $fs."))
        idx1 = vsearch(frq_lim[1], f)
        idx2 = vsearch(frq_lim[2], f)
        c = c[:, :, idx1:idx2]
        f = f[idx1:idx2]
    end
    c = c[1, 2, :]
    
    return (c=c, msc=c.^2, f=f)

end

"""
    fcoherence(obj1, obj2; ch1, ch2, ep1, ep2, frq_lim)

Calculate coherence (mean over frequencies) and MSC (magnitude-squared coherence).

# Arguments

- `obj1::NeuroAnalyzer.NEURO`
- `obj2::NeuroAnalyzer.NEURO`
- `ch1::Union{Int64, Vector{Int64}, <:AbstractRange}=signal_channels(obj1)`: index of channels, default is all signal channels
- `ch2::Union{Int64, Vector{Int64}, <:AbstractRange}=signal_channels(obj2)`: index of channels, default is all signal channels
- `ep1::Union{Int64, Vector{Int64}, <:AbstractRange}=_c(epoch_n(obj1))`: default use all epochs
- `ep2::Union{Int64, Vector{Int64}, <:AbstractRange}=_c(epoch_n(obj2))`: default use all epochs
- `frq_lim::Union{Tuple{Real, Real}, Nothing}=nothing`: return coherence only for the given frequency range

# Returns

Named tuple containing:
- `c::Array{Float64, 3}`: coherence
- `msc::Array{Float64, 3}`: MSC
- `f::Vector{Float64}`: frequencies
"""
function fcoherence(obj1::NeuroAnalyzer.NEURO, obj2::NeuroAnalyzer.NEURO; ch1::Union{Int64, Vector{Int64}, <:AbstractRange}=0, ch2::Union{Int64, Vector{Int64}, <:AbstractRange}=0, ep1::Union{Int64, Vector{Int64}, <:AbstractRange}=0, ep2::Union{Int64, Vector{Int64}, <:AbstractRange}=0, frq_lim::Union{Tuple{Real, Real}, Nothing}=nothing)

    _check_channels(obj1, ch1)
    _check_channels(obj2, ch2)
    length(ch1) == length(ch2) || throw(ArgumentError("ch1 and ch2 lengths must be equal."))
    
    _check_epochs(obj1, ep1)
    _check_epochs(obj2, ep2)
    length(ep1) == length(ep2) || throw(ArgumentError("ep1 and ep2 lengths must be equal."))
    epoch_len(obj1) == epoch_len(obj2) || throw(ArgumentError("OBJ1 and OBJ2 must have the same epoch lengths."))

    sr(obj1) == sr(obj2) || throw(ArgumentError("OBJ1 and OBJ2 must have the same sampling rate."))

    c_tmp, _, f = @views fcoherence(obj1.data[1, :, 1], obj1.data[1, :, 1], fs=sr(obj1), frq_lim=frq_lim)
    c = zeros(length(ch1), length(c_tmp), length(ep1))
    msc = zeros(length(ch1), length(c_tmp), length(ep1))
    f = zeros(length(ch1), length(c_tmp), length(ep1))

    @inbounds @simd for ep_idx in eachindex(ep1)
        Threads.@threads for ch_idx in eachindex(ch1)
            c[ch_idx, :, ep_idx], msc[ch_idx, :, ep_idx], _ = @views fcoherence(obj1.data[ch1[ch_idx], :, ep1[ep_idx]], obj2.data[ch2[ch_idx], :, ep2[ep_idx]], fs=sr(obj1), frq_lim=frq_lim)
        end
    end

    return (c=c, msc=msc, f=f)

end
