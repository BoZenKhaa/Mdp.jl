println("=====================test_pricing_problem=====================")
# P = Problem(
#     [0:1, 0:1],             # Capacity of edges
#     [3, 5],                 # Selling period end of edges
#     5,                      # Number of timesteps (Start at 1)
#     [10, 20],               # Actions (prices)
#     [(1,), (2,), (1, 2)],   # Products (seqeuences of edge indeces)
#     Dict((1,) => 0.5,       # λ: Dictionary of demand intensities for products
#         (2,) => 0.5,
#         (1, 2) => 0.4),
# )

@testset "PricingProblem.jl" begin
using Mdp.PricingProblem

um = price -> prob_user_accept(price, slope_start=5., slope_end=30.)
e1, e2 = Edge(1, 3), Edge(1, 5)
prd1, prd2, prd12 = Product([e1,], 0.5, um),
                    Product([e2,], 0.5, um),
                    Product([e1,e2], 0.4, um)
P = Problem(
    [e1,e2],
    [prd1, prd2, prd12],
    [10,20],
    5
)

@testset "prob_user_accept" begin
    @test prob_user_accept(5.0; slope_start = 5.0, slope_end = 10.0) == 1.0
    @test prob_user_accept(10.0; slope_start = 5.0, slope_end = 10.0) == 0.0
    @test prob_user_accept(7.5; slope_start = 5.0, slope_end = 10.0) == 0.5
    @test prob_user_accept(3.0; slope_start = 5.0, slope_end = 10.0) == 1.0
    @test prob_user_accept(15.0; slope_start = 5.0, slope_end = 10.0) == 0.0
end

@testset "len_product_selling_period" begin
    @test len_product_selling_period(prd1) == 3
    @test len_product_selling_period(prd2) == 5
    @test len_product_selling_period(prd12) == 3
end

@testset "prob_prod_req" begin
    k = 3
    @test prob_prod_req(prd1, k, P) == 0.16666666666666666
    @test prob_prod_req(prd2, k, P) == 0.1
    @test prob_prod_req(prd12, k, P) == 0.13333333333333333
    k = 4
    @test prob_prod_req(prd1, k, P) == 0.
    @test prob_prod_req(prd2, k, P) == 0.1
    @test prob_prod_req(prd12, k, P) == 0.
end

@testset "product_generator" begin
    println(all_possible_products([e1, e2], 0.5, um))
end

end
