"""
Module consisting of functions for computing metrics (namely RMSE) of
 shifted, trimmed, and/or masked arrays.
"""
module MetricsTools

using Missings
using Statistics: mean, median, minimum
using ShiftedArrays, AxisArrays

# Functions starting with _ are helper functions mainly used in other functions
# Just ignore these.

function _get_trim_index(x, trim)
    return (Int ∘ round)(trim * size(x)[1]) |> (z -> (z == 0) ? 1 : z)
end


_f_missing(f, x, ::Colon, kwargs...) = (f ∘ skipmissing)(x, kwargs...)


function _f_missing(f, x, dims, kwargs...)
    eachslice(x, dims=dims) .|> (z -> (f ∘ skipmissing)(z, kwargs...))
end

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


_mse_missing(x, y; dims=:) = mean_missing((x .- y).^2, dims=dims)

# NOTE: Modify this function to change how RMSE is calculated
# NOTE: kwargs for all other rmse functions are passed here.
function _rmse_missing(x, y; dims=2, square=false, normalize=false, kwargs...)
    # penalty should be either nothing or a function
    # kwargs are keyword arguments for penalty

    mse_ = _mse_missing(x, y, dims=dims)
    
    # FIXME: Normalize gives error
    if normalize
        # FIXME: dims for _f_missing and mean are different
        mean_dims = (dims ==1) ? 2 : 1
        mse = mse_ / mean(x, dims=mean_dims)
    else
        mse = mse_
    end

    if square
        return mse
    else
        return sqrt.(mse)
    end

end


# # Compute RMSE after shifting x
# function _rmse_shifted(x, y, shift; kwargs...)
#     return _rmse_missing(lag(x, shift), y; kwargs...)
# end

# # Compute RMSE after trimming x, y by Tmin, Tmax
# function _rmse_trimmed(x, y, Tmin, Tmax; kwargs...)
#     x_trimmed, y_trimmed = trim_array.((x, y), Tmin, Tmax)
#     rmse = _rmse_missing(x_trimmed, y_trimmed; kwargs...)

#     return rmse
# end

function _shift_trim(x, shift, Tmin, Tmax; trim_first=false)

    if trim_first
        x_trimmed = trim_array(x, Tmin, Tmax)
        return lag(x_trimmed, shift)
    else
        x_shifted = lag(x, shift)
        return trim_array(x_shifted, Tmin, Tmax)
    end
end


# Combine shifting and trimming
# NOTE: kwargs contain dims, square, normalize
function _rmse_shifted_trimmed(x, y, shift, Tmin, Tmax;
                               trim_first=false, kwargs...)

    x_ = _shift_trim(x, shift, Tmin, Tmax, trim_first=trim_first)
    y_ = trim_array(y, Tmin, Tmax)
    
    return _rmse_missing(x_, y_; kwargs...)
    
    # if trim_first
    #     # Trim before shifting
    #     x_trimmed, y_trimmed = trim_arrays.((x, y), Tmin, Tmax)
    #     rmse = _rmse_shifted(x_trimmed, y_trimmed,
    #                           dims=dims, square=square)
    # else
    #     # Shift before trimming
    #     rmse = _rmse_trimmed(lag(x, shift), y, Tmin, Tmax; kwargs...)
    # end

end

# NOTE: kwargs contain dims, square, normalize, penaltyfunc, penalty_kwargs
function __rmse(x, y, shift::Integer, Tmin::Number, Tmax::Number;
                mask=nothing, copy=true, penaltyfunc=nothing, penalize_x=true,
                penalty_kwargs=Dict(:dims=>1), kwargs...)

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

    # HACK: To prevent taking square root twice
    # square = pop!(kwargs, "square", nothing)
    mse = _rmse_shifted_trimmed(x_, y_, shift, Tmin, Tmax; square=true, kwargs...)
    
    # Penalize RMSE based on shift, Tmin, Tmax
    if isnothing(penaltyfunc)
        return sqrt.(mse)
    else
        if penalize_x
            penalty_val = penaltyfunc(x_, shift, Tmin, Tmax; penalty_kwargs...)
        else
            penalty_val = penaltyfunc(y_, shift, Tmin, Tmax; penalty_kwargs...)
        end
        return sqrt.(mse .+ penalty_val)
    end
end

# NOTE: kwargs contain dims, square, normalize, mask, copy, penaltyfunc, penalty_kwargs
function _rmse(x, y, shift::Integer, Tmin::AbstractFloat, Tmax::AbstractFloat; kwargs...)

    rmse = __rmse(x, y, shift, Tmin, Tmax; kwargs...)
    return rmse, (shift=shift, Tmin=Tmin, Tmax=Tmax)
end

function _rmse(x, y, shift::Vector, Tmin::Vector, Tmax::Vector; kwargs...)

    n_shift, n_Tmin, n_Tmax = length.((shift, Tmin, Tmax))

    @assert size(x) == size(y)

    qoi_dim = axisdim(x, Axis{:qoi})
    n_qoi = size(x)[qoi_dim]

    # Initialize array to store results
    res = zeros(n_shift, n_Tmin, n_Tmax, n_qoi)

    for i = 1:n_shift, j = 1:n_Tmin, k = 1:n_Tmax
        res[i,j,k,:] = __rmse(x, y, shift[i], Tmin[j], Tmax[k]; kwargs...)
    end


    # Take argmin of shift for Ur
    min_idx = res[:,:,:,1:1] |> argmin |> (x -> x.I[1:end-1])

    # Take min of the mean over QOIs
    # min_idx = mean(res, dims=4) |> argmin |> (x -> x.I[1:end-1])

    min_rmse = res[min_idx...,:]

    best_params = (shift=shift[min_idx[1]],
                   Tmin=Tmin[min_idx[2]],
                   Tmax=Tmax[min_idx[3]])

    return min_rmse, best_params

end

#############################################################################

function axesdict(x::AxisArray)
    # Get dictionary with axis name, values as key, value

    ax = AxisArrays.axes(x)

    ax_names = (collect ∘ zip)(axisnames.(ax)...)[1]
    ax_values = (x -> x.val).(ax)

    return Dict(ax_names .=> ax_values)
end

# Compute f while ignoring missing values
f_missing(f, x; dims=:, kwargs...) = _f_missing(f, x, dims, kwargs...)
f_missing(f) = (f ∘ skipmissing)

# Compute mean, ignoring missing
mean_missing(x; dims=:) = f_missing(mean, x, dims=dims)
# Can add any other function analogously

# Mask array when mask is either a function or BitArray
mask_array(x, mask::BitArray) = _mask_array(x, mask)
mask_array(x, mask::Function) = _mask_array(x, mask(x))
mask_array(x, ::Nothing) = x

@doc raw"""
    trim_array(x, Tmin, Tmax[; dim=1])

Trim array.

# Arguments
- `x`: Array to trim
- `Tmin`: Percentage to trim from the beginning of x
- `Tmax`: Percentage to trim from the end of x
- `dim=1`: Dimension to trim over. Default is to trim by rows.

```
"""
function trim_array(x, Tmin, Tmax; dim=1)

    @assert Tmin >= 0 "Tmin must be >= 0."
    @assert Tmax <= 1 "Tmax must be <= 1."
    @assert Tmin <= Tmax "Tmin should be <= Tmax."

    Tmin_idx = _get_trim_index(x, Tmin)
    Tmax_idx = _get_trim_index(x, Tmax)

    return selectdim(x, dim, Tmin_idx:Tmax_idx)
end

function mean_max_distance(x; dims=1)
    
    x_max = maximum(x, dims=dims)
    x_min = minimum(x, dims=dims)

    return mean(max.(x_max .- x, x .- x_min).^2, dims=dims)
end


function timeshift_penalty(x, shift=0, Tmin=0.2, Tmax=0.8; var_measure=mean_max_distance,
                           max_shift=48, lambda=1.0, trim_first=false, kwargs...)
    
    x_ = _shift_trim(x, shift, Tmin, Tmax; trim_first=trim_first)
    
    penalty = (collect ∘ Iterators.flatten)(
        (shift/max_shift)^2 * var_measure(x_; kwargs...)
    )

    return lambda .* penalty 
end

# Compute RMSE with options to shift, trim, and mask x, y
function rmse(x, y; shift=0, Tmin=0.0, Tmax=1.0, mask=nothing,
              copy=true, dims=2, normalize=false, penaltyfunc=nothing,
              penalty_kwargs=Dict(:dims=>1), penalize_x=true)
    return _rmse(x, y, shift, Tmin, Tmax, mask=mask, copy=copy,
                 dims=dims, normalize=normalize, penaltyfunc=penaltyfunc,
                 penalty_kwargs=penalty_kwargs, penalize=true)
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
    compute_metrics,
    _get_trim_index,
    trim_array

end
