module MetricsTools

using Missings
using Statistics: mean

# Masks can either be BitArrays or functions that take vectors
const MASKTYPE(P) = Union{BitArray{P}, Function, Nothing}

# Array that allows missing type
const MISSINGARRAY(T,P) = Array{Union{Missing, T}, P}

@doc raw"""
    maskArray(x::Array{T,P}, mask::Union{BitArray{P},Function})

Returns array masked by `mask`.

"""
function maskArray(
    x::Array{T,P},
    mask::MASKTYPE(P),
    # mask::Union{BitArray{P},Function}
)::MISSINGARRAY(T,P) where {T,P}

    if !(T <: Union{Missing, Any})
        x = convert(Array{Union{T,Missing},P}, x)
    end

    if typeof(mask) <: BitArray{P}
        x_masked = x[mask]
    else
        computedMask = mask(x)
        x_masked = x[computedMask]
    end

    if P > 1
        x_masked = reshape(x_masked, :, size(x)[2])
    end

    return x_masked
end

@doc raw"""
    computeMaskedMetric(x::Vector, y::Vector, mask::MASKTYPE{1}, metric::Function)

Compute metrics of masked arrays.

Note: Only works for 1 or 2 dim. arrays.

"""
function computeMaskedMetric(
    # x::Array{Any, P},
    x::Array,
    y::Vector,
    mask::MASKTYPE(1),
    metric::Function
)

    computedMask = mask(x) .& mask(y)

    x_masked = maskArray(x, computedMask)

    if ndims(x) == 1
        y_masked = maskArray(y, computedMask)
    elseif ndims(x) == 2
        y_masked = maskArray(
            repeat(y, inner=(1,size(x)[2])),
            computedMask)
    else
        throw(ErrorException("P must be 1 or 2."))
    end

    computedMetric = metric(x_masked, y_masked)

    return computedMetric
end

RMSE(x::Array, obs::Array) = sqrt(mean((x .- obs).^2))
computeMaskedRMSE(x, y, mask) = computeMaskedMetric(x, y, mask, RMSE)

@doc raw"""
    function shiftArray(x::Array, y::Array, timeshift::Int,
                        Tmin::Int, Tmax::Int, shiftx::Bool=true)

Shift x (if shiftx, else y) by timeshift by appending/prepending missing values
and subset to [Tmin:Tmax]

"""
function shiftArray(x::Array, y::Array,
                    timeshift::Int,
                    Tmin::Float64,
                    Tmax::Float64,
                    shiftx::Bool=true)
    # TODO: Check if x,y have same length

    # xShifted = copy(allowmissing(x))
    # yShifted = copy(allowmissing(y))

    # xShifted = allowmissing(x)
    # yShifted = allowmissing(y)

    if ndims(x) > 1
        missingArray = repeat([missing], timeshift, size(x)[2])
    else
        missingArray = repeat([missing], timeshift)
    end

    if shiftx
        xShifted = vcat(missingArray, x)
        yShifted = vcat(y, missingArray)
    else
        yShifted = vcat(missingArray, y)
        xShifted = vcat(x, missingArray)
    end

    TminIdx = Int(ceil(Tmin * size(xShifted)[1]))
    TmaxIdx = Int(floor(Tmax * size(xShifted)[1]))

    xShifted = xShifted[TminIdx:TmaxIdx]
    yShifted = yShifted[TminIdx:TmaxIdx]

    return xShifted, yShifted

end

"""
    function shiftedRMSE(x::Array, y::Array, timeshift::Int,
                        Tmin::Int, Tmax::Int, shiftx::Bool=true)

Shift x,y using shiftArray and compute RMSE on non-missing indices.

"""
function shiftedRMSE(x::Array,
                     y::Array,
                     timeshift::Int,
                     Tmin::Float64,
                     Tmax::Float64,
                     shiftx::Bool=true)

    xShifted, yShifted = shiftArray(x, y, timeshift,
                                    Tmin, Tmax, shiftx)

    sqDiff = skipmissing((xShifted .- yShifted).^2)
    rmse = sqrt(mean(sqDiff))

    return rmse
end


@doc raw"""
    function computeShiftedRMSE(x::Array, y::Array, timeshifts::Vector{Int},
                                Tmins::Vector{Int}, Tmaxs::Vector{Int},
                                shiftx::Bool=true, RMSEonly::Bool=false)

Computes min{timeshift, Tmin, Tmax} shiftedRMSE(timeshift, Tmin, Tmax) over
the grid timeshifts x Tmins x Tmaxs.

If RMSEonly, return the minimum RMSE. Otherwise, return a dictionary with
the best parameters and RMSE.

"""
function computeShiftedRMSE(x::Array, y::Array, timeshifts::Vector,
                            Tmins::Vector{Float64}, Tmaxs::Vector{Float64},
                            shiftx::Bool=true, RMSEonly::Bool=false,
                            verbose::Bool=false)

    # Initialize array to store RMSEs
    res = zeros(size(timeshifts)[1],
                size(Tmins)[1],
                size(Tmaxs)[1])

    # Gridsearch
    for (i, timeshift) in enumerate(timeshifts)
        for (j, Tmin) in enumerate(Tmins)
            for (k, Tmax) in enumerate(Tmaxs)

                res[i,j,k] = shiftedRMSE(x, y, timeshift, Tmin, Tmax)

                if verbose
                    println("RMSE for timeshift=$timeshift, Tmin=$Tmin, Tmax=$Tmax: $(res[i,j,k])")
                end

            end
        end
    end

    if RMSEonly
        # Only return the minimum RMSE
        return minimum(res)
    else
        # Return a dictionary with the best parameters and RMSE
        bestIdx = argmin(res)

        resDict = Dict(
        "RMSE" => res[bestIdx],
        "timeshift" => timeshifts[bestIdx[1]],
        "Tmin" => Tmins[bestIdx[2]],
        "Tmax" => Tmaxs[bestIdx[3]],
        )

        return resDict
    end

end

function computeShiftedMaskedRMSE(x, y, timeshifts, mask,
                                  Tmins, Tmaxs; shiftx=true, RMSEonly=false,
                                  verbose=false)

    rmse = computeMaskedMetric(
        x, y, mask,
        (x, y) -> computeShiftedRMSE(x, y, timeshifts, Tmins, Tmaxs, shiftx, RMSEonly, verbose)
    )

    return rmse

end


export maskArray,
    computeMaskedMetric,
    computeMaskedRMSE,
    computeShiftedRMSE

end
