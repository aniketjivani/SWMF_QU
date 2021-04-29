using JLD, CSV, AxisArrays, DataFrames

# Load data
traj_array = load("output/qoi_arrays.jld", "traj");
obs_array = load("output/qoi_arrays.jld", "obs");


function make_dataframe(x)

    axes_tuple = map((z -> z.val), x.axes)
    idx_names = (collect ∘ zip)(axisnames.(x.axes)...)[1]

    df = (collect ∘ Iterators.product)(axes_tuple...)[:] .|>
        NamedTuple{idx_names} |> DataFrame
    df[:value] = x[:]

    return df
end

traj_df = make_dataframe(traj_array)
select!(traj_df, [:qoi, :mapCR, :model, :run, :t, :value])
CSV.write("output/simulation_traj.csv", traj_df)

obs_df = make_dataframe(obs_array)
select!(obs_df, [:qoi, :mapCR, :model, :t, :value])
CSV.write("output/observed_traj.csv", obs_df)
