# Load packages
using DelimitedFiles
using DataFrames
using Printf
using IterTools
using Dates

using PyCall
# pygui(:qt)
using PyPlot        
@pyimport matplotlib.pyplot as pyplt

# using Plots
# gr()


# Constants
ProtonMass = 1.67e-24
k = 1.3807e-23

# specify groups of magnetogram (or map), cr, md - map not used as variable so as to avoid confusion with "map" function. 
mg = ["GONG", "ADAPT"]
cr = [2208, 2209, 2152, 2154]
md = ["AWSoM", "AWSoMR"]

numberOfGroups = length(product(mg, cr, md))

dataTrajectory = "EARTH"
# dataTrajectory = "STEREO-A"

if dataTrajectory == "EARTH"
    obsFilePrefix = "omni"
elseif dataTrajectory == "STEREO-A"
    obsFilePrefix = "sta"
end

# skip the first line, pick off the headings from the second.
IHData, IHColumns = readdlm("C:/Users/anike/Desktop/PhDUofM/NextGenSWMF/code_v_2021_02_07/BaselineRuns/run001_AWSoM/run01/IH/trj_earth_n00005000.sat", header=true, skipstart=1)

m, n = size(IHData)

Ur = zeros(m, numberOfGroups)
Np = zeros(m, numberOfGroups)
T = zeros(m, numberOfGroups)
B = zeros(m, numberOfGroups)

tmPeriods = Array{DateTime, 2}(undef, m, numberOfGroups)
tmTicks = []
plotXLabels = []
obsFileDates = []

# Calculate Radial speed (Ur)
fUr(ux, uy, uz, x, y, z) = (ux*x + uy*y + uz*z)/sqrt(x^2 + y^2 + z^2) # one line function for convenience

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

        # go through steps of calculating derived quantities
        IHDF = DataFrame(IHData_groupIdx)
        rename!(IHDF, vec(IHColumns_groupIdx))

        # extract dates from first row for each of the runs and add 15 so as to load corresponding obs data. 
        push!(obsFileDates, Dates.format(Dates.DateTime(IHDF[1, :year], IHDF[1, :mo], IHDF[1, :dy], IHDF[1, :hr], IHDF[1, :mn]) + Dates.Day(15), "yyyy_mm_ddTHH_MM_SS"))

        # push derived quantities into arrays, discard rest of dataframe 
        Ur[:, groupIdx] = fUr.(IHDF[!, :ux], IHDF[!, :uy], IHDF[!, :uz], IHDF[!, :X], IHDF[!, :Y], IHDF[!, :Z])
        Np[:, groupIdx] = IHDF[!, :rho] ./ ProtonMass
        T[:, groupIdx] = (IHDF[!, :p]) .* ((ProtonMass ./ IHDF[!, :rho]) / k) * 1e-7
        B[:, groupIdx] = sqrt.(IHDF[!, :bx].^2 .+ IHDF[!, :by].^2 .+ IHDF[!, :bz].^2) * 1e5

        tmPeriods[:, groupIdx] = Dates.DateTime.(IHDF[!, :year], IHDF[!, :mo], IHDF[!, :dy], IHDF[!, :hr], IHDF[!, :mn], IHDF[!, :sc])

        # push!(tmTicks, range(tmPeriods[:, groupIdx][1] + Day(3), tmPeriods[:, groupIdx][end], step=Day(5)))
        push!(tmTicks, range(tmPeriods[:, groupIdx][1] + Day(3), tmPeriods[:, groupIdx][end], step=Day(6)))

        dateLabels_groupIdx = Dates.format.(Dates.DateTime.(IHDF[!, :year], IHDF[!, :mo], IHDF[!, :dy]), "dd-u");

        push!(plotXLabels, Dates.format(Dates.DateTime(IHDF[1, :year], IHDF[1, :mo], IHDF[1, :dy], IHDF[1, :hr], IHDF[1, :mn], IHDF[1, :sc]), "dd-u-yy HH:MM:SS"))
    # else
    #     push!(failedRuns, groupIdx)

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


ioBaseline = open("baseline_runs_16_event_list.txt")
linesBase = readlines(ioBaseline)
close(ioBaseline)

function retrieveGONGADAPTIndices(eventListLinesArray)
    mapCRList = []
    gongIdx = []
    adaptIdx = []   
    runCounter = 0
    for line in eventListLinesArray
        m = match(r"map=(GONG|ADAPT)_CR(2208|2209|2152|2154).fits", line)
        if m !== nothing
            runCounter += 1
            push!(mapCRList, m.captures[1]*m.captures[2])
            if m.captures[1] == "GONG"
                push!(gongIdx, runCounter)
            elseif m.captures[1] == "ADAPT"
                push!(adaptIdx, runCounter)
            end
        end
    end
    return mapCRList, gongIdx, adaptIdx
end


mapCRList, gongIdx, adaptIdx = retrieveGONGADAPTIndices(linesBase)

macro Name(x) # for full details of usage, refer to : https://discourse.julialang.org/t/convert-input-function-variable-name-to-string/25398
    quote
    ($(esc(x)), $(string(x)))
    end
end

function formatTmTicks(tmTickRange)
    return Dates.format.(tmTickRange, "dd-u")
end

function plotQoI((varName, varNameLabel), observationArray)
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

    if varNameLabel == "Np" # need to find a better method (i.e. downsample only when needed)
        tmPeriodsObserved = tmPeriods[1:4:end, :]
        observationArray = observationArray[1:4:end, :]
    else
        tmPeriodsObserved = tmPeriods
    end


    for (plotIdx, ax) in enumerate(axesQoI[:])
        xObs = tmPeriodsObserved[:, plotIdx]
        yObs = observationArray[:, plotIdx]

        x = tmPeriods[:, plotIdx]
        yAWSoM = varName[:, plotIdx]
        yAWSoMR = varName[:, plotIdx + 8]

        ax.plot(xObs, yObs, color="black", lw=2, label="OMNI")
        ax.plot(x, yAWSoM, color="red", lw=2, label="AWSoM")
        ax.plot(x, yAWSoMR, color="blue", lw=2, label="AWSoMR")
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
    figureQoI.legend(handles, labels, loc="upper right", ncol=3)
    figureQoI.suptitle(varNameLabel * "_" * dataTrajectory)
    figureQoI.set_size_inches(12.5, 13.9)
    # figureQoI.tight_layout()
    # return figureQoI, axesQoI
end









