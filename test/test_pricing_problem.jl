using Mdp.PricingProblem

# Model of problem:
"""
Model of problem:

3 nodes, 2 edges:
graph:      A---B---C
capacity:     1   1
sell end:     3   5
"""

const capacity_ranges = (0:1, 0:1) # Capacity of problem capacity edges
const selling_period_ends = (3,5) # timestep after which the corresponding capacity edge can not be sold
const N = 5  # Number of timesteps
const S = Base.product(capacity_ranges...) # States defined by available capacity
const A = [10,20,1000] # price range <-> actions

const λ = [2,2,2] # demand intensity for edge A-B, B-C, A-C


function prob_user_accept(x::Number)
    # "Step" function with slope in the middle, like so:
    #  1-|-----\
    #    |      \
    #    |       \
    #  0-|-----|--\------
    #    0  start end
    slope_start = 5.
    slope_end = 10.
    if x<slope_start
        return 1.
    elseif x>slope_end
        return 0.
    elseif
        return (x-slope_end)/(slope_start-slope_end)

end

function prob_edge_arrival(edge, timestep)

end

function next_states(s, n) # Transition probability and reward matrices for transitions between states

end
