export psd
export psd_mw

"""
    psd(s; fs, norm, method, nt, wlen, woverlap, w, frq_lim, frq_n, frq, fs, ncyc)

Calculate power spectrum density. Default method is Welch periodogram.

# Arguments
- `s::Vector{Float64}`
- `fs::Int64`: sampling rate
- `norm::Bool=false`: normalize do dB
- `method::Symbol=:welch`: method used to calculate PSD:
    - `:welch`: Welch periodogram
    - `:fft`: fast Fourier transform
    - `:mt`: multi-tapered periodogram
    - `:stft`: short time Fourier transform
    - `:mw`: Morlet wavelet convolution
- `nt::Int64=8`: number of Slepian tapers
- `wlen::Int64=fs`: window length (in samples), default is 1 second
- `woverlap::Int64=round(Int64, wlen * 0.97)`: window overlap (in samples)
- `w::Bool=true`: if true, apply Hanning window for Welch and STFT
- `frq_lim::Tuple{Real, Real}=(0, fs / 2)`: frequency bounds
- `frq_n::Int64=length(frq_lim[1]:frq_lim[2])`: number of frequencies
- `frq::Symbol=:log`: linear (`:lin`) or logarithmic (`:log`) frequencies
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet, for tuple a variable number of cycles is used per frequency: `ncyc=logspace(log10(ncyc[1]), log10(ncyc[2]), frq_n)` for `frq = :log` or `ncyc=linspace(ncyc[1], ncyc[2], frq_n)` for `frq = :lin`

# Returns

Named tuple containing:
- `pw::Vector{Float64}`: powers
- `pf::Vector{Float64}`: frequencies
"""
function psd(s::AbstractVector; fs::Int64, norm::Bool=false, method::Symbol=:welch, nt::Int64=8, wlen::Int64=fs, woverlap::Int64=round(Int64, wlen * 0.97), w::Bool=true, frq_lim::Tuple{Real, Real}=(0, fs / 2), frq_n::Int64=_tlength(frq_lim), frq::Symbol=:lin, ncyc::Union{Int64, Tuple{Int64, Int64}}=6)

    _check_var(method, [:fft, :welch, :mt, :mw, :stft], "method")
    @assert nt >= 1 "nt must be ≥ 1."
    @assert fs >= 1 "fs must be ≥ 1."
    @assert wlen <= length(s) "wlen must be ≤ $(length(s))."
    @assert wlen >= 2 "wlen must be ≥ 2."
    @assert woverlap <= wlen "woverlap must be ≤ $(wlen)."
    @assert woverlap >= 0 "woverlap must be ≥ 0."

    w = w ? DSP.hanning : nothing

    if method === :mt
        p = mt_pgram(s, fs=fs, nw=(nt ÷ 2 + 1), ntapers=nt)
        pw = power(p)
        pf = Vector(freq(p))
        pw = pw[1:length(pf)]
    elseif method === :stft
        p = abs.(DSP.stft(s, wlen, woverlap, fs=fs, window=w))
        # average STFT segments along time
        pw = vec(mean(p, dims=2))
        # create frequencies vector
        pf = linspace(0, fs / 2, length(pw))
    elseif method === :welch
        p = DSP.welch_pgram(s, wlen, woverlap, fs=fs, window=w)
        pw = power(p)
        pf = Vector(freq(p))
        pw = pw[1:length(pf)]
    elseif method === :fft
        p = DSP.periodogram(s, fs=fs, window=w)
        pw = power(p)
        pf = Vector(freq(p))
        pw = pw[1:length(pf)]
    elseif method === :mw
        pw, pf = psd_mw(s, norm=false, fs=fs, frq_lim=frq_lim, frq_n=frq_n, frq=frq, ncyc=ncyc)
    end

    # replace powers at extreme frequencies
    # pw[1] = pw[2]
    # pw[end] = pw[end - 1]
    
    norm == true && (pw = pow2db.(pw))

    return (pw=pw, pf=pf)

end

"""
    psd(s; fs, norm, method, nt, wlen, woverlap, w, frq_lim, frq_n, frq, fs, ncyc)

Calculate power spectrum density. Default method is Welch periodogram.

# Arguments

- `s::AbstractMatrix`
- `fs::Int64`: sampling rate
- `norm::Bool=false`: normalize do dB
- `method::Symbol=:welch`: method used to calculate PSD:
    - `:welch`: Welch periodogram
    - `:fft`: fast Fourier transform
    - `:mt`: multi-tapered periodogram
    - `:stft`: short time Fourier transform
    - `:mw`: Morlet wavelet convolution
- `nt::Int64=8`: number of Slepian tapers
- `wlen::Int64=fs`: window length (in samples), default is 1 second
- `woverlap::Int64=round(Int64, wlen * 0.97)`: window overlap (in samples)
- `w::Bool=true`: if true, apply Hanning window
- `frq_lim::Tuple{Real, Real}=(0, fs / 2)`: frequency bounds
- `frq_n::Int64=length(frq_lim[1]:frq_lim[2])`: number of frequencies
- `frq::Symbol=:log`: linear (`:lin`) or logarithmic (`:log`) frequencies
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet, for tuple a variable number of cycles is used per frequency: `ncyc=logspace(log10(ncyc[1]), log10(ncyc[2]), frq_n)` for `frq = :log` or `ncyc=linspace(ncyc[1], ncyc[2], frq_n)` for `frq = :lin`

# Returns

Named tuple containing:
- `pw::Array{Float64, 2}`: powers
- `pf::Vector{Float64}`: frequencies
"""
function psd(s::AbstractMatrix; fs::Int64, norm::Bool=false, method::Symbol=:welch, nt::Int64=8, wlen::Int64=fs, woverlap::Int64=round(Int64, wlen * 0.97), w::Bool=true, frq_lim::Tuple{Real, Real}=(0, fs / 2), frq_n::Int64=_tlength(frq_lim), frq::Symbol=:lin, ncyc::Union{Int64, Tuple{Int64, Int64}}=6)

    ch_n = size(s, 1)
    _, pf = psd(s[1, :], fs=fs, norm=norm, method=method, nt=nt, wlen=wlen, woverlap=woverlap, w=w)

    pw = zeros(ch_n, length(pf))

    @inbounds @simd for ch_idx in 1:ch_n
        pw[ch_idx, :], _ = psd(s[ch_idx, :], fs=fs, norm=norm, method=method, nt=nt, wlen=wlen, woverlap=woverlap, w=w, frq_lim=frq_lim, frq_n=frq_n, frq=frq, ncyc=ncyc)
    end
    
    return (pw=pw, pf=pf)

end

"""
    psd(s; fs, norm, method, nt, wlen, woverlap, w, frq_lim, frq_n, frq, fs, ncyc)

Calculate power spectrum density. Default method is Welch periodogram.

# Arguments
- `s::AbstractArray`
- `fs::Int64`: sampling rate
- `norm::Bool=false`: normalize do dB
- `method::Symbol=:welch`: method used to calculate PSD:
    - `:welch`: Welch periodogram
    - `:fft`: fast Fourier transform
    - `:mt`: multi-tapered periodogram
    - `:stft`: short time Fourier transform
    - `:mw`: Morlet wavelet convolution
- `nt::Int64=8`: number of Slepian tapers
- `wlen::Int64=fs`: window length (in samples), default is 1 second
- `woverlap::Int64=round(Int64, wlen * 0.97)`: window overlap (in samples)
- `w::Bool=true`: if true, apply Hanning window for Welch and STFT
- `frq_lim::Tuple{Real, Real}=(0, fs / 2)`: frequency bounds
- `frq_n::Int64=length(frq_lim[1]:frq_lim[2])`: number of frequencies
- `frq::Symbol=:log`: linear (`:lin`) or logarithmic (`:log`) frequencies
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet, for tuple a variable number of cycles is used per frequency: `ncyc=logspace(log10(ncyc[1]), log10(ncyc[2]), frq_n)` for `frq = :log` or `ncyc=linspace(ncyc[1], ncyc[2], frq_n)` for `frq = :lin`

# Returns

Named tuple containing:
- `pw::Array{Float64, 3}`: powers
- `pf::Vector{Float64}`: frequencies
"""
function psd(s::AbstractArray; fs::Int64, norm::Bool=false, method::Symbol=:welch, nt::Int64=8, wlen::Int64=fs, woverlap::Int64=round(Int64, wlen * 0.97), w::Bool=true, frq_lim::Tuple{Real, Real}=(0, fs / 2), frq_n::Int64=_tlength(frq_lim), frq::Symbol=:lin, ncyc::Union{Int64, Tuple{Int64, Int64}}=6)

    ch_n = size(s, 1)
    ep_n = size(s, 3)

    _, pf = psd(s[1, :, 1], fs=fs, norm=norm, method=method, nt=nt, wlen=wlen, woverlap=woverlap, w=w, frq_lim=frq_lim, frq_n=frq_n, frq=frq, ncyc=ncyc)

    pw = zeros(ch_n, length(pf), ep_n)

    @inbounds @simd for ep_idx in 1:ep_n
        Threads.@threads for ch_idx in 1:ch_n
            pw[ch_idx, :, ep_idx], _ = psd(s[ch_idx, :, ep_idx], fs=fs, norm=norm, method=method, nt=nt, wlen=wlen, woverlap=woverlap, w=w, frq_lim=frq_lim, frq_n=frq_n, frq=frq, ncyc=ncyc)
        end
    end
    
    return (pw=pw, pf=pf)

end

"""
    psd(obj; ch, norm, method, nt, wlen, woverlap, w, frq_lim, frq_n, frq, fs, ncyc)

Calculate power spectrum density. Default method is Welch periodogram.

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `ch::Union{Int64, Vector{Int64}, <:AbstractRange}=signal_channels(obj)`: index of channels, default is all signal channels
- `norm::Bool=false`: normalize do dB
- `method::Symbol=:welch`: method used to calculate PSD:
    - `:welch`: Welch periodogram
    - `:fft`: fast Fourier transform
    - `:mt`: multi-tapered periodogram
    - `:stft`: short time Fourier transform
    - `:mw`: Morlet wavelet convolution
- `nt::Int64=8`: number of Slepian tapers
- `wlen::Int64=sr(obj)`: window length (in samples), default is 1 second
- `woverlap::Int64=round(Int64, wlen * 0.97)`: window overlap (in samples)
- `w::Bool=true`: if true, apply Hanning window for Welch and STFT
- `frq_lim::Tuple{Real, Real}=(0, sr(obj) / 2)`: frequency bounds
- `frq_n::Int64=length(frq_lim[1]:frq_lim[2])`: number of frequencies
- `frq::Symbol=:log`: linear (`:lin`) or logarithmic (`:log`) frequencies
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet, for tuple a variable number of cycles is used per frequency: `ncyc=logspace(log10(ncyc[1]), log10(ncyc[2]), frq_n)` for `frq = :log` or `ncyc=linspace(ncyc[1], ncyc[2], frq_n)` for `frq = :lin`

# Returns

Named tuple containing:
- `pw::Array{Float64, 3}`: powers
- `pf::Vector{Float64}`: frequencies
"""
function psd(obj::NeuroAnalyzer.NEURO; ch::Union{Int64, Vector{Int64}, <:AbstractRange}=signal_channels(obj), norm::Bool=false, method::Symbol=:welch, nt::Int64=8, wlen::Int64=sr(obj), woverlap::Int64=round(Int64, wlen * 0.97), w::Bool=true, frq_lim::Tuple{Real, Real}=(0, sr(obj) / 2), frq_n::Int64=_tlength(frq_lim), frq::Symbol=:lin, ncyc::Union{Int64, Tuple{Int64, Int64}}=6)

    _check_channels(obj, ch)

    if length(ch) == 1
        pw, pf = psd(reshape(obj.data[ch, :, :], length(ch), :, size(obj.data[ch, :, :], 3)), fs=sr(obj), norm=norm, method=method, nt=nt, wlen=wlen, woverlap=woverlap, w=w, frq_lim=frq_lim, frq_n=frq_n, frq=frq, ncyc=ncyc)
    else
        pw, pf = psd(obj.data[ch, :, :], fs=sr(obj), norm=norm, method=method, nt=nt, wlen=wlen, woverlap=woverlap, w=w, frq_lim=frq_lim, frq_n=frq_n, frq=frq, ncyc=ncyc)
    end

    return (pw=pw, pf=pf)

end

"""
    psd_mw(s; pad, norm, frq_lim, frq_n, frq, fs, ncyc)

Calculate power spectrum using Morlet wavelet convolution.

# Arguments

- `s::AbstractVector`
- `pad::Int64=0`: pad with `pad` zeros
- `norm::Bool=true`: normalize powers to dB
- `fs::Int64`: sampling rate
- `frq_lim::Tuple{Real, Real}=(0, fs / 2)`: frequency bounds
- `frq_n::Int64=length(frq_lim[1]:frq_lim[2])`: number of frequencies
- `frq::Symbol=:log`: linear (`:lin`) or logarithmic (`:log`) frequencies
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet, for tuple a variable number of cycles is used per frequency: `ncyc=logspace(log10(ncyc[1]), log10(ncyc[2]), frq_n)` for `frq = :log` or `ncyc=linspace(ncyc[1], ncyc[2], frq_n)` for `frq = :lin`

# Returns

Named tuple containing:
- `pw::Matrix{Float64}`: powers
- `pf::Vector{Float64}`: frequencies
"""
function psd_mw(s::AbstractVector; pad::Int64=0, norm::Bool=true, fs::Int64, frq_lim::Tuple{Real, Real}=(0, fs / 2), frq_n::Int64=_tlength(frq_lim), frq::Symbol=:lin, ncyc::Union{Int64, Tuple{Int64, Int64}}=6)

    _check_var(frq, [:log, :lin], "frq")
    @assert fs >= 1 "fs must be ≥ 1."
    @assert pad >= 0 "pad must be ≥ 0."
    frq_lim = tuple_order(frq_lim)
    @assert !(frq_lim[1] < 0 || frq_lim[2] < 0 || frq_lim[1] > fs / 2 || frq_lim[2] > fs / 2) "frq_lim must be in [0, $(fs / 2)]."
    @assert frq_n >= 2 "frq_n must be ≥ 2."

    if frq === :log
        frq_lim = frq_lim[1] == 0 ? (0.1, frq_lim[2]) : (frq_lim[1], frq_lim[2])
        pf = round.(logspace(log10(frq_lim[1]), log10(frq_lim[2]), frq_n), digits=1)
    else
        pf = linspace(frq_lim[1], frq_lim[2], frq_n)
    end

    if typeof(ncyc) != Tuple{Int64, Int64}
        ncyc = repeat([ncyc], frq_n)
    else
        if frq === :log
            ncyc = round.(Int64, logspace(log10(ncyc[1]), log10(ncyc[2]), frq_n))
        else
            ncyc = round.(Int64, linspace(ncyc[1], ncyc[2], frq_n))
        end
    end

    ch_n = size(s, 1)
    pw = zeros(ch_n, length(pf))

    pad > 0 && (s = pad0(s, pad))
    @inbounds @simd for frq_idx in 1:frq_n
        kernel = generate_morlet(fs, pf[frq_idx], 1, ncyc=ncyc[frq_idx], complex=true)
        w_conv = fconv(s, kernel=kernel, norm=true)
        pw[frq_idx] = mean(@. abs(w_conv)^2)
    end

    pw = pw[1:length(pf)]
    
    norm == true && (pw = pow2db.(pw))

    return (pw=pw, pf=pf)

end

"""
    psd_mw(s; pad, norm, frq_lim, frq_n, frq, fs, ncyc)

Calculate power spectrum using Morlet wavelet convolution.

# Arguments

- `s::AbstractMatrix`
- `pad::Int64=0`: pad with `pad` zeros
- `norm::Bool=true`: normalize powers to dB
- `fs::Int64`: sampling rate
- `frq_lim::Tuple{Real, Real}=(0, fs / 2)`: frequency bounds
- `frq_n::Int64=10`: number of frequencies
- `frq::Symbol=:log`: linear (`:lin`) or logarithmic (`:log`) frequencies
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet, for tuple a variable number of cycles is used per frequency: `ncyc = logspace(log10(ncyc[1]), log10(ncyc[2]), frq_n)` for `frq = :log` or `ncyc = linspace(ncyc[1], ncyc[2], frq_n)` for `frq = :lin`

# Returns

Named tuple containing:
- `pw::Array{Float64, 2}`: powers
- `pf::Vector{Float64}`: frequencies
"""
function psd_mw(s::AbstractMatrix; pad::Int64=0, norm::Bool=true, fs::Int64, frq_lim::Tuple{Real, Real}=(0, fs / 2), frq_n::Int64=_tlength(frq_lim), frq::Symbol=:lin, ncyc::Union{Int64, Tuple{Int64, Int64}}=6)

    ch_n = size(s, 1)

    _, pf = psd_mw(s[1, :], pad=pad, norm=norm, fs=fs, frq_lim=frq_lim, frq_n=frq_n, frq=frq, ncyc=ncyc)
    pw = zeros(ch_n, length(pf))

    @inbounds @simd for ch_idx in 1:ch_n
        pw[ch_idx, :], _ = @views psd_mw(s[ch_idx, :], pad=pad, norm=norm, fs=fs, frq_lim=frq_lim, frq_n=frq_n, frq=frq, ncyc=ncyc)
    end

    return (pw=pw, pf=pf)

end

"""
    psd_mw(s; pad, norm, frq_lim, frq_n, frq, fs, ncyc)

Calculate power spectrum using Morlet wavelet convolution.

# Arguments

- `s::AbstractArray`
- `pad::Int64=0`: pad with `pad` zeros
- `norm::Bool=true`: normalize powers to dB
- `fs::Int64`: sampling rate
- `frq_lim::Tuple{Real, Real}=(0, fs / 2)`: frequency bounds
- `frq_n::Int64=10`: number of frequencies
- `frq::Symbol=:log`: linear (`:lin`) or logarithmic (`:log`) frequencies
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet, for tuple a variable number of cycles is used per frequency: `ncyc = logspace(log10(ncyc[1]), log10(ncyc[2]), frq_n)` for `frq = :log` or `ncyc = linspace(ncyc[1], ncyc[2], frq_n)` for `frq = :lin`

# Returns

Named tuple containing:
- `pw::Array{Float64, 3}`: powers
- `pf::Vector{Float64}`: frequencies
"""
function psd_mw(s::AbstractArray; pad::Int64=0, norm::Bool=true, fs::Int64, frq_lim::Tuple{Real, Real}=(0, fs / 2), frq_n::Int64=_tlength(frq_lim), frq::Symbol=:lin, ncyc::Union{Int64, Tuple{Int64, Int64}}=6)

    ch_n = size(s, 1)
    ep_n = size(s, 3)

    _, pf = psd_mw(s[1, :, 1], pad=pad, norm=norm, fs=fs, frq_lim=frq_lim, frq_n=frq_n, frq=frq, ncyc=ncyc)
    pw = zeros(ch_n, length(pf), ep_n)

    # initialize progress bar
    progress_bar == true && (progbar = Progress(ep_n * ch_n, dt=1, barlen=20, color=:white))

    @inbounds @simd for ep_idx in 1:ep_n
        Threads.@threads for ch_idx in 1:ch_n
            pw[ch_idx, :, ep_idx], _ = @views psd_mw(s[ch_idx, :, ep_idx], pad=pad, norm=norm, fs=fs, frq_lim=frq_lim, frq_n=frq_n, frq=frq, ncyc=ncyc)

            # update progress bar
            progress_bar == true && next!(progbar)
        end
    end

    return (pw=pw, pf=pf)

end

"""
    psd_mw(obj; ch, pad, norm, frq_lim, frq_n, frq, ncyc)

Calculate power spectrum using Morlet wavelet convolution.

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `ch::Union{Int64, Vector{Int64}, <:AbstractRange}=signal_channels(obj)`: index of channels, default is all s channels
- `pad::Int64=0`: pad with `pad` zeros
- `norm::Bool`=true: normalize powers to dB
- `frq_lim::Tuple{Real, Real}=(0, sr(obj) / 2)`: frequency bounds
- `frq_n::Int64=_tlength(frq_lim)`: number of frequencies
- `frq::Symbol=:log`: linear (`:lin`) or logarithmic (`:log`) frequencies
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet, for tuple a variable number of cycles is used per frequency: `ncyc=logspace(log10(ncyc[1]), log10(ncyc[2]), frq_n)` for `frq = :log` or `ncyc=linspace(ncyc[1], ncyc[2], frq_n)` for `frq = :lin`

# Returns

Named tuple containing:
- `pw::Array{Float64, 3}`: powers
- `pf::Vector{Float64}`: frequencies
"""
function psd_mw(obj::NeuroAnalyzer.NEURO; ch::Union{Int64, Vector{Int64}, <:AbstractRange}=signal_channels(obj), pad::Int64=0, norm::Bool=true, frq_lim::Tuple{Real, Real}=(0, sr(obj) / 2), frq_n::Int64=_tlength(frq_lim), frq::Symbol=:lin, ncyc::Union{Int64, Tuple{Int64, Int64}}=6)

    _check_channels(obj, ch)

    if length(ch) == 1
        pw, pf = @views psd_mw(reshape(obj.data[ch, :, :], length(ch), :, size(obj.data[ch, :, :], 2)), pad=pad, fs=sr(obj), norm=norm, frq_lim=frq_lim, frq_n=frq_n, frq=frq, ncyc=ncyc)
    else
        pw, pf = @views psd_mw(obj.data[ch, :, :], pad=pad, fs=sr(obj), norm=norm, frq_lim=frq_lim, frq_n=frq_n, frq=frq, ncyc=ncyc)
    end

    return (pw=pw, pf=pf)

end
