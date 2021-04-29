# Load relevant packages
using Plots
gr()

using DataFrames
using CSV
using IterTools

using DelimitedFiles
using Printf
using Dates

mg = "ADAPT"
md = "AWSoM"
cr = 2208

# Load and parse event list for relevant params
# NOTE: Filepath is with reference to working directory set as MaxProAnalysis
ips, ipNames = readdlm("./data/X_design_MaxPro_ADAPT_AWSoM.txt", header=true)

ips = ips[1:200, 2:end]
ipNames = ipNames[1:end-1]

ipTable = DataFrame(ips, :auto)
rename!(ipTable, vec(ipNames))

ipTable."REALIZATIONS_ADAPT" .= floor.(ipTable."REALIZATIONS_ADAPT" * 11 .+ 1)
ipTable[!, "REALIZATIONS_ADAPT"] = convert.(Int, ipTable[!, "REALIZATIONS_ADAPT"])

# Load trajectory files
# skip the first line, pick off the headings from the second.
IHData, IHColumns = readdlm("./data/L1_Apr23/run001_AWSoM/run03/IH/trj_earth_n00005000.sat", header=true, skipstart=1)
m, n = size(IHData)

failedRuns = []

Ur = zeros(m, 200)
# Calculate Radial speed (Ur)
fUr(ux, uy, uz, x, y, z) = (ux*x + uy*y + uz*z)/sqrt(x^2 + y^2 + z^2) # one line function for convenience

# Store failed run IDs to a separate vector
for (runIdx, realization) in enumerate(ipTable[!, "REALIZATIONS_ADAPT"])
    opFileName = joinpath("./data/L1_Apr23/", "run" * @sprintf("%03d", runIdx) * "_AWSoM", "run" * @sprintf("%02d", realization), "IH/trj_earth_n00005000.sat")
    if isfile(opFileName)
        IHData_fileIdx, IHColumns_fileIdx = readdlm(opFileName, header=true, skipstart=1)

        # go through steps of calculating derived quantities
        IHDF = DataFrame(IHData_fileIdx, :auto)
        rename!(IHDF, vec(IHColumns_fileIdx))

        # push derived quantities into arrays, discard rest of dataframe 
        Ur[:, runIdx] = fUr.(IHDF[!, :ux], IHDF[!, :uy], IHDF[!, :uz], IHDF[!, :X], IHDF[!, :Y], IHDF[!, :Z])
    else
        push!(failedRuns, runIdx)
    end
end


# Plot the params coloured by success / failure of the runs

# ipTable = ipTable[:, Not([:PFSS, :REALIZATIONS_ADAPT, :UseSurfaceWaveRefl])]

successfulRunInputs = ipTable[Not(failedRuns), :]
failedRunInputs = ipTable[failedRuns, :]

for name_x in names(successfulRunInputs)
    for name_y in names(successfulRunInputs)
        if name_x !== name_y
            scatter(successfulRunInputs[!, name_x], 
                    successfulRunInputs[!, name_y],
                    label = "Successful Runs ")
            scatter!(failedRunInputs[!, name_x],
                     failedRunInputs[!, name_y], 
                     label = "Failed Runs")
            plot!(xlabel=name_x, ylabel=name_y)
            plot!(legend=true)    
            figTitle = name_x * "vs" * name_y * ".pdf"
            savefig(joinpath("./Outputs/ScatterPlots", figTitle))
        end
    end
end       




