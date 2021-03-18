using JLD, Statistics, IterTools, DataFrames, JSON
# using CSV

include("metricsTools.jl")

function computemetric_onevar(
    metricfunc::Function,
    qoi::Array,
    obs::Union{Nothing,Array}=nothing;
    nparts::Integer=6,
    mapCR_list::Union{Nothing, Vector}=nothing,
    model_list::Union{Nothing, Vector}=nothing,
)

    # Partition columns of QOI array
    part = partition(axes(qoi, 2), nparts)

    # Iterate through trajectories for one QOI
    # NOTE: metricfunc can return anything (i.e. Dict, Array, etc)
    metrics = map(enumerate(part)) do (i, cols)
        # i, cols = enum

        current_qoi = qoi[:, [cols...]]

        if !isnothing(obs)
            current_obs = obs[:,i]
        else
            current_obs = nothing
        end

        result = metricfunc(current_qoi, current_obs)

        # if typeof(result) <: Dict
        #     result["mapCR"] = mapCR_list[i]
        #     result["model"] = model_list[i]
        # # TODO: What to do if not dictionary?
        # end

        return result
    end

    new_keys = collect(zip(mapCR_list, model_list))
    metrics_dict = Dict(new_keys .=> metrics)

    return metrics_dict

end


function compute_metrics(
    metricfunc::Function,
    trajDict::Dict,
    obsDict::Union{Nothing, Dict}=nothing;
    nparts::Int=6,
    mapCR_list::Union{Nothing, Vector}=nothing,
    model_list::Union{Nothing, Vector}=nothing
)

    # Iterate through quantities of interest
    metric_tuples = map(keys(trajDict), values(trajDict)) do key, qoi

        obs = isnothing(obsDict) ? nothing : obsDict[key * "Observed"]
        value = computemetric_onevar(metricfunc, qoi, obs, nparts=nparts,
                                     mapCR_list=mapCR_list, model_list=model_list)

        return key, value

    end

    metrics_dict = Dict(metric_tuples)

    return metrics_dict

end


mapCR = load("output/mapCRList.jld")
trajDict = load("output/qoi_96runs.jld")
obsDict = load("output/obs_qoi_96runs.jld")

mapCR_list = mapCR["mapCRList"]
model_list = vcat(repeat(["AWSoM"], 8), repeat(["AWSoMR"], 8))

mask(x) = x .> 0

timeshifts = collect(-72:72)
Tmins = collect(0.1:0.01:0.40)
Tmaxs = collect(0.60:0.01:0.9)
dims = 2
funcs = [mean, minimum, median, maximum, std]
sortBy=1

metricfunc(traj, obs) = MetricsTools.computeShiftedMaskedRMSE(
    traj, obs, mask, timeshifts, Tmins, Tmaxs, dims=dims, funcs=funcs,
    sortBy=sortBy)

metrics = compute_metrics(metricfunc, trajDict, obsDict,
                          mapCR_list=mapCR_list,
                          model_list=model_list)

metrics_json = json(metrics)

open("output/shifted_metrics_dict.json", "w") do f
    write(f, metrics_json)
end

save("output/shifted_metrics_dict.jld", metrics)
