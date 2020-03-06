module PricingAlgorithmFH

using Mdp.PricingProblem

export State, add_next_state!, get_next_states, state_transitions, state2id, state_rewards, get_R, get_Q, get_V, get_π, pricing_FH

State = Vector{Int64} # Consider https://github.com/JuliaArrays/StaticArrays.jl for speedup

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

b = [1,2]
a = Matrix{Float64}(undef,5,5)
a[b...]

"""
    state_transitions(s, k, P.actions, P.products, P)

Compute transition probability matrix for transitions from state `s`. Return
array with next states and the transition table. Rows of the table are indexed
by actions from the problem description, plus the "reject" action. Columns
correspond to next states.

# Examples
see tests.
"""
function state_transitions(s::State, k::Int64, actions::Array{Int64}, products::Array{Product}, P::Problem)
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

"""
    state2id(s)

Convert state to matrix index.
"""
function state2id(s::State)
    return s.+1
end

function state_rewards(actions::Array{Int64})
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

function get_V(Q_k::Array{Float64, 3})
    # TODO: Merge V and π usinf `findmax` function
    V_k = maximum(Q_k, dims=1)
    V_k = dropdims(V_k, dims=1)
    return V_k
end

function get_π(Q_k::Array{Float64, 3})
    # TODO: Argmax here returns the lowest index for multiple equal values.
    # In deployment, randomizing over the actions could be better.
    # π_k = argmax(Q, dims=1) # returns Cartesian index
    π_k = mapslices(argmax,Q_k, dims=1) # Returns array
    π_k = dropdims(π_k, dims=1)
    return π_k
end

function pricing_FH(P::Problem)
    V_old = zeros(Float64, map(length, P.C)...)
    V_new = similar(V_old)
    # π_star = Array{Float64, 3}(undef,P.N,map(length, P.C)...)
    π_star = Array{Int64, 3}(undef, map(length, P.C)..., P.N)
    for k in P.N:-1:1
        Q_k = get_Q(k, V_old, P)
        V_new = get_V(Q_k)
        # π_star[k, :, :]=π(Q_k)
        π_star[:, :, k]= get_π(Q_k)
        V_old = V_new    # V_new, V_old = V_old, V_new
    end
    return π_star
end

end
