# Obtain all QoIs from simulation / observation files for successful MaxPro runs!
# PWD should be MaxProAnalysis
include("./src/MaxProAnalysis.jl")

using Plots
gr()

using DataFrames
using CSV
using IterTools

using DelimitedFiles
using Printf
using Dates

using JLD

mg = "ADAPT"
md = "AWSoM"
cr = 2152

INPUTS_PATH ="./data/MaxPro_inputs_outputs_event_list_2021_06_02_21.txt"
OUTPUTS_PATH = "./data/L1_runs_event_list_2021_06_02_21"
QOIS_PATH = "./Outputs/QoIs/code_v_2021_05_17/event_list_2021_06_02_21"

ips, ipNames = readdlm(INPUTS_PATH, 
                        header=true, 
                        ','
                        );
ipTable = DataFrame(ips, :auto);
rename!(ipTable, vec(ipNames));



IHData, IHColumns = readdlm(joinpath(OUTPUTS_PATH, "run001_AWSoM/trj_earth_n00005000.sat"), 
                            header=true, 
                            skipstart=1
                            );
IHDF = DataFrame(IHData, :auto);
rename!(IHDF, vec(IHColumns));
m, n = size(IHData)


##### Observation files #####
obsFileDate = Dates.format(Dates.DateTime(IHDF[1, :year], IHDF[1, :mo], IHDF[1, :dy], IHDF[1, :hr], IHDF[1, :mn]) + Dates.Day(15), "yyyy_mm_ddTHH_MM_SS")
# There are only two observation files - corresponding to EARTH and STEREO-A
# (Since contact with STEREO-B was lost after 2014)

obsFilePrefix = Dict("EARTH" => "omni",
                     "STEREO-A" => "sta", 
                     "STEREO-B" => "stb"
                    )
        
UrObs = zeros(m, 2);
NpObs = zeros(m, 2);
TObs = zeros(m, 2);
BObs = zeros(m, 2);

for (trajIdx, obsTrajectory) in enumerate(["EARTH", "STEREO-A"])
    obsFileName = joinpath("./data", obsFilePrefix[obsTrajectory] * "_" * obsFileDate * ".out")
    qoiObject = MaxProAnalysis.getQoIFromFile(obsFileName, "obs")
    UrObs[:, trajIdx] = qoiObject.Ur
    NpObs[:, trajIdx] = qoiObject.Np
    TObs[:, trajIdx] = qoiObject.T
    BObs[:, trajIdx] = qoiObject.B
end

UrObs = UrObs[1:end - 1, :];
NpObs = NpObs[1:end - 1, :];
TObs  = TObs[1:end - 1, :];
BObs  = BObs[1:end - 1, :];

# # Write out all QoIs to .txt files
# UrfileName = joinpath(QOIS_PATH, "UrObs_earth_sta" * ".txt")
# NpfileName = joinpath(QOIS_PATH, "NpObs_earth_sta" *  ".txt")
# TfileName = joinpath(QOIS_PATH, "TObs_earth_sta" * ".txt")
# BfileName = joinpath(QOIS_PATH, "BObs_earth_sta"  * ".txt")

# open(UrfileName, "w") do io
#     writedlm(io, UrObs)
# end
# # close(UrfileName)
# open(NpfileName, "w") do io
#     writedlm(io, NpObs)
# end
# # close(NpfileName)
# open(TfileName, "w") do io
#     writedlm(io, TObs)
# end
# # close(TfileName)
# open(BfileName, "w") do io
#     writedlm(io, BObs)
# end
# # close(BfileName)
# println("Observation files processed and written.")

##### Simulation files #####
tmPeriods = Dates.DateTime.(IHDF[!, :year], IHDF[!, :mo], IHDF[!, :dy], IHDF[!, :hr], IHDF[!, :mn], IHDF[!, :sc])
save("./Outputs/QoIs/tmPeriods_earth_cr2152.jld", "tmPeriods", tmPeriods)

dataTrajectory = "EARTH"
# dataTrajectory = "STEREO-A"
# dataTrajectory = "STEREO-B"


simFilePrefix = Dict("EARTH" => "trj_earth", 
                     "STEREO-A" => "trj_sta", 
                     "STEREO-B" => "trj_stb"
                    )


Ur = zeros(m, 200);
Np = zeros(m, 200);
T  = zeros(m, 200);
B  = zeros(m, 200);
for (runIdx, realization) in enumerate(ipTable[!, "REALIZATIONS_ADAPT"])


    opFileName = joinpath(OUTPUTS_PATH, 
                        "run" * @sprintf("%03d", runIdx) * "_AWSoM", 
                        simFilePrefix[dataTrajectory] * "_n00005000.sat")

    if isfile(opFileName)
        qoiObject = MaxProAnalysis.getQoIFromFile(opFileName, "sim")
        # push derived quantities into arrays
        Ur[:, runIdx] = qoiObject.Ur
        Np[:, runIdx] = qoiObject.Np
        T[:, runIdx] = qoiObject.T
        B[:, runIdx] = qoiObject.B    
    end   
end

# Remove last row (720 rows to match observed data)
Ur = Ur[1:end - 1, :];
Np = Np[1:end - 1, :];
T  = T[1:end - 1, :];
B  = B[1:end - 1, :];

# # Write out all QoIs to .txt files
UrfileName = joinpath(QOIS_PATH, "Ur" * "Sim_earth" * ".txt")
NpfileName = joinpath(QOIS_PATH, "Np" * "Sim_earth" * ".txt")
TfileName = joinpath(QOIS_PATH, "T" * "Sim_earth" * ".txt")
BfileName = joinpath(QOIS_PATH, "B" * "Sim_earth" * ".txt")

println("Simulation files processed.")


