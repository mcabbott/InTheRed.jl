using InTheRed, Test

@testset "Float64" begin
    @test repr(1.0, context=stdout) == "1.0"
    @test contains(repr(0.0, context=stdout), "90m0.0")
    @test contains(repr(-1.0, context=stdout), "31m-1.0")
    @test contains(repr(NaN, context=stdout), "33mNaN")
    @test contains(repr(Inf, context=stdout), "33mInf")

    @test contains(repr("text/plain", [0.0], context=stdout), "90m0.0")
    @test contains(repr("text/plain", [1 0.0; -1 -2]', context=stdout), "90m0.0")
end

@testset "Float32" begin
    @test contains(repr(1.0f0, context=stdout), "36m1.0f0")
    @test contains(repr(0.0f0, context=stdout), "90m0.0f0")
    @test contains(repr(-1.0f0, context=stdout), "35m-1.0f0")
    @test contains(repr(NaN32, context=stdout), "33mNaN32")

    @test contains(repr("text/plain", Float32[0.0], context=stdout), "36mFloat32")
    @test contains(repr("text/plain", Float32[1 0; -1 -2]', context=stdout), "90m0.0")
end

@testset "vectors" begin
    @test contains(repr("text/plain", ones(3)), "|+++++++")
    @test contains(repr("text/plain", -ones(3)), "-------|")
    @test contains(repr("text/plain", [1,0,-1]), "       |\n")
    @test contains(repr("text/plain", [1,missing,-1,Inf]), "|+++++++")

    @test contains(repr("text/plain", ones(3), context=stdout), "90m")  # light grey
    @test contains(repr("text/plain", [1,missing,-1], context=stdout), "33m")  # yellow
end