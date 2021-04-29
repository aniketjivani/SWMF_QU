using JLD, PyPlot, IterTools, Missings, StatsPlots, DataFrame

include("metricsTools.jl")

mapCR = load("output/mapCRList.jld")["mapCRList"]
trajDict = load("output/qoi_96runs.jld")
obsDict = load("output/obs_qoi_96runs.jld")

function get_col_idx(X, map_cr, model, mapCRlist, nparts=6)

    part = collect(partition(axes(X, 2), nparts))
    mapCR_idx = findall(mapCRlist .== map_cr)

    if model == "AWSoM"
        col_idx = part[mapCR_idx[1]]
    elseif model == "AWSoMR"
        col_idx = part[mapCR_idx[2]]
    end

    return col_idx
end


a2208_awsom_traj_idx = get_col_idx(trajDict["B"], "ADAPT2208", "AWSoMR", mapCR)
a2208_awsom_obs_idx = findall(mapCR .== "ADAPT2208")[1]

B = trajDict["B"][:,[a2208_awsom_traj_idx...]]
B_obs = obsDict["BObserved"][:,a2208_awsom_obs_idx]

df = DataFrame(B)
@df df StatsPlots.plot(cols(1:6))

timeshifts = collect(-72:72)
# Tmins = [0.2]
# Tmaxs = [0.8]
Tmins = collect(0.1:0.01:0.20)
Tmaxs = collect(0.80:0.01:0.9)


function compute_best_shifted(traj, obs, timeshifts, Tmins, Tmaxs)

    res = MetricsTools.computeShiftedRMSE(traj, obs, timeshifts, Tmins, Tmaxs)

    traj_shifted, obs_shifted = MetricsTools.shift_trim_array(
        traj, obs, res["timeshift"], res["Tmin"], res["Tmax"])

    # traj = collect(Missings.replace(traj, 0))
    # obs = collect(Missings.replace(obs, 0))

    return traj_shifted, obs_shifted

end

plot(B_obs, color="black"); plot(B[:,2], color="red")

traj, obs = compute_best_shifted(B[:,2], B_obs, timeshifts, Tmins, Tmaxs)
plot(traj, color="black"); plot(obs, color="red")


shifted_traj = Dict()
shifted_obs = Dict()

# B_obs_trimmed = MetricsTools.trim_array(B[:,1], B_obs, Tmins[1], Tmaxs[1])[2]
plot(B_obs, color="black")

for i in 1:6
    traj, obs = compute_best_shifted(B[:,i], B_obs, timeshifts, Tmins, Tmaxs)
    plot(traj, label=i)
end

res = MetricsTools.computeShiftedRMSE(B[:,2], B_obs, timeshifts, Tmins, Tmaxs)

B_shifted, B_obs_shifted = MetricsTools.shift_trim_array(B, B_obs,
                                                         res["timeshift"],
                                                         res["Tmin"],
                                                         res["Tmax"])

B_shifted = collect(Missings.replace(B_shifted, 0))
B_obs_shifted = collect(Missings.replace(B_obs_shifted, 0))

plot(B_shifted[:,2])
plot(B_obs_shifted)


res = MetricsTools.computeShiftedRMSE(B[:,6], B_obs, timeshifts, Tmins, Tmaxs)

B_shifted, B_obs_shifted = MetricsTools.shift_trim_array(B, B_obs,
                                                         res["timeshift"],
                                                         res["Tmin"],
                                                         res["Tmax"])

B_shifted = collect(Missings.replace(B_shifted, 0))
B_obs_shifted = collect(Missings.replace(B_obs_shifted, 0))

plot(B_shifted[:,6])
plot(B_obs_shifted)
