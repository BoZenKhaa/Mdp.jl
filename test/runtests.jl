using Mdp
using Test


@testset "VI.jl" begin
    include("test_vi.jl")
end

@testset "FH.jl" begin
    include("test_fh.jl")
end

include("test_pricing_problem.jl")


@testset "PricingAlgorithmFH.jl" begin
    include("test_pricing_algorithm_fh.jl")
end
