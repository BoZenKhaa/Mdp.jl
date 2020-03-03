module PricingAlgorithmFH

using Mdp.PricingProblem

export State, add_next_state!, get_next_states, state_transitions

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

"""
    state_transitions(s, k, P.actions, P.products, P)

Compute transition probability matrix for transitions from state `s`. Return
array with next states and the transition table. Rows of the table are indexed
by actions from the problem description, plus the "reject" action. Columns
correspond to next states.

# Examples
see tests.
"""
function state_transitions(s::State, k::Int64, actions::NTuple{N, Int64} where N, products::NTuple{N, Product} where N, P::Problem)
    available_prods, next_states = get_next_states(s, products)

    T_s = Matrix{Float64}(undef, length(actions)+1, length(next_states)) # +1 for action=Infinity
    T_s[end, 2:end].=0.
    T_s[:, 1].=1. # First column is the state transition for empty product ()

    for (i_a, a) in enumerate(actions)
        for (i_p, p) in enumerate(available_prods)
            if p==()
                continue
            else
                p_T = prob_prod_req(p, k, P)*prob_user_accept(a)
                T_s[i_a, i_p] = p_T
                T_s[i_a, 1] -= p_T
            end
        end
    end

    return next_states, T_s
end


end
