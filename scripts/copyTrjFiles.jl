# PURPOSE: Extract the trj_earth files in IH subdir of the Results in Dropbox and save them to appropriate directories on disk. 
# Written mainly to avoid downloading massive run directories from Dropbox and extract only required files. 
# Note: By tweaking the source file path and/or the file name, we can generalize the script to copy other files as well. 

using Printf

# cd("C:/Users/anike/Desktop/PhDUofM/NextGenSWMF/BaselineRunsExploration/")
maindir = expanduser("~/Dropbox/SWMF_QU/JuliaFiles/2021_02_26_RunExploration")
runsdir = "code_v_2021_02_07_96_Runs/"
cd(maindir)
if !isdir(runsdir)
    mkdir(runsdir)
    cd(runsdir)
    for runIdx in 1:48
        dirName = @sprintf("run%03d_AWSoM", runIdx)
        mkdir(dirName)
    end
    for runIdx in 49:96
        dirName = @sprintf("run%03d_AWSoMR", runIdx)
        mkdir(dirName)
    end
end
# cd("../")
# parentDir = "C:/Users/anike/Desktop/PhDUofM/NextGenSWMF/BaselineRunsExploration/code_v_2021_02_07_96_Runs/";
parentDir = joinpath(maindir, runsdir)

# ioLHS = open("C:/Users/anike/Desktop/PhDUofM/NextGenSWMF/BaselineRunsExploration/2021_02_06_04_51_17_event_list_randomized.txt");
ioLHS = open(joinpath(maindir, "event_list_files", "2021_02_06_04_51_17_event_list_randomized.txt"))
linesLHS = readlines(ioLHS);
close(ioLHS);


# Now figure out realization_idx from the input list (if its GONG maps, then by default realization_idx is to be picked up as 1, else to be read from event_list). 

function getRealizationIdxList(eventListLinesArray) 
    realizationIdxList = []
    for line in eventListLinesArray
        m1 = match(r"realization=\[(\d+)]", line)
        m2 = match(r"map=(GONG|ADAPT)_CR(2208|2209|2152|2154).fits", line)
        if m1 !== nothing 
            push!(realizationIdxList, parse(Int64, m1.captures[1]))
        elseif m1 === nothing && m2 !== nothing
            push!(realizationIdxList, 1)
        end
    end
    return realizationIdxList 
end

realizationIdxList = getRealizationIdxList(linesLHS);


# implement isdir function - since all run directories are not in dropbox

# srcParentDir = "C:\\Users\\anike\\Dropbox (University of Michigan)\\Results\\code_v_2021-02-07\\event_list_2021_02_06_04\\"
resultsdir = expanduser("~/DropboxFUSE/Results/code_v_2021-02-07/")
srcParentDir = joinpath(resultsdir, "event_list_2021_02_06_04")
srcDirs = readdir(srcParentDir);
trjFileName = "trj_earth_n00005000.sat"; 

for dir in srcDirs  
    m = match(r"run(\d+)_(AWSoM|AWSoMR)", dir);
    runIdx = parse(Int64, m.captures[1])
    # 02/23/2021: The above step is since all runs are not uploaded yet to Dropbox. So need to skip realizationIdx accordingly.

    srcFilePath = joinpath(srcParentDir, dir, "run" * @sprintf("%02d", realizationIdxList[runIdx]), "IH", trjFileName)
    dstFilePath = joinpath(parentDir, dir, trjFileName);
    if isfile(srcFilePath)
        cp(srcFilePath, dstFilePath, force=true);
        # println("Copied file for run idx ", runIdx)
    end
    
end


println("All files copied into respective run directories.")

