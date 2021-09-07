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

# ╔═╡ ee4b427e-ea14-11eb-1f25-a30bc54df7b9
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

# ╔═╡ c7da7cbb-4668-4d8c-993a-a3a39ee7d18b
html"""
<style>
  main {
    max-width: 1000px;
  }
</style>
"""

# ╔═╡ aaa5068a-84b9-49fc-b51c-210466b5e00f
mg = "ADAPT"

# ╔═╡ 57866166-b213-46d0-946a-f7c8ea5ffb55
md"""
## Load Inputs
"""

# ╔═╡ 52ffe397-b2d2-4b25-88ef-8a357c934232
md"""
## Load Outputs and Filter QoIs
"""

# ╔═╡ 656c2b6c-a8e8-4241-b33b-99ce8672451b


# ╔═╡ fed64699-ab2e-4946-afe9-e2c502024c1c


# ╔═╡ e76d0a1a-7adf-4a7e-a35e-9499704be0c7
md"""
## Save indices of successful runs to file
"""

# ╔═╡ 77f0e30c-666f-42e2-b5e7-44d1e770fe4b
md"""
## Plot Input values 
"""

# ╔═╡ e3e8ad93-f7b9-4a62-bab3-10c65a33fd22
cur_colors = palette(:default)

# ╔═╡ 014c54b1-0f63-400e-bf9e-ec6bf163801e
@bind QOI Select(["Ur", "Np"])

# ╔═╡ 0fe6665c-d792-4717-9014-b26f23331aad
begin
	nbsp = html"&nbsp"
# 	md"""

# 	`SELECTED_RUN = ` $(selected_run)	$nbsp $nbsp $nbsp	`SELECTED_QOI = ` $(QOI)
# 	"""
	md"""
	`SELECTED_QOI = ` $(QOI)
	"""
end

# ╔═╡ 39e07ae9-0e88-4f4f-9595-91e8f55b04af
md"""
Model = $(@bind md html"<select><option value='AWSoM'>AWSoM</option><option value='AWSoMR'>AWSoMR</option><option value='AWSoM2T'>AWSoM2T</option></select>") 	$nbsp $nbsp $nbsp $nbsp	CR = $(@bind crr  html"<select><option value=2152>2152</option><option value=2208>2208</option></select>")

"""

# ╔═╡ 90340db6-263a-4df7-b74a-7aa8a324f6e7
cr = parse(Int64, crr)

# ╔═╡ fd94981d-ff02-414f-ae34-e0d53379f1f4
if cr==2152
	rotation="Max"
else
	rotation="Min"
end

# ╔═╡ 560a5630-1d48-45a4-b6b8-774ebb216ba7
md

# ╔═╡ 9cbe13ce-c9a9-4c93-ac23-dc0f8959333e
crr

# ╔═╡ 4d5235a1-f1aa-4a0f-aa73-d4af871cd1b6
if md=="AWSoM" || md=="AWSoM2T"
	INPUTS_PATH = joinpath("../data/QMC_Data_for_event_lists/revised_thresholds/", "X_design_QMC_masterList_solar" * "$(rotation)" * "_" * "AWSoM" * "_" * "reducedThreshold.txt")
else
	INPUTS_PATH = joinpath("../data/QMC_Data_for_event_lists/revised_thresholds/", "X_design_QMC_masterList_solar" * "$(rotation)" * "_" * "AWSoMR" * "_" * "reducedThreshold.txt")
end

# ╔═╡ 56174c5f-c6d5-4af1-9b12-420bbff19d9b
INPUTS_PATH

# ╔═╡ f20a6915-fb41-4f12-a133-544f4001a158
begin
	ips, ipNames = readdlm(INPUTS_PATH, 
                        header=true, 
                        );
	ips = ips[1:100, 2:end]
	ipNames = ipNames[1:end-1]
	
	ipTable = DataFrame(ips, :auto);
	rename!(ipTable, vec(ipNames));

	REALIZATIONS_ADAPT = floor.(ipTable[:, :realization] * 11 .+ 1) .|> Int
	REALIZATIONS_ADAPT = [REALIZATIONS_ADAPT[i, :] for i in 1:size(ipTable, 1)]
	select!(ipTable, Not(:realization))
	insertcols!(ipTable, 10, :realization=>REALIZATIONS_ADAPT)

	first(ipTable, 6)
	
end

# ╔═╡ 46c971a0-8039-41d6-8d23-1c614ff46ffe
names(ipTable)

# ╔═╡ cf5cc995-8ea2-43e6-ba47-9655abe38bad
QOIS_PATH = joinpath("../Outputs/QoIs/code_v_2021_05_17/", "event_list_2021_07_11_" * md * "_CR" * "$(cr)")

# ╔═╡ 2f53ab7b-cf4a-4805-a2a1-d8d5ed4b2912
Ur = readdlm(joinpath(QOIS_PATH, "UrSim_earth.txt"))

# ╔═╡ d169c7e8-4e7d-45f9-ad59-b49ca2c63b68
begin
	failed_runs = []
	for run in 1:size(Ur, 2)
		if Ur[:, run] == zeros(size(Ur, 1))
			push!(failed_runs, run)
		end
	end
end

# ╔═╡ 7760cc47-ae56-49e6-a935-17df1412c30a
failed_runs

# ╔═╡ b89c0bc7-a41a-470b-9ff0-045ae8fac9cf
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

# ╔═╡ 6f84f97a-ddf5-4944-afa1-1e98dec708db
excluded_runs_Ur

# ╔═╡ 9b57168c-3a69-47c3-8581-bb369f76184c
Np = readdlm(joinpath(QOIS_PATH, "NpSim_earth.txt"))

# ╔═╡ 541ac05f-35fd-43fc-a657-9121d043eb26
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

# ╔═╡ 0c602587-ddd1-48da-a105-ef1a5261eb21
excluded_runs_Np

# ╔═╡ d93fdc60-139c-4874-b805-766d850ddb77
# Note: excluded runs will also contain failed runs automatically thanks to condition for Ur, so plot these at the last. 
excluded_runs = unique([excluded_runs_Ur;
				 excluded_runs_Np])

# ╔═╡ fe3f875e-f103-4e55-9632-14c1a42554a6
runs_to_keep = setdiff(1:100, excluded_runs)

# ╔═╡ 75ef75c8-e085-43ef-bd43-058167221da0
length(runs_to_keep)

# ╔═╡ cdeb145b-142a-483e-bc74-68e8ea575635
length(excluded_runs)

# ╔═╡ 2468f1d2-e2c7-4477-9e8f-cfd54a23cec5
begin
	success = ipTable[Not(excluded_runs), :]
	failed = ipTable[failed_runs, :]
	excluded = ipTable[excluded_runs, :]	
	successful_and_excluded = ipTable[Not(failed_runs), :]
end

# ╔═╡ 65b56149-b4b7-4b61-a9aa-e340763134d4
UrObs = readdlm(joinpath(QOIS_PATH, "UrObs_earth_sta.txt"))[:, 1]

# ╔═╡ e04eaa92-597f-4089-9ec1-347864c16d22
NpObs = readdlm(joinpath(QOIS_PATH, "NpObs_earth_sta.txt"))[:, 1]

# ╔═╡ 46bdd132-8259-4f79-9770-34540a99f23e
RUNS_TO_KEEP_PATH = joinpath(QOIS_PATH, 
							 "runs_to_keep.txt")

# ╔═╡ 1a19de10-d24a-48b0-a319-289d2cad588d
# Write run IDs to be retained to file
open(RUNS_TO_KEEP_PATH, "w") do io
	writedlm(io, runs_to_keep)
end

# ╔═╡ 6f9f0e1f-efac-4ca0-8248-40cb088cedad
if md=="AWSoM" || md=="AWSoM2T"
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
	
	# ny = @bind name_y html"<select>
	# 				  <option value='PoyntingFluxPerBSi'>PoyntingFluxPerBSi</option>
	# 				  </select>"
	
else
	nx = @bind name_x html"<select>
					<option value='BrFactor_ADAPT'>BrFactor_ADAPT</option>
					<option value='rMin_AWSoMR'>rMin_AWSoMR</option>
				  	<option value='PoyntingFluxPerBSi'>PoyntingFluxPerBSi</option>
					<option value='LperpTimesSqrtBSi'>LperpTimesSqrtBSi</option>
					<option value='StocasticExponent'>StochasticExponent</option>
					<option value='BrMin'>BrMin</option>
					<option value='rMinWaveReflection'>rMinWaveRefl</option>
				  	</select>"
	
	ny = @bind name_y html"<select>
					<option value='BrFactor_ADAPT'>BrFactor_ADAPT</option>
					<option value='rMin_AWSoMR'>rMin_AWSoMR</option>
				  	<option value='PoyntingFluxPerBSi'>PoyntingFluxPerBSi</option>
					<option value='LperpTimesSqrtBSi'>LperpTimesSqrtBSi</option>
					<option value='StocasticExponent'>StochasticExponent</option>
					<option value='BrMin'>BrMin</option>
					<option value='rMinWaveReflection'>rMinWaveRefl</option>
				  	</select>"
	
	# ny = @bind name_y html"<select>
	# 				  <option value='PoyntingFluxPerBSi'>PoyntingFluxPerBSi</option>
	# 				  </select>"
end

# ╔═╡ 67e649e1-628c-4e0a-a29f-2c237bb66a3c
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

# ╔═╡ 2e83156f-e2ee-49a5-a14e-1af8554a25da
md"""
Make plot coloured by the normalized threshold
"""

# ╔═╡ 572b5823-705e-45a3-884c-dd3f45227308
# begin 
#             p2 = scatter(success[!, name_x], 
#                     	 success[!, name_y],
#                     	 zcolor = chosen_metrics[!, "rmse_" * "$(QOI)"],
# 						 # marker = (:star5, 4),
# 						 marker = (:circle, 4),
#                     	 markerstrokewidth=0,
# 						 label="")
			
# 			scatter!(excluded[!, name_x],
# 					 excluded[!, name_y],
# 					 marker=(:hexagon, cur_colors[3], 8),
# 					 markerstrokewidth=0,
# 					 label="")
	
# 			scatter!(failed[!, name_x],
# 					 failed[!, name_y],
# 					 marker=(:diamond, cur_colors[2], 8),
# 					 markerstrokewidth=0,
# 					 label="")
	
# 			scatter!([success[min_rmse_idx, name_x]],
# 					 [success[min_rmse_idx, name_y]],
# 					 marker=(:circle, :magenta, 6),
# 					 markerstrokealpha = 0.4,
# 					 markerstrokewidth = 3,
# 					 label=""
# 					 # label="Min RMSE Run $(min_rmse_idx)"
# 					 )
	
# 			scatter!([success[max_rmse_idx, name_x]],
# 					 [success[max_rmse_idx, name_y]],
# 					 marker=(:circle, :cyan, 6),
# 					 markerstrokealpha = 0.4,
# 					 markerstrokewidth = 3,
# 					 label=""
# 					 # label="Max RMSE Run $(max_rmse_idx)"
# 					 )

#             plot!(xlabel=name_x, ylabel=name_y)
#             # plot!(legend=false)
# 			plot!(title="RMSE for " * "$(QOI)" * "\n")
# 			plot!(figsize=(900, 600))
	
# 			annotate!(0.5 * (minimum(ipTable[!, name_x]) + maximum(ipTable[!, name_x])), 
# 				1.005 * maximum(ipTable[!, name_y]), 
# 				text("Failed", cur_colors[2], :above, 13, :bold))
# 			annotate!(0.8 * maximum(ipTable[!, name_x]), 
# 				1.005 * maximum(ipTable[!, name_y]), 
# 				text("Excluded", cur_colors[3], :above, 13, :bold))

# 			plot!(figsize=(800, 600))
# 			# plot(p2, p2_sim_obs, figsize=(900, 600), layout=(1, 2))

# end 

# ╔═╡ 272228cb-8270-44fa-888a-8721ffa43e72
md"""
## Summary table for parameter ranges (Ur and Np)

We constrain the RMSE to lie below a certain threshold and see changes in parameter ranges accordingly for both Ur and Np. The disadvantage is i) that we are not covering the full sample space and ranges may fluctuate wildly without uncovering anything meaningful ii) Very few samples are retained for a high threshold. 

"""

# ╔═╡ bb742ff7-5617-409b-a471-088efee10704
md"""
We try normalizations based on difference in min and max values, mean, σ and IQR of the observations.
"""

# ╔═╡ 1b45e9b0-a973-46a4-ad71-071c352a2334
normalization = (diff ∘ collect ∘ extrema)

# ╔═╡ b5e923ee-30fb-49b1-8d63-533777c06d47
threshold_Ur = 90
# threshold_Ur for cr2152, awsom = 70

# ╔═╡ 564d240a-95cf-4253-aeb8-ed268ffbe379
threshold_Np = 7

# ╔═╡ 9d4c611e-60c5-4ddb-8085-8e82c84d5b2e
md"""

`x = ` $(nx) 		$nbsp $nbsp $nbsp $nbsp			`y = ` $(ny)
"""

# ╔═╡ 145b21ae-dd12-47c3-9778-7c9159921aa4


# ╔═╡ 104a9fd9-1377-4fd1-8280-45ef166a9a91


# ╔═╡ 93483fd5-04e8-4526-838b-e1fbe9ef7b77
ipTable_extrema = mapcols(col -> extrema(col), ipTable)

# ╔═╡ c7eceb13-7664-4411-a109-58708f9875e9
md"""

**Solar Max, AWSoM**

thresholdNp = 7

| Parameter          	| Original Range 	| Range in samples   	| Range after filtering (thresholdUr=70) 20 Runs 	| Range after filtering (thresholdUr=90) 40 Runs 	|
|--------------------	|----------------	|--------------------	|------------------------------------------------	|------------------------------------------------	|
| BrMin              	| [0, 10]        	| [0.034, 9.95]      	| [0.27, 9.67]                                   	| [0.14, 9.95]                                   	|
| BrFactor_ADAPT     	| [0.54, 2.7]    	| [0.54, 1.78]       	| [0.68, 1.51]                                   	| [0.55, 1.73]                                   	|
| nChromoSi_AWSoM    	| [2e17, 5e18]   	| [2.15e17, 4.97e18] 	| [5.83e17, 4.74e18]                             	| [3.15e17, 4.89e18]                             	|
| PoyntingFluxPerBSi 	| [0.3e6, 1.1e6] 	| [0.3e6, 1.02e6]    	| [0.3e6, 6.04e5]                                	| [0.3e6, 7.8e5]                                 	|
| LperpTimesSqrtBSi  	| [0.3e5, 3e5]   	| [0.3e5, 2.99e5]    	| [0.8e5, 2.96e5]                                	| [0.38e5, 2.96e5]                               	|
| StochasticExponent 	| [0.1, 0.34]    	| [0.107, 0.33]      	| [0.107, 0.33]                                  	| [0.107, 0.33]                                  	|
| rMinWaveReflection 	| [1, 1.2]       	| [1.05, 1.19]       	| [1.07, 1.19]                                   	| [1.07, 1.19]                                   	|
**Solar Min, AWSoM (19 runs)**

thresholdUr = 100, 

thresholdNp = 7

| Parameter          	| Original Range 	| Range in samples  	| Range after filtering 	|
|--------------------	|----------------	|-------------------	|-----------------------	|
| BrMin              	| [0, 10]        	| [0.034, 9.98]     	| [0.034, 9.98]         	|
| BrFactor_ADAPT     	| [0.54, 2.7]    	| [0.55, 2.69]      	| [0.61, 2.13]          	|
| nChromoSi_AWSoM    	| [2e17, 5e18]   	| [2.2e17, 4.97e18] 	| [6.07e17, 4.56e18]    	|
| PoyntingFluxPerBSi 	| [0.3e6, 1.1e6] 	| [0.3e6, 1.09e6]   	| [0.3e6, 6.04e5]       	|
| LperpTimesSqrtBSi  	| [0.3e5, 3e5]   	| [0.3e5, 2.97e5]   	| [0.3e5, 2.97e5]       	|
| StochasticExponent 	| [0.1, 0.34]    	| [0.107, 0.33]     	| [0.107, 0.33]         	|
| rMinWaveReflection 	| [1, 1.2]       	| [1.06, 1.19]      	| [1.08, 1.18]          	|

"""

# ╔═╡ d8f89798-e071-4a9f-ad45-6fd6e1596450
md"""
**CURRENT SELECTION**
1) **Model** = $(md)

2) **CR** = $(cr)

3) **Number of failed runs** =  $(length(failed_runs))

4) **Number of excluded runs (on Ur and Np criteria)** =  $(length(excluded_runs) - length(failed_runs))
"""

# ╔═╡ 860df494-d165-4879-9acd-6be43d5cd55c
md"""
### Summary table for all models and CR (originally 100 runs in total per model)

Note: Excluded run indices are recorded on the basis of the command:

```julia
unique(excluded_runs_from_Ur, excluded_runs_from_Np)
```

If we remove the `unique` and then perform the tabulation, AWSoMR 2152 is the only case that records excluded runs common to both Ur and Np, with the count jumping from 41 to 48. - these runs have the indices 5, 9, 50, 59, 65, 72, 80


| Model   	| CR   	| Failed Runs 	| Excluded Runs 	|
|---------	|------	|-------------	|---------------	|
| AWSoM   	| 2152 	| 2           	| 7             	|
| AWSoMR  	| 2152 	| 2           	| 41            	|
| AWSoM2T 	| 2152 	| 0           	| 26            	|
| AWSoM   	| 2208 	| 0           	| 2             	|
| AWSoMR  	| 2208 	| 0           	| 9             	|
| AWSoM2T 	| 2208 	| 0           	| 11            	|

"""

# ╔═╡ 72e4df03-07d3-4c97-a10d-3cd0836b4443
md"""
## Accuracy comparison across different models
"""

# ╔═╡ 16054f36-47f4-4fbc-94d3-e8607f384835
METRICS_PATH = joinpath("../Outputs/QoIs/code_v_2021_05_17/", 
						"event_list_2021_07_11_" * md * "_CR" * "$(cr)",
						"metrics.csv")

# ╔═╡ ac0c7aa8-d1f7-46eb-9135-d3d5f195ceca
METRICS_PATH_NP = joinpath("../Outputs/QoIs/code_v_2021_05_17/", 
						"event_list_2021_07_11_" * md * "_CR" * "$(cr)",
						"metrics_Np.csv")

# ╔═╡ 39772e8c-e281-4c8b-9097-5cf37526e002
begin
	metrics = CSV.read(METRICS_PATH, DataFrame)[:, [:rmse_Ur, :rmse_Np, :rmse_B, :rmse_T, :shift, :Tmin, :Tmax]]
	metrics_successful = metrics[Not(excluded_runs), :]
	metrics_excluded = metrics[excluded_runs, :]
	
end

# ╔═╡ b9194f96-fe11-402c-b9b6-6a33773fa88a
begin
	metricsNp = CSV.read(METRICS_PATH_NP, DataFrame)[:, [:rmse_Np, :shift, :Tmin, :Tmax]]
	metricsNp_successful = metricsNp[Not(excluded_runs), :]
	metricsNp_excluded = metricsNp[excluded_runs, :]
end

# ╔═╡ f42b3413-3a57-445a-a099-b0e82c42a0c4
begin
	p3 = scatter(success[!, name_x], 
                    	 success[!, name_y],
                    	 marker_z = metricsNp_successful[!, :rmse_Np],
                    	 markerstrokewidth=0)
			
			scatter!(excluded[!, name_x],
					 excluded[!, name_y],
					 marker=(:hexagon, cur_colors[3], 8),
					 markerstrokewidth=0)
	
			scatter!(failed[!, name_x],
					 failed[!, name_y],
					 marker=(:diamond, cur_colors[2], 10),
					 markerstrokewidth=0)
			
	
			plot!(xlabel=name_x, ylabel=name_y)
            plot!(legend=false)
			plot!(title="RMSE for Np\n")
			plot!(figsize=(800, 600))
end

# ╔═╡ ee18252e-228b-4076-aed5-41fd547d022c
begin
	rmse_Ur = metrics_successful[!, :rmse_Ur]
	rmse_Np = metricsNp_successful[!, :rmse_Np]
end

# ╔═╡ 808cd142-cefe-4948-a7f8-ac393ace85a5
begin
	plotTitles = ["Usual", "Difference", "Mean", "Std", "IQR"]
	nrmseUr = [f(rmse_Ur)[1] for f in [(ones∘length), (diff∘collect∘extrema), mean, std, iqr]]
	nrmseNp = [f(rmse_Np)[1] for f in [(ones∘length), (diff∘collect∘extrema), mean, std, iqr]]
	
	normalized_plots = [plot() for i in 1:length(nrmseUr)]

	for i in 1:length(nrmseUr)
		normalized_plots[i] = scatter(rmse_Ur ./ nrmseUr[i], label="")
		scatter!(rmse_Np ./ nrmseNp[i], label="")
		plot!(title = plotTitles[i])
	end
	
end

# ╔═╡ f9e725c6-01fb-4768-902a-1e963186d459
begin
	plot(normalized_plots...)
end

# ╔═╡ 0bd16df3-1c8c-409e-89d4-2dc236f68a81
rmse_Ur_Np = 0.5 * (rmse_Ur ./ normalization(UrObs) + rmse_Np ./ normalization(NpObs))

# ╔═╡ 01521585-7563-482d-b54c-ad70baba7710
# Filter out rmse values that satisfy the constraint, and extract the ranges of the parameters accordingly

retained_idx_Ur = findall(x -> x <= threshold_Ur, rmse_Ur)

# ╔═╡ 7b42bdfb-e797-4ca0-a152-8e4215ee1fc2
retained_idx_Np = findall(x -> x <= threshold_Np, rmse_Np)

# ╔═╡ c8c42d6a-0d48-4aea-b87a-297e6fb1d47d
common_retained = intersect(retained_idx_Ur,
							retained_idx_Np)

# ╔═╡ 2f7359a4-223d-492b-ae7f-fc2f7630014c
length(common_retained)

# ╔═╡ 45a034d2-c55b-4653-b8d0-617404d25a70
begin
	UrSuccess = Ur[:, Not(excluded_runs)]
	ur_rmse_plot = plot(UrSuccess, label="", alpha = 0.2)
	plot!(UrSuccess[:, common_retained], line=(2), label="")
	plot!(UrObs[:, 1], line=(:dash, :black, 3), label="Observation")
	
	NpSuccess = Np[:, Not(excluded_runs)]
	np_rmse_plot = plot(NpSuccess, label="", alpha = 0.2)
	plot!(NpSuccess[:, common_retained], line=(2), label="")
	plot!(NpObs[NpObs .> 0, 1], line=(:dash, :black, 3), label="Observation")
	
	plot(ur_rmse_plot, np_rmse_plot, layout=(1, 2))
	
	
end

# ╔═╡ 1ee30715-1166-424e-bc75-f53b8b8002e4
begin
	successful_retained_rmse = success[common_retained, :]
	successful_retained_extrema = mapcols(col -> extrema(col), successful_retained_rmse)
end

# ╔═╡ e5b2d661-ce22-4db3-939e-71bc3d248b2b
begin
	scatter(success[common_retained, name_x],
			success[common_retained, name_y],
			xlabel=name_x,
			ylabel=name_y,
			marker=(:circle, 4),
			markerstrokewidth=0,
			zcolor = rmse_Ur[common_retained],
			label="")
end

# ╔═╡ 0a52b907-6ab7-40be-b3b4-f2428aa97631
md"""
## Write failed and excluded runs to file
"""

# ╔═╡ b166d07f-e5ea-4b06-ab99-b69bbaeadd40
RUNS_TO_REMOVE_PATH = joinpath(QOIS_PATH, 
							   "failed_and_excluded_runs.txt")

# ╔═╡ 18bfbf40-cbc7-4aa2-a957-cb6248c60ec1
open(RUNS_TO_REMOVE_PATH, "w") do io
	writedlm(io, excluded_runs)
end

# ╔═╡ 66d3492f-a6ca-49d4-9b51-c2d5988b85c7
md"""
## Miscellaneous and Notes
"""

# ╔═╡ a545cdbe-788b-4f86-b134-4b887bf2407f
md"""
 **Things to Do**

- add feature for highlighting line from QoI plot and highlighting point on i/p scatterplot based on `SELECTED_RUN` value - seems to be a bad idea, refresh takes a lot of time 

- add timeshifts calculated on basis of rmse Np - see if rmse value is different when we change input in VSC $(@bind timeshift_Np CheckBox()) 

- look at other parameter combinations and check if any of them produces distinct boundaries between more accurate and less accurate runs $(@bind param_combos CheckBox())

- make plots of ranges as affected by threshold on rmse for Ur alone or for threshold on normalized_RMSE for Ur and Np.
"""

# ╔═╡ 4af7dba4-45b7-42c1-ab0c-e316ac0c36a7
# accuracy of awsom vs 2t vs awsomr for same runs - min and max separately
# current plots coloured by rmse


# ╔═╡ fa656d9b-299c-4c5d-88ff-def51fb95370
# Plot QoIs colored blue and green based on the above plot


# ╔═╡ caeadbf2-92b0-48b9-8043-17d8f0533c91
begin
	
	if QOI == "Ur"
		chosen_metrics = metrics_successful
		chosen_metrics_excluded = metrics_excluded
		chosen_sim = Ur
		chosen_obs = UrObs
	else
		chosen_metrics = metricsNp_successful
		chosen_metrics_excluded = metricsNp_excluded
		chosen_sim = Np
		chosen_obs = NpObs
	end
end

# ╔═╡ 784961b8-279d-46a8-932b-ba147c7f8ccd
min_rmse_idx = argmin(chosen_metrics[!, "rmse_" * "$(QOI)"]) # Note that this run Idx is not from the original 1:100 indices, but only for the subset of successful runs 

# ╔═╡ 220a4d1b-17b3-444a-89c1-a69449ecbea7
max_rmse_idx = argmax(chosen_metrics[!, "rmse_" * "$(QOI)"])

# ╔═╡ 0f4e34b1-b662-4b7d-843a-b0ae721c5884
begin 
            p2 = scatter(success[!, name_x], 
                    	 success[!, name_y],
                    	 zcolor = chosen_metrics[!, "rmse_" * "$(QOI)"],
						 # marker = (:star5, 4),
						 marker = (:circle, 4),
                    	 markerstrokewidth=0,
						 label="")
			
			scatter!(excluded[!, name_x],
					 excluded[!, name_y],
					 marker=(:hexagon, cur_colors[3], 8),
					 markerstrokewidth=0,
					 label="")
	
			scatter!(failed[!, name_x],
					 failed[!, name_y],
					 marker=(:diamond, cur_colors[2], 8),
					 markerstrokewidth=0,
					 label="")
	
			scatter!([success[min_rmse_idx, name_x]],
					 [success[min_rmse_idx, name_y]],
					 marker=(:circle, :magenta, 6),
					 markerstrokealpha = 0.4,
					 markerstrokewidth = 3,
					 label=""
					 # label="Min RMSE Run $(min_rmse_idx)"
					 )
	
			scatter!([success[max_rmse_idx, name_x]],
					 [success[max_rmse_idx, name_y]],
					 marker=(:circle, :cyan, 6),
					 markerstrokealpha = 0.4,
					 markerstrokewidth = 3,
					 label=""
					 # label="Max RMSE Run $(max_rmse_idx)"
					 )

            plot!(xlabel=name_x, ylabel=name_y)
            # plot!(legend=false)
			plot!(title="RMSE for " * "$(QOI)" * "\n")
			plot!(figsize=(900, 600))
	
			annotate!(0.5 * (minimum(ipTable[!, name_x]) + maximum(ipTable[!, name_x])), 
				1.005 * maximum(ipTable[!, name_y]), 
				text("Failed", cur_colors[2], :above, 13, :bold))
			annotate!(0.8 * maximum(ipTable[!, name_x]), 
				1.005 * maximum(ipTable[!, name_y]), 
				text("Excluded", cur_colors[3], :above, 13, :bold))

			plot!(figsize=(800, 600))
			# plot(p2, p2_sim_obs, figsize=(900, 600), layout=(1, 2))

end 

# ╔═╡ 588768bc-bcfc-447a-8d55-adaa67bedfd5
begin
	chosen_sim_success = chosen_sim[:, Not(excluded_runs)]
	
	p2_sim_obs = plot(chosen_sim[:, Not(excluded_runs)], alpha = 0.3, label="")
	
	if cr==2208
		co = chosen_obs
		co_retained = co[co .> 0]
		plot!(co_retained, line=(:dash, :black, 3), label="Observation")
	else
		plot!(chosen_obs, line=(:dash, :black, 3), label="Observation")
	end
	
	
	# if selected_run in excluded_runs
	# 	chosenLineColor = cur_colors[3]
	# else
	# 	chosenLineColor = cur_colors[1]
	# end
	
	plot!(chosen_sim_success[:, min_rmse_idx], line=(:magenta, 3.5), label = "Min RMSE")
	plot!(chosen_sim_success[:, max_rmse_idx], line=(:cyan, 3.5), label = "Max RMSE")
end

# ╔═╡ 3bea1231-c190-4024-9dc6-cf98030172e9


# ╔═╡ Cell order:
# ╟─c7da7cbb-4668-4d8c-993a-a3a39ee7d18b
# ╠═ee4b427e-ea14-11eb-1f25-a30bc54df7b9
# ╠═aaa5068a-84b9-49fc-b51c-210466b5e00f
# ╠═90340db6-263a-4df7-b74a-7aa8a324f6e7
# ╠═fd94981d-ff02-414f-ae34-e0d53379f1f4
# ╠═560a5630-1d48-45a4-b6b8-774ebb216ba7
# ╠═9cbe13ce-c9a9-4c93-ac23-dc0f8959333e
# ╟─57866166-b213-46d0-946a-f7c8ea5ffb55
# ╠═4d5235a1-f1aa-4a0f-aa73-d4af871cd1b6
# ╠═56174c5f-c6d5-4af1-9b12-420bbff19d9b
# ╠═f20a6915-fb41-4f12-a133-544f4001a158
# ╠═46c971a0-8039-41d6-8d23-1c614ff46ffe
# ╠═52ffe397-b2d2-4b25-88ef-8a357c934232
# ╠═cf5cc995-8ea2-43e6-ba47-9655abe38bad
# ╠═656c2b6c-a8e8-4241-b33b-99ce8672451b
# ╠═2f53ab7b-cf4a-4805-a2a1-d8d5ed4b2912
# ╠═9b57168c-3a69-47c3-8581-bb369f76184c
# ╠═65b56149-b4b7-4b61-a9aa-e340763134d4
# ╠═e04eaa92-597f-4089-9ec1-347864c16d22
# ╠═d169c7e8-4e7d-45f9-ad59-b49ca2c63b68
# ╠═7760cc47-ae56-49e6-a935-17df1412c30a
# ╠═b89c0bc7-a41a-470b-9ff0-045ae8fac9cf
# ╠═6f84f97a-ddf5-4944-afa1-1e98dec708db
# ╠═fed64699-ab2e-4946-afe9-e2c502024c1c
# ╠═541ac05f-35fd-43fc-a657-9121d043eb26
# ╠═0c602587-ddd1-48da-a105-ef1a5261eb21
# ╠═d93fdc60-139c-4874-b805-766d850ddb77
# ╟─e76d0a1a-7adf-4a7e-a35e-9499704be0c7
# ╠═fe3f875e-f103-4e55-9632-14c1a42554a6
# ╠═75ef75c8-e085-43ef-bd43-058167221da0
# ╠═cdeb145b-142a-483e-bc74-68e8ea575635
# ╠═46bdd132-8259-4f79-9770-34540a99f23e
# ╠═1a19de10-d24a-48b0-a319-289d2cad588d
# ╟─77f0e30c-666f-42e2-b5e7-44d1e770fe4b
# ╠═e3e8ad93-f7b9-4a62-bab3-10c65a33fd22
# ╠═6f9f0e1f-efac-4ca0-8248-40cb088cedad
# ╠═2468f1d2-e2c7-4477-9e8f-cfd54a23cec5
# ╠═67e649e1-628c-4e0a-a29f-2c237bb66a3c
# ╠═39e07ae9-0e88-4f4f-9595-91e8f55b04af
# ╠═784961b8-279d-46a8-932b-ba147c7f8ccd
# ╠═220a4d1b-17b3-444a-89c1-a69449ecbea7
# ╠═014c54b1-0f63-400e-bf9e-ec6bf163801e
# ╟─0fe6665c-d792-4717-9014-b26f23331aad
# ╟─0f4e34b1-b662-4b7d-843a-b0ae721c5884
# ╟─2e83156f-e2ee-49a5-a14e-1af8554a25da
# ╟─572b5823-705e-45a3-884c-dd3f45227308
# ╠═588768bc-bcfc-447a-8d55-adaa67bedfd5
# ╟─f42b3413-3a57-445a-a099-b0e82c42a0c4
# ╟─272228cb-8270-44fa-888a-8721ffa43e72
# ╟─bb742ff7-5617-409b-a471-088efee10704
# ╠═808cd142-cefe-4948-a7f8-ac393ace85a5
# ╠═f9e725c6-01fb-4768-902a-1e963186d459
# ╠═1b45e9b0-a973-46a4-ad71-071c352a2334
# ╠═0bd16df3-1c8c-409e-89d4-2dc236f68a81
# ╠═b5e923ee-30fb-49b1-8d63-533777c06d47
# ╠═01521585-7563-482d-b54c-ad70baba7710
# ╠═564d240a-95cf-4253-aeb8-ed268ffbe379
# ╠═7b42bdfb-e797-4ca0-a152-8e4215ee1fc2
# ╠═c8c42d6a-0d48-4aea-b87a-297e6fb1d47d
# ╠═2f7359a4-223d-492b-ae7f-fc2f7630014c
# ╠═9d4c611e-60c5-4ddb-8085-8e82c84d5b2e
# ╠═e5b2d661-ce22-4db3-939e-71bc3d248b2b
# ╠═145b21ae-dd12-47c3-9778-7c9159921aa4
# ╠═104a9fd9-1377-4fd1-8280-45ef166a9a91
# ╠═45a034d2-c55b-4653-b8d0-617404d25a70
# ╠═1ee30715-1166-424e-bc75-f53b8b8002e4
# ╠═93483fd5-04e8-4526-838b-e1fbe9ef7b77
# ╟─c7eceb13-7664-4411-a109-58708f9875e9
# ╟─d8f89798-e071-4a9f-ad45-6fd6e1596450
# ╟─860df494-d165-4879-9acd-6be43d5cd55c
# ╟─72e4df03-07d3-4c97-a10d-3cd0836b4443
# ╠═16054f36-47f4-4fbc-94d3-e8607f384835
# ╠═ac0c7aa8-d1f7-46eb-9135-d3d5f195ceca
# ╠═39772e8c-e281-4c8b-9097-5cf37526e002
# ╠═ee18252e-228b-4076-aed5-41fd547d022c
# ╠═b9194f96-fe11-402c-b9b6-6a33773fa88a
# ╟─0a52b907-6ab7-40be-b3b4-f2428aa97631
# ╠═b166d07f-e5ea-4b06-ab99-b69bbaeadd40
# ╠═18bfbf40-cbc7-4aa2-a957-cb6248c60ec1
# ╟─66d3492f-a6ca-49d4-9b51-c2d5988b85c7
# ╠═a545cdbe-788b-4f86-b134-4b887bf2407f
# ╠═4af7dba4-45b7-42c1-ab0c-e316ac0c36a7
# ╠═fa656d9b-299c-4c5d-88ff-def51fb95370
# ╠═caeadbf2-92b0-48b9-8043-17d8f0533c91
# ╠═3bea1231-c190-4024-9dc6-cf98030172e9
