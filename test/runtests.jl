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

State  = Vector{Int64} # Consider https://github.com/JuliaArrays/StaticArrays.jl for speedup

function add_next_state!(available_prods::Array{Product}, next_states::Array{State}, s::State, product::Product)
    s_next = copy(s)
    for c_i in product
        new_c = s_next[c_i]-1
        if new_c<0
            return
        else
            s_next[c_i] = new_c
        end
    end
    push!(next_states, s_next)
    push!(available_prods, product)
end

function get_next_states(s::State, products)
    next_states::Vector{State} = [s]
    available_prods::Vector{Product} = [()] #Matrix{State}(undef, length(P.C), length(P.products))
    for p in products
        add_next_state!(available_prods, next_states, s, p)
    end
    return available_prods, next_states
end

println(get_next_states([0,1], P.products))

function state_transitions(s, actions, products, P)
    available_prods, next_states = get_next_states(s, products)

    T_s = Matrix{Float64}(undef, length(actions)+1, length(next_states)) # +1 for action=Infinity
    T_s[end, 2:end].=0.
    T_s[:, 1].=1. # First column is the state transition for empty product ()

    for (i_a, a) in enumerate(actions)
        for (i_p, p) in enumerate(available_prods)
            if p==()
                continue
            else
                p_T = prob_prod_req(p, P)*prob_user_accept(a)
                T_s[i_a, i_p] = p_T
                T_s[i_a, 1] -= p_T
            end
        end
    end

    return next_states, T_s
end

next_states, T_s = state_transitions([0,1], P.A, P.products, P)



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

    @test prob_prod_req((1,), 1, P) == P.λ[(1,)] / P.edge_selling_horizon_end[1]
    @test prob_prod_req((1, 2), 1, P) == P.λ[(1, 2)] / P.edge_selling_horizon_end[1]
end
end
