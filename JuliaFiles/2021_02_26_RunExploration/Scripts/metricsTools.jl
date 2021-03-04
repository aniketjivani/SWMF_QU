module MetricsTools

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

    x_masked = reshape(x_masked, :, size(x)[2])

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

export maskArray, computeMaskedMetric, RMSE, computeMaskedRMSE

end
