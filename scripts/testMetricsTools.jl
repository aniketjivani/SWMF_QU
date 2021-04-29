include("metricsTools.jl")
using Test, Missings


levelsEqual(x, y) = levels(x) == levels(y)

x = collect(1:10)
y = collect(5:14)

X = repeat(x, 1, 5)

@testset "maskArray tests" begin
    maskArr = BitArray([1,1,1,0,0,0,0,1,0,0])
    maskFunc(y) = y .> 5

    @test levelsEqual(MetricsTools.maskArray(x, maskArr),
                      [1,2,3,8])
    @test levelsEqual(MetricsTools.maskArray(x, maskFunc),
                      collect(6:10))
end;

@testset "computeMaskedMetric tests" begin
    mask(z) = z .< 10
    metric(x, y) = sum(x .+ y)

    test1 = MetricsTools.computeMaskedMetric(x, y, mask, metric)
    @test test1 == metric([1,2,3,4,5],[5,6,7,8,9])

end;

timeshift = 2
Tmin = .2
Tmax = .8

@testset "shiftArray tests" begin

    @testset "Both Vectors" begin

        xShifted, yShifted = MetricsTools.shiftArray(
        x,y, timeshift, Tmin, Tmax)

        @test isequal(xShifted, [1,2,3,4,5,6,7])
        @test isequal(yShifted, [7,8,9,10,11,12,13])

        xShifted, yShifted = MetricsTools.shiftArray(
            x, y, 0, 0.0, 1.0)
        @test isequal(xShifted, x)
        @test isequal(yShifted, y)

    end

    @testset "Array x, Vector y" begin
        xShifted, yShifted = MetricsTools.shiftArray(
            X, y, timeshift, Tmin, Tmax
        )


    end


end

@testset "shiftedRMSE tests" begin

    test1 = MetricsTools.shiftedRMSE(x, y, timeshift, Tmin, Tmax)
    @test test1 == 6

    test2 = MetricsTools.shiftedRMSE(X, y, timeshift, Tmin, Tmax, dims=2)
    @test test2 == repeat([6.0], 5)

end

@testset "computeShiftedMaskedRMSE tests" begin

    mask(z) = z .< 10

    test1 = MetricsTools.computeShiftedMaskedRMSE(
        x, y, mask, [timeshift], [Tmin], [Tmax],
        RMSEonly=true, verbose=false
    )

    @test test1 == 6


    timeshifts = [1,2,3]
    Tmins = [.15,.2,.25]
    Tmaxs = [.75,.8,.85]

    test2 = MetricsTools.computeShiftedMaskedRMSE(
        X, y, mask, timeshifts, Tmins, Tmaxs,
        dims=2, RMSEonly=true, funcs=[mean, minimum])

    @test test2 == 5.0

end
