using JLD, Statistics, IterTools, DataFrames, CSV

include("metricsTools.jl")

function computeMetric(
    func::T,
    trajDict::Dict,
    file::String,
    mask::Union{Nothing, Function}=nothing,
    mapCR=nothing,
    obsDict::Union{Nothing, Dict}=nothing,
    nparts::Int=6,
    kwargs...
) where {T<:Function}

    metrics = Dict()

    for key = keys(trajDict)

        obsKey = key * "Observed"
        qoi = trajDict[key]

        if !isnothing(obsDict)
            obs = obsDict[obsKey]
        else
            obs = nothing
        end

        metrics[key] = zeros(Int(size(qoi)[2] / nparts))
        part = partition(axes(qoi, 2), nparts)

        for (i, cols) in enumerate(part)
            currgroupQOI = qoi[:, [cols...]]

            if !isnothing(obs)
                currgroupObs = obs[:,i]
            else
                currgroupObs = nothing
            end

            # TODO: Find better way to do this
            if (T <: typeof(MetricsTools.computeShiftedMaskedRMSE)
                || T <: typeof(computeShiftedMaskedRMSE))

                resDict = func(currgroupQOI, currgroupObs, mask, kwargs...)
                metrics[key][i] = round(resDict["RMSE"], digits=3)
            else
                metrics[key][i] = round(
                    func(currgroupQOI, currgroupObs, mask, kwargs...),
                    digits=3)
            end
        end
    end

    metrics_df = DataFrame(metrics)

    if !isnothing(mapCR)
        insert!(metrics_df, 1, mapCR, :mapCR)
        # metrics_df["mapCR"] = mapCR
    end

    # CSV.write(file, metrics_df[!, [:mapCR, :B, :Np, :T, :Ur]])
    CSV.write(file, metrics_df)

    # save(file, metrics)
    # return metrics
end

mapCRList = load("output/mapCRList.jld")
trajDict = load("output/qoi_96runs.jld")
obsDict = load("output/obs_qoi_96runs.jld")

mapCR = mapCRList["mapCRList"]

mask(x) = x .> 0

# relVar(x, obs=nothing) = sqrt(mean(var(x, corrected=false, dims=2))) / mean(x)
# path = "output/relvar_96runs.csv"

# if !isfile(path)
#     computeMetric(
#         relVar,
#         trajDict,
#         path,
#         mask,
#         mapCR,
#     )
# end

path = "output/rmse_96runs.csv"

if !isfile(path)
    computeMetric(
        MetricsTools.computeMaskedRMSE,
        trajDict,
        path,
        mask,
        mapCR,
        obsDict
    )
end

path = "output/shifted_rmse_96runs.csv"

timeshifts = collect(1:48)
Tmins = collect(0.1:0.025:0.25)
Tmaxs = collect(0.70:0.025:0.85)

function computeShiftedMaskedRMSE(x, y, mask)
    MetricsTools.computeShiftedMaskedRMSE(
    x, y, timeshifts, mask, Tmins, Tmaxs, verbose=true)
end
if !isfile(path)
    computeMetric(
        computeShiftedMaskedRMSE,
        # MetricsTools.computeShiftedMaskedRMSE,
        trajDict,
        path,
        mask,
        mapCR,
        obsDict)
end
