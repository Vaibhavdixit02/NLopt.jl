include("tutorial.jl")
include("fix133.jl")
include("MPB_wrapper.jl")
include("MOI_wrapper.jl")

using NLopt
using Test

@testset "Fix #163" begin
    opt = Opt(:LN_COBYLA, 2)
    opt.min_objective = (x, g) -> sum(x.^2)
    inequality_constraint!(opt, 2, (result, x, g) -> (result .= 1 .- x))
    (minf, minx, ret) = optimize(opt, [2.0, 2.0])
    @test minx ≈ [1.0, 1.0]
end

@testset "Fix #132" begin
    opt = Opt(:LN_COBYLA, 2)
    err = ErrorException(
        "Getting `initial_step` is unsupported. Use " *
        "`initial_step(opt, x)` to access the initial step at a point `x`.",
    )
    @test_throws err opt.initial_step
end

@testset "Fix #156" begin
    @testset "Test that SavedException is thrown" begin
        f(x, g=[]) = (error("test error"); x[1]^2)
        opt = Opt(:LN_SBPLX, 1)
        opt.min_objective = f
        @test_throws NLopt.SavedException{ErrorException} optimize(opt, [0.1234])
        @test NLopt.nlopt_exception === nothing
        try
            optimize(opt, [0.1234])
        catch e
            # Check that the backtrace is being printed
            @test length(sprint(show, e)) > 100
        end
    end
    @testset "Test that ForcedStop does not rethrow" begin
        f(x, g=[]) = (throw(NLopt.ForcedStop()); x[1]^2)
        opt = Opt(:LN_SBPLX, 1)
        opt.min_objective = f
        fmin, xmin, ret = optimize(opt, [0.1234])
        @test ret == :FORCED_STOP
        @test NLopt.nlopt_exception === nothing
    end
    @testset "Test that no error works correctly" begin
        f(x, g=[]) = (x[1]^2)
        opt = Opt(:LN_SBPLX, 1)
        opt.min_objective = f
        fmin, xmin, ret = optimize(opt, [0.1234])
        @test ret ∈ (:SUCCESS, :FTOL_REACHED, :XTOL_REACHED)
        @test NLopt.nlopt_exception === nothing
    end
end
