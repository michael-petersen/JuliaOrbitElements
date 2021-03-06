"""alphabeta_from_uv(u,v,n1,n2,dψdr,d²ψdr²,rmax,Omega0)

mapping from (alpha,beta) to (u,v)

Fouvry & Prunet B5

@IMPROVE, this has rounding error: concern?
@IMPROVE, Omega0 isnt really optional, so we should perhaps not set a default?

"""
function alphabeta_from_uv(u::Float64,v::Float64,
                           n1::Int64,n2::Int64,
                           dψdr::Function,d²ψdr²::Function,
                           rmax::Float64=1000.,Omega0::Float64=1.)


    ωmin,ωmax = find_wmin_wmax(n1,n2,dψdr,d²ψdr²,rmax,Omega0)

    if n2 == 0
        beta  = v
        alpha = (1/(2n1))*((ωmax-ωmin)*u + ωmin + ωmax)
    else
        alpha = v
        beta  = (1/(n2*v))*(0.5*((ωmax-ωmin)*u + ωmin + ωmax) - n1*v)
    end

    return alpha,beta
end

"""alphabeta_from_uv(u,v,n1,n2,ωmin,ωmax)

mapping from (alpha,beta) to (u,v)

Fouvry & Prunet B5

This signature specifies ωmin and ωmax, to avoid extra calls.

"""
function alphabeta_from_uv(u::Float64,v::Float64,
                           n1::Int64,n2::Int64,
                           ωmin::Float64,ωmax::Float64)

    if n2 == 0
        beta  = v
        alpha = (1/(2n1))*((ωmax-ωmin)*u + ωmin + ωmax)
    else
        alpha = v
        beta  = (1/(n2*v))*(0.5*((ωmax-ωmin)*u + ωmin + ωmax) - n1*v)
    end

    return alpha,beta
end

"""uv_from_alphabeta(alpha,beta,n1,n2,dψdr,d²ψdr²[,rmax,Omega0])

mapping from  (u,v) to (alpha,beta)

@IMPROVE, this has rounding error: concern?

OrbitalElements.uv_from_alphabeta(0.5,0.7,-3,4,OrbitalElements.isochrone_dpsi_dr,OrbitalElements.isochrone_ddpsi_ddr)

"""
function uv_from_alphabeta(alpha::Float64,beta::Float64,
                           n1::Int64,n2::Int64,dψdr::Function,d²ψdr²::Function,rmax::Float64=1000.,Omega0=1.)

    ωmin,ωmax = find_wmin_wmax(n1,n2,dψdr,d²ψdr²,rmax,Omega0)

    wval = n1*alpha + n2*beta*alpha

    u = (2*wval - ωmax - ωmin)/(ωmax-ωmin)

    if (n2==0)
        v = beta
    else
        v = alpha
    end

    return u,v

end

"""uv_from_alphabeta(alpha,beta,n1,n2,ωmin,ωmax )

mapping from  (u,v) to (alpha,beta), from Fouvry & Prunet Appendix B

@IMPROVE, this has rounding error: concern?

OrbitalElements.uv_from_alphabeta(0.5,0.7,-3,4,OrbitalElements.isochrone_dpsi_dr,OrbitalElements.isochrone_ddpsi_ddr)

"""
function uv_from_alphabeta(alpha::Float64,beta::Float64,
                           n1::Int64,n2::Int64,
                           ωmin::Float64,ωmax::Float64)

    # Equation B1
    wval = n1*alpha + n2*beta*alpha

    # Equation B3
    u = (2*wval - ωmax - ωmin)/(ωmax-ωmin)

    # Equation B4
    if (n2==0)
        v = beta
    else
        v = alpha
    end

    return u,v

end

"""
using the definitions for (alpha, beta) and (u,v), compute the Jacobian.
@ATTENTION, to match eq. B6, this has the 2/(ωmax-ωmin) term already absorbed into it. therefore, not formally the Jacobian, but adds the dimensional removal.
"""
function Jacalphabeta_to_uv(n1::Int64,n2::Int64,w_min::Float64,w_max::Float64,v::Float64)

    if n2 ==0
        return (2.0/(w_max-w_min))*abs((w_max-w_min) * (1/(2n1)))
    else
        return (2.0/(w_max-w_min))*abs((w_max-w_min) * (1/(2n2*v)))
    end
end
