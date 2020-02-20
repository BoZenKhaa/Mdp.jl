module Mdp
export value_iteration, bellman_backup

function state_backup(sas, T, C, V_old)
    return get(T, sas, 0.)*(get(C, sas, 0.) + V_old[sas[end]])
end

function bellman_backup(s, S, A, T, C, V_old)
    Q = ones(length(A)).*typemax(Float64)
    for a in  eachindex(A)
        for s_next in eachindex(S)
            # Intutively, (sparse) matrix operations will be a lot faster than dict access
            if (s, a, s_next) in keys(T)
                if Q[a]==typemax(Float64)
                    Q[a]=0.
                end
                Q[a] += state_backup((s, a, s_next), T, C, V_old)
            end
        end
    end
    return minimum(Q)
end

function value_iteration(S,A,T,C; ϵ=0.001, V_old = zeros(length(S)))
    # println("Start")
    V_new = copy(V_old)
    residuals = ones(length(S)).*typemax(Float64)
    n = 0
    while maximum(residuals)>ϵ
        # println("Running, iteration $n ")
        # println(residuals)
        # println(V_old)

        n+=1
        for s in eachindex(S)
            V_new[s] = bellman_backup(s, S, A, T, C, V_old)
            # println(V_new[s])
        end
        residuals = abs.(V_new.-V_old)
        V_old, V_new = V_new, V_old
    end
    # println("Final: ")
    # println(residuals)
    # println(V_new)
    println("Finished after $n iterartions")
    return V_new
end

end # module