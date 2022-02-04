"""
    linspace(start, stop, length)

Generates `length`-long sequence of evenly spaced numbers between `start` and `stop`.
"""
linspace(start, stop, length) = collect(range(start, stop, length))

"""
    logspace(start, stop, length)

Generates `length`-long sequence of log10-spaced numbers between `start` and `stop`.
"""
logspace(start, stop, length) = collect(exp10.(range(start, stop, length)))

"""
    zero_pad(m)

Pads the matrix `m` with zeros to make it square.
"""
function zero_pad(m::Matrix)
    nr, nc = size(m)
    if nr > nc
        mp = repeat([0], nr, nr - nc)
        mp = hcat(m, mp)
    elseif nr < nc
        mp = repeat([0], nc - nr, nc)
        mp = vcat(m, mp)
    elseif nr == nc
        mp = m
    end
    return mp
end

"""
    vsearch(x, y; return_distance=false)

Returns the positions of the `y` value in the vector `x` and the difference between `y` and `x[vsearch(x, y)].
"""
function vsearch(x::Union{Vector{Int64}, Vector{Float64}}, y::Union{Int64, Float64}; return_distance=false)
    y_dist, y_idx = findmin(abs.(x .- y))
    return_distance == false && return y_idx
    return_distance == true && return y_idx, y_dist
end
"""
    vsearch(x, y)

Returns the positions of the `y` vector in the vector `x`.
"""
function vsearch(x::Union{Vector{Int64}, Vector{Float64}}, y::Union{Vector{Int64}, Vector{Float64}}; return_distance=false)
    length(y) > length(x) && throw(ArgumentError("Length of 'y' cannot be larger than length 'x'"))
    y_idx = zeros(length(y))
    y_dist = zeros(length(y))
    for idx in 1:length(y)
        y_dist[idx], y_idx[idx] = findmin(abs.(x .- y[idx]))
    end
    return_distance == false && return convert.(Int64, y_idx)
    return_distance == true && return convert.(Int64, y_idx), y_dist
end

"""
    cart2pol(x, y)

Converts cartographic coordinates `x` and `y` to polar.
"""
function cart2pol(x::Union{Int64, Float64}, y::Union{Int64, Float64})
    rho = hypot(x, y)
    theta = atan(y, x)
    return rho, theta
end

"""
    pol2cart(theta, rho)

Converts polar coordinates `theta` and `rho` to cartographic.
"""
function pol2cart(theta::Float64, rho::Float64)
    x = rho * cos(theta)
    y = rho * sin(theta)
    return x, y
end

"""
    generate_hann(n)

Returns the `n`-point long symmetric Hanning window.
"""
generate_hann(n::Int64) = 0.5 .* (1 .+ cos.(2 .* pi .* range(0, 1, length = n)))

"""
    hildebrand_rule(x)

Calculates Hildebrand rule for vector `x`.
If H < 0.2 then the vector `x` is symmetrical.
"""
hildebrand_rule(x::Union{Vector{Int64}, Vector{Float64}}) = (mean(x) - median(x)) ./ std(x)

"""
    jaccard_similarity(x, y)

Calculates Jaccard similarity between two vectors `x` and `y`.
"""
function jaccard_similarity(x::Union{Vector{Int64}, Vector{Float64}}, y::Union{Vector{Int64}, Vector{Float64}})
    intersection = length(intersect(x, y))
    union = length(x) + length(y) - intersection
    return intersection / union
end

"""
    fft0(x, n)

Calculates FFT for the vector `x` padded with `n` or `n - length(x)` zeros at the end.
"""
function fft0(x::Union{Vector{Int64}, Vector{Float64}, Vector{ComplexF64}}, n::Int64)
    n > length(x) && (n = n - length(x))
    return fft(vcat(x, zeros(eltype(x), n)))
end

"""
    ifft0(x, n)

Calculates IFFT for the vector `x` padded with `n` or `n - length(x)` zeros at the end.
"""
function ifft0(x::Vector{ComplexF64}, n::Int64)
    n > length(x) && (n = n - length(x))
    return ifft(vcat(x, zeros(eltype(x), n)))
end

"""
    nexpow2(x)

Returns the next power of 2 for given number `x`.
"""
function nexpow2(x::Int64)
    x == 0 && return 1
    x == 0 || return 2 ^ ndigits(x - 1, base=2)
end

"""
    vsplit(x, n)

Splits the vector `x` into `n`-long pieces.
"""
function vsplit(x::Union{Vector{Int64}, Vector{Float64}}, n::Int64=1)
    length(x) % n == 0 || throw(ArgumentError("""Length of "x" must be a multiple of "n"."""))
    x_m = reshape(x, length(x) ÷ n, n)
    result = [x_m[1, :]]
    for idx in 2:size(x_m, 1)
        result = vcat(result, [x_m[idx, :]])
    end
    return result
end

"""
    rms(x)

Calculates Root Mean Square of the vector `x`.
"""
rms(x::Union{Vector{Int64}, Vector{Float64}}) = norm(x) / sqrt(length(x))

"""
    generate_sine(f, t, a, p)

Generates sine wave of `f` frequency over `t` time; optional arguments are: `a` amplitude and  `p` phase.
"""
generate_sine(f, t::Union{Vector{Int64}, Vector{Float64}}, a=1, p=0) = @. a * sin(2 * pi * f * t + p)

"""
    freqs(t)

Returns vector of frequencies and Nyquist frequency for given time vector `t`.
"""
function freqs(t::Union{Vector{Int64}, Vector{Float64}, UnitRange{Int64}, StepRange{Int64, Int64}, StepRangeLen{Float64, Base.TwicePrecision{Float64}, Base.TwicePrecision{Float64}, Int64}})
    if typeof(t) == StepRangeLen{Float64, Base.TwicePrecision{Float64}, Base.TwicePrecision{Float64}, Int64}
        t = collect(t)
    end
    if typeof(t) == StepRange{Int64, Int64}
        t = collect(t)
    end

    # sampling interval
    dt = t[2] - t[1]
    # sampling rate
    fs = 1 / dt
    # frequency step size
    df = 1 / (length(t) * dt)
    # Nyquist frequency
    nyquist_freq = fs / 2
    # frequency array
    hz = collect(0:df:nyquist_freq)

    return hz, nyquist_freq
end

"""
    freqs(signal, fs)

Returns vector of frequencies and Nyquist frequency for given `signal` and `fs`.
"""
function freqs(signal::Vector{Float64}, fs::Union{Int64, Float64})
    # Nyquist frequency
    nyquist_freq = fs / 2
    # frequency array
    hz = linspace(0, nyquist_freq, floor(Int64, length(signal) / 2) + 1)

    return hz, nyquist_freq
end

"""
    matrix_sortperm(m; rev=false, dims=1)

Generates sorting index for matrix `m` by columns (`dims` = 1) or by rows (`dims` = 2).
"""
function matrix_sortperm(m::Matrix; rev=false, dims=1)
    m_idx = zeros(Int, size(m))
    idx=1
    if dims == 1
        for idx = 1:size(m, 2)
            # sort by columns
            m_idx[:, idx] = sortperm(m[:, idx], rev=rev)
        end
    else
        for idx = 1:size(m, 1)
            # sort by rows
            m_idx[idx, :] = sortperm(m[idx, :], rev=rev)'
        end     
    end
    return m_idx
end

"""
    matrix_sort(m, m_idx; rev=false, dims=1)

Sorts matrix `m` using sorting index `m_idx` by columns (`dims` = 1) or by rows (`dims` = 2).
"""
function matrix_sort(m::Matrix, m_idx::Vector{Int64}; rev=false, dims=1)
    sorted_m = zeros(eltype(m), size(m))
    if dims == 1
        for idx = 1:size(m, 2)
            # sort by columns
            tmp = m[:, idx]
            tmp = tmp[m_idx]
            sorted_m[:, idx] = tmp
        end
    else
        for idx = 1:size(m, 1)
            # sort by rows
            tmp = m[idx, :]
            tmp = tmp[m_idx]
            sorted_m[idx, :] = tmp
        end
    end
    return sorted_m
end

"""
    pad0(x, n)

Pads the vector `x` with `n` zeros at the beginning and at the end.
"""
# to do: check if x is numeric vector
pad0(x::Union{Vector{Int64}, Vector{Float64}}, n) = vcat(zeros(eltype(x), n), x, zeros(eltype(x), n))

"""
    hz2rads(f)

Converts frequency `f` in Hz to rad/s.
"""
hz2rads(f) = 2 * pi * f

"""
    rads2hz(f)

Converts frequency `f` in rad/s to Hz.
"""
rads2hz(f) = f / 2 * pi

"""
    z_score(x)

Calculates Z-scores for each value of the vector `x`.
"""
z_score(x) = (x .- mean(x)) ./ std(x)

"""
    k(n)

Calculates number of categories for a given sample size `n`.
"""
k(n) = (sqrt(n), (1 + 3.222 * log10(n)))

"""
    cmax(x)

Returns maximum value of the Complex vector`x`.
"""
cmax(x::Vector{ComplexF64}) = argmax(abs, x)

"""
    cmin(x)

Returns minimum value of the Complex vector`x`.
"""
cmin(x::Vector{ComplexF64}) = argmin(abs, x)

"""
    generate_sinc(t=0:0.01:10, f=10, peak=4)

Generates sinc function.

# Arguments

- `t::StepRangeLen` - time
- `f::Float64` - frequency
- `peak::Float64` - peak time of sinc function
"""
function generate_sinc(t=-2:0.01:2, f=10.0, peak=0)
    y_sinc = @. sin(2 * pi * f * (t - peak)) / (t - peak)
    nan_idx = y_sinc[y_sinc .== NaN]
    y_sinc[findall(isnan, y_sinc)[1]] = (y_sinc[findall(isnan, y_sinc)[1] - 1] + y_sinc[findall(isnan, y_sinc)[1] + 1]) / 2
    return y_sinc
end

"""
    generate_time(len, fs)

Returns time vector of length `len` and sampling frequency `fs`.
"""
generate_time(len::Union{Int64, Float64}, fs::Int64) = collect(range(0, len, step=(1 / fs)))


"""
    generate_morlet(fs, wt, wf)

Generates Morlet wavelet.

# Arguments

- `fs::Int64` - sampling frequency
- `wt::Union{Int64, Float64}` - length = -wt:1/fs:wt
- `wf::Union{Int64, Float64}` - frequency
- `ncyc::Int64` - number of cycles
- `complex::Bool` - generate complex Morlet
"""
function generate_morlet(fs::Int64, wt::Union{Int64, Float64}, wf::Union{Int64, Float64}; ncyc::Int64=5, complex::Bool=false)
    wt = -wt:1/fs:wt
    complex == false && (sin_wave = @. cos(2 * pi * wf * wt))           # for symmetry at x = 0
    complex == true && (sin_wave = @. exp(im * 2 * pi * wf * wt))       # for symmetry at x = 0
    w = 2 * (ncyc / (2 * pi * wf))^2                                    # ncyc: time-frequency precision
    gaussian = @. exp((-wt.^2) / w)
    morlet_wavelet = sin_wave .* gaussian
    return morlet_wavelet
end