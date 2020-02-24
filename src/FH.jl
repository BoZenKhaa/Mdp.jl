module FH

export finite_horizon, backward_recursion

function backward_recursion(s,n, V, S,A,N,T,R)
    V_a = zeros(Float64, length(A))
    for a in eachindex(A)
        for s_next in eachindex(S)
            if (s, a, s_next, n) in keys(T)
                r = R[s, a, s_next, n]
                p = T[s, a, s_next, n]

                # Backward induction formula
                V_a[a] += p*(r+V[s_next, n+1])
            end
        end
    end
    return maximum(V_a), argmax(V_a)
end

function finite_horizon(S,A,N,T,R; goal_reward = 0.)
    V = Matrix{Float64}(undef, length(S), length(N))
    V[:,N[end]].=goal_reward # Set rewords for reaching goal states
    π = Matrix{Int64}(undef, length(S), length(N))

    # println("Start")
    for n in reverse(N[1:end-1])
        # println(n)
        for s in S
            V[s, n], π[s,n] = backward_recursion(s,n,V, S,A,N,T,R)
        end
    end
    return V, π
end

end
