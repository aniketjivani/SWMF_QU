using JLD, Statistics, IterTools, DataFrames, JSON, AxisArrays, CSV, StatsBase


include("metricsTools.jl")


@doc raw"""
    compute_metrics(metricfunc::Function,
                         traj::AxisArray,
                         obs::AxisArray[,
                         verbose=false,
                         kwargs...])

Main function for computing metrics on trajectories and observations.

# Arguments
- `metricfunc::Function`: function that takes 2 arrays and computes a metric
- `traj::AxisArray`: Multi-dimensional array containing simulation trajectories
- `obs::AxisArray`: Multi-dimensional array containing observed trajectories
- `verbose::Bool`: Print status statements
- `kwargs...`: Keyword arguments to pass into metricfunc

"""
function compute_metrics(metricfunc::Function,
                         traj::AxisArray,
                         obs::AxisArray;
                         verbose=false,
                         kwargs...)
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

function make_table(array)

    axes_tuple = map((x -> x.val), array.axes)
    indices_names = (collect ∘ zip)(axisnames.(array.axes)...)[1]

    df = (collect ∘ product)(axes_tuple...)[:] .|>
        NamedTuple{indices_names} |>
        DataFrame

    df[:value] = array[:]

    return df
end

function make_params_table(params)

    df = make_table(params) |> dropmissing |>
        (df -> hcat(df, DataFrame(df[:value])))
    select!(df, Not(:value))
    return df

end


@doc raw"""
    min_metrics_table(metrics[; dims=:run])

Make table of the minimum metrics over dims from a metrics array.

# Arguments
- `metrics`: Array from compute_metrics.
- `dims=:run`: Dimension to compute minimum over

"""
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

@doc raw"""
    min_params_table(metrics, params[; dims=:run])

Make table of the parameters that minimize metrics over dims.

# Arguments
- `metrics`: Array from compute_metrics.
- `params`: Params array from compute_metrics.
- `dims=:run`: Dimension to compute minimum over

"""
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

@doc raw"""
    save_results(traj_array, obs_array[;
                      metric=MetricsTools.rmse,
                      mask=(x -> x .>= 0),
                      timeshifts=collect(-72:72),
                      Tmins=[0.2], Tmaxs=[0.8],
                      save_path="output/metrics_table.csv",
                      verbose=false,
                      kwargs...])

Save results.

By default, this saves a table to save_path with the columns
qoi, model, mapCR, value, shift, Tmin, Tmax.

# Arguments
- `traj_array`: Array containing simulation trajectories
- `obs_array`: Array containing observed trajectories
- `metric=MetricsTools.rmse`: Function that computes metric between 2 arrays
- `mask`: Function to compute mask. By default, this is a function that subsets
          the non-negative values. This is used to filter out the really large
          negative values in some of the observed trajectories.
- `timeshifts=collect(-72:72)`: Array of timeshifts to minimize metric over.
- `Tmins=[0.2]`: Array of Tmins to minimize metric over.
                 e.g. 0.2 means we trim the first 20% time points
- `Tmaxs=[0.8]`: Array of Tmaxs to minimize metric over.
- `save_path="output/metrics_table.csv"`: Path to save results table to
- `verbose=false`: Print status statements
- `kwargs...`: Keyword arguments for metric

```
"""
function save_results(traj_array, obs_array;
                      metric=MetricsTools.rmse,
                      mask=(x -> x .>= 0),
                      timeshifts=collect(-72:72),
                      Tmins=[0.2], Tmaxs=[0.8],
                      save_path="output/metrics_table.csv",
                      verbose=false,
                      kwargs...)

    println("Computing metrics...")
    metrics, params = compute_metrics(
        metric, traj_array, obs_array, verbose=verbose;
        shift=timeshifts, Tmin=Tmins, Tmax=Tmaxs,
        mask=mask, kwargs...)

    println("Converting to tables...")
    metrics_df = make_table(metrics)
    rename!(metrics_df, :value=>"metric")
    params_df = make_params_table(params)

    # min_metrics_df = min_metrics_table(metrics, dims=:run)
    # params_df = min_params_table(metrics, params, dims=:run)

    # Join dataframes on mapCR, model
    println("Joining tables...")
    df = join(metrics_df, params_df, on = [:mapCR, :model, :run],
              kind = :inner)
    select!(df, [:qoi, :mapCR, :model, :run, :metric, :shift, :Tmin, :Tmax])

    println("Saving joined table...")
    CSV.write(save_path, df)
end


# Load data
traj_array = load("output/qoi_arrays.jld", "traj");
obs_array = load("output/qoi_arrays.jld", "obs");

metric = MetricsTools.rmse
penalty = MetricsTools.timeshift_penalty
# save_path = "output/metrics_tables.csv"

# Remove negative values
mask(x) = x .>= 0

# Parameters to optimize over
timeshifts = collect(-48:48)
Tmins = [.2]
Tmaxs = [.8]
penalty_kwargs = Dict{Symbol, Any}(
    :dims=>1,
    :max_shift=>maximum(abs.(timeshifts)),
    # :var_measure=>mad_array,
    # :lambda=>0.2,
)

MADsq(x; dims=1, kwargs...) = mad.(eachslice(transpose(x), dims=dims); kwargs...).^2
IQRsq(x; dims=1, kwargs...) = iqr.(eachslice(transpose(x), dims=dims); kwargs...).^2

var_measures = [MetricsTools.mean_max_distance, var, MADsq, IQRsq]
for measure in var_measures
    measure_name = String(Symbol(measure))
    println("Computing metrics with penalty " * measure_name * "...")
    penalty_kwargs[:var_measure] = measure
    save_path = "output/metrics_tables_" * measure_name * ".csv"

    if !isfile(save_path)
        save_results(traj_array, obs_array, metric=metric, mask=mask, timeshifts=timeshifts,
                     Tmins=Tmins, Tmaxs=Tmaxs, save_path=save_path, normalize=false,
                     penaltyfunc=penalty, penalize_x=true, penalty_kwargs=penalty_kwargs)
    else
        println(save_path * " already exists.")
    end
end


