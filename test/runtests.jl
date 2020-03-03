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
Model of test problem 2:

2 nodes, 1 edge: graph:      A---B
capacity:     1
sell end:     5
"""
# P_2 = Problem(
#     (0:1,),                  # Capacity of edges
#     (5,),                    # Selling period end of edges
#     5,                      # Number of timesteps (Start at 1)
#     (10, 20),               # Actions (prices)
#     ((1,),),                # Products (seqeuences of edge indeces)
#     Dict((1,) => 0.5)       # λ: Dictionary of demand intensities for products
# )


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

function get_Q(k::Int64, V_next::Matrix{Float64}, P::Problem)
    Q = zeros(Float64, length(P.A)+1, map(length, P.C)...)
    R_s = state_rewards(P.A)

    for s_tuple in P.S
        s = [s_tuple...]
        next_states, T_s = state_transitions(s, k, P.A, P.products, P)
        for (i_s, s_next) in enumerate(next_states)
            p = T_s[:,i_s]
            r = get_R(s, s_next, R_s)
            v = V_next[state2id(s_next)...]
            # tmp = p.*(r.+v)
            # display("$s - $i_s - $s_next p: $tmp")
            Q[:, state2id(s)...].+= p.*(r.+v)
        end
    end
    return Q
end

# TODO: Merge V and π usinf `findmax` function
function V(Q_k::Array{Float64, 3})
    V_k = maximum(Q_k, dims=1)
    V_k = dropdims(V_k, dims=1)
    return V_k
end

function π(Q_k::Array{Float64, 3})
    # TODO: Argmax here returns the lowest index for multiple equal values.
    # In deployment, randomizing over the actions could be better.
    # π_k = argmax(Q, dims=1) # returns Cartesian index
    π_k = mapslices(argmax,Q_k, dims=1) # Returns array
    π_k = dropdims(π_k, dims=1)
    return π_k
end

V_next = ones(Float64, map(length, P.C)...).*10
k = 5
Q = get_Q(k, V_next, P)
π_k = π(Q)
V_k = V(Q)
display(Q)
display(Q[1,2,2])
display(Q[2,2,2])


@testset "Q, π, V" begin
    @testset "Test Problem 1" begin
        # See docs/FH_mdp_testcase.jpg
        @testset "V_next=0" begin
            V_next = zeros(Float64, map(length, P.C)...)
            k = 3#P.N
            Q = get_Q(k, V_next, P)
            # Q array dimensions are [c1, a, c2]
            @test Q == cat([0.0 1.3333333333333333;
                            0.0 1.3333333333333333;
                            0.0 0.0],
                            [0.8000000000000002 3.2;
                            0.8000000000000002 3.2;
                            0.0 0.0], dims=3)
            @test V(Q) == [0.0 0.8000000000000002;
                           1.3333333333333333 3.2]
            @test π(Q) == [1 1; 1 1]

            k=5 # difference from selling period end for products (1,) and (1,2)
            Q = get_Q(k, V_next, P)
            @test Q == cat([0.0 0.0;
                            0.0 0.0;
                            0.0 0.0],
                            [0.8000000000000002 0.8000000000000002;
                            0.8000000000000002 0.8000000000000002;
                            0.0 0.0], dims=3)
            @test V(Q) == [0.0 0.8000000000000002;
                          0.0 0.8000000000000002]
            @test π(Q) == [1 1; 1 1]
        end

        @testset "V_next=10" begin
            V_next = ones(Float64, map(length, P.C)...).*10
            k = 3
            #TODO: The action 2 is caused by numerical instability!
            Q = get_Q(k, V_next, P)
            @test Q == cat([10.0 11.333333333333334;
                            10.0 11.333333333333334;
                            10.0 10.0],
                            [10.799999999999999 13.199999999999998;
                            10.8 13.200000000000001;
                            10.0 10.0], dims=3)
            @test V(Q) == [0.0 0.8000000000000002;
                          1.3333333333333333 3.200000000000001].+10.
            @test π(Q) == [1 2; 1 2]

            k = 5
            Q = get_Q(k, V_next, P)
            @test Q == cat([10.0 10.0;
                            10.0 10.0;
                            10.0 10.0],
                            [10.799999999999999 10.799999999999999;
                            10.8 10.8; 
                            10.0 10.0], dims=3)
            @test V(Q) == [0.0 0.8000000000000002;
                          0.0 0.8000000000000002].+10.
            @test π(Q) == [1 2; 1 2]
        end
    end
    @testset "Test Problem 2" begin
    end
end


@testset "state2id" begin
    @test state2id([0,1])==[1,2]
    @test state2id([0,0])==[1,1]
end

@testset "get_R" begin
    R_s = state_rewards(P.A)
    @test get_R([0,1], [0,1], R_s)==[0.,0.,0.]
    @test get_R([0,0], [0,0], R_s)==[0.,0.,0.]
    @test get_R([0,1], [0,0], R_s)==[P.A...,0.]
    @test get_R([1,0], [0,0], R_s)==[P.A...,0.]
    @test get_R([1,1], [0,1], R_s)==[P.A...,0.]
end

@testset "state_transitions" begin
    """
    These probabilities are used to set up the following testcases.
    """
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
