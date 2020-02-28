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

"""
Model of test problem:

3 nodes, 2 edges: graph:      A---B---C
capacity:     1   1
sell end:     3   5
"""
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

"""
    state2id(s)

Convert state to matrix index.
"""
function state2id(s::State)
    return s.+1
end

function state_rewards(actions::NTuple{N, Int64} where N)
    R_s = zeros(Float64, length(actions)+1, 2) # 2 columns, one for empty product, one for all others
    # Last row is the "reject" action
    # First column is the state transition for empty product "()"
    R_s[1:(end-1),2].=actions

    return R_s
end

function get_R(s::State, s_next::State, R_s::Matrix{Float64})
    if s==s_next
        return R_s[:, 1]
    else
        return R_s[:, 2]
    end
end

k = P.N
V_k = zeros(Float64, map(length, P.C)...)
Q = zeros(Float64, length(P.A)+1, map(length, P.C)...)
R_s = state_rewards(P.A)

for it in P.S
    s = [it...]
    next_states, T_s = state_transitions(s,k, P.A, P.products, P)
    for (i_s, s_next) in enumerate(next_states)
        p = T_s[:,i_s]
        r = get_R(s, s_next, R_s)
        v_k = V_k[state2id(s_next)...]
        Q[:, state2id(s_next)...].+= p.*(r.+v_k)
    end
end

Q[1, :, :]
Q[2, :, :]
Q[3, :, :]


@testset "get_R" begin
    R_s = state_rewards(P.A)
    @test get_R([0,1], [0,1], R_s)==[0.,0.,0.]
    @test get_R([0,0], [0,0], R_s)==[0.,0.,0.]
    @test get_R([0,1], [0,0], R_s)==[P.A...,0.]
    @test get_R([1,0], [0,0], R_s)==[P.A...,0.]
    @test get_R([1,1], [0,1], R_s)==[P.A...,0.]
end

@testset "state_transitions" begin
    k = 3
    @test state_transitions([0,0],k, P.A, P.products, P) == ([[0,0]],
        reshape([1,1,1], 3,1))
    @test state_transitions([0,1],k, P.A, P.products, P) == ([[0,1],[0,0]],
        [0.9199999999999999 0.08000000000000002;
        0.96 0.04000000000000001;
        1.0 0.0])
    @test state_transitions([1,0],k, P.A, P.products, P) == ([[1,0],[0,0]],
        [0.8666666666666667 0.13333333333333333;
        0.9333333333333333 0.06666666666666667;
        1.0 0.0])
    @test state_transitions([1,1],k, P.A, P.products, P) == ([[1,1],[0,1],[1,0],[0,0]],
        [0.6799999999999999 0.13333333333333333 0.08000000000000002 0.10666666666666667;
        0.84 0.06666666666666667 0.04000000000000001 0.05333333333333334;
        1.0 0.0 0.0 0.0])

    k = 4
    @test state_transitions([0,0],k, P.A, P.products, P) == ([[0,0]],
        reshape([1,1,1], 3,1))
    @test state_transitions([0,1],k, P.A, P.products, P) == ([[0,1],[0,0]],
        [0.9199999999999999 0.08000000000000002;
        0.96 0.04000000000000001;
        1.0 0.0])
    @test state_transitions([1,0],k, P.A, P.products, P) == ([[1,0],[0,0]],
        [1. 0.0;
        1. 0.0;
        1.0 0.0])
    @test state_transitions([1,1],k, P.A, P.products, P) == ([[1,1],[0,1],[1,0],[0,0]],
        [0.91999999999999998 0.0 0.08000000000000002 0.0;
        0.95999999999999999 0.0 0.04000000000000001 0.0;
        1.0 0.0 0.0 0.0])
end

@testset "get_next_states" begin
    @test get_next_states([0,0], P.products) == ([()],
        [[0,0]])
    @test get_next_states([0,1], P.products) == ([(), (2,)],
        [[0,1],[0,0]])
    @test get_next_states([1,0], P.products) == ([(), (1,)],
        [[1,0],[0,0]])
    @test get_next_states([1,1], P.products) == ([(), (1,), (2,), (1,2)],
        [[1,1],[0,1],[1,0],[0,0]])
end

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
end
