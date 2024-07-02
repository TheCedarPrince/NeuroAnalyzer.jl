export cpsd

"""
   cpsd(s1, s2; method, fs, frq_lim, demean, nt, wlen, woverlap, w, db)

Calculate cross power spectral density (CPSD).

# Arguments

- `s1::AbstractVector`
- `s2::AbstractVector`
- `method::Symbol=:mt`: method used to calculate CPSD:
    - `:mt`: multi-tapered cross-power spectra
    - `:fft`: fast Fourier transformation
- `fs::Int64`: sampling rate
- `frq_lim::Tuple{Real, Real}=(0, fs / 2)`: frequency bounds
- `demean::Bool=false`: if true, the channel-wise mean will be subtracted from the input signals before the cross spectral powers are computed
- `nt::Int64=7`: number of Slepian tapers
- `wlen::Int64=fs`: window length (in samples), default is 1 second
- `woverlap::Int64=round(Int64, wlen * 0.97)`: window overlap (in samples)
- `w::Bool=true`: if true, apply Hanning window
- `db::Bool=false`: normalize do dB

# Returns

- `pxy::Vector{Float64}`: cross-power spectrum
- `p::Vector{Float64}`: frequencies
"""
function cpsd(s1::AbstractVector, s2::AbstractVector; method::Symbol=:mt, fs::Int64, frq_lim::Tuple{Real, Real}=(0, fs / 2), demean::Bool=false, nt::Int64=7, wlen::Int64=fs, woverlap::Int64=round(Int64, wlen * 0.97), w::Bool=true, db::Bool=false)

    _check_var(method, [:mt, :fft], "method")
    s1, s2 = _veqlen(s1, s2)
    @assert nt >= 1 "nt must be ≥ 1."
    @assert fs >= 1 "fs must be ≥ 1."
    @assert wlen <= length(s1) "wlen must be ≤ $(length(s1))."
    @assert wlen >= 2 "wlen must be ≥ 2."
    @assert woverlap <= wlen "woverlap must be ≤ $(wlen)."
    @assert woverlap >= 0 "woverlap must be ≥ 0."
    _check_tuple(frq_lim, "frq_lim", (0, fs / 2))

    if method === :mt
        w = w ? hanning(length(s1)) : nothing
        # multitaper
        s = hcat(s1, s2)'
        n_samples = length(s1)
        pxy = mt_cross_power_spectra(s, fs=fs, demean=demean, nfft=nextpow(2, n_samples), window=nothing, nw=((nt + 1) ÷ 2), ntapers=nt)
        f = freq(pxy)
        pxy = power(pxy)
        f1_idx = vsearch(frq_lim[1], f)
        f2_idx = vsearch(frq_lim[2], f)
        f = f[f1_idx:f2_idx]
        pxy = @views abs.(pxy[1, 2, f1_idx:f2_idx])
    elseif method === :fft
        # fft
        ss1, f = fft_transform(s1, fs=fs, wlen=wlen, woverlap=woverlap, w=w, demean=demean, mode=:r)
        ss2, f = fft_transform(s2, fs=fs, wlen=wlen, woverlap=woverlap, w=w, demean=demean, mode=:r)
        pxy = conj.(ss1) .* ss2
        f1_idx = vsearch(frq_lim[1], f)
        f2_idx = vsearch(frq_lim[2], f)
        f = f[f1_idx:f2_idx]
        pxy = @views abs.(pxy[f1_idx:f2_idx])
    end

    db && (pxy = pow2db.(pxy))

    return (pxy=pxy, f=f)

end

"""
    cpsd(s1, s2; method, fs, frq_lim, demean, nt, wlen, woverlap, w, db)

Calculate cross power spectral density (CPSD).

# Arguments

- `s1::AbstractArray`
- `s2::AbstractArray`
- `method::Symbol=:mt`: method used to calculate CPSD:
    - `:mt`: multi-tapered cross-power spectra
    - `:fft`: fast Fourier transformation
- `fs::Int64`: sampling rate
- `frq_lim::Tuple{Real, Real}=(0, fs / 2)`: frequency bounds
- `demean::Bool=false`: if true, the channelwise mean will be subtracted from the input signals before the cross spectral powers are computed
- `nt::Int64=7`: number of Slepian tapers
- `wlen::Int64=fs`: window length (in samples), default is 1 second
- `woverlap::Int64=round(Int64, wlen * 0.97)`: window overlap (in samples)
- `w::Bool=true`: if true, apply Hanning window
- `db::Bool=false`: normalize do dB

# Returns

Named tuple containing:
- `pxy::Array{Float64, 3}`: cross-power spectrum
- `f::Vector{Float64}`: frequencies
"""
function cpsd(s1::AbstractArray, s2::AbstractArray; method::Symbol=:mt, fs::Int64, frq_lim::Tuple{Real, Real}=(0, fs / 2), demean::Bool=false, nt::Int64=7, wlen::Int64=fs, woverlap::Int64=round(Int64, wlen * 0.97), w::Bool=true, db::Bool=false)

    @assert size(s1) == size(s2) "s1 and s2 must have the same size."

    ch_n = size(s1, 1)
    ep_n = size(s1, 3)

    _, f = cpsd(s1[1, :, 1], s2[1, :, 1]; method=method, fs=fs, frq_lim=frq_lim, demean=demean, nt=nt, wlen=wlen, woverlap=woverlap, w=w, db=db)
    if frq_lim !== nothing
        _check_tuple(frq_lim, "frq_lim", (0, fs / 2))
        idx1 = vsearch(frq_lim[1], f)
        idx2 = vsearch(frq_lim[2], f)
        f = f[idx1:idx2]
    end

    pxy = zeros(ch_n, length(f), ep_n)

    @inbounds for ep_idx in 1:ep_n
        Threads.@threads for ch_idx in 1:ch_n
            pxy[ch_idx, :, ep_idx], _ = @views cpsd(s1[ch_idx, :, ep_idx], s2[ch_idx, :, ep_idx], method=method, fs=fs, frq_lim=frq_lim, demean=demean, nt=nt, wlen=wlen, woverlap=woverlap, w=w, db=db)
        end
    end

    return (pxy=pxy, f=f)
end

"""
    cpsd(obj1, obj2; ch1, ch2, ep1, ep2, method, frq_lim, demean, nt, wlen, woverlap, w, db)

Calculate cross power spectral density (CPSD).

# Arguments

- `obj1::NeuroAnalyzer.NEURO`
- `obj2::NeuroAnalyzer.NEURO`
- `ch1::Union{Int64, Vector{Int64}, AbstractRange}=signal_channels(obj1)`: index of channels, default is all signal channels
- `ch2::Union{Int64, Vector{Int64}, AbstractRange}=signal_channels(obj2)`: index of channels, default is all signal channels
- `ep1::Union{Int64, Vector{Int64}, AbstractRange}=_c(nepochs(obj1))`: default use all epochs
- `ep2::Union{Int64, Vector{Int64}, AbstractRange}=_c(nepochs(obj2))`: default use all epochs
- `method::Symbol=:mt`: method used to calculate CPSD:
    - `:mt`: multi-tapered cross-power spectra
    - `:fft`: fast Fourier transformation
- `frq_lim::Tuple{Real, Real}=(0, sr(obj1) / 2)`: frequency bounds
- `demean::Bool=false`: if true, the channelwise mean will be subtracted from the input signals before the cross spectral powers are computed
- `nt::Int64=7`: number of Slepian tapers
- `wlen::Int64=sr(obj1)`: window length (in samples), default is 1 second
- `woverlap::Int64=round(Int64, wlen * 0.97)`: window overlap (in samples)
- `w::Bool=true`: if true, apply Hanning window
- `db::Bool=false`: normalize do dB

# Returns

Named tuple containing:
- `pxy::Array{Float64, 3}`: cross-power spectrum
- `f::Vector{Float64}`: frequencies
"""
function cpsd(obj1::NeuroAnalyzer.NEURO, obj2::NeuroAnalyzer.NEURO; ch1::Union{Int64, Vector{Int64}, AbstractRange}=signal_channels(obj1), ch2::Union{Int64, Vector{Int64}, AbstractRange}=signal_channels(obj2), ep1::Union{Int64, Vector{Int64}, AbstractRange}=_c(nepochs(obj1)), ep2::Union{Int64, Vector{Int64}, AbstractRange}=_c(nepochs(obj2)), method::Symbol=:mt, frq_lim::Tuple{Real, Real}=(0, sr(obj1) / 2), demean::Bool=false, nt::Int64=7, wlen::Int64=sr(obj1), woverlap::Int64=round(Int64, wlen * 0.97), w::Bool=true, db::Bool=false)

    _check_channels(obj1, ch1)
    _check_channels(obj2, ch2)
    @assert length(ch1) == length(ch2) "ch1 and ch2 must have the same length."

    _check_epochs(obj1, ep1)
    _check_epochs(obj2, ep2)
    @assert length(ep1) == length(ep2) "ep1 and ep2 must have the same length."
    @assert epoch_len(obj1) == epoch_len(obj2) "OBJ1 and OBJ2 must have the same epoch lengths."

    @assert sr(obj1) == sr(obj2) "OBJ1 and OBJ2 must have the same sampling rate."

    size(ch1) == () && (ch1 = [ch1])
    size(ch2) == () && (ch2 = [ch2])
    size(ep1) == () && (ep1 = [ep1])
    size(ep2) == () && (ep2 = [ep2])

    pxy, f = @views cpsd(obj1.data[ch1, :, ep1], obj2.data[ch2, :, ep2], method=method, fs=sr(obj1), frq_lim=frq_lim, demean=demean, nt=nt, wlen=wlen, woverlap=woverlap, w=w, db=db)

    return (pxy=pxy, f=f)

end
