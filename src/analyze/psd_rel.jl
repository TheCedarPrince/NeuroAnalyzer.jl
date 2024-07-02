export psd_rel

"""
    psd_rel(s; fs, db, frq_lim, method, nt, wlen, woverlap, w, ncyc)

Calculate relative power spectrum density. Default method is Welch's periodogram.

# Arguments
- `s::AbstractVector`
- `fs::Int64`: sampling rate
- `db::Bool=false`: normalize do dB
- `frq_lim::Union{Tuple{Real, Real}, Nothing}=nothing`: frequency range to calculate relative power to; if nothing, than calculate relative to total power
- `method::Symbol=:welch`: method used to calculate PSD:
    - `:welch`: Welch's periodogram
    - `:fft`: fast Fourier transform
    - `:mt`: multi-tapered periodogram
    - `:stft`: short time Fourier transform
    - `:mw`: Morlet wavelet convolution
- `nt::Int64=7`: number of Slepian tapers
- `wlen::Int64=fs`: window length (in samples), default is 1 second
- `woverlap::Int64=round(Int64, wlen * 0.97)`: window overlap (in samples)
- `w::Bool=true`: if true, apply Hanning window
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=32`: number of cycles for Morlet wavelet, for tuple a variable number of cycles is used per frequency: `ncyc=linspace(ncyc[1], ncyc[2], frq_n)`, where `frq_n` is the length of `0:(fs / 2)`

# Returns

Named tuple containing:
- `pw::Vector{Float64}`: powers
- `pf::Vector{Float64}`: frequencies
"""
function psd_rel(s::AbstractVector; fs::Int64, db::Bool=false, frq_lim::Union{Tuple{Real, Real}, Nothing}=nothing, method::Symbol=:welch, nt::Int64=7, wlen::Int64=fs, woverlap::Int64=round(Int64, wlen * 0.97), w::Bool=true, ncyc::Union{Int64, Tuple{Int64, Int64}}=32)

    ref_pw = frq_lim === nothing ? total_power(s, fs=fs, method=method, nt=nt, wlen=wlen, woverlap=woverlap, w=w) : band_power(s, fs=fs, frq_lim=frq_lim, method=method, nt=nt, wlen=wlen, woverlap=woverlap, w=w, ncyc=ncyc)

    pw, pf = psd(s, fs=fs, db=db, method=method, nt=nt, wlen=wlen, woverlap=woverlap, w=w, ncyc=ncyc)

    pw = pw ./ ref_pw

    return (pw=pw, pf=pf)

end

"""
    psd_rel(s; fs, db, frq_lim, smethod, nt, wlen, woverlap, w, ncyc)

Calculate relative power spectrum density. Default method is Welch's periodogram.

# Arguments
- `s::AbstractMatrix`
- `fs::Int64`: sampling rate
- `db::Bool=false`: normalize do dB
- `frq_lim::Union{Tuple{Real, Real}, Nothing}=nothing`: frequency range to calculate relative power to; if nothing, than calculate relative to total power
- `method::Symbol=:welch`: method used to calculate PSD:
    - `:welch`: Welch's periodogram
    - `:fft`: fast Fourier transform
    - `:mt`: multi-tapered periodogram
    - `:stft`: short time Fourier transform
    - `:mw`: Morlet wavelet convolution
- `nt::Int64=7`: number of Slepian tapers
- `wlen::Int64=fs`: window length (in samples), default is 1 second
- `woverlap::Int64=round(Int64, wlen * 0.97)`: window overlap (in samples)
- `w::Bool=true`: if true, apply Hanning window
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=32`: number of cycles for Morlet wavelet, for tuple a variable number of cycles is used per frequency: `ncyc=linspace(ncyc[1], ncyc[2], frq_n)`, where `frq_n` is the length of `0:(fs / 2)`

# Returns

Named tuple containing:
- `pw::Array{Float64, 3}`: powers
- `pf::Vector{Float64}`: frequencies
"""
function psd_rel(s::AbstractMatrix; fs::Int64, db::Bool=false, frq_lim::Union{Tuple{Real, Real}, Nothing}=nothing, method::Symbol=:welch, nt::Int64=7, wlen::Int64=fs, woverlap::Int64=round(Int64, wlen * 0.97), w::Bool=true, ncyc::Union{Int64, Tuple{Int64, Int64}}=32)

    ch_n = size(s, 1)

    _, pf = psd_rel(s[1, :, 1], fs=fs, db=db, frq_lim=frq_lim, method=method, nt=nt, wlen=wlen, woverlap=woverlap, w=w, ncyc=ncyc)

    pw = zeros(ch_n, length(pf))

    @inbounds for ch_idx in 1:ch_n
        pw[ch_idx, :], _ = psd_rel(s[ch_idx, :], fs=fs, db=db, frq_lim=frq_lim, method=method, nt=nt, wlen=wlen, woverlap=woverlap, w=w, ncyc=ncyc)
    end

    return (pw=pw, pf=pf)

end

"""
    psd_rel(s; fs, db, frq_lim, method, nt, wlen, woverlap, w, ncyc)

Calculate relative power spectrum density. Default method is Welch's periodogram.

# Arguments
- `s::AbstractArray`
- `fs::Int64`: sampling rate
- `db::Bool=false`: normalize do dB
- `frq_lim::Union{Tuple{Real, Real}, Nothing}=nothing`: frequency range to calculate relative power to; if nothing, than calculate relative to total power
- `method::Symbol=:welch`: method used to calculate PSD:
    - `:welch`: Welch's periodogram
    - `:fft`: fast Fourier transform
    - `:mt`: multi-tapered periodogram
    - `:stft`: short time Fourier transform
    - `:mw`: Morlet wavelet convolution
- `nt::Int64=7`: number of Slepian tapers
- `wlen::Int64=fs`: window length (in samples), default is 1 second
- `woverlap::Int64=round(Int64, wlen * 0.97)`: window overlap (in samples)
- `w::Bool=true`: if true, apply Hanning window
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=32`: number of cycles for Morlet wavelet, for tuple a variable number of cycles is used per frequency: `ncyc=linspace(ncyc[1], ncyc[2], frq_n)`, where `frq_n` is the length of `0:(fs / 2)`

# Returns

Named tuple containing:
- `pw::Array{Float64, 3}`: powers
- `pf::Vector{Float64}`: frequencies
"""
function psd_rel(s::AbstractArray; fs::Int64, db::Bool=false, frq_lim::Union{Tuple{Real, Real}, Nothing}=nothing, method::Symbol=:welch, nt::Int64=7, wlen::Int64=fs, woverlap::Int64=round(Int64, wlen * 0.97), w::Bool=true, ncyc::Union{Int64, Tuple{Int64, Int64}}=32)

    ch_n = size(s, 1)
    ep_n = size(s, 3)

    _, pf = psd_rel(s[1, :, 1], fs=fs, db=db, method=method, nt=nt, wlen=wlen, woverlap=woverlap, w=w, ncyc=ncyc)

    pw = zeros(ch_n, length(pf), ep_n)

    @inbounds for ep_idx in 1:ep_n
        Threads.@threads for ch_idx in 1:ch_n
            pw[ch_idx, :, ep_idx], _ = psd_rel(s[ch_idx, :, ep_idx], fs=fs, db=db, frq_lim=frq_lim, method=method, nt=nt, wlen=wlen, woverlap=woverlap, w=w, ncyc=ncyc)
        end
    end

    return (pw=pw, pf=pf)

end

"""
    psd_rel(obj; ch, db, frq_lim, method, nt, wlen, woverlap, w, ncyc)

Calculate relative power spectrum density. Default method is Welch's periodogram.

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `ch::Union{Int64, Vector{Int64}, <:AbstractRange}=signal_channels(obj)`: index of channels, default is all signal channels
- `db::Bool=false`: normalize do dB
- `frq_lim::Union{Tuple{Real, Real}, Nothing}=nothing`: frequency range to calculate relative power to; if nothing, than calculate relative to total power
- `method::Symbol=:welch`: method used to calculate PSD:
    - `:welch`: Welch's periodogram
    - `:fft`: fast Fourier transform
    - `:mt`: multi-tapered periodogram
    - `:stft`: short time Fourier transform
    - `:mw`: Morlet wavelet convolution
- `nt::Int64=7`: number of Slepian tapers
- `wlen::Int64=sr(obj)`: window length (in samples), default is 1 second
- `woverlap::Int64=round(Int64, wlen * 0.97)`: window overlap (in samples)
- `w::Bool=true`: if true, apply Hanning window
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=32`: number of cycles for Morlet wavelet, for tuple a variable number of cycles is used per frequency: `ncyc=linspace(ncyc[1], ncyc[2], frq_n)`, where `frq_n` is the length of `0:(sr(obj) / 2)`

# Returns

Named tuple containing:
- `pw::Array{Float64, 3}`: powers
- `pf::Array{Float64, 3}`: frequencies
"""
function psd_rel(obj::NeuroAnalyzer.NEURO; ch::Union{Int64, Vector{Int64}, <:AbstractRange}=signal_channels(obj), db::Bool=false, method::Symbol=:welch, nt::Int64=7, frq_lim::Union{Tuple{Real, Real}, Nothing}=nothing, wlen::Int64=sr(obj), woverlap::Int64=round(Int64, wlen * 0.97), w::Bool=true, ncyc::Union{Int64, Tuple{Int64, Int64}}=32)

    _check_channels(obj, ch)
    length(ch) == 1 && (ch = [ch])

    pw, pf = @views psd_rel(obj.data[ch, :, :], fs=sr(obj), frq_lim=frq_lim, db=db, method=method, nt=nt, wlen=wlen, woverlap=woverlap, w=w, ncyc=ncyc)

    return (pw=pw, pf=pf)

end
