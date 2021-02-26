# Run copyTrjFiles before running this. 

using DelimitedFiles
using DataFrames
using Printf
using IterTools
using Dates

using PyCall
using PyPlot
@pyimport matplotlib.pyplot as pyplt

include("TrajectoriesTools.jl")

# Constants
ProtonMass = 1.67e-24
k = 1.3807e-23

# specify groups of magnetogram (or map), cr, md - map not used as variable so as to avoid confusion with "map" function. 
mg = ["GONG", "ADAPT"]
cr = [2208, 2209, 2152, 2154]
md = ["AWSoM", "AWSoMR"]

# Calculate number of groups and 
numberOfGroups = length(product(mg, cr, md))
dataTrajectory = "EARTH"
# dataTrajectory = "STEREO-A"
if dataTrajectory == "EARTH"
    obsFilePrefix = "omni"
elseif dataTrajectory == "STEREO-A"
    obsFilePrefix = "sta"
end

# skip the first line, pick off the headings from the second.
IHData, IHColumns = readdlm("C:/Users/anike/Desktop/PhDUofM/NextGenSWMF/BaselineRunsExploration/code_v_2021_02_07_96_Runs/run001_AWSoM/" * "trj_earth_n00005000.sat", header=true, skipstart=1)

m, n = size(IHData)

Ur = zeros(m, 6 * numberOfGroups)
Np = zeros(m, 6 * numberOfGroups)
T = zeros(m, 6 * numberOfGroups)
B = zeros(m, 6 * numberOfGroups)

tmPeriods = Array{DateTime, 2}(undef, m, numberOfGroups)
tmTicks = []
plotXLabels = []
obsFileDates = []

ioLHS = open("C:/Users/anike/Desktop/PhDUofM/NextGenSWMF/BaselineRunsExploration/2021_02_06_04_51_17_event_list_randomized.txt");
linesLHS = readlines(ioLHS);
close(ioLHS);

# Get realization Idx to specify filepath to trj files correctly. 
realizationIdxList = TrajectoriesTools.getRealizationIdxList(linesLHS);


ioBaseline = open("baseline_runs_16_event_list.txt")
linesBase = readlines(ioBaseline)
close(ioBaseline)

# Get the subplot titles (for example, GONG2208, ADAPT2209 etc)
mapCRList = TrajectoriesTools.retrieveMapCRVals(linesBase)

# Calculate Radial speed (Ur)
fUr(ux, uy, uz, x, y, z) = (ux*x + uy*y + uz*z)/sqrt(x^2 + y^2 + z^2) # one line function for convenience

for groupIdx = 1:numberOfGroups # This indexing will only get the AWSoMR runs
    if groupIdx in 1:Int(numberOfGroups/2)
        modelUsed = "AWSoM"
    else
        modelUsed = "AWSoMR"
    end
    for fileIdx = (groupIdx - 1) * 6 + 1:(groupIdx)*6
        opFileName = "C:/Users/anike/Desktop/PhDUofM/NextGenSWMF/BaselineRunsExploration/code_v_2021_02_07_96_Runs/" * "run"*@sprintf("%03d", fileIdx)*"_"*modelUsed*"/trj_earth_n00005000.sat"

        # replace opFileName syntax with 'join' command
        
        if isfile(opFileName)
            # println("File idx ", fileIdx, " is a file")
            # process output file
            IHData_fileIdx, IHColumns_fileIdx = readdlm(opFileName, header=true, skipstart=1)

            # go through steps of calculating derived quantities
            IHDF = DataFrame(IHData_fileIdx)
            rename!(IHDF, vec(IHColumns_fileIdx))

            # push derived quantities into arrays, discard rest of dataframe 
            Ur[:, fileIdx] = fUr.(IHDF[!, :ux], IHDF[!, :uy], IHDF[!, :uz], IHDF[!, :X], IHDF[!, :Y], IHDF[!, :Z])
            Np[:, fileIdx] = IHDF[!, :rho] ./ ProtonMass
            T[:, fileIdx] = (IHDF[!, :p]) .* ((ProtonMass ./ IHDF[!, :rho]) / k) * 1e-7
            B[:, fileIdx] = sqrt.(IHDF[!, :bx].^2 .+ IHDF[!, :by].^2 .+ IHDF[!, :bz].^2) * 1e5
        end
    end
end

# Get obsFileDates, tmPeriods, tmTicks, plotXLabels from baseline run data itself!
for groupIdx = 1:numberOfGroups
    if groupIdx in 1:Int(numberOfGroups/2)
        modelUsed = "AWSoM"
    else
        modelUsed = "AWSoMR"
    end

    opFileName = "C:/Users/anike/Desktop/PhDUofM/NextGenSWMF/code_v_2021_02_07/BaselineRuns/" * "run"*@sprintf("%03d", groupIdx)*"_"*modelUsed*"/run01/IH/trj_earth_n00005000.sat"

    if isfile(opFileName)
        # process output file
        IHData_groupIdx, IHColumns_groupIdx = readdlm(opFileName, header=true, skipstart=1)
        IHDF = DataFrame(IHData_groupIdx)
        rename!(IHDF, vec(IHColumns_groupIdx))

        # extract dates from first row for each of the runs and add 15 so as to load corresponding obs data. 
        push!(obsFileDates, Dates.format(Dates.DateTime(IHDF[1, :year], IHDF[1, :mo], IHDF[1, :dy], IHDF[1, :hr], IHDF[1, :mn]) + Dates.Day(15), "yyyy_mm_ddTHH_MM_SS"))
        tmPeriods[:, groupIdx] = Dates.DateTime.(IHDF[!, :year], IHDF[!, :mo], IHDF[!, :dy], IHDF[!, :hr], IHDF[!, :mn], IHDF[!, :sc])

        push!(tmTicks, range(tmPeriods[:, groupIdx][1] + Day(3), tmPeriods[:, groupIdx][end], step=Day(6)))

        push!(plotXLabels, Dates.format(Dates.DateTime(IHDF[1, :year], IHDF[1, :mo], IHDF[1, :dy], IHDF[1, :hr], IHDF[1, :mn], IHDF[1, :sc]), "dd-u-yy HH:MM:SS"))
    end
end



# Remove last row (720 rows to match observed data)
Ur = Ur[1:end - 1, :];
Np = Np[1:end - 1, :];
T = T[1:end - 1, :];
B = B[1:end - 1, :];
tmPeriods = tmPeriods[1:end - 1, :]

UrObserved = zeros(m - 1, numberOfGroups)
NpObserved = zeros(m - 1, numberOfGroups)
TObserved = zeros(m - 1, numberOfGroups)
BObserved = zeros(m - 1, numberOfGroups)


# Load observation data
for (obsIdx, dt) in enumerate(obsFileDates)

    obsFileName = "C:/Users/anike/Desktop/PhDUofM/NextGenSWMF/obsdata/"* obsFilePrefix * "_" * dt * ".out"
    obsData, obsColumns = readdlm(obsFileName, header=true, skipstart=3)

    ObsDF = DataFrame(obsData)
    rename!(ObsDF, vec(obsColumns))

    # This df to matrix method is wayy too clunky - probably just work with DFs in the future to retain advantage of column headers to access data easily?

    UrObserved[:, obsIdx] = ObsDF[1:m-1, :V_tot]
    NpObserved[:, obsIdx] = ObsDF[1:m-1, :Rho]
    TObserved[:, obsIdx] = ObsDF[1:m-1, :Temperature]
    BObserved[:, obsIdx] = ObsDF[1:m-1, :B_tot]
end

println("Data pushed into respective arrays")

"""
@Name(x)
Returns the value of the variable itself and a string corresponding to the variable name. 
For full details, refer this post: https://discourse.julialang.org/t/convert-input-function-variable-name-to-string/25398
"""
macro Name(x)
    quote
    ($(esc(x)), $(string(x)))
    end
end

"""
    formatTmTicks(tmTickRange)
Format a range of dates in date month style for tick labels on plots. 
"""
function formatTmTicks(tmTickRange)
    return Dates.format.(tmTickRange, "dd-u")
end

# Make plots for AWSoM and AWSoMR
"""
varName: This is the actual variable whose columns will be used for plotting. 
varNameLabel: This is the string created from the variable name. It will be used for placing appropriate title / label. 
observationArray: This is the array of observations corresponding to the same variable. 
modelName: This can accept either AWSoM or AWSoMR. 
"""
function plotQoIMultipleRealizations((varName, varNameLabel), observationArray, modelName)
    figureQoI, axesInitial = pyplt.subplots(nrows = 4, 
                                            ncols = 2, 
                                            constrained_layout=true)

    # transpose before flattening to enable rowwise filling of plots (Julia uses column major order by default)
    axesQoI = Array{PyObject, 2}(undef, 2, 4)
    for j in 1:4
        for i in 1:2
            axesQoI[i, j] = axesInitial[j, i]
        end
    end

    if varNameLabel == "Np" # need to find a better method (i.e. drop negative values and plot)
        tmPeriodsObserved = tmPeriods[1:4:end, :]
        observationArray = observationArray[1:4:end, :]
    else
        tmPeriodsObserved = tmPeriods
    end

    for (plotIdx, ax) in enumerate(axesQoI[:])
        xObs = tmPeriodsObserved[:, plotIdx]
        yObs = observationArray[:, plotIdx]

        x = tmPeriods[:, plotIdx]
        if modelName == "AWSoM"
            y = varName[:, (plotIdx - 1) * 6 + 1:(plotIdx)*6]
            lineStyle = "red"
        elseif modelName == "AWSoMR"
            y = varName[:, (8 + plotIdx - 1)*6 + 1:(8 + plotIdx)*6]
            lineStyle = "blue"
        else
            error("Model name should be one of AWSoM or AWSoMR");
        end

        ax.plot(xObs, yObs, color="black", lw=2, label="OMNI")
        ax.plot(x, y, color=lineStyle, lw=2, label=modelName)
        ax.set(xticks=tmTicks[plotIdx], xticklabels=formatTmTicks(tmTicks[plotIdx]))
        ax.set_xlabel("Start Time " * plotXLabels[plotIdx])
        ax.set_title(mapCRList[plotIdx])
        ax.set_xlim(x[1], x[end])
        ax.grid()
        if varNameLabel == "T"
            ax.set_yscale("log")
        end
        
    end   
    handles, labels = axesQoI[end].get_legend_handles_labels()
    figureQoI.legend(handles[1:2], labels[1:2], loc="upper left", ncol=2) # generalize ncols, extraction of handles / labels
    figureQoI.suptitle(varNameLabel * "_" * dataTrajectory)
    figureQoI.set_size_inches(12.5, 13.9)
end




