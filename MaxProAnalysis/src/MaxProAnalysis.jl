module MaxProAnalysis

    export Name, formatTmTicks
    export fUr, QoIObject, getQoIFromFile

    using DataFrames
    using CSV
    using IterTools

    using DelimitedFiles
    using Printf
    using Dates

    # Constants
    ProtonMass = 1.67e-24
    k = 1.3807e-23

    """
    Return radial speed for inputs from data file.
    """
    fUr(ux, uy, uz, x, y, z) = (ux*x + uy*y + uz*z)/sqrt(x^2 + y^2 + z^2) # one line function for convenience

    """
    Constructor whose fields are the 4 QoIs for a particular run (Ur, Np, T and B). Can return this as output from a function. 
    """
    mutable struct QoIObject
        Ur
        Np
        T
        B
        nPoints
        function QoIObject(nPoints) 
            return new(zeros(nPoints), zeros(nPoints), zeros(nPoints), zeros(nPoints), nPoints)
        end
    end

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

    """
        Process all observations from obs / sim file, convert to QoI and return
    """
    function getQoIFromFile(fileName, type::String="sim")

        if type == "sim"
            skipStart = 1
        else
            skipStart = 3
        end
        IHData_fileIdx, IHColumns_fileIdx = readdlm(fileName, header = true, skipstart = skipStart)

        # go through steps of calculating derived quantities
        IHDF = DataFrame(IHData_fileIdx, :auto)
        rename!(IHDF, vec(IHColumns_fileIdx))

        m, n = size(IHDF)

        qoiObject = QoIObject(n) # Create QoIObject with all QoIs initialized to zeros(n) and then populate them. 

        if type == "sim"
            qoiObject.Ur = fUr.(IHDF[!, :ux], IHDF[!, :uy], IHDF[!, :uz], IHDF[!, :X], IHDF[!, :Y], IHDF[!, :Z])
            qoiObject.Np = IHDF[!, :rho] ./ ProtonMass
            qoiObject.T = (IHDF[!, :p]) .* ((ProtonMass ./ IHDF[!, :rho]) / k) * 1e-7
            qoiObject.B = sqrt.(IHDF[!, :bx].^2 .+ IHDF[!, :by].^2 .+ IHDF[!, :bz].^2) * 1e5 
        elseif type == "obs"
            qoiObject.Ur = IHDF[!, :V_tot]
            qoiObject.Np = IHDF[!, :Rho]
            qoiObject.T = IHDF[!, :Temperature]
            qoiObject.B = IHDF[!, :B_tot]
        end
        return qoiObject
    end


end # module
