"""
This file contains the Customer implementation and related functionality.
"""

"""
    Customer

# Fields
`arrival::Float64`: time of arrival into the system
`departure::Float64`: time of departure from the system. equal to -1.0 if customer is still
                      in the system.
"""
mutable struct Customer
    arrival::Float64
    departure::Float64
end
