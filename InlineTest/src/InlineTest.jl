module InlineTest

@static if isdefined(Base, :Experimental) &&
             isdefined(Base.Experimental, Symbol("@optlevel"))
    Base.Experimental.@optlevel 0
end

export @testset

# from Test:
export Test,
    @test, @test_throws, @test_broken, @test_skip,
    @test_warn, @test_nowarn,
    @test_logs, @test_deprecated,
    @inferred,
    detect_ambiguities, detect_unbound_args

using Test: Test,
    @test, @test_throws, @test_broken, @test_skip,
    @test_warn, @test_nowarn,
    @test_logs, @test_deprecated,
    @inferred,
    detect_ambiguities, detect_unbound_args


const INLINE_TEST = Ref{Symbol}(:__INLINE_TEST__)
const TESTED_MODULES = Union{Module,Nothing}[]

__init__() = INLINE_TEST[] = gensym()


function get_tests(m::Module)
    inline_test::Symbol = INLINE_TEST[]
    if !isdefined(m, inline_test)
        @eval m $inline_test = (tests=[], news=[], map=Dict{Union{String,Expr},Int}())
        push!(TESTED_MODULES, m)
    end
    getfield(m, inline_test)
end

function retest end

"""
    @testset args...

Similar to `Test.@testset args...`, but the contained tests are not run
immediately, and are instead stored for later execution, triggered by
`runtests()`.
Invocations of `@testset` can be nested, but qualified invocations of
`ReTest.@testset` can't.
Internally, `@testset` expressions are converted to an equivalent of
`Test.@testset` at execution time.
"""
macro testset(args...)
    if !isdefined(__module__, :runtests)
        @eval __module__ function runtests(specs...; kwargs...)
            $retest($__module__, specs...; kwargs...)
        end
    end
    # this must take effect at compile/run time rather than parse time, e.g.
    # if the @testset if in a `if false` branch
    # TODO: test that
    quote
        push!(get_tests($__module__).news, (ts=$args, source=$(QuoteNode(__source__))))
        nothing
    end
end

end # InlineTest
