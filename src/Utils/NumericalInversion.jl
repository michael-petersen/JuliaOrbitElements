"""
numerical inversion of (omega1,omega2) -> (a,e)
by brute-forcing the derivative increments domega1/da, domega1/de, deomega2/da, domega2/de

"""



"""ae_from_omega1omega2_brute(Ω₁,Ω₂,ψ,dψ/dr,d²ψ/dr²[,eps,maxiter])

basic Newton-Raphson algorithm to find (a,e) from (omega1,omega2) brute force derivatives.

@IMPROVE add escape for circular orbits
"""
function ae_from_omega1omega2_brute(omega1::Float64,omega2::Float64,
                                    potential::Function,
                                    dpotential::Function,
                                    ddpotential::Function,
                                    eps::Float64=1*10^(-10),
                                    maxiter::Int64=1000,
                                    TOLECC::Float64=0.001,TOLA::Float64=0.0001,
                                    da::Float64=0.0001,de::Float64=0.0001,
                                    verbose::Int64=0)
    #

    # get the circular orbit (maximum radius) for a given omega1,omega2. use the stronger constraint.
    acirc = Omega1circ_to_radius(omega1,dpotential,ddpotential)


    # check to make sure we aren't very close to circular (radial isn't a problem)
    f1circ,f2circ = compute_frequencies_ae(potential,dpotential,ddpotential,acirc,0.0)
    #if (((omega1 - f1circ)^2 + (omega2 - f2circ)^2) < eps^2)
    #    return acirc,0.0
    #end


    # then start from ecc=0.5 and take numerical derivatives
    aguess = acirc
    eguess = 0.5
    f1,f2 = compute_frequencies_ae(potential,dpotential,ddpotential,aguess,eguess)

    # 2d Newton Raphson inversion and find new increments
    iter = 0
    while (((omega1 - f1)^2 + (omega2 - f2)^2) > eps^2)

        f1,f2,df1da,df2da,df1de,df2de = compute_frequencies_ae_derivs(potential,dpotential,ddpotential,aguess,eguess,da,de,TOLECC,verbose)

        jacobian = [df1da df1de ; df2da df2de]

        # this increment reports occasional failures; why?
        try
            increment = jacobian \ (-([f1 ; f2] - [omega1 ; omega2]))
            aguess,eguess = aguess + increment[1],eguess + increment[2]
        catch e # this catch appears to not work because LAPACK is doing something under the hood
            if verbose>0
                println("OrbitalElements/NumericalInversion.jl: bad division for Jacobian=",jacobian," and (f1,f2)=",f1,f2," and (Ω₁,Ω₂)=",omega1,omega2)
            end
            # are we just in some tiny bad patch? # reset to 'safe' values
            aguess,eguess = aguess + 1.e-3,0.5
            increment = [0;0]
        end

        # the try...catch above is failing for some reason
        if (@isdefined increment) == false
            increment = [0;0]
        end




        # @WARNING: these appear to have broken something.
        # if bad guesses, needs to reset to a different part of space
        # can't go too small
        if eguess < TOLECC
            # go halfway between the previous guess and 0.
            try
                # reset eguess value
                eguess = eguess - increment[2]
                eguess = max(TOLECC,0.5eguess)
            catch e
                if verbose>0
                    println("OrbitalElements/NumericalInversion.jl: guessing close to ecc=0: ",eguess," (a=",aguess,")")
                end
                eguess = max(TOLECC,0.5eguess)
            end
        end

        if eguess >= (1-TOLECC)
            # go halfway between the previous guess and 1.
            try
                eguess = eguess - increment[2]
                eguess = min(1-TOLECC,eguess + 0.5*(1-eguess))
            catch e
                println("OrbitalElements/NumericalInversion.jl: guessing close to ecc=1: ",eguess," (a=",aguess,") for increment ",increment)
                eguess = min(1-TOLECC,eguess + 0.5*(1-eguess))
            end
        end

        if aguess < TOLA
            aguess = TOLA
            if verbose>1
                println("OrbitalElements/NumericalInversion.jl: guessing close to a=0: ",aguess," (e=",eguess,")")
            end
        end

        if (verbose>2)
            println("OrbitalElements/NumericalInversion.jl: iter=",iter," a=",aguess," e=",eguess)
        end

        iter += 1
        if iter > maxiter
            break
        end
    end

    if verbose > 0
        println("OrbitalElements/NumericalInversion.jl: niter=",iter)
    end

    finaltol = ((omega1 - f1)^2 + (omega2 - f2)^2)

    # check here to not allow bad values?
    if isnan(aguess) | isnan(eguess)
        if verbose>0
            println("OrbitalElements/NumericalInversion.jl: failed for inputs (Ω₁,Ω₂)=",omega1,omega2)
        end
        return acirc,0.5,-1,finaltol
    else
        return aguess,eguess,iter,finaltol
    end
end


"""jacobian_EL_alphabeta(α,β,ψ,dψ/dr,d²ψ/dr²[,eps,maxiter])

use the potential derivatives to compute the Jacobian. Needs to be finished!
"""
function jacobian_EL_alphabeta(alpha::Float64,beta::Float64,
                               potential::Function,
                               dpotential::Function,
                               ddpotential::Function,
                               eps::Float64=1*10^(-6),
                               maxiter::Int64=10000)

    return 1.

end


"""ae_from_EL_brute(E,L,ψ,dψ/dr,d²ψ/dr²[,eps,maxiter,TOLECC,verbose])
basic Newton-Raphson algorithm to find (a,e) from (E,L) brute force derivatives.
@IMPROVE add escape for circular orbits
"""
function ae_from_EL_brute(E::Float64,L::Float64,
                          potential::Function,
                          dpotential::Function,
                          ddpotential::Function,
                          eps::Float64=1*10^(-6),
                          maxiter::Int64=1000,
                          TOLECC::Float64=0.001,
                          verbose::Int64=0)
    #

    # get the circular orbit (maximum radius) for a given E. use the stronger constraint.
    #acirc = Omega1circ_to_radius(omega1,dpotential,ddpotential)
    # is this the best launching eccentricity?
    aguess,eccguess = 1.,TOLECC

    rpguess,raguess = rpra_from_ae(aguess,eccguess)

    if (verbose>0)
      println("iter=",-1," aguess=",aguess," eguess=",eccguess)
    end

    Eguess,Lguess,dEda,dEde,dLda,dLde = dEdL_from_rpra_pot(potential,dpotential,ddpotential,rpguess,raguess,da=0.0001,de=0.0001,TOLECC=TOLECC)



    # 2d Newton Raphson inversion and find new increments
    iter = 0
    while (((E - Eguess)^2 + (L - Lguess)^2) > eps^2)

        # convert to rp,ra for EL input
        rpguess,raguess = rpra_from_ae(aguess,eccguess)

        Eguess,Lguess,dEda,dEde,dLda,dLde = dEdL_from_rpra_pot(potential,dpotential,ddpotential,rpguess,raguess,da=0.0001,de=0.0001,TOLECC=TOLECC)

        jacobian = [dEda dEde ; dLda dLde]
        increment = jacobian \ (-([Eguess;Lguess] - [E ; L]))

        aguess,eccguess = aguess + increment[1],eccguess + increment[2]

        # if bad guesses, needs to reset to a different part of space
        # can't go too small
        if eccguess < TOLECC
            # go halfway between the previous guess and 0.
            eccguess = eccguess - increment[2]
            eccguess = 0.5*eccguess
        end

        if eccguess >= 1.0-0.000001
            # go halfway between the previous guess and 1.
            eccguess = eccguess - increment[2]
            eccguess = eccguess + 0.5*(1-eccguess)
        end

        if aguess < 0.00000001
            aguess = 0.00000001
        end

        if (verbose>0)
            println("iter=",iter," aguess=",aguess," eguess=",eccguess)
        end

        iter += 1
        if iter > maxiter
            break
        end
    end

    return aguess,eccguess
end
