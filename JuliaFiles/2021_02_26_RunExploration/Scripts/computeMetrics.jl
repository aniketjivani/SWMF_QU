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
    # TODO: Take functions (i.e. min) over axes

    ## Get mapCR and model list
    mapCRs = AxisArrays.axes(traj)[3]
    models = AxisArrays.axes(traj)[4]

    ## Initialize AxisArray to store metric values
    metrics_size = size(traj)[2:end]
    # Axes are the same as traj except for the first (time) axis
    metrics_axes = AxisArrays.axes(traj)[2:end]
    metrics = AxisArray(missings(Float64, metrics_size),
                        metrics_axes)

    # Get dict with axes, values as key, pairs
    ax = MetricsTools.axesdict(traj)

    ## Iterate over mapCR, model, and run
    for mapCR = ax[:mapCR], model = ax[:model], run = ax[:run]

        if verbose
            println("mapCR=$mapCR, model=$model, run=$run")
        end

        idx = (Axis{:mapCR}(mapCR), Axis{:model}(model), Axis{:run}(run))
        # metrics[idx...] is the same as metrics[mapCR=mapCR,model=model,run=run]

        # Some runs have all 0s

        if !all(traj[idx...] .== 0)

            metrics[idx...] = metricfunc(traj[idx...], obs[mapCR=mapCR, model=model];
                                         kwargs...)
        else
            if verbose
                println("traj is all 0.")
            end
        end

    end

    # TODO: Apply functions over dim. (i.e. take min over runs)
    # TODO: Figure out how to restructure result and present it.

    return metrics
end


# Load data
traj_array = load("output/qoi_arrays.jld", "traj");
obs_array = load("output/qoi_arrays.jld", "obs");
# mapCR_list = load("output/mapCRList.jld", "mapCRList")
# model_list = vcat(repeat(["AWSoM"], 8), repeat(["AWSoMR"], 8))

# Remove negative values
mask(x) = x .> 0

timeshifts = collect(-72:72)
Tmins = collect(0.1:0.01:0.40)
Tmaxs = collect(0.60:0.01:0.9)
dims = 2

metrics = compute_metrics(metricfunc, traj_array, obs_array,
                          mapCR_list=mapCR_list,
                          model_list=model_list)


save("output/shifted_metrics_array.jld", "metrics", metrics)


# TODO: Figure out how to save AxisArray in a presentable way

# metrics_json = json(metrics)

# open("output/shifted_metrics_dict.json", "w") do f
#     write(f, metrics_json)
# end

# save("output/shifted_metrics_dict.jld", metrics)
