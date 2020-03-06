module PricingProblem

using Combinatorics

export Product, Problem, Edge, prob_user_accept, prob_prod_req,
len_product_selling_period, all_possible_products

# Product = NTuple{N, Int64} where N

struct Edge
    c::Int64   # capacity
    selling_horizon_end::Int64
end

struct Product
    edges::Array{Edge}#NTuple{N,Edge} where N # indexes into the edges array of the problem
    λ::Float64     # user demand intensity for product
    um::Function    # user model of product buyers
end

struct Problem
    edges::Array{Edge}  # Problem capacity edges
    products::Array{Product}
    A::Array{Int64} # price actions of seller (common for all products)
    N::Int64        # number of timesteps
end

# struct Problem
#     C::Array{AbstractArray} # Capacity of problem capacity edges
#     edge_selling_horizon_end::Array{Int64} # timestep after which the corresponding capacity edge can not be sold
#     N::Int64  # Number of timesteps
#     A::Array{Int64} # price range <-> actions
#     products::Array{Product}
#     λ::Dict{Product, Float64}
#
#     S::Base.Iterators.ProductIterator # States defined by available capacity
#
#     Problem(C, edge_selling_horizon_end, N, A, products, λ)=
#         new(C, edge_selling_horizon_end, N, A, products, λ,
#             Base.product(Tuple(C)...))
# end

function len_product_selling_period(product::Product)
    product.edges[1].selling_horizon_end
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

function prob_prod_req(product::Product, timestep::Int64, pr::Problem)
    if timestep <= len_product_selling_period(product)
        return product.λ/len_product_selling_period(product)
    else
        return 0.
    end
end

function all_possible_products(edges::Array{Edge}, λ::Float64, um::Function)
    edge_combos = collect(combinations(edges))
    products = Array{Product}(undef, length(edge_combos))
    for (i, product_edges) in enumerate(edge_combos)
        products[i]=Product(product_edges, 1, price->price)
    end
    return products
end

end
