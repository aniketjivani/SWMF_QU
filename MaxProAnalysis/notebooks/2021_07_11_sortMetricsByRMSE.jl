### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 69117661-d1d7-49cf-8fee-da5e2026b029
begin
	# Activate project environment before starting analysis!
	using Pkg
	Pkg.activate("../Project.toml")
end

# ╔═╡ 06f995a4-1c8e-11ec-1994-6b1f01ff64a3
begin

	
	using Plots
	plotly()
	# gr()

	using DataFrames
	using CSV
	using IterTools

	using DelimitedFiles
	using Printf
	using Dates
	
	using PlutoUI
	
	
	using Statistics
	using StatsBase
	
	
end

# ╔═╡ 1e961fcd-49d5-433a-9e86-2e84c8e1dba5
md"""
## Load all packages
"""

# ╔═╡ 2e63e680-4007-4ee4-90b3-1da180c457be
mg = "ADAPT"

# ╔═╡ a44a1d15-2004-41e7-aa3e-ea2ea5e51be5
md = "AWSoM"

# ╔═╡ 4d083d7a-6825-4bba-8850-cb945f9f9505
@bind crr  html"<select><option value=2152>2152</option><option value=2208>2208</option></select>"

# ╔═╡ 43babe3d-17e3-4dcf-8a89-f42fb521f6f2
cr = parse(Int64, crr)

# ╔═╡ fe384fd1-2a97-47c6-912a-4c59c7189d47
if cr==2152
	rotation="Max"
else
	rotation="Min"
end

# ╔═╡ 5fa03570-84dd-47a5-91c9-c5404daf0ef8
md"""
## Give appropriate filepaths
"""

# ╔═╡ 20885d40-d9bd-4496-9528-5bef8283f543
INPUTS_PATH = joinpath("../data/QMC_Data_for_event_lists/revised_thresholds/", "X_design_QMC_masterList_solar" * "$(rotation)" * "_" * md * "_" * "reducedThreshold.txt")

# ╔═╡ 354084a9-41fa-4bee-8740-3d218be267ab
QOIS_PATH = joinpath("../Outputs/QoIs/code_v_2021_05_17/", "event_list_2021_07_11_" * md * "_CR" * "$(cr)")

# ╔═╡ b78758dc-5f0b-4ed8-9f25-3768f344a1f0
RUNS_TO_KEEP_PATH = joinpath(QOIS_PATH, 
							 "runs_to_keep.txt")

# ╔═╡ 2372346e-59ba-4bb1-a162-a5822ce79aed
METRICS_PATH = joinpath(QOIS_PATH, 
						"metrics.csv")

# ╔═╡ 571ea650-a055-4331-9fce-52f141a74741
METRICS_PATH_NP = joinpath(QOIS_PATH, 
						"metrics_Np.csv")

# ╔═╡ a7ec93c2-d1b9-4ecc-92ee-9779f22ca623
md"""
## Load all required files
"""

# ╔═╡ ac6bb938-fed8-4d56-9c1d-aa6c9c37014d
begin
	ips, ipNames = readdlm(INPUTS_PATH, 
                        header=true, 
                        );
	ips = ips[1:100, 2:end]
	ipNames = ipNames[1:end-1]
	
	ipTable = DataFrame(ips, :auto);
	rename!(ipTable, vec(ipNames));
	
	ipTable_downselect = ipTable[:, [:BrFactor_ADAPT, :PoyntingFluxPerBSi, 		:LperpTimesSqrtBSi]]
end

# ╔═╡ b18fe55e-1db6-49b6-a083-37a8f45bd21b
runs_to_keep = readdlm(RUNS_TO_KEEP_PATH, Int)[:]

# ╔═╡ 7dbf891f-9948-410b-8157-d7bb1a45d8a3
metricsUr = CSV.read(METRICS_PATH, DataFrame)[:, [:rmse_Ur, :shift]]

# ╔═╡ 4f7a4406-26d9-4fc4-8501-b1402bb8c2f1
metricsNp = CSV.read(METRICS_PATH_NP, DataFrame)[:, [:rmse_Np, :shift]]

# ╔═╡ 9f6df389-4513-4f51-9878-367f382b7101
md"""Join `ipTable_downselect` with each metric and get separate dataframes"""

# ╔═╡ 2f2d1f6e-4dad-4d54-b7da-eddb19eb71dd
begin
	RMSE_by_Ur = hcat(ipTable_downselect,
					  metricsUr)
end

# ╔═╡ 2843ad2c-c834-4522-9462-eb309c0b7e34
begin
	RMSE_by_Np = hcat(ipTable_downselect, 
					  metricsNp)
end

# ╔═╡ 28709785-4132-4359-bd21-a08b7d148570
md"""
## Filter by RMSE 
"""

# ╔═╡ e693493d-8a77-475c-b59d-93d5b9be019b
md"""
Use `sortperm` to get the rows sorted by RMSE
"""

# ╔═╡ f9d22c63-195d-4866-97c1-215a812b2d3d
Ur_Sorted_idx = sortperm(metricsUr, :rmse_Ur)

# ╔═╡ d61fdfb4-700e-4a19-ae1c-8e0054410277
md""" 
But then filter out runs we don't want
"""

# ╔═╡ 164f91ed-ed8b-4360-a47d-638cfa96d7ba
excluded_runs = setdiff(1:100, runs_to_keep)

# ╔═╡ 25a37f4f-5315-4820-94cc-2cde10750b0a
Ur_Sorted_idx_Final = setdiff(Ur_Sorted_idx, excluded_runs)

# ╔═╡ 2a40f90c-e06e-4bb7-a9f0-933ecd96e2ab
md"""
Repeat this process for Np!!
"""

# ╔═╡ ecfebe5d-228f-40b8-91af-c09001f455be
Np_Sorted_idx = sortperm(metricsNp, :rmse_Np)

# ╔═╡ 1cd19399-65c4-4d89-9817-106c6c50876b
Np_Sorted_idx_Final = setdiff(Np_Sorted_idx, excluded_runs)

# ╔═╡ d7b4f3f6-0112-4a80-b662-c3701a9a8452
md"""Sort inputs by Ur and Np"""

# ╔═╡ 6c1c1355-e21c-463f-b718-3231081afa00
RMSE_by_Ur_Sorted = RMSE_by_Ur[Ur_Sorted_idx_Final, :]

# ╔═╡ 9c780352-4453-4ae2-a051-ee8903803bf8
RMSE_by_Np_Sorted = RMSE_by_Np[Np_Sorted_idx_Final, :]

# ╔═╡ 1b82fd7a-f0ef-4d82-acd8-97b29b9fbf8c
md"""Add columns for respective run IDs to keep track!!"""

# ╔═╡ 98ec1d9b-c9dc-45ad-b21b-6f121cb512f6
RMSE_by_Ur_Sorted_Final = hcat(RMSE_by_Ur_Sorted, 
						 DataFrame(:runID => Ur_Sorted_idx_Final))

# ╔═╡ bc3cf4dc-c366-400e-ac97-7ae2a92e61bc
RMSE_by_Np_Sorted_Final = hcat(RMSE_by_Np_Sorted, 
						 DataFrame(:runID => Np_Sorted_idx_Final))

# ╔═╡ 1712cc04-03bc-4ed2-b178-71c30f272d00
md"""
## Make Plots to Verify (see if sorted runs are "close")

**Note**: QoIs are plotted as they are, to see them aligned, we need to apply shift according to the columns in the dataframes above
"""

# ╔═╡ 746a96c9-829f-475a-91c5-fc1e23f81509
Ur = readdlm(joinpath(QOIS_PATH, "UrSim_earth.txt"))

# ╔═╡ 371ab850-83c8-4629-8bfd-31832715076b
Np = readdlm(joinpath(QOIS_PATH, "NpSim_earth.txt"))

# ╔═╡ e72d506b-77ca-4f75-9d89-e192d0f4747f
UrObs = readdlm(joinpath(QOIS_PATH, "UrObs_earth_sta.txt"))[:, 1]

# ╔═╡ fc7f32c5-a150-4111-a50c-694f6bac08b7
NpObs = readdlm(joinpath(QOIS_PATH, "NpObs_earth_sta.txt"))[:, 1]

# ╔═╡ 7b5b3857-26f2-4134-9745-7f9e517b477b
begin
	plot(Ur[:, Ur_Sorted_idx_Final[1:15]], label="")
	plot!(UrObs, line=(:black, :dash, 3), label="Observation")
end

# ╔═╡ 9cf0a541-2143-4f4e-9362-59a66609921e
begin
	plot(Np[:, Np_Sorted_idx_Final[1:15]], label="")
	plot!(NpObs[NpObs.>0], line=(:black, :dash, 3), label="Observation")
end

# ╔═╡ b86384a5-1562-49a9-b990-b6fcb7b52434
md"""
## Write to file
"""

# ╔═╡ 7b85f445-2d83-437b-89cf-a0bbdb2189ae
CSV.write(joinpath(QOIS_PATH, 
				   "RMSE_by_Ur_Sorted_Final.csv"),
		  RMSE_by_Ur_Sorted_Final)

# ╔═╡ 5adf11ab-872a-4b5f-b250-0d32a1abecc6
CSV.write(joinpath(QOIS_PATH, 
				   "RMSE_by_Np_Sorted_Final.csv"),
		  RMSE_by_Np_Sorted_Final)

# ╔═╡ d0ebc2c5-c641-4f74-b1cd-f2d33e70f4f2


# ╔═╡ 52a619ca-d641-474a-a016-73fa0f5837ed
md"""
## Miscellaneous
"""

# ╔═╡ 789ee760-72e5-46af-a864-397d9b0ef7f9
nbsp = html"&nbsp"

# ╔═╡ Cell order:
# ╟─1e961fcd-49d5-433a-9e86-2e84c8e1dba5
# ╠═69117661-d1d7-49cf-8fee-da5e2026b029
# ╠═06f995a4-1c8e-11ec-1994-6b1f01ff64a3
# ╠═fe384fd1-2a97-47c6-912a-4c59c7189d47
# ╠═2e63e680-4007-4ee4-90b3-1da180c457be
# ╠═a44a1d15-2004-41e7-aa3e-ea2ea5e51be5
# ╠═4d083d7a-6825-4bba-8850-cb945f9f9505
# ╠═43babe3d-17e3-4dcf-8a89-f42fb521f6f2
# ╟─5fa03570-84dd-47a5-91c9-c5404daf0ef8
# ╠═20885d40-d9bd-4496-9528-5bef8283f543
# ╠═354084a9-41fa-4bee-8740-3d218be267ab
# ╠═b78758dc-5f0b-4ed8-9f25-3768f344a1f0
# ╠═2372346e-59ba-4bb1-a162-a5822ce79aed
# ╠═571ea650-a055-4331-9fce-52f141a74741
# ╟─a7ec93c2-d1b9-4ecc-92ee-9779f22ca623
# ╠═ac6bb938-fed8-4d56-9c1d-aa6c9c37014d
# ╠═b18fe55e-1db6-49b6-a083-37a8f45bd21b
# ╠═7dbf891f-9948-410b-8157-d7bb1a45d8a3
# ╠═4f7a4406-26d9-4fc4-8501-b1402bb8c2f1
# ╟─9f6df389-4513-4f51-9878-367f382b7101
# ╠═2f2d1f6e-4dad-4d54-b7da-eddb19eb71dd
# ╠═2843ad2c-c834-4522-9462-eb309c0b7e34
# ╟─28709785-4132-4359-bd21-a08b7d148570
# ╟─e693493d-8a77-475c-b59d-93d5b9be019b
# ╠═f9d22c63-195d-4866-97c1-215a812b2d3d
# ╟─d61fdfb4-700e-4a19-ae1c-8e0054410277
# ╠═164f91ed-ed8b-4360-a47d-638cfa96d7ba
# ╠═25a37f4f-5315-4820-94cc-2cde10750b0a
# ╟─2a40f90c-e06e-4bb7-a9f0-933ecd96e2ab
# ╠═ecfebe5d-228f-40b8-91af-c09001f455be
# ╠═1cd19399-65c4-4d89-9817-106c6c50876b
# ╟─d7b4f3f6-0112-4a80-b662-c3701a9a8452
# ╠═6c1c1355-e21c-463f-b718-3231081afa00
# ╠═9c780352-4453-4ae2-a051-ee8903803bf8
# ╟─1b82fd7a-f0ef-4d82-acd8-97b29b9fbf8c
# ╠═98ec1d9b-c9dc-45ad-b21b-6f121cb512f6
# ╠═bc3cf4dc-c366-400e-ac97-7ae2a92e61bc
# ╟─1712cc04-03bc-4ed2-b178-71c30f272d00
# ╠═746a96c9-829f-475a-91c5-fc1e23f81509
# ╠═371ab850-83c8-4629-8bfd-31832715076b
# ╠═e72d506b-77ca-4f75-9d89-e192d0f4747f
# ╠═fc7f32c5-a150-4111-a50c-694f6bac08b7
# ╠═7b5b3857-26f2-4134-9745-7f9e517b477b
# ╠═9cf0a541-2143-4f4e-9362-59a66609921e
# ╟─b86384a5-1562-49a9-b990-b6fcb7b52434
# ╠═7b85f445-2d83-437b-89cf-a0bbdb2189ae
# ╠═5adf11ab-872a-4b5f-b250-0d32a1abecc6
# ╠═d0ebc2c5-c641-4f74-b1cd-f2d33e70f4f2
# ╠═52a619ca-d641-474a-a016-73fa0f5837ed
# ╠═789ee760-72e5-46af-a864-397d9b0ef7f9
