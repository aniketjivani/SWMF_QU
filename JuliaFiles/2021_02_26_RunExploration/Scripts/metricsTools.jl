module MetricsTools

using Statistics

# Masks can either be BitArrays or functions that take vectors
const MASKTYPE(P) = Union{BitArray{P},Function}

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

    return x_masked
end

@doc raw"""
    computeMaskedMetric(x::Vector, y::Vector, mask::MASKTYPE{1}, metric::Function)

Compute metrics of masked arrays.

"""
function computeMaskedMetric(
    x::Vector,
    y::Vector,
    mask::MASKTYPE(1),
    metric::Function
)

    # Both x, y have to satisfy condition
    computedMask = mask(x) .& mask(y)

    x_masked = maskArray(x, computedMask)
    y_masked = maskArray(y, computedMask)

    computedMetric = metric(x_masked, y_masked)

    return computedMetric
end

RMSE(x, obs) = sqrt(mean((x .- obs).^2))

computeMaskedRMSE(x, y, mask) = computeMaskedMetric(x, y, mask, RMSE)

export maskArray, computeMaskedMetric, RMSE, computeMaskedRMSE

end
