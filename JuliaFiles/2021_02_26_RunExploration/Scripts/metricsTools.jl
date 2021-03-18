module MetricsTools

using Missings
using Statistics: mean, median

# Masks can either be BitArrays or functions that take vectors
const MASKTYPE(P) = Union{BitArray{P},Function,Nothing}

# Array that allows missing type
const MISSINGARRAY(T, P) = Array{Union{Missing,T},P}

@doc raw"""
    maskArray(x::Array{T,P}, mask::Union{BitArray{P},Function})

Returns array masked by `mask`.

"""
function maskArray(
    x::Array{T,P},
    mask::MASKTYPE(P),
    # mask::Union{BitArray{P},Function}
)::MISSINGARRAY(T, P) where {T,P}

    if !(T <: Union{Missing,Any})
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
            repeat(y, inner=(1, size(x)[2])),
            computedMask)
    else
        throw(ErrorException("P must be 1 or 2."))
    end

    computedMetric = metric(x_masked, y_masked)

    return computedMetric
end

RMSE(x::Array, obs::Array) = sqrt(mean((x .- obs).^2))
computeMaskedRMSE(x, y, mask) = computeMaskedMetric(x, y, mask, RMSE)


function _get_missing_array(z, timeshift)
    if ndims(z) > 1
        missingArray = repeat([missing], timeshift, size(z)[2])
    else
        missingArray = repeat([missing], timeshift)
    end

    return missingArray
end


function shift_array(x::Array, y::Array, timeshift::Int)

    @assert size(x)[1] == size(y)[1] "x, y don't have the same number of rows!"

    # Shift x if timeshift > 0
    # Shift y if timeshift < 0
    if timeshift > 0
        x_shifted = vcat(_get_missing_array(x, timeshift), x)
        y_shifted = vcat(y, _get_missing_array(y, timeshift))

    else
        x_shifted = vcat(x, _get_missing_array(x, -timeshift))
        y_shifted = vcat(_get_missing_array(y, -timeshift), y)
    end

    return x_shifted, y_shifted

end

function trim_array(x, y, Tmin, Tmax)


    TminIdx = Int(ceil(Tmin * size(x)[1]))

    if Tmin == 0
        TminIdx = TminIdx + 1
    end

    TmaxIdx = Int(floor(Tmax * size(x)[1]))

    if ndims(x) > 1
        xTrimmed = x[TminIdx:TmaxIdx,:]
    else
        xTrimmed = x[TminIdx:TmaxIdx]
    end

    if ndims(y) > 1
        yTrimmed = y[TminIdx:TmaxIdx,:]
    else
        yTrimmed = y[TminIdx:TmaxIdx]
    end

    return xTrimmed, yTrimmed

end

function shift_trim_array(x, y, timeshift, Tmin, Tmax)

    x_shifted, y_shifted = shift_array(x, y, timeshift)
    x_trimmed, y_trimmed = trim_array(x_shifted, y_shifted, Tmin, Tmax)

    return x_trimmed, y_trimmed

end

"""
    function shiftedRMSE(x::Array, y::Array, timeshift::Int,
                        Tmin::Int, Tmax::Int, shiftx::Bool=true)

Shift x,y using shiftArray and compute RMSE on non-missing indices.

"""
function shiftedRMSE(
    x::Array,
    y::Array,
    timeshift::Int,
    Tmin::Float64,
    Tmax::Float64;
    shiftx::Bool=true,
    square::Bool=false,
    dims::Union{Nothing,Int}=nothing
)

    xShifted, yShifted = shift_trim_array(x, y, timeshift, Tmin, Tmax)

    sqDiff = (xShifted .- yShifted).^2
    rmse = meanNA(sqDiff, dims=dims)

    if !square
        rmse = sqrt.(rmse)
    end

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
function computeShiftedRMSE(x::Array, y::Array,
                            timeshifts::Vector,
                            Tmins::Vector{Float64},
                            Tmaxs::Vector{Float64};
                            shiftx::Bool=true,
                            RMSEonly::Bool=false,
                            dims::Union{Nothing,Int}=nothing,
                            funcs::Vector=[median],
                            sortBy::Int=1,
                            verbose::Bool=false)

    # TODO: Modify to allow different functions of the RMSE vector if dims > 1

    RMSEisVector = !ismissing(dims) && ndims(x) > 1

    # Initialize array to store RMSEs
    if RMSEisVector
        res = allowmissing(
            zeros(size(timeshifts)[1],
                  size(Tmins)[1],
                  size(Tmaxs)[1],
                  length(funcs)))
    else
        res = allowmissing(
            zeros(size(timeshifts)[1],
                  size(Tmins)[1],
                  size(Tmaxs)[1]))
    end

    # Gridsearch
    for (i, timeshift) in enumerate(timeshifts)
        for (j, Tmin) in enumerate(Tmins)
            for (k, Tmax) in enumerate(Tmaxs)

                rmse = shiftedRMSE(x, y, timeshift, Tmin, Tmax,
                                   shiftx=shiftx, dims=dims)
                if RMSEisVector
                    res[i,j,k,:] = map((f) -> f(rmse), funcs)
                else
                    res[i,j,k] = rmse
                end

                if verbose
                    println("RMSE for timeshift=$timeshift, Tmin=$Tmin, Tmax=$Tmax: $(res[i,j,k])")
                end

            end
        end
    end

    @assert !all(ismissing.(res)) "RMSE's are all missing!"

    if RMSEisVector
        bestIdx = argmin(skipmissing(res[:,:,:,sortBy]))
        sortedres = res[bestIdx,:]
    else
        bestIdx = argmin(skipmissing(res))
        sortedres = res[bestIdx]
    end

    if RMSEonly
        # Only return the minimum RMSE
        return minimum(skipmissing(sortedres))
    else
        # Return a dictionary with the best parameters and RMSE

        bestTimeshift = length(timeshifts) == 1 ? 1 : timeshifts[bestIdx[1]]
        bestTmin = length(Tmins) == 1 ? 1 : Tmins[bestIdx[2]]
        bestTmax = length(Tmaxs) == 1 ? 1 : Tmaxs[bestIdx[3]]

        funcNames = String.(Symbol.(funcs))
        RMSEdict = Dict(funcNames .=> sortedres)

        resDict = Dict(
            "RMSE" => sortedres[sortBy],
            "RMSEdict" => RMSEdict,
            "timeshift" => bestTimeshift,
            "Tmin" => bestTmin,
            "Tmax" => bestTmax
        )

        return resDict
    end

end

function computeShiftedMaskedRMSE(x, y, mask, timeshifts, Tmins, Tmaxs;
                                  shiftx=true,
                                  dims=nothing,
                                  funcs=[mean],
                                  sortBy=1,
                                  RMSEonly=false,
                                  verbose=false)

    rmse = computeMaskedMetric(
        x, y, mask,
        (x, y) -> computeShiftedRMSE(x, y, timeshifts, Tmins, Tmaxs,
                                     shiftx=shiftx,
                                     dims=dims,
                                     funcs=funcs,
                                     sortBy=sortBy,
                                     RMSEonly=RMSEonly,
                                     verbose=verbose)
    )

    return rmse

end


export maskArray,
    computeMaskedMetric,
    computeMaskedRMSE,
    computeShiftedRMSE

end
