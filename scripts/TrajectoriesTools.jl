module TrajectoriesTools
# Define some functions useful for loading and processing trajectories. Still a WIP. 
"""
    getRealizationIdxList(eventListLinesArray)

Retrieve the realization Idx corresponding to GONG (default: 1) and ADAPT runs. 
# Arguments:
- `eventListLinesArray`: An array of strings, with each string corresponding to a line in the input event_list file. This is created through the readlines() function. 
"""
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

"""
    retrieveMapCRVals(eventListLinesArray)

Retrieve the map and the CR used in the 16 groups from the baseline_event_list with 16 runs. 
# Arguments:
- `eventListLinesArray`: An array of strings, with each string corresponding to a line in the input _baseline_ event_list file. This is created through the readlines() function. 
"""
function retrieveMapCRVals(eventListLinesArray)
    mapCRList = []  
    runCounter = 0
    for line in eventListLinesArray
        m = match(r"map=(GONG|ADAPT)_CR(2208|2209|2152|2154).fits", line)
        if m !== nothing
            runCounter += 1
            push!(mapCRList, m.captures[1]*m.captures[2])
        end
    end
    return mapCRList
end


export getRealizationIdxList, retrieveMapCRVals

end