using ArgParse, DelimitedFiles, CSV, DataFrames, Statistics, AxisArrays

s = ArgParseSettings(
    description="This script is used to compute time-shifted metrics between simulated and observed trajectories for SWQU.")
@add_arg_table! s begin
    "--inputs-outputs-path"
        help = "Path to inputs_outputs file."
        default = "./data/MaxPro_inputs_outputs.txt"
    "--qois-path"
        help = "Path to QoIs directory."
        default = "./Outputs/QoIs/"
    "--output", "-o"
        help = "Path to save metrics to."
        default = "./Outputs/QoIs/metrics.csv"
    "--qois", "-q"
        help = "List of QOIs. Timeshift in RMSE is obtained with respect to the first variable in this list."
        nargs = '*'
        action = :store_arg
        default=["Ur", "Np", "B", "T"]
    "--obs-suffix"
        help = "Filename suffix for observations." 
        default = "Obs_earth_sta"
    "--sim-suffix"
        help = "Filename suffix for simulations."
        default = "Sim_earth"
    "--ext"
        help = "File extension for observations/simulations."
        default = ".txt"
end

args = parse_args(s)

include("../../scripts/metricsTools.jl")

INPUTS_OUTPUTS_PATH = args["inputs-outputs-path"]
QOIS_PATH = args["qois-path"]
RESULTS_PATH = args["output"]

# timeshift in rmse is obtained with respect to first variable in this list
QOIS = args["qois"]
SUFFIXES = Dict(:obs=>args["obs-suffix"],
                :sim=>args["sim-suffix"])
EXT = args["ext"]

# Parameters for computing timeshifted RMSE
timeshifts = collect(-48:48);
mask(x) = x .>= 0
penalty_kwargs = Dict(
    :dims=>1,
    :max_shift=>maximum(abs.(timeshifts)),
    :var_measure=>var,
)
rmse_kwargs = Dict(
    :shift=>timeshifts,
    :Tmin=>[.2],
    :Tmax=>[.8],
    :mask=>mask,
    :dims=>2,
    :penaltyfunc=>MetricsTools.timeshift_penalty,
    :penalty_kwargs=>penalty_kwargs,
    :penalize_x=>true
)


# rmse function takes AxisArrays so we first create an AxisArray
function create_axisarray(times, qois, params)

    n_times = length(times)
    n_qois = length(qois)
    n_params = length(params)
    obs = AxisArray(zeros(n_times, n_qois), t=times, qoi=qois)
    sim = AxisArray(zeros(n_times, n_params, n_qois), t=times, param=params, qoi=qois)
    
    for qoi in QOIS
        obs[qoi=qoi] = readdlm(QOIS_PATH*qoi*SUFFIXES[:obs]*EXT)[:,1]
        sim[qoi=qoi] = readdlm(QOIS_PATH*qoi*SUFFIXES[:sim]*EXT)
    end

    return obs, sim
end


function get_metrics_table(sim, obs, qois, params, shift_params=["timeshift", "Tmin", "Tmax"])
    
    # Initialize columns to store metrics, and shift parameters with 0
    # insertcols!(df, Dict(qois.=>0)...) 
    
    n_shift_params = length(shift_params)
    n_params = length(params)
    n_qois = length(qois)

    # col_names = ["rmse_".*qois; shift_params]
    # df = DataFrame(zeros(n_params, n_qois+n_shift_params), col_names)

    df = DataFrame([])
    for param in params
        rmse, shift_params = MetricsTools.rmse(sim[param=param], obs; rmse_kwargs...)
        rmse_tup = (; zip(Symbol.("rmse_".*qois), rmse)...)
        row = merge(rmse_tup, shift_params)
        push!(df, row)
    end

    return df
end

# inputs_outputs = CSV.read(INPUTS_OUTPUTS_PATH, DataFrame)[1:200,:]

inputs_outputs = CSV.read(INPUTS_OUTPUTS_PATH, DataFrame)[1:100, :]
obs, sim = create_axisarray(1:720, QOIS, 1:size(inputs_outputs)[1])
# metrics_df = get_metrics_table(sim, obs, QOIS, 1:200) # Used for 200 runs in MaxPro

metrics_df = get_metrics_table(sim, obs, QOIS, 1:100)
results_df = hcat(inputs_outputs, metrics_df)
CSV.write(RESULTS_PATH, results_df)
