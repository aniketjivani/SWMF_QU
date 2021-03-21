"""
Module consisting of helper functions for computing metrics (namely RMSE) of
 shifted, trimmed, and/or masked arrays.
"""
module MetricsTools

using Missings
using Statistics: mean, median, minimum
using ShiftedArrays, AxisArrays


function _get_trim_index(x, trim)
    return (Int ∘ round)(trim * size(x)[1]) |> (z -> (z == 0) ? 1 : z)
end

function axesdict(x::AxisArray)

    ax = AxisArrays.axes(x)

    ax_names = (collect ∘ zip)(axisnames.(ax)...)[1]
    ax_values = (x -> x.val).(ax)

    return Dict(ax_names .=> ax_values)
end


_f_missing(f, x, ::Colon, kwargs...) = (f ∘ skipmissing)(x, kwargs...)


function _f_missing(f, x, dims, kwargs...)
    eachslice(x, dims=dims) .|> (z -> (f ∘ skipmissing)(z, kwargs...))
end


f_missing(f, x; dims=:, kwargs...) = _f_missing(f, x, dims, kwargs...)
f_missing(f) = (f ∘ skipmissing)

function _mask_array(x, mask::BitArray)

    @assert size(x) == size(mask)

    if any(.!mask)
        # Initialize array of all missing with same size and eltype as x
        x_masked = similar([missing], Union{Missing, eltype(x)}, size(x)...)

        # If mask[i,j] = 1, x_masked[i, j] = x[i, j].
        # Otherwise, x_masked[i, j] = missing
        x_masked[mask] .= x[mask]

        return x_masked
    else
        # Do nothing if mask is all 1
        return x
    end
end

mask_array(x, mask::BitArray) = _mask_array(x, mask)
mask_array(x, mask::Function) = _mask_array(x, mask(x))
mask_array(x, ::Nothing) = x


function trim_array(x, Tmin, Tmax; dim=1)

    @assert Tmin >= 0 "Tmin must be >= 0."
    @assert Tmax <= 1 "Tmax must be <= 1."
    @assert Tmin <= Tmax "Tmin should be <= Tmax."

    Tmin_idx = _get_trim_index(x, Tmin)
    Tmax_idx = _get_trim_index(x, Tmax)

    return selectdim(x, dim, Tmin_idx:Tmax_idx)
end


mean_missing(x; dims=:) = f_missing(mean, x, dims=dims)
# Can add any other function analogously

_mse_missing(x, y; dims=:) = mean_missing((x .- y).^2, dims=dims)


function _rmse_missing(x, y; dims=2, square=false)
    if square
        return _mse_missing(x, y, dims=dims)
    else
        return _mse_missing(x, y, dims=dims) .|> sqrt
    end
end



function rmse_shifted(x, y, shift; kwargs...)
    return _rmse_missing(lag(x, shift), y; kwargs...)
end


function rmse_trimmed(x, y, Tmin, Tmax; kwargs...)
    x_trimmed, y_trimmed = trim_array.((x, y), Tmin, Tmax)
    rmse = _rmse_missing(x_trimmed, y_trimmed; kwargs...)

    return rmse
end


# NOTE: kwargs contain dims, square
function rmse_shifted_trimmed(x, y, shift, Tmin, Tmax;
                              trim_first=false, kwargs...)

    if trim_first
        x_trimmed, y_trimmed = trim_arrays.((x, y), Tmin, Tmax)
        rmse = rmse_shifted(x_trimmed, y_trimmed,
                            dims=dims, square=square)
    else
        rmse = rmse_trimmed(lag(x, shift), y, Tmin, Tmax; kwargs...)
    end

    return rmse
end


function rmse(x, y; shift::Integer, Tmin::Number, Tmax::Number,
              mask, copy=true, trim_first=false, dims=2, square=false)

    # Mask x, y
    if copy
        x_ = mask_array(x, mask)
        y_ = mask_array(y, mask)
    else
        x_ = x
        y_ = y
        mask_array!(x, mask)
        mask_array!(y, mask)
    end

    return rmse_shifted_trimmed(x_, y_, shift, Tmin, Tmax,
                                trim_first=trim_first, dims=dims, square=square)

end

# NOTE: This commented section tried to implement RMSE functions that apply a
# function to an array of RMSEs.
# This is not relevant to the current framework because we want to apply to
# functions to the overall RMSE array in compute_metrics. This might be useful
# in the future so I keep it commented here.

# # NOTE: kwargs contain trim_first, dims, square
# function __rmse(x, y, shift::Integer, Tmin::Number, Tmax::Number;
#                 mask, copy, kwargs...)

#     # Mask x, y
#     if copy
#         x_ = mask_array(x, mask)
#         y_ = mask_array(y, mask)
#     else
#         x_ = x
#         y_ = y
#         mask_array!(x, mask)
#         mask_array!(y, mask)
#     end

#     return rmse_shifted_trimmed(x_, y_, shift, Tmin, Tmax; kwargs...)

# end


# # NOTE: kwargs contain trim_first, dims, square, mask, copy for _rmse
# # Apply function to one of the axes
# function _rmse(x, y, func::Function, func_dim::Integer, shift, Tmin, Tmax;
#                kwargs...)

#     rmse_array = __rmse(x, y, shift, Tmin, Tmax; kwargs...)

#     # NOTE: func needs to have keyword argument dims
#     # e.g. minimum, mean, etc
#     # Tried mapslices but it gave an error

#     func_rmse = func(rmse_array, dims=func_dim)

#     return dropdims(func_rmse, dims=func_dim)

# end

# function _rmse(x, y, func::Function, func_dim::Symbol,
#                shift, Tmin, Tmax; kwargs...)

#     rmse_array = __rmse(x, y, shift, Tmin, Tmax; kwargs...)

#     # NOTE: func needs to have keyword argument dims
#     # e.g. minimum, mean, etc
#     # Tried mapslices but it gave an error

#     ax_dim = axisdim(rmse_array, Axis{func_dim})
#     func_rmse = func(rmse_array, dims=ax_dim)

#     return dropdims(func_rmse, dims=ax_dim)
# end

# function _rmse(x, y, ::Nothing, func_dim, shift, Tmin, Tmax; kwargs...)
#     return __rmse(x, y, shift, Tmin, Tmax; kwargs...)
# end


# function rmse(x, y; func=nothing, func_dim=1,
#               shift, Tmin, Tmax, mask=nothing, dims=2, square=false,
#               copy=true, trim_first=false)

#     return _rmse(x, y, func, func_dim, shift, Tmin, Tmax;
#                  mask=mask, dims=dims, square=square, copy=copy,
#                  trim_first=trim_first)
# end



export mean_missing,
    _rmse_missing,
    rmse_shifted_trimmed,
    mask_array!,
    rmse_masked,
    compute_metrics

end
