using JLD, Statistics, IterTools, DataFrames, JSON, AxisArrays
# using CSV

include("metricsTools.jl")


function compute_metrics(metricfunc::Function,
                         traj::AxisArray,
                         obs::AxisArray;
                         verbose=false,
                         kwargs...)
    # Computes an array where each element is the metric value for
    # a specific mapCR, model, and run

    ## Get mapCR and model list
    mapCRs = AxisArrays.axes(traj)[3]
    models = AxisArrays.axes(traj)[4]

    ## Initialize AxisArray to store metric values
    metrics_size = size(traj)[2:end]
    # Axes are the same as traj except for the first (time) axis
    metrics_axes = AxisArrays.axes(traj)[2:end]
    metrics = AxisArray(fill(Inf, metrics_size), metrics_axes)
    # metrics = AxisArray(missings(Float64, metrics_size),
    #                     metrics_axes)

    # Initalize AxisArray to store param values
    params = AxisArray(missings(NamedTuple, metrics_size[1:end-1]),
                       metrics_axes[1:end-1])

    # Get dict with axes, values as key, pairs
    ax = MetricsTools.axesdict(traj)

    ## Iterate over mapCR, model, and run
    for mapCR = ax[:mapCR], model = ax[:model], run = ax[:run]

        if verbose
            println("mapCR=$mapCR, model=$model, run=$run")
        end

        idx = (Axis{:mapCR}(mapCR), Axis{:model}(model), Axis{:run}(run))
        # metrics[idx...] is the same as metrics[mapCR=mapCR,model=model,run=run]

        # Some runs have all 0s.
        # Keep metrics, params of runs with all 0s missing.
        if !all(traj[idx...] .== 0)

            # metricfunc should return an array containing a value for each QOI
            # Save metric and params for current iter.
            metrics[idx...], params[idx...] = metricfunc(
                traj[idx...],
                obs[mapCR=mapCR, model=model];
                kwargs...)
        else
            if verbose
                println("traj is all 0.")
            end
        end

    end

    return metrics, params
end

function min_metrics(metrics, params, dims=:run)
    ax_dims = axisdim(metrics, Axis{dims})
    min_metrics = minimum(metrics, dims=ax_dims)

    return dropdims(min_metrics, dims=ax_dim)
end

function min_params(metrics, params, dims=:run)

    ax_dim = axisdim(metrics, Axis{dims})
    qoi_dim = axisdim(metrics, Axis{:qoi})
    dims_ = (ax_dim, qoi_dim)

    min_idx = argmin(metrics.data, dims=dims_) |> (z -> dropdims(z, dims=dims_))

    # Drop last index in CartesianIndex
    min_idx_params = [CartesianIndex(idx.I[1:end-1]) for idx in min_idx[:]]

    min_params = AxisArray(reshape(params[min_idx_params], size(min_idx)),
                            AxisArrays.axes(params)[2:end])

    # TODO: Make the result a dataframe instead.

    return min_params
end


# Load data
traj_array = load("output/qoi_arrays.jld", "traj");
obs_array = load("output/qoi_arrays.jld", "obs");

# mapCR_list = load("output/mapCRList.jld", "mapCRList")
# model_list = vcat(repeat(["AWSoM"], 8), repeat(["AWSoMR"], 8))
# # Don't need to load these anymore because they are in the axes

# Remove negative values
mask(x) = x .>= 0

# Parameters to optimize over
timeshifts = collect(-72:72)
Tmins = collect(0.1:0.01:0.40)
Tmaxs = collect(0.60:0.01:0.9)
dims = 2

metrics, params = compute_metrics(metricfunc, traj_array, obs_array,)


save("output/shifted_metrics_array.jld", "metrics", metrics)


# TODO: Figure out how to save AxisArray in a presentable way

# metrics_json = json(metrics)

# open("output/shifted_metrics_dict.json", "w") do f
#     write(f, metrics_json)
# end

# save("output/shifted_metrics_dict.jld", metrics)
