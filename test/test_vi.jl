using Mdp.VI
# Define simple domains (from Massau Kolobov 2016 book, p.41)
S = 1:6 # States
A = 1:2
T = Dict(   # Transitions, prob = T[(state, action, next_state)]
    (1,1,3)=>1.,
    (1,2,2)=>1.,
    (2,1,3)=>1.,
    (3,1,5)=>1.,
    (3,2,2)=>1.,
    (4,1,5)=>1.,
    (5,1,6)=>1.,
    (5,2,6)=>.6,
    (5,2,4)=>.4,
    (6,1,6)=>1.,    # Manually added goal state transition
)
C = Dict( # Costs, cost = C[(state, action, next_state)]
    (1,1,3)=>1,
    (1,2,2)=>1,
    (2,1,3)=>1,
    (3,1,5)=>1,
    (3,2,2)=>1,
    (4,1,5)=>1,
    (5,1,6)=>5,
    (5,2,6)=>2,
    (5,2,4)=>2,
    (6,1,6)=>0,   # Manually added goal state transition cost
)

V_init = [3.,3.,2.,2.,1.,0.]
@testset "Bellman backup" begin
    @test bellman_backup(1, S, A, T, C, V_init)==3.
    @test bellman_backup(2, S, A, T, C, V_init)==3.
    @test bellman_backup(3, S, A, T, C, V_init)==2.
    @test bellman_backup(4, S, A, T, C, V_init)==2.
    @test bellman_backup(5, S, A, T, C, V_init)==2.8
    @test bellman_backup(6, S, A, T, C, V_init)==0.
end

@test isapprox(value_iteration(S,A,T,C, ϵ=0.001, V_old=[3.,3.,2.,2.,1.,0.]), [5.99921,5.99921,4.99969, 4.99969,3.99969,0.], atol=0.001)
