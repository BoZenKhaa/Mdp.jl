module PricingProblem

const selling_period_ends = (3,5,3)

req = [0,1]
λ = [2,2,2] # [[2,2],[2]]
N = 5

function prob_edge_req(req, ts)
    return λ[req_ind(req)]/selling_period_end(req)
end
