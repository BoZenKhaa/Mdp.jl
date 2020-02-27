module PricingProblem

export Product, Problem, State, prob_user_accept, prob_prod_req, len_product_selling_period, add_next_state!, get_next_states, state_transitions

Product = NTuple{N, Int64} where N
State  = Vector{Int64} # Consider https://github.com/JuliaArrays/StaticArrays.jl for speedup

struct Problem
    C::NTuple{N, AbstractArray} where N # Capacity of problem capacity edges
    edge_selling_horizon_end::NTuple{N, Int64} where N # timestep after which the corresponding capacity edge can not be sold
    N::Int64  # Number of timesteps
    A::NTuple{N, Int64} where N # price range <-> actions
    products::NTuple{N, Product} where N
    λ::Dict{Product, Float64}

    S::Base.Iterators.ProductIterator # States defined by available capacity

    Problem(C, edge_selling_horizon_end, N, A, products, λ)=
        new(C, edge_selling_horizon_end, N, A, products, λ,
            Base.product(C...)
            )
end

function len_product_selling_period(product::Product, pr::Problem)
    pr.edge_selling_horizon_end[product[1]]
end

"""
    prob_user_accept(10, slope_start=5., slope_end=30.)

"Step" function with slope in the middle, like so:
  1-|-----\\
    |      \\
    |       \\
  0-|-----|--\\------
    0  start end

TODO: Handle better configuration of user model in problem, now its hardcoded here.
"""
function prob_user_accept(x::Number;
                        slope_start::Float64=5.,
                        slope_end::Float64=30.)
    if x<slope_start
        return 1.
    elseif x>slope_end
        return 0.
    else
        return (x-slope_end)/(slope_start-slope_end)
    end
end

function prob_prod_req(product::Product, pr::Problem)
    return pr.λ[product]/len_product_selling_period(product, pr)
end

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

"""
    state_transitions(s, P.actions, P.products, P)

Compute transition probability matrix for transitions from state `s`. Return
array with next states and the transition table. Rows of the table are indexed by
actions from the problem description, plus the "reject" action. Columns
correspond to next states.

# Examples
see tests.
"""
function state_transitions(s::State, actions::NTuple{N, Int64} where N, products::NTuple{N, Product} where N, P::Problem)
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

end
