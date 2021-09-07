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

# ╔═╡ 94ef1e6a-0a78-11ec-0239-2bf8e9421657
begin
	using Pkg
	Pkg.activate("../Project.toml")
	
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
	
	
	md"""
	## Loaded all packages
	"""
end

# ╔═╡ f6a6bc59-49ab-4833-acd1-db328bb3d900
md"""
These are event lists dated 2021/07/30 and follow on with next 500 runs from the 100 runs of 2021/07/21 event list. Here, the GridResolution parameter is added as well, and changed to 1.5. Much of the processing is identical to 2021/07/21 notebook!
"""

# ╔═╡ e3ee5864-b573-434f-a8f8-9a4b0cdcaf1e
nbsp = html"&nbsp"

# ╔═╡ d0b4f889-cd38-4ddf-8129-55afeed12eb4
mg = "ADAPT"

# ╔═╡ 54a5dd4c-44da-4e59-831e-f6d304e9ffcc
# crr and md are defined in the drop down cell code

# ╔═╡ abf96fd8-6e3d-4a2a-a714-23103663d563
md"""
## Load Outputs and Filter QoIs
"""

# ╔═╡ e252d428-61cf-4115-95fb-49b38220f5bf
begin
	201
	202
	204
	205
	241
	
end

# ╔═╡ 72d35f11-e3ea-4511-b319-7ebbeeb6fbc2
cur_colors = palette(:default)

# ╔═╡ b489df77-0515-4df2-a952-92927b68b5ec
md"""
## Plot out input data points
"""

# ╔═╡ b6b09fb3-fc77-405e-83a7-6d46d0946dbe
begin
		nx = @bind name_x html"<select>
					<option value='BrFactor_ADAPT'>BrFactor_ADAPT</option>
					<option value='nChromoSiAWSoM'>nChromoSiAWSoM</option>
				  	<option value='PoyntingFluxPerBSi'>PoyntingFluxPerBSi</option>
					<option value='LperpTimesSqrtBSi'>LperpTimesSqrtBSi</option>
					<option value='StocasticExponent'>StochasticExponent</option>
					<option value='BrMin'>BrMin</option>
					<option value='rMinWaveReflection'>rMinWaveRefl</option>
				  	</select>"
	
	ny = @bind name_y html"<select>
					<option value='BrFactor_ADAPT'>BrFactor_ADAPT</option>
					<option value='nChromoSiAWSoM'>nChromoSiAWSoM</option>
				  	<option value='PoyntingFluxPerBSi'>PoyntingFluxPerBSi</option>
					<option value='LperpTimesSqrtBSi'>LperpTimesSqrtBSi</option>
					<option value='StocasticExponent'>StochasticExponent</option>
					<option value='BrMin'>BrMin</option>
					<option value='rMinWaveReflection'>rMinWaveRefl</option>
				  	</select>"
end

# ╔═╡ d0ef22dc-ac29-42b5-8662-b2513112dd7b
md"""

`x = ` $(nx) 		$nbsp $nbsp $nbsp $nbsp			`y = ` $(ny)
"""

# ╔═╡ 7da8863b-318b-4852-928a-f62e1e2c414e
md"""
Model = $(@bind md html"<select><option value='AWSoM'>AWSoM</option><option value='AWSoMR'>AWSoMR</option><option value='AWSoM2T'>AWSoM2T</option></select>") 	$nbsp $nbsp $nbsp $nbsp	
CR = $(@bind crr  html"<select><option value=2152>2152</option><option value=2208>2208</option></select>")

"""

# ╔═╡ 2fc34146-3028-4d7e-8a27-7636bb49ece4
cr = parse(Int64, crr)

# ╔═╡ 3e9bc254-949b-457e-8080-e0856c54901d
if cr==2152
	rotation="Max"
else
	rotation="Min"
end

# ╔═╡ 0c867740-388c-48f1-9c17-63790008f909
INPUTS_PATH = joinpath("../data/QMC_Data_for_event_lists/revised_thresholds/", "X_design_QMC_masterList_solar" * "$(rotation)" * "_" * "AWSoM" * "_" * "reducedThreshold.txt")

# ╔═╡ ffa01b3b-753c-4b2d-8428-ce25a3c314ad
begin
	ips, ipNames = readdlm(INPUTS_PATH, 
                        header=true, 
                        );
	ips = ips[101:600, 2:end]
	ipNames = ipNames[1:end-1]
	
	ipTable = DataFrame(ips, :auto);
	rename!(ipTable, vec(ipNames));

	REALIZATIONS_ADAPT = floor.(ipTable[:, :realization] * 11 .+ 1) .|> Int
	REALIZATIONS_ADAPT = [REALIZATIONS_ADAPT[i, :] for i in 1:size(ipTable, 1)]
	select!(ipTable, Not(:realization))
	insertcols!(ipTable, 10, :realization=>REALIZATIONS_ADAPT)

	first(ipTable, 6)
	
end

# ╔═╡ 4633d444-c283-4dfa-965d-f5005235d684
names(ipTable)

# ╔═╡ 93fe4add-6587-403f-a3b6-3eaca9a21e4f
md

# ╔═╡ fbf00268-ce40-446b-accd-a7a1d5f4086e
QOIS_PATH = joinpath("../Outputs/QoIs/code_v_2021_05_17/", "event_list_2021_07_30_" * md * "_CR" * "$(cr)")

# ╔═╡ fbb09344-3e54-44df-8c07-87e432ff125d
Ur = readdlm(joinpath(QOIS_PATH, "UrSim_earth.txt"))

# ╔═╡ dfdb62a5-9ada-49ca-9258-f643e191ac19
begin
	failed_runs = []
	for run in 1:size(Ur, 2)
		if Ur[:, run] == zeros(size(Ur, 1))
			push!(failed_runs, run)
		end
	end
end

# ╔═╡ 93d02ab2-086b-4f67-97e5-ae7732ae9fc0
failed_runs

# ╔═╡ e47dc7e8-5414-48a4-851c-d3259814c245
failed_runs .+ 100 # since run IDs ran from 101 to 600

# ╔═╡ dac3533b-c2a9-4458-8748-eb71aa919178
length(failed_runs)

# ╔═╡ 551e70e1-2cad-4835-bdcd-da57617fcc00
# Perform filtering operation for Ur
begin
	excluded_columns_Ur = []
	for run in 1:size(Ur, 2)
			exclude_idx = findall(x -> x < 200 || x > 900, Ur[:, run])
			push!(excluded_columns_Ur, exclude_idx)
	end
	
	
	excluded_runs_Ur = []
	for run in 1:size(Ur, 2)
		if length(excluded_columns_Ur[run]) > 0
			push!(excluded_runs_Ur, run)
		end
	end
	
end

# ╔═╡ 2ab3c86c-24ef-4df4-aaf5-5f86138ade6b
excluded_runs_Ur

# ╔═╡ 37873dfa-0f20-4815-9594-c0c822b6d2f6
excluded_runs_Ur .+ 100

# ╔═╡ ecd61b27-d044-46aa-a6af-1b29bf144734
Np = readdlm(joinpath(QOIS_PATH, "NpSim_earth.txt"))

# ╔═╡ b4ab60ce-552c-44c1-b010-89f0dafd3d8d
# Perform filtering operation for Np
begin
	excluded_columns_Np = []
	for run in 1:size(Np, 2)
			exclude_idx = findall(x -> x > 100, Np[:, run])
			push!(excluded_columns_Np, exclude_idx)
	end
	
	
	excluded_runs_Np = []
	for run in 1:size(Np, 2)
		if length(excluded_columns_Np[run]) > 0
			push!(excluded_runs_Np, run)
		end
	end
	
end

# ╔═╡ 967e4337-f145-4054-bf1a-a8bf0da59228
excluded_runs_Np

# ╔═╡ 412a2377-2b74-441a-bdff-76573540b751
excluded_runs = unique([excluded_runs_Ur;
				 excluded_runs_Np])

# ╔═╡ e3035ad4-aa52-47f9-bec1-3d028bc9779f
excluded_runs .+ 100

# ╔═╡ 10145b47-050f-4e15-9cc8-97146c2b214e
runs_to_keep = setdiff(101:600, excluded_runs .+ 100)

# ╔═╡ 3018c795-d75e-4dfc-98f8-ff4621de94f3
runs_to_keep .- 100

# ╔═╡ ba6b2ca2-15e9-49bc-8fd8-ad045bcd1ba4
length(runs_to_keep)

# ╔═╡ 4d52aac6-575e-4550-867d-f0fb9cd43ac6
length(excluded_runs) - length(failed_runs)

# ╔═╡ 4f871681-7460-4d9f-9503-fb4051e790b3
begin
	success = ipTable[Not(excluded_runs), :]
	failed = ipTable[failed_runs, :]
	excluded = ipTable[excluded_runs, :]	
	successful_and_excluded = ipTable[Not(failed_runs), :]
end

# ╔═╡ f5004d46-7e76-408f-b45a-a2e07335f857
UrObs = readdlm(joinpath(QOIS_PATH, "UrObs_earth_sta.txt"))[:, 1]

# ╔═╡ 5e524ad3-79da-40da-b7c0-dcebc43eebc1
NpObs = readdlm(joinpath(QOIS_PATH, "NpObs_earth_sta.txt"))[:, 1]

# ╔═╡ 336f895c-5dc3-407c-8f1d-9a8ca55fb5ef
RUNS_TO_KEEP_PATH = joinpath(QOIS_PATH, 
							 "runs_to_keep.txt")

# ╔═╡ e17dc384-c093-428b-8cff-c331a1c6324a
# Write run IDs to be retained to file
open(RUNS_TO_KEEP_PATH, "w") do io
	writedlm(io, runs_to_keep)
end

# ╔═╡ c90003ad-53c3-479c-9dc0-6555649f1260
# plot runs excluded by Ur as well as Np
begin      
            p1 = scatter(success[!, name_x], 
                    success[!, name_y],
                    label = "Successful Runs ",
                    markerstrokewidth=0)

            scatter!(excluded[!, name_x],
                     excluded[!, name_y], 
                     label = "Excluded Runs",
					 marker=cur_colors[3],
                     markerstrokewidth=0)
	
			scatter!(failed[!, name_x],
                     failed[!, name_y], 
                     label = "Failed Runs",
					 marker= cur_colors[2],
                     markerstrokewidth=0)
    
            annotate!(1.35 * minimum(ipTable[!, name_x]), 
                    1.01 * maximum(ipTable[!, name_y]), 
                    text("Successful", cur_colors[1], :above, 12, :bold))
            annotate!(0.5 * (minimum(ipTable[!, name_x]) + maximum(ipTable[!, name_x])), 
                    1.01 * maximum(ipTable[!, name_y]), 
                    text("Failed", cur_colors[2], :above, 12, :bold))
            annotate!(0.8 * maximum(ipTable[!, name_x]), 
                    1.01 * maximum(ipTable[!, name_y]), 
                    text("Excluded", cur_colors[3], :above, 12, :bold))

            plot!(xlabel=name_x, ylabel=name_y)
            plot!(legend=false)
			plot!(title="Inputs coloured by excluded runs for Np and Ur\n")
			plot!(figsize=(800, 600))

end 

# ╔═╡ 07983bdd-231b-467f-9400-9926f7147995
md"""
**Notes**:

Max:
 - lower values of Lperp?
 - excluded runs in lower right of parabola
   (this is consistent with where runs were marked last time around)

Min:
 - some excluded runs at boundary (like the last time)
 - but also some at the lower values of BrFactor
 - other factors don't seem to play much of a role?
"""

# ╔═╡ 7305a3e7-148c-461b-a352-9afcf0585523
begin
	UrSuccess = Ur[:, Not(excluded_runs)]
	ur_rmse_plot = plot(UrSuccess, label="", alpha = 0.25)
	# plot!(UrSuccess[:, common_retained], line=(2), label="")
	plot!(UrObs[:, 1], line=(:dash, :black, 3), label="Observation")
	
# 	NpSuccess = Np[:, Not(excluded_runs)]
# 	np_rmse_plot = plot(NpSuccess, label="", alpha = 0.25)
# 	# plot!(NpSuccess[:, common_retained], line=(2), label="")
# 	plot!(NpObs[NpObs .> 0, 1], line=(:dash, :black, 3), label="Observation")
	
# 	plot(ur_rmse_plot, np_rmse_plot, layout=(1, 2))
	
	
end

# ╔═╡ c1e4a9c8-9aff-488a-86d6-2ee5c62be80b
md"""
### Summary table for all models and CR (originally 100 runs in total per model)

Note: Excluded run indices are recorded on the basis of the command:

```julia
unique(excluded_runs_from_Ur, excluded_runs_from_Np)
```



| Model 	| CR   	| Failed Runs 	| Excluded Runs 	| Successful Runs 	|
|-------	|------	|-------------	|---------------	|-----------------	|
| AWSoM 	| 2152 	| 16          	| 52            	| 432             	|
| AWSoM 	| 2208 	| 25          	| 9             	| 466             	|


"""

# ╔═╡ cef088b3-122f-47b9-a8da-a5512430d4bc


# ╔═╡ ba795a53-fb66-43e6-a0ce-abc4614a8deb


# ╔═╡ f2502f6b-6177-4ae3-9c66-1491f27035f3


# ╔═╡ Cell order:
# ╟─f6a6bc59-49ab-4833-acd1-db328bb3d900
# ╠═94ef1e6a-0a78-11ec-0239-2bf8e9421657
# ╠═e3ee5864-b573-434f-a8f8-9a4b0cdcaf1e
# ╠═d0b4f889-cd38-4ddf-8129-55afeed12eb4
# ╠═2fc34146-3028-4d7e-8a27-7636bb49ece4
# ╠═3e9bc254-949b-457e-8080-e0856c54901d
# ╠═93fe4add-6587-403f-a3b6-3eaca9a21e4f
# ╠═54a5dd4c-44da-4e59-831e-f6d304e9ffcc
# ╠═0c867740-388c-48f1-9c17-63790008f909
# ╠═ffa01b3b-753c-4b2d-8428-ce25a3c314ad
# ╠═4633d444-c283-4dfa-965d-f5005235d684
# ╟─abf96fd8-6e3d-4a2a-a714-23103663d563
# ╠═fbf00268-ce40-446b-accd-a7a1d5f4086e
# ╠═fbb09344-3e54-44df-8c07-87e432ff125d
# ╠═ecd61b27-d044-46aa-a6af-1b29bf144734
# ╠═f5004d46-7e76-408f-b45a-a2e07335f857
# ╠═5e524ad3-79da-40da-b7c0-dcebc43eebc1
# ╠═dfdb62a5-9ada-49ca-9258-f643e191ac19
# ╠═93d02ab2-086b-4f67-97e5-ae7732ae9fc0
# ╠═e47dc7e8-5414-48a4-851c-d3259814c245
# ╠═e252d428-61cf-4115-95fb-49b38220f5bf
# ╠═551e70e1-2cad-4835-bdcd-da57617fcc00
# ╠═2ab3c86c-24ef-4df4-aaf5-5f86138ade6b
# ╠═37873dfa-0f20-4815-9594-c0c822b6d2f6
# ╠═b4ab60ce-552c-44c1-b010-89f0dafd3d8d
# ╠═967e4337-f145-4054-bf1a-a8bf0da59228
# ╠═412a2377-2b74-441a-bdff-76573540b751
# ╠═e3035ad4-aa52-47f9-bec1-3d028bc9779f
# ╠═10145b47-050f-4e15-9cc8-97146c2b214e
# ╠═3018c795-d75e-4dfc-98f8-ff4621de94f3
# ╠═ba6b2ca2-15e9-49bc-8fd8-ad045bcd1ba4
# ╠═336f895c-5dc3-407c-8f1d-9a8ca55fb5ef
# ╠═e17dc384-c093-428b-8cff-c331a1c6324a
# ╠═dac3533b-c2a9-4458-8748-eb71aa919178
# ╠═4d52aac6-575e-4550-867d-f0fb9cd43ac6
# ╠═72d35f11-e3ea-4511-b319-7ebbeeb6fbc2
# ╟─b489df77-0515-4df2-a952-92927b68b5ec
# ╟─b6b09fb3-fc77-405e-83a7-6d46d0946dbe
# ╠═4f871681-7460-4d9f-9503-fb4051e790b3
# ╟─d0ef22dc-ac29-42b5-8662-b2513112dd7b
# ╟─7da8863b-318b-4852-928a-f62e1e2c414e
# ╟─c90003ad-53c3-479c-9dc0-6555649f1260
# ╟─07983bdd-231b-467f-9400-9926f7147995
# ╠═7305a3e7-148c-461b-a352-9afcf0585523
# ╟─c1e4a9c8-9aff-488a-86d6-2ee5c62be80b
# ╠═cef088b3-122f-47b9-a8da-a5512430d4bc
# ╠═ba795a53-fb66-43e6-a0ce-abc4614a8deb
# ╠═f2502f6b-6177-4ae3-9c66-1491f27035f3
