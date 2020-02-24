using Mdp
using Test

@testset "VI.jl" begin
    # Write your own tests here.
    include("test_vi.jl")
end

@testset "FH.jl" begin
    # Write your own tests here.
    include("test_fh.jl")
end

@testset "PricingProblem.jl" begin
    # Write your own tests here.
    include("test_pricing_problem.jl")
end
