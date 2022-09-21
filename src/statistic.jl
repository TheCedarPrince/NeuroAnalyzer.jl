"""
    hildebrand_rule(x)

Calculate Hildebrand rule for vector `x`.
If H < 0.2 then the vector `x` is symmetrical.

# Arguments

- `x::AbstractVector`

# Returns

- `h::Float64`
"""
function hildebrand_rule(x::AbstractVector)
    return (mean(x) - median(x)) ./ std(x)
end

"""
    jaccard_similarity(x, y)

Calculate Jaccard similarity between two vectors `x` and `y`.

# Arguments

- `x::AbstractVector`
- `y::AbstractVector`

# Returns

- `j::Float64`
"""
function jaccard_similarity(x::AbstractVector, y::AbstractVector)

    i = length(intersect(x, y))
    u = length(x) + length(y) - i
    j = i / u

    return j
end

"""
    z_score(x)

Calculate Z-scores for each value of the vector `x`.

# Arguments

- `x::AbstractVector`

# Returns

- `z_score::Vector{Float64}`
"""
function z_score(x::AbstractVector)

    return (x .- mean(x)) ./ std(x)
end

"""
    k_categories(n)

Calculate number of categories for a given sample size `n`.

# Arguments

- `n::Int64`

# Returns

Named tuple containing:
- `k1::Float64`: sqrt(n)
- `k2::Float64`: 1 + 3.222 * log10(n)
"""
function k_categories(n::Int64)
    return (k1=sqrt(n), k2=(1 + 3.222 * log10(n)))
end

"""
    effsize(x1, x2)

Calculate Cohen's d and Hedges g effect sizes.

# Arguments

- `x1::AbstractVector`
- `x2::AbstractVector`

# Returns

Named tuple containing:
- `d::Float64`: Cohen's d
- `g::Float64`: Hedges g
"""
function effsize(x1::AbstractVector, x2::AbstractVector)
    d = (mean(x2) - mean(x1)) / sqrt((std(x1)^2 + std(x2)^2) / 2)
    g = (mean(x2) - mean(x1)) / sqrt((((length(x1) - 1) * (std(x1)^2)) + ((length(x2) - 1) * (std(x2)^2))) / (length(x1) + length(x2) - 2))
    return (cohen=d, hedges=g)
end

"""
    infcrit(m)

Calculate Akaike’s Information Criterion (AIC) and Bayesian Information Criterion (BIC) for a linear regression model `m`.

# Arguments

- `m::StatsModels.TableRegressionModel`

# Returns

Named tuple containing:
- `aic::Float64`
- `bic::Float64`
"""
function infcrit(m)

    typeof(m) <: StatsModels.TableRegressionModel || throw(ArgumentError("Argument must be a regression model."))

    k = length(coef(m)) - 1
    n = length(MultivariateStats.predict(m))
    aic = 2 * k - 2 * log(r2(m))
    bic = k * log(n) - 2 * log(r2(m))
    
    return (aic=aic, bic=bic)
end

"""
    grubbs(x; alpha, t)

Perform Grubbs test for outlier in vector `x`.

# Arguments

- `x::AbstractVector`
- `alpha::Float64=0.95`
- `t::Int64=0`: test type: -1 test whether the minimum value is an outlier; 0 two-sided test; 1 test whether the maximum value is an outlier

# Returns

Named tuple containing:
- `g::Bool`: true: outlier exists, false: there is no outlier
"""
function grubbs(x::AbstractVector; alpha::Float64=0.95, t::Int64=0)

    std(x) == 0 && throw(ArgumentError("Standard deviation of the input vector must not be 0."))

    n = length(x)
    df = n - 2

    if t == 0
        two_sided = true
        g = maximum(abs.(x .- mean(x))) / std(x)
    elseif t == -1
        two_sided = false
        g = (mean(x) - minimum(x)) / std(x)
    elseif t == 1
        two_sided = false
        g = (maximum(x) - mean(x)) / std(x)
    else
        throw(ArgumentError("type must be -1, 0 or 1."))
    end

    p = two_sided == true ? (1 - alpha) / (2 * n) : (1 - alpha) / n
    t_critical = quantile(TDist(df), 1 - p)
    h = (n - 1) * t_critical / sqrt(n * (df + t_critical^2))

    return g < h ? false : true
end

"""
    outlier_detect(x; method)

Detect outliers in `x`.

# Arguments

- `x::AbstractVector`
- `method::Symbol=iqr`: methods: `:iqr` (interquartile range), `:z` (z-score) or `:g` (Grubbs test)

# Returns

- `o::Vector{Bool}`: index of outliers
"""
function outlier_detect(x::AbstractVector; method::Symbol=:iqr)
    method in [:iqr, :z, :g] || throw(ArgumentError("method must be :iqr, :z or :g."))

    o = zeros(Bool, length(x))
    
    if method === :iqr
        m1 = quantile(x, 0.25) - 1.5 * iqr(x)
        m2 = quantile(x, 0.75) + 1.5 * iqr(x)
        o[x .< m1] .= true
        o[x .> m2] .= true
    elseif method === :z
        z = z_score(x)
        o[z .< -3] .= true
        o[z .> 3] .= true
    else
        length(x) > 6 || throw(ArgumentError("For :g method length(x) must be > 6."))
        x_tmp = deepcopy(x)
        for idx in length(x_tmp):-1:6
            _, m_idx = findmax(x_tmp)
            if grubbs(x_tmp, t=1) == true
                o[m_idx] = true
                deleteat!(x_tmp, m_idx)
            end
        end
        x_tmp = deepcopy(x)
        for idx in length(x_tmp):-1:6
            _, m_idx = findmin(x_tmp)
            if grubbs(x_tmp, t=-1) == true
                o[m_idx] = true
                deleteat!(x_tmp, m_idx)
            end
        end
    end
    
    return o
end

"""
    seg_tcmp(seg1, seg2, paired)

Compare two segments; Kruskall-Wallis test is used first, next t-test (paired on non-paired) or non-parametric test (paired: Wilcoxon signed rank, non-paired: Mann-Whitney U test) is applied.

# Arguments

- `seg1::AbstractArray`
- `seg2::AbstractArray`
- `paired::Bool`
- `alpha::Float64=0.05`: confidence level
- `type::Symbol=:auto`: choose test automatically (:auto, :p for parametric and :np for non-parametric)

# Returns

Named tuple containing:
- `tt`: test results
- `t::Tuple{Float64, String}`: test value and name
- `c::Tuple{Float64, Float64}`: test value confidence interval
- `df::Int64`: degrees of freedom
- `p::Float64`: p-value
- `seg1::Vector{Float64}`: averaged segment 1
- `seg2::Vector{Float64}`: averaged segment 2
"""
function seg_cmp(seg1::AbstractArray, seg2::AbstractArray; paired::Bool, alpha::Float64=0.05, type::Symbol=:auto)

    type in [:auto, :p, :np] || throw(ArgumentError("type must be :auto, :p or :np."))
    paired == true && size(seg1) != size(seg2) && throw(ArgumentError("For paired test both segments must have the same size."))

    seg1_avg = reshape(mean(mean(seg1, dims=1), dims=2), size(seg1, 3))
    seg2_avg = reshape(mean(mean(seg2, dims=1), dims=2), size(seg2, 3))

    ks = ApproximateTwoSampleKSTest(seg1_avg, seg2_avg)
    pks = pvalue(ks)
    if (pks < alpha && type === :auto) || type === :p
        if paired == true
            tt = OneSampleTTest(seg1_avg, seg2_avg)
        else
            pf = pvalue(VarianceFTest(seg1_avg, seg2_avg))
            if pf < alpha
                tt = EqualVarianceTTest(seg1_avg, seg2_avg)
            else
                tt = UnequalVarianceTTest(seg1_avg, seg2_avg)
            end
        end
        df = tt.df
        t = round(tt.t, digits=2)
        c = round.(confint(tt, level=(1 - alpha)), digits=2)
        tn = "t"
    elseif (pks >= alpha && type === :auto) || type === :np
        if paired == true
            tt = SignedRankTest(seg1_avg, seg2_avg)
            t = round(tt.W, digits=2)
            df = tt.n - 1
            tn = "W"
        else
            tt = MannWhitneyUTest(seg1_avg, seg2_avg)
            t = round(tt.U, digits=2)
            df = 2 * size(seg1, 3) - 2
            tn = "U"
        end
        c = NaN
    end

    p = pvalue(tt)
    p < eps() && (p = 0.0001)
    p = round(p, digits=4)

    return (tt=tt, t=(t, tn), c=c, df=df, p=p, seg1=seg1_avg, seg2=seg2_avg)
end

"""
    binom_prob(p, r, n)

Calculate probability of exactly `r` successes in `n` trials.

# Arguments

- `p::Float64`: proportion of successes
- `r::Int64`: number of successes
- `n::Int64`: number of trials

# Returns

- `binomp::Float64`: probability
"""
function binom_prob(p::Float64, r::Int64, n::Int64)
    return binomial(n, r) * (p^r) * (1 - p)^(n - r)
end

"""
    binom_stat(p, n)

Calculate mean and standard deviation for probability `p`.

# Arguments

- `p::Float64`: proportion of successes
- `n::Int64`: number of trials

# Returns

- `mean::Float64`
- `std::Float64`
"""
function binom_stat(p::Float64, n::Int64)
    return n * p, sqrt(n * p * (1 - p))
end

"""
    cvar_mean(x)

Calculate coefficient of variation for a mean.

# Arguments

- `x::AbstractVector`

# Returns

- `cvar::Float64`
"""
function cvar_mean(x::AbstractVector)
    return std(x) / mean(x)
end

"""
    cvar_median(x)

Calculate coefficient of variation for a median.

# Arguments

- `x::AbstractVector`

# Returns

- `cvar::Float64`
"""
function cvar_median(x::AbstractVector)
    return ((quantile(x, 0.75) - quantile(x, 0.25)) / 2) / median(x)
end

"""
    cvar(se, s)

Calculate coefficient of variation for statistic `s`.

# Arguments

- `se::Real`: standard error
- `s::Real`: statistics, e.g. mean value

# Returns

- `cvar::Float64`
"""
function cvar(se::Real, s::Real)
    return 100 * (se / s)
end

"""
    effsize(p1, p2)

Calculate effect size for two proportions `p1` and `p2`.

# Arguments

- `p1::Float64`: 1st proportion, e.g. 0.7
- `p2::Float64`: 2nd proportion, e.g. 0.3

# Returns

- `e::Float64`
"""
function effsize(p1::Float64, p2::Float64)
    p1 + p2 == 1.0 || throw(ArgumentError("Proportions must add to 1.0."))    
    return 2 * asin(sqrt(p1)) - 2 * asin(sqrt(p2))
end

"""
    meang(x)

Calculate geometric mean.

# Arguments

- `x::AbstractVector`

# Returns

- `m::Float64`
"""
function meang(x::AbstractVector)
    return exp(mean(log.(x[x .> 0])))
end

"""
    meanh(x)

Calculate harmonic mean.

# Arguments

- `x::AbstractVector`

# Returns

- `m::Float64`
"""
function meanh(x::AbstractVector)
    return length(x) / sum(1 ./ x)
end

"""
    meanw(x, w)

Calculate weighted mean.

# Arguments

- `x::AbstractVector`
- `w::AbstractVector`: weights

# Returns

- `m::Float64`
"""
function meanw(x::AbstractVector, w::AbstractVector)
    length(x) == length(w) || throw(ArgumentError("Weights and values vectors must have the same length."))
    return length(x) / sum(1 ./ x)
end

"""
    moe(n)

Calculate margin of error for given sample size `n`.

# Arguments

- `n::Int64`

# Returns

- `moe::Float64`
"""
function moe(n::Int64)
    return 1 / sqrt(n)
end

"""
    rng(x)

Calculate range.

# Arguments

- `x::AbstractVector`

# Returns

- `r::Float64`
"""
function rng(x::AbstractVector)
    return maximum(x) - minimum(x)
end

"""
    se(x)

Calculate standard error.

# Arguments

- `x::AbstractVector`

# Returns

- `se::Float64`
"""
function se(x::AbstractVector)
    return std(x) / sqrt(length(x))
end

"""
    pred_int(n)

Calculates the prediction interval (95% CI adjusted for sample size)

# Arguments

- `n::Int64`: sample size

# Returns

- `pred_int::Tuple{Float64, Float64}`
"""
function pred_int(n::Int64)
    n < 1 && throw(ArgumentError("n must be ≥ 1."))
    if n > 0 && n < 21
        return [NaN, 15.56, 4.97, 3.56, 3.04, 2.78, 2.62, 2.51, 2.43, 2.37, 2.33, 2.29, 2.26, 2.24, 2.22, 2.18, 2.17, 2.16, 2.10][n]
    end
    @warn "Result may not be accurate."
    n > 20 && n <= 25 && return 2.10
    n > 25 && n <= 30 && return 2.08
    n > 31 && n <= 35 && return 2.06
    n > 35 && n <= 40 && return 2.05
    n > 41 && n <= 50 && return 2.03
    n > 51 && n <= 60 && return 2.02
    n > 61 && n <= 70 && return 2.01
    n > 71 && n <= 80 && return 2.00
    n > 81 && n <= 90 && return 2.00
    n > 91 && n <= 100 && return 1.99
    n > 100 && return 1.98
end