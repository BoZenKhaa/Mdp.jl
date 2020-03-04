using Mdp
using Test


@testset "VI.jl" begin
    include("test_vi.jl")
end

@testset "FH.jl" begin
    include("test_fh.jl")
end

@testset "PricingProblem.jl" begin
    include("test_pricing_problem.jl")
end

@testset "PricingAlgorithmFH.jl" begin
    include("test_pricing_algorithm_fh.jl")
end
