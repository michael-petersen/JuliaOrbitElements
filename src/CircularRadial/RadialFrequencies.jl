#=
RadialFrequencies.jl

Special treatment for radial orbits


=#

"""make_o2r

do a high-resolution interpolation to get frequency curves for radial orbits
recall that o1 for radial orbits is 2*o2

inputs
----------------
- potential
- dpotential
- ddpotential
- numr          : (Int64) number of interpolation points

 @IMPROVE the potential range is not adaptive.

"""
function make_o2r(potential::Function,dpotential::Function,ddpotential::Function,numr::Int64=2000)

    testu = 10 .^ LinRange(-5.,5.,numr)

    # initialise the interpolation array
    farr = Array{Float64}(undef, (numr))

    for u = 1:numr
        f3,f4 = compute_frequencies_henon_ae(potential,dpotential,ddpotential,testu[u],1.)
        farr[u] = f4
    end

    o2radial = LinearInterpolation(testu,farr)

    return o2radial
end

"""Omega2rad_to_radius(omega,o2rad[, rmax])

perform the backwards mapping from Omega_2 for a radial orbit to radius, via zero-finding
"""
function Omega2rad_to_radius(omega::Float64,o2rad,rmax::Float64=1000.)
    r_omega1 = optimize(x -> abs(omega - o2rad(x)), 0.    ,rmax  , Brent()).minimizer
    return r_omega1
end

"""Omega1rad_to_radius(omega,o2rad[, rmax])

perform the backwards mapping from Omega_1 for a radial orbit to radius, via zero-finding

uses Omega1 = 2*Omega2 for a radial orbit!
"""
function Omega1rad_to_radius(omega::Float64,o2rad,rmax::Float64=1000.)
    r_omega1 = optimize(x -> abs(omega - 2*o2rad(x)), 0.    ,rmax  , Brent()).minimizer
    return r_omega1
end
