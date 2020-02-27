using Mdp
using Test

@testset "VI.jl" begin
    include("test_vi.jl")
end

@testset "FH.jl" begin
    include("test_fh.jl")
end

@testset "PricingProblem.jl" begin
    # include("test_pricing_problem.jl")

using Mdp.PricingProblem

# Model of problem:
"""
Model of problem:

3 nodes, 2 edges:
graph:      A---B---C
capacity:     1   1
sell end:     3   5
"""

P = Problem(
    (0:1, 0:1),             # Capacity of edges
    (3, 5),                 # Selling period end of edges
    5,                      # Number of timesteps (Start at 1)
    (10, 20),         # Actions (prices)
    ((1,), (2,), (1, 2)),   # Products (seqeuences of edge indeces)
    Dict((1,) => 0.5,         # λ: Dictionary of demand intensities for products
        (2,) => 0.5,
        (1, 2) => 0.5),
)


@testset "state_transitions" begin
    @test state_transitions([0,0], P.A, P.products, P) == ([[0,0]],
        reshape([1,1,1], 3,1))
    @test state_transitions([0,1], P.A, P.products, P) == ([[0,1],[0,0]],
        [0.9199999999999999 0.08000000000000002;
        0.96 0.04000000000000001;
        1.0 0.0])
    @test state_transitions([1,0], P.A, P.products, P) == ([[1,0],[0,0]],
        [0.8666666666666667 0.13333333333333333;
        0.9333333333333333 0.06666666666666667;
        1.0 0.0])
    @test state_transitions([1,1], P.A, P.products, P) == ([[1,1],[0,1],[1,0],[0,0]],
        [0.6533333333333333 0.13333333333333333 0.08000000000000002 0.13333333333333333;
        0.8266666666666667 0.06666666666666667 0.04000000000000001 0.06666666666666667;
        1.0 0.0 0.0 0.0])
end

@testset "get_next_states" begin
    @test get_next_states([0,0], P.products) == ([()], [[0,0]])
    @test get_next_states([0,1], P.products) == ([(), (2,)], [[0,1],[0,0]])
    @test get_next_states([1,0], P.products) == ([(), (1,)], [[1,0],[0,0]])
    @test get_next_states([1,1], P.products) == ([(), (1,), (2,), (1,2)], [[1,1],[0,1],[1,0],[0,0]])
end

@testset "prob_user_accept" begin
    @test prob_user_accept(5.0; slope_start = 5.0, slope_end = 10.0) == 1.0
    @test prob_user_accept(10.0; slope_start = 5.0, slope_end = 10.0) == 0.0
    @test prob_user_accept(7.5; slope_start = 5.0, slope_end = 10.0) == 0.5
    @test prob_user_accept(3.0; slope_start = 5.0, slope_end = 10.0) == 1.0
    @test prob_user_accept(15.0; slope_start = 5.0, slope_end = 10.0) == 0.0
end

@testset "prob_prod_req" begin
    @test len_product_selling_period((1,), P) == P.edge_selling_horizon_end[1]
    @test len_product_selling_period((2,), P) == P.edge_selling_horizon_end[2]
    @test len_product_selling_period((1, 2), P) == P.edge_selling_horizon_end[1]

    @test prob_prod_req((1,), P) == P.λ[(1,)] / P.edge_selling_horizon_end[1]
    @test prob_prod_req((1, 2), P) == P.λ[(1, 2)] / P.edge_selling_horizon_end[1]
end
end
