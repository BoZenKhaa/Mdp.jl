using Mdp.FH

# Define simple FH domain (See figure in docs)
S = [1,2] # States
A = [1,2] # Actions
N = 1:3 # timesteps
T = Dict(   # Transitions, prob = T[(state, action, next_state, timestep)]
    (1,1,1,1)=>1.,
    (1,2,1,1)=>0.5,
    (1,2,2,1)=>0.5,
    (2,1,2,1)=>1.,
    (1,1,1,2)=>1.,
    (1,2,1,2)=>0.7,
    (1,2,2,2)=>0.3,
    (2,1,2,2)=>1.,
)
R = Dict( # Rewards, reward = R[(state, action, next_state, timestep)]
    (1,1,1,1)=>0.,
    (1,2,1,1)=>0.,
    (1,2,2,1)=>1.,
    (2,1,2,1)=>0.,
    (1,1,1,2)=>0.,
    (1,2,1,2)=>0.,
    (1,2,2,2)=>1.7,
    (2,1,2,2)=>0.,
)

V, π = finite_horizon(S,A,N,T,R)
@test V==[[0.755,0.] [0.51, 0.] [ 0., 0.]]
@test π[:, 1:end-1]==[[2,1] [2, 1]]
