export band_power

"""
    band_power(s; fs, f, mt)

Calculate absolute band power between two frequencies.

# Arguments

- `s::AbstractVector`
- `fs::Int64`: sampling rate
- `f::Tuple{Real, Real}`: lower and upper frequency bounds
- `mt::Bool=false`: if true use multi-tapered periodogram
- `nt::Int64=8`: number of Slepian tapers

# Returns

- `bp::Float64`: band power
"""
function band_power(s::AbstractVector; fs::Int64, f::Tuple{Real, Real}, mt::Bool=false, nt::Int64=8)

    @assert fs >= 1 "fs must be ≥ 1."
    f = tuple_order(f)
    @assert f[1] >= 0 "Lower frequency bound must be ≥ 0."
    @assert f[2] <= fs / 2 "Upper frequency bound must be ≤ $(fs / 2)."

    # for short signals use multi-tapered periodogram
    length(s) < 4 * fs && (mt = true)

    if mt == true
        p = mt_pgram(s, fs=fs, nw=(nt÷2+1), ntapers=nt)
    else
        p = welch_pgram(s, 4*fs, fs=fs)
    end

    pw = power(p)
    pf = Vector(freq(p))
    pw = pw[1:length(pf)]

    f1_idx = vsearch(f[1], pf)
    f2_idx = vsearch(f[2], pf)
    frq_idx = [f1_idx, f2_idx]

    # dx: frequency resolution
    dx = pf[2] - pf[1]

    # integrate
    bp = simpson(pw[frq_idx[1]:frq_idx[2]], pf[frq_idx[1]:frq_idx[2]], dx=dx)

    return bp

end

"""
    band_power(s; fs, f, mt)

Calculate absolute band power between two frequencies.

# Arguments

- `s::AbstractArray`
- `fs::Int64`: sampling rate
- `f::Tuple{Real, Real}`: lower and upper frequency bounds
- `mt::Bool=false`: if true use multi-tapered periodogram
- `nt::Int64=8`: number of Slepian tapers

# Returns

- `bp::Matrix{Float64}`: band power
"""
function band_power(s::AbstractArray; fs::Int64, f::Tuple{Real, Real}, mt::Bool=false, nt::Int64=8)

    ch_n = size(s, 1)
    ep_n = size(s, 3)
    bp = zeros(ch_n, ep_n)

    @inbounds @simd for ep_idx in 1:ep_n
        Threads.@threads for ch_idx in 1:ch_n
            bp[ch_idx, ep_idx] = @views band_power(s[ch_idx, :, ep_idx], fs=fs, f=f, mt=mt, nt=nt)
        end
    end

    return bp

end

"""
    band_power(obj; ch, f, mt)

Calculate absolute band power between two frequencies.

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `ch::Union{Int64, Vector{Int64}, <:AbstractRange}=signal_channels(obj)`: index of channels, default is all signal channels
- `f::Tuple{Real, Real}`: lower and upper frequency bounds
- `mt::Bool=false`: if true use multi-tapered periodogram
- `nt::Int64=8`: number of Slepian tapers

# Returns

- `bp::Matrix{Float64}`: band power
"""
function band_power(obj::NeuroAnalyzer.NEURO; ch::Union{Int64, Vector{Int64}, <:AbstractRange}=signal_channels(obj), f::Tuple{Real, Real}, mt::Bool=false, nt::Int64=8)

    _check_channels(obj, ch)

    bp = @views band_power(obj.data[ch, :, :], fs=sr(obj), f=f, mt=mt, nt=nt)

    return bp

end
