using ArgParse
using DelimitedFiles, CSV, DataFrames, Statistics, AxisArrays
using ShiftedArrays

s = ArgParseSettings(
    description="This script is used to store and export shifted and trimmed QoIs.")
@add_arg_table! s begin
    "--inputs-outputs-path"
        help = "Path to inputs_outputs file."
        default = "./data/L1_runs_event_list_2021_04_16_09/MaxPro_inputs_outputs.txt"
    "--qois-path"
        help = "Path to QoIs directory."
        default = "./Outputs/QoIs/code_v_2021_05_17/event_list_2021_04_16_09/"
    "--output", "-o"
        help = "Path to save metrics to."
        default = "./Outputs/QoIs/code_v_2021_05_17/event_list_2021_04_16_09/metrics.csv"
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

inputs_outputs = CSV.read(INPUTS_OUTPUTS_PATH, DataFrame)[1:200,:]
metrics_table = CSV.read(RESULTS_PATH, DataFrame)

obs, sim = create_axisarray(1:720, QOIS, 1:size(inputs_outputs)[1])

outcomes = inputs_outputs.Outcomes
shift_vec = metrics_table.shift[outcomes .== 1]

for qoi in QOIS

    qoiArray = sim[qoi=qoi]
    qoiArray_successful = qoiArray[:, outcomes .== 1]
    qoi_trimmed = zeros(433, sum(outcomes .== 1))

    for i in 1:sum(outcomes .== 1)
        qoi_shifted = lag(qoiArray_successful[:, i], shift_vec[i])
        qoi_trimmed[:, i] = MetricsTools.trim_array(qoi_shifted, rmse_kwargs[:Tmin][1], rmse_kwargs[:Tmax][1]); 
    end

    open(joinpath(QOIS_PATH, qoi * args["sim-suffix"] * "_trimmed_shifted.txt"), "w") do io
        writedlm(io, qoi_trimmed)
    end

end


# similar loop for obs qois
for qoi in QOIS

    qoiArray = obs[qoi=qoi]
    qoi_trimmed = zeros(433) # 0.6 * 720 + 1

    qoi_trimmed = MetricsTools.trim_array(qoiArray, rmse_kwargs[:Tmin][1], rmse_kwargs[:Tmax][1])

    open(joinpath(QOIS_PATH, qoi * args["obs-suffix"] * "_trimmed_shifted.txt"), "w") do io
        writedlm(io, qoi_trimmed)
    end

end
    