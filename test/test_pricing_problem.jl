using Mdp.PricingProblem

capacity_ranges = (0:2, 0:2, 0:2) # Capacity of problem capacity edges
selling_period_ends = (2,3,4) # timestep after which the corresponding capacity edge can not be sold
N = 4  # Number of timesteps
S = Base.product(capacity_ranges...) # States defined by available capacity
A = [10,20,30,1000] # price range <-> actions

function following_states(s, a, s_next, n) # Transition probability and reward for transitions between states


end


for v in S
    println(v)
end
