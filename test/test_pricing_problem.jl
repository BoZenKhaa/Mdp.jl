
using Mdp.PricingProblem

P = Problem(
    (0:1, 0:1),             # Capacity of edges
    (3, 5),                 # Selling period end of edges
    5,                      # Number of timesteps (Start at 1)
    (10, 20),               # Actions (prices)
    ((1,), (2,), (1, 2)),   # Products (seqeuences of edge indeces)
    Dict((1,) => 0.5,       # λ: Dictionary of demand intensities for products
        (2,) => 0.5,
        (1, 2) => 0.4),
)

@testset "prob_user_accept" begin
    @test prob_user_accept(5.0; slope_start = 5.0, slope_end = 10.0) == 1.0
    @test prob_user_accept(10.0; slope_start = 5.0, slope_end = 10.0) == 0.0
    @test prob_user_accept(7.5; slope_start = 5.0, slope_end = 10.0) == 0.5
    @test prob_user_accept(3.0; slope_start = 5.0, slope_end = 10.0) == 1.0
    @test prob_user_accept(15.0; slope_start = 5.0, slope_end = 10.0) == 0.0
end

@testset "prob_prod_req" begin
    @test len_product_selling_period((1,),  P) == P.edge_selling_horizon_end[1]
    @test len_product_selling_period((2,), P) == P.edge_selling_horizon_end[2]
    @test len_product_selling_period((1, 2), P) == P.edge_selling_horizon_end[1]

    k = 3
    @test prob_prod_req((1,),k, P) == P.λ[(1,)] / P.edge_selling_horizon_end[1]
    @test prob_prod_req((2,),k, P) == P.λ[(2,)] / P.edge_selling_horizon_end[2]
    @test prob_prod_req((1, 2),k, P) == P.λ[(1, 2)] / P.edge_selling_horizon_end[1]
    k = 4
    @test prob_prod_req((1,),k, P) == 0.
    @test prob_prod_req((2,),k, P) == P.λ[(2,)] / P.edge_selling_horizon_end[2]
    @test prob_prod_req((1,2),k, P) == 0.
end
