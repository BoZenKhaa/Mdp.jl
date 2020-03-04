using Mdp.PricingProblem
using Mdp.PricingAlgorithmFH

"""
Model of test problem:

3 nodes, 2 edges: graph:      A---B---C
capacity:     1   1
sell end:     3   5
"""
P = Problem(
    [0:1, 0:1],             # Capacity of edges
    [3, 5],                 # Selling period end of edges
    5,                      # Number of timesteps (Start at 1)
    [10, 20],               # Actions (prices)
    [(1,), (2,), (1, 2)],   # Products (seqeuences of edge indeces)
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
P_2 = Problem(
    [0:1,],                 # Capacity of edges
    [5,],                   # Selling period end of edges
    5,                      # Number of timesteps (Start at 1)
    [10, 20],               # Actions (prices)
    [(1,),],                # Products (seqeuences of edge indeces)
    Dict((1,) => 0.5)       # λ: Dictionary of demand intensities for products
)

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
            @test get_V(Q) == [0.0 0.8000000000000002;
                           1.3333333333333333 3.2]
            @test get_π(Q) == [1 1; 1 1]

            k=5 # difference from selling period end for products (1,) and (1,2)
            Q = get_Q(k, V_next, P)
            @test Q == cat([0.0 0.0;
                            0.0 0.0;
                            0.0 0.0],
                            [0.8000000000000002 0.8000000000000002;
                            0.8000000000000002 0.8000000000000002;
                            0.0 0.0], dims=3)
            @test get_V(Q) == [0.0 0.8000000000000002;
                          0.0 0.8000000000000002]
            @test get_π(Q) == [1 1; 1 1]
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
            @test get_V(Q) == [0.0 0.8000000000000002;
                          1.3333333333333333 3.200000000000001].+10.
            @test get_π(Q) == [1 2; 1 2]

            k = 5
            Q = get_Q(k, V_next, P)
            @test Q == cat([10.0 10.0;
                            10.0 10.0;
                            10.0 10.0],
                            [10.799999999999999 10.799999999999999;
                            10.8 10.8;
                            10.0 10.0], dims=3)
            @test get_V(Q) == [0.0 0.8000000000000002;
                          0.0 0.8000000000000002].+10.
            @test get_π(Q) == [1 2; 1 2]
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
