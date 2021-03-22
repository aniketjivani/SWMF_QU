using JLD, Statistics, IterTools, DataFrames, JSON, AxisArrays, CSV
# using CSV

include("metricsTools.jl")


function compute_metrics(metricfunc::Function,
                         traj::AxisArray,
                         obs::AxisArray;
                         verbose=false,
                         kwargs...)
    # Computes an array where each element is the metric value for
    # a specific mapCR, model, and run

    # NOTE: I use AxisArrays here because they are easy to manipulate and index.

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


function min_metrics_table(metrics; dims=:run)

    # Get minimum rmse array
    ax_dims = axisdim(metrics, Axis{dims})
    min_metrics = minimum(metrics, dims=ax_dims) |>
        (z -> dropdims(z, dims=ax_dims))

    # Get indices in the correct format
    axes_tuple = map((x -> x.val), min_metrics.axes)
    indices_names = (collect ∘ zip)(axisnames.(min_metrics.axes)...)[1]

    # Create dataframe
    df = (collect ∘ product)(axes_tuple...)[:] .|>
        NamedTuple{indices_names} |>
        DataFrame
    df[:value] = min_metrics[:]

    return df
end

function min_params_table(metrics, params; dims=:run)

    ax_dim = axisdim(metrics, Axis{dims})
    qoi_dim = axisdim(metrics, Axis{:qoi})
    dims_ = (ax_dim, qoi_dim)

    min_idx = argmin(metrics.data, dims=dims_) |>
        (z -> dropdims(z, dims=dims_))

    # Drop last index in CartesianIndex
    min_idx_params = [CartesianIndex(idx.I[1:end-1]) for idx in min_idx[:]]

    min_params_axes = params.axes[2:end]
    axes_tuple = map((x -> x.val), min_params_axes)
    idx_names = (collect ∘ zip)(axisnames.(min_params_axes)...)[1]

    idx_df = (collect ∘ product)(axes_tuple...)[:] .|>
        NamedTuple{idx_names} |>
        DataFrame

    param_df = DataFrame(params[min_idx_params][:])

    return hcat(idx_df, param_df)
end

function save_results(traj_array, obs_array;
                      metric=MetricsTools.rmse,
                      mask=(x -> x .>= 0),
                      timeshifts=collect(-72:72),
                      Tmins=[0.2],
                      Tmaxs=[0.8],
                      save_path="output/metrics_table.csv",
                      verbose=false,
                      kwargs...)

    println("Computing metrics...")
    metrics, params = compute_metrics(
        metric, traj_array, obs_array; shift=timeshifts, Tmin=Tmins, Tmax=Tmaxs,
        mask=mask, verbose=verbose)

    println("Converting to tables...")
    min_metrics_df = min_metrics_table(metrics, dims=:run)
    params_df = min_params_table(metrics, params, dims=:run)

    # Join dataframes on mapCR, model
    println("Joining tables...")
    df = innerjoin(min_metrics_df, params_df, on = [:mapCR, :model])

    println("Saving joined table...")
    CSV.write(save_path, df)
end


# Load data
traj_array = load("output/qoi_arrays.jld", "traj");
obs_array = load("output/qoi_arrays.jld", "obs");

metric = MetricTools.rmse
save_path = "output/metrics_tables.csv"

# Remove negative values
mask(x) = x .>= 0

# Parameters to optimize over
timeshifts = collect(-72:72)
Tmins = [.2]
Tmaxs = [.8]

save_results(traj_array, obs_array, metric=metric, mask=mask,
             timeshifts=timeshifts, Tmins=Tmins, Tmaxs=Tmaxs,
             save_path=save_path)
