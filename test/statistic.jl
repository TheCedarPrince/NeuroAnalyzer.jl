using NeuroJ
using Test
using DataFrames
using GLM

@test hildebrand_rule([1, 2, 3]) == 0.0
@test jaccard_similarity(ones(3), zeros(3)) == 0.0
@test z_score([1, 2, 3]) == [-1.0, 0.0, 1.0]
@test k_categories(10) == (3.1622776601683795, 4.2219999999999995)
@test effsize([1,2,3], [2,3,4]) == (cohen = 1.0, hedges = 1.0)

x = rand(10)
y = rand(10)
df = DataFrame(:x=>x, :y=>y)
m = lm(@formula(y ~ x), df)
@test length(infcrit(m)) == 2

@test grubbs([1, 2, 3, 4, 5]) == false
@test outlier_detect(ones(10)) == zeros(10)

_, t, c, df, p, _, _, _, _ = seg_tcmp(ones(5,5,5), zeros(5,5,5), paired=true)
@test df == 4

true