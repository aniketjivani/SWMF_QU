using JLD, Statistics, IterTools, DataFrames, CSV

include("metricsTools.jl")

function computeMetric(
    func::Function,
    trajDict::Dict,
    file::String,
    mask::Union{Nothing, Function}=nothing,
    mapCR=nothing,
    obsDict::Union{Nothing, Dict}=nothing,
    nparts::Int=6,
)

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

            metrics[key][i] = round(func(currgroupQOI, currgroupObs, mask),
                                    digits=3)
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

relVar(x, obs=nothing) = sqrt(mean(var(x, corrected=false, dims=2))) / mean(x)
path = "output/relvar_96runs.csv"

if !isfile(path)
    computeMetric(
        relVar,
        trajDict,
        path,
        mapCR,
    )
end

RMSE(x, obs) = sqrt(mean((x .- obs).^2))
mask(x) = x .> 0
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
