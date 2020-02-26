module PricingProblem

export Product, Problem, prob_user_accept, prob_prod_req, len_product_selling_period

Product = NTuple{N, Int64} where N

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

function prob_user_accept(
                        x::Number;
                        slope_start::Float64=5.,
                        slope_end::Float64=30.)
    # "Step" function with slope in the middle, like so:
    #  1-|-----\
    #    |      \
    #    |       \
    #  0-|-----|--\------
    #    0  start end
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

end
