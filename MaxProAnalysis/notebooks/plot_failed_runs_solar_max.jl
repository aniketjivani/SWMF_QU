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

# ╔═╡ c76ce670-0ea0-4d36-896f-105c51079928
begin
	using Pkg
	Pkg.activate("../Project.toml")
	
	using Plots
	gr()

	using DataFrames
	using CSV
	using IterTools

	using DelimitedFiles
	using Printf
	using Dates
end

# ╔═╡ f7446395-3c0a-4f73-afea-438f07576a79
Plots.reset_defaults()

# ╔═╡ c0e6912a-17cc-431b-9b0e-6b54e3480256
begin
	mg = "ADAPT"
	md = "AWSoM"
	cr = 2152
end

# ╔═╡ 0a1f12f9-69c9-43be-a351-714398305c95
begin
	ips, _ = readdlm("../data/MaxPro_inputs_outputs_event_list_2021_06_02_21.txt", ',', header=true)
	ipNames = ["BrFactor", 
		"nChromoSi", 
		"PoyntingFlux", 
		"Lperp", 
		"StochExp", 
		"BrMin", 
		"rMinWaveRefl", 
		"REALIZATIONS_ADAPT", 
		"PFSS", 
		"UseSurfaceWaveRefl",
		"Outcomes"]
end

# ╔═╡ 7eab8e8e-e39c-492b-a21f-3f4cffd5007f
begin
	ipTable = DataFrame(ips, :auto)
	rename!(ipTable, vec(ipNames))
	first(ipTable, 5)
end

# ╔═╡ 9f41d95a-4fdb-4514-b9e3-8655db9064fb
begin
	failedRuns   = [61, 104, 135, 137, 143, 148, 160, 182, 184]
	excludedRuns = [40, 43, 76, 86, 96, 110]
	removedRuns = vcat(failedRuns, 
					   excludedRuns)
end

# ╔═╡ b1bd3c8b-9e7d-406e-a6d3-44345a5b94bb
begin
	successfulRunInputs = ipTable[Not(failedRuns), :]
	failedRunInputs = ipTable[failedRuns, :]
	excludedRunInputs = ipTable[excludedRuns, :]
end

# ╔═╡ d6b27006-2c3d-4280-bc30-2c8f279438c1
# we remove all runs where Np value exceeds 100 - this left behind 69 runs out of a possible 191.
np_runs_to_keep = readdlm("../Outputs/QoIs/code_v_2021_05_17/event_list_2021_06_02_21/runs_to_keep.txt", Int64)[:]

# ╔═╡ 63d6bf11-581b-410e-b12a-b643a9f6e479
# these runs are removed on the basis of Ur being less than 200! (overall criterion is: 200 < Ur < 900 km / s)
np_more_runs_to_remove = [18, 24, 25, 37, 41, 53, 106, 127, 164, 173]

# ╔═╡ 19c1dadb-73dc-4c50-aa2a-27fcb845e117
ur_np_runs_to_keep = setdiff(np_runs_to_keep, np_more_runs_to_remove)

# ╔═╡ 99cc6e88-cac0-470c-bea3-b7906582c223
length(ur_np_runs_to_keep)

# ╔═╡ c22eecf1-420e-4e64-9547-7a93c4563d9c
ur_np_runs_to_remove = setdiff(1:200, ur_np_runs_to_keep)

# ╔═╡ e307a87b-4ccd-48a6-8957-381592c23adc
length(ur_np_runs_to_remove)

# ╔═╡ 89b6eb14-701e-4e13-b71d-726b0b47df9f
begin
	Ur = readdlm("../Outputs/QoIs/code_v_2021_05_17/event_list_2021_06_02_21/UrSim_earth.txt")
	Np = readdlm("../Outputs/QoIs/code_v_2021_05_17/event_list_2021_06_02_21/NpSim_earth.txt")
	UrObs = readdlm("../Outputs/QoIs/code_v_2021_05_17/event_list_2021_06_02_21/UrObs_earth_sta.txt")[:, 1]
	NpObs = readdlm("../Outputs/QoIs/code_v_2021_05_17/event_list_2021_06_02_21/NpObs_earth_sta.txt")[:, 1]
	
end

# ╔═╡ 4a0e3b87-f412-4efb-ade3-9f6b6e289e07
begin
	UrToKeep = Ur[:, ur_np_runs_to_keep]
	NpToKeep = Np[:, ur_np_runs_to_keep]
	
end

# ╔═╡ 0d870394-9ff1-4893-aa67-c00cc4736e73
begin
	# default(guidefont = (14, :match), tickfont = (12, :match), framestyle=:semi, titlefont=(20, :match), legendfont=:match)
	# plot(NpToKeep, label="")
	# plot!(NpObs, line=(:dash, :black, 2), label="Observation (OMNI)")
	# plot!(xlabel="Time Index", ylabel="Number Density Np")
end

# ╔═╡ 652708aa-a500-4616-9157-a89d27afe423
begin
	successful_runs_Np = ipTable[np_runs_to_keep, :]
	failed_runs_Np = ipTable[failedRuns, :]
	excluded_runs_Np = ipTable[Not(vcat(np_runs_to_keep, failedRuns)), :]
	successful_runs_UrNp = ipTable[ur_np_runs_to_keep, :]
	excluded_runs_UrNp = ipTable[ur_np_runs_to_remove, :]
end

# ╔═╡ d445e43f-d88c-49b1-9f60-36a66662b73a
ipRange = 1:200

# ╔═╡ 257eac68-7384-4202-89b6-5a847e6d67b7
collect(ipRange[Not(vcat(np_runs_to_keep, failedRuns))])

# ╔═╡ 31bddd16-626d-41e5-baff-c5d4aaa77b4a
cur_colors = palette(:default)

# ╔═╡ e6d3978f-fbab-418e-96b3-35e15ab16d9a
md"""
`x = ` $(@bind name_x html"<select>
					<option value='BrFactor'>BrFactor</option>
					<option value='nChromoSi'>nChromoSi</option>
				  	<option value='PoyntingFlux'>PoyntingFlux</option>
					<option value='Lperp'>Lperp</option>
					<option value='StochExp'>StochExp</option>
					<option value='BrMin'>BrMin</option>
					<option value='rMinWaveRefl'>rMinWaveRefl</option>
				  	</select>"
)


`y = ` $(@bind name_y html"<select>
					<option value='BrFactor'>BrFactor</option>
					<option value='nChromoSi'>nChromoSi</option>
				  	<option value='PoyntingFlux'>PoyntingFlux</option>
					<option value='Lperp'>Lperp</option>
					<option value='StochExp'>StochExp</option>
					<option value='BrMin'>BrMin</option>
					<option value='rMinWaveRefl'>rMinWaveRefl</option>
				  	</select>"
)

"""

# ╔═╡ c8c52ac0-5dfc-4d04-92ce-945c7f07999d
name_x, name_y

# ╔═╡ 9f7243a6-c363-44e7-a5ad-597d680d4715
begin      
            p1 = scatter(successfulRunInputs[!, name_x], 
                    successfulRunInputs[!, name_y],
                    label = "Successful Runs ",
                    markerstrokewidth=0)
            scatter!(failedRunInputs[!, name_x],
                     failedRunInputs[!, name_y], 
                     label = "Failed Runs",
                     markerstrokewidth=0)
            scatter!(excludedRunInputs[!, name_x],
                     excludedRunInputs[!, name_y], 
                     label = "Excluded Runs",
                     markerstrokewidth=0)
            # scatter!(tuple(ipTable[47, name_x],
            #          ipTable[47, name_y]),
            #          markersize=6,
            #          markerstrokewidth=0,
            #          marker=(:diamond, cur_colors[15]))
            # scatter!(tuple(ipTable[43, name_x],
            #          ipTable[43, name_y]),
            #          markersize=6,
            #          markerstrokewidth=0,
            #          marker=(:square, cur_colors[12]))
    
            annotate!(1.35 * minimum(ipTable[!, name_x]), 
                    1.015 * maximum(ipTable[!, name_y]), 
                    text("Successful", cur_colors[1], :above, 12, :bold))
            annotate!(0.5 * (minimum(ipTable[!, name_x]) + maximum(ipTable[!, name_x])), 
                    1.015 * maximum(ipTable[!, name_y]), 
                    text("Failed", cur_colors[2], :above, 12, :bold))
            annotate!(0.8 * maximum(ipTable[!, name_x]), 
                    1.015 * maximum(ipTable[!, name_y]), 
                    text("Excluded", cur_colors[3], :above, 12, :bold))
#             annotate!(, 0.2e18, text("Failed", cur_colors[2], :below, 10, :bold))
#             annotate!(1.62, 4.95e18, text("Excluded", cur_colors[3], :above, 10, :bold))
            plot!(xlabel=name_x, ylabel=name_y)
            plot!(legend=false)
			plot!(title="Inputs coloured by excluded runs for Ur")
#             figTitle = name_x * "vs" * name_y * ".pdf"
#             savefig(joinpath("./Outputs/ScatterPlots", figTitle))
end      

# ╔═╡ 735cdb31-5ff1-482b-841d-d7bd84323154
begin      
	
			# default(titlefont = (20, "times"), guidefont = (14), tickfont = (12), framestyle = :box)
            pp = scatter(ipTable[!, name_x], 
                    ipTable[!, name_y],
                    label = "Successful Runs ",
                    markerstrokewidth=0
)
            plot!(xlabel=name_x, ylabel=name_y)
            plot!(legend=false)
			
			# plot!(title="Inputs coloured by excluded runs for Np")

end 

# ╔═╡ 71b05da6-6dee-4e3b-be8c-e7bc6cb2186c

		

# ╔═╡ f42db30c-5f02-4dec-aa07-3052ece1a245
begin      
            p2 = scatter(successful_runs_Np[!, name_x], 
                    successful_runs_Np[!, name_y],
                    label = "Successful Runs ",
                    markerstrokewidth=0)
            scatter!(failed_runs_Np[!, name_x],
                     failed_runs_Np[!, name_y], 
                     label = "Failed Runs",
                     markerstrokewidth=0)
            scatter!(excluded_runs_Np[!, name_x],
                     excluded_runs_Np[!, name_y], 
                     label = "Excluded Runs",
                     markerstrokewidth=0)
    
            annotate!(1.35 * minimum(ipTable[!, name_x]), 
                    1.015 * maximum(ipTable[!, name_y]), 
                    text("Successful", cur_colors[1], :above, 12, :bold))
            annotate!(0.5 * (minimum(ipTable[!, name_x]) + maximum(ipTable[!, name_x])), 
                    1.015 * maximum(ipTable[!, name_y]), 
                    text("Failed", cur_colors[2], :above, 12, :bold))
            annotate!(0.8 * maximum(ipTable[!, name_x]), 
                    1.015 * maximum(ipTable[!, name_y]), 
                    text("Excluded", cur_colors[3], :above, 12, :bold))

            plot!(xlabel=name_x, ylabel=name_y)
            plot!(legend=false)
			plot!(title="Inputs coloured by excluded runs for Np")

end 

# ╔═╡ 70c53dba-76f6-471e-baed-1c17d47a5f8d
# plot runs excluded by Ur as well as Np
begin      
			# default(guidefont = (14), tickfont = (12))
            ppp = scatter(successful_runs_UrNp[!, name_x], 
                    successful_runs_UrNp[!, name_y],
                    label = "Successful Runs ",
                    markerstrokewidth=0)

            scatter!(excluded_runs_UrNp[!, name_x],
                     excluded_runs_UrNp[!, name_y], 
                     label = "Excluded Runs",
					 marker=cur_colors[3],
                     markerstrokewidth=0)
	
			scatter!(failed_runs_Np[!, name_x],
                     failed_runs_Np[!, name_y], 
                     label = "Failed Runs",
					 marker= cur_colors[2],
                     markerstrokewidth=0)
    
            annotate!(1.35 * minimum(ipTable[!, name_x]), 
                    1.015 * maximum(ipTable[!, name_y]), 
                    text("Successful", cur_colors[1], :above, 12, :bold))
            annotate!(0.5 * (minimum(ipTable[!, name_x]) + maximum(ipTable[!, name_x])), 
                    1.015 * maximum(ipTable[!, name_y]), 
                    text("Failed", cur_colors[2], :above, 12, :bold))
            annotate!(0.8 * maximum(ipTable[!, name_x]), 
                    1.015 * maximum(ipTable[!, name_y]), 
                    text("Excluded", cur_colors[3], :above, 12, :bold))

            plot!(xlabel=name_x, ylabel=name_y)
            plot!(legend=false)
			plot!(title="Inputs coloured by excluded runs for Np and Ur")

end 

# ╔═╡ 280b8277-cee8-4b8b-8343-bfc84b44f82d
begin
	
	x_var = "BrFactor"
	y_var = "PoyntingFlux"

	BrFactor = sort(ipTable[!, "BrFactor"])
	PoyntingFlux = sort(ipTable[!, "PoyntingFlux"])
	
	energy(BrFactor, PoyntingFlux) = BrFactor * PoyntingFlux 
	

	# ccol = cgrad([cur_colors[1], cur_colors[3]])
	ccol = cgrad([RGB(0.3,0.3,0.8), RGB(0.3,0.9,0.5)])
	contour(BrFactor, PoyntingFlux, energy, f=true, nlev=8, c=ccol)
	
	
	scatter!(successful_runs_Np[!, x_var], 
			successful_runs_Np[!, y_var],
			label = "Successful Runs ",
			markerstrokewidth=2, 
			marker=cur_colors[1],
			markersize=7)
	scatter!(failed_runs_Np[!, x_var],
			 failed_runs_Np[!, y_var], 
			 label = "Failed Runs",
			 markerstrokewidth=2,
			marker=cur_colors[2],
		 	markersize=7)
	scatter!(excluded_runs_Np[!, x_var],
			 excluded_runs_Np[!, y_var], 
			 label = "Excluded Runs",
			 markerstrokewidth=2,
			 marker=cur_colors[3],
			 markersize=7)
	# scatter!(successful_runs_UrNp[!, x_var],
	# 	 successful_runs_UrNp[!, y_var], 
	# 	 markerstrokewidth=2,
	# 	 marker=cur_colors[4],
	# 	 markersize=7)
	# plot!(BrFactor, 7*10^5 ./BrFactor, linewidth=3)
	plot!(BrFactor, 6*10^5 ./BrFactor, linewidth=3)
	annotate!(1.35 * minimum(ipTable[!, x_var]), 
			1.02 * maximum(ipTable[!, y_var]), 
			text("Successful", cur_colors[1], :above, 12, :bold))
	annotate!(0.5 * (minimum(ipTable[!, x_var]) + maximum(ipTable[!, x_var])), 
			1.02 * maximum(ipTable[!, y_var]), 
			text("Failed", cur_colors[2], :above, 12, :bold))
	annotate!(0.8 * maximum(ipTable[!, x_var]), 
			1.02 * maximum(ipTable[!, y_var]), 
			text("Excluded", cur_colors[3], :above, 12, :bold))

	plot!(xlabel=x_var, ylabel=y_var)
	plot!(legend=false)
	plot!(title="Inputs coloured by successful and excluded runs")
	plot!(xlim=(0.5, 2.7))
	plot!(ylim=(2.5e5, 1.1e6))
	# plot!(xlim=extrema(BrFactor))
	# plot!(ylim=extrema(PoyntingFlux))
	plot!(size=(1000, 800))

end

# ╔═╡ 61ae8f7a-6ba0-4d41-b16d-03dd512861eb
begin
	
# 	x_var = "BrFactor"
# 	y_var = "PoyntingFlux"

# 	BrFactor = sort(ipTable[!, "BrFactor"])
# 	PoyntingFlux = sort(ipTable[!, "PoyntingFlux"])
	
# 	energy(BrFactor, PoyntingFlux) = BrFactor * PoyntingFlux 
	

# 	# ccol = cgrad([cur_colors[1], cur_colors[3]])
# 	ccol = cgrad([RGB(0.3,0.3,0.8), RGB(0.3,0.9,0.5)])
	contour(BrFactor, PoyntingFlux, energy, f=true, nlev=8, c=ccol)
	
	
	scatter!(successful_runs_UrNp[!, x_var], 
			successful_runs_UrNp[!, y_var],
			label = "Successful Runs ",
			markerstrokewidth=2, 
			marker=cur_colors[1],
			markersize=7)

	scatter!(excluded_runs_UrNp[!, x_var],
			 excluded_runs_UrNp[!, y_var], 
			 label = "Excluded Runs",
			 markerstrokewidth=2,
			 marker=cur_colors[3],
			 markersize=7)
	
	scatter!(failed_runs_Np[!, x_var],
			 failed_runs_Np[!, y_var], 
			 label = "Failed Runs",
			 markerstrokewidth=2,
			marker=cur_colors[2],
		 	markersize=7)
	# scatter!(successful_runs_UrNp[!, x_var],
	# 	 successful_runs_UrNp[!, y_var], 
	# 	 markerstrokewidth=2,
	# 	 marker=cur_colors[4],
	# 	 markersize=7)
	# plot!(BrFactor, 7*10^5 ./BrFactor, linewidth=3)
	plot!(BrFactor, 6*10^5 ./BrFactor, linewidth=3)
	annotate!(1.35 * minimum(ipTable[!, x_var]), 
			1.01 * maximum(ipTable[!, y_var]), 
			text("Successful", cur_colors[1], :above, 11, :bold))
	annotate!(0.5 * (minimum(ipTable[!, x_var]) + maximum(ipTable[!, x_var])), 
			1.01 * maximum(ipTable[!, y_var]), 
			text("Failed", cur_colors[2], :above, 11, :bold))
	annotate!(0.8 * maximum(ipTable[!, x_var]), 
			1.01 * maximum(ipTable[!, y_var]), 
			text("Excluded", cur_colors[3], :above, 11, :bold))

	plot!(xlabel=x_var, ylabel=y_var)
	plot!(legend=false)
	# plot!(title="Inputs coloured by excluded runs for Np")
	plot!(xlim=(0.5, 2.7))
	plot!(ylim=(2.5e5, 1.1e6))
	# plot!(xlim=extrema(BrFactor))
	# plot!(ylim=extrema(PoyntingFlux))
	plot!(size=(1000, 800))

end

# ╔═╡ 8a553dca-f416-4302-8682-e7537e39e0cf
# begin
	
# 	contour(BrFactor, PoyntingFlux, energy, f=true, nlev=7, c=ccol)
# 	scatter!(successful_runs_Np[!, name_x], 
# 			successful_runs_Np[!, name_y],
# 			label = "Successful Runs ",
# 			# markerstrokewidth=0, 
# 			marker=cur_colors[1],
# 			markersize=6)
# 	scatter!(failed_runs_Np[!, name_x],
# 			 failed_runs_Np[!, name_y], 
# 			 label = "Failed Runs",
# 			 # markerstrokewidth=0,
# 			marker=cur_colors[2],
# 		 	markersize=6)
# 	scatter!(excluded_runs_Np[!, name_x],
# 			 excluded_runs_Np[!, name_y], 
# 			 label = "Excluded Runs",
# 			 # markerstrokewidth=0,
# 			 marker=cur_colors[3],
# 			 markersize=6)
	
# 	annotate!(1.35 * minimum(ipTable[!, name_x]), 
# 			1.02 * maximum(ipTable[!, name_y]), 
# 			text("Successful", cur_colors[1], :above, 12, :bold))
# 	annotate!(0.5 * (minimum(ipTable[!, name_x]) + maximum(ipTable[!, name_x])), 
# 			1.02 * maximum(ipTable[!, name_y]), 
# 			text("Failed", cur_colors[2], :above, 12, :bold))
# 	annotate!(0.8 * maximum(ipTable[!, name_x]), 
# 			1.02 * maximum(ipTable[!, name_y]), 
# 			text("Excluded", cur_colors[3], :above, 12, :bold))

# 	plot!(xlabel=name_x, ylabel=name_y)
# 	plot!(legend=false)
# 	plot!(title="Inputs coloured by excluded runs for Np")
# 	# plot!(xlim=extrema(BrFactor))
# 	# plot!(ylim=extrema(PoyntingFlux))
# 	plot!(size=(1000, 800))

# end

# ╔═╡ 9c8cd5eb-43f6-4bc2-b6d7-36ec963a3f58
extrema(BrFactor)

# ╔═╡ ca849f81-4ca1-4ec6-8e25-aec1ff4cdd9c
BrFactor

# ╔═╡ a01fc407-26cc-4412-8da3-2685c018b740
# plot(p1, p2, layout=(1, 2), size=(1500, 700))

# ╔═╡ 8f843ed9-50ca-44e9-89bd-fdc615f6565c
md"""
## Code for plotting decision boundaries (MWE)

Source: [Plotting Decision Boundary For Classifiers](https://discourse.julialang.org/t/plotting-decision-boundary-regions-for-classifier/21397/2?u=aniket_jivani)
"""

# ╔═╡ 70feeaa1-7fe3-409f-ab49-bc427b3d8dc4
# begin
# 	using Random
# 	Random.seed!(1)
# 	p = rand(40,3) + rand(40,3)*im
# 	r = 0:.002:1

# 	# classifier: returns 1, 2, or 3 for any given (x, y)
# 	f(x, y) = findmin(sum(abs.(x + y*im .- p); dims=1)[:])[2]

# 	# colors and markers for the 3 regions
# 	ccol = cgrad([RGB(1,.3,.3), RGB(.4,1,.4), RGB(.3,.3,1)])
# 	mcol = [RGB(1,.1,.1) RGB(.3,1,.3) RGB(.1,.1,1)]
# 	m = [:rect :circle :utriangle]

# 	anim = @animate for d = 0:.03:2π
# 		contour(r, r, f, f=true, nlev=3, c=ccol, leg=:none)
# 		scatter!(real(p), imag(p), m=m, c=mcol, lims=(0,1))
# 		gui()
# 		c = [cis(d)sin(d+.5π) cis(d+2π/3)cos(d) cis(d-2π/3)]
# 		global p += .003(c .+ .5(1+im) .- p)
# 	end

# 	gif(anim, "contour.gif", fps = 30)
# end

# ╔═╡ 5120e0f5-f319-4410-a5ef-9a3c8879ca8c


# ╔═╡ bd39187f-d680-47f8-b255-56601d4bd3f9
md"""
## Uniform sampling from product of BrFactor and Poynting Flux
"""

# ╔═╡ 87fe8deb-4d43-4904-87c7-84dc1092b500
# function getPFSample(BrF_Sample)
#     PF_Sample = rand(Uniform(0.3e6, 1.1e6))
#     if PF_Sample <= 7.7 * 10^5 / BrF_Sample
#         return PF_Sample
#     else
#         getPFSample(BrF_Sample)
#     end
# end


# ╔═╡ 7046d902-981c-495d-b114-a087f907a91b


# ╔═╡ Cell order:
# ╠═c76ce670-0ea0-4d36-896f-105c51079928
# ╠═f7446395-3c0a-4f73-afea-438f07576a79
# ╠═c0e6912a-17cc-431b-9b0e-6b54e3480256
# ╠═0a1f12f9-69c9-43be-a351-714398305c95
# ╠═7eab8e8e-e39c-492b-a21f-3f4cffd5007f
# ╠═9f41d95a-4fdb-4514-b9e3-8655db9064fb
# ╠═b1bd3c8b-9e7d-406e-a6d3-44345a5b94bb
# ╟─d6b27006-2c3d-4280-bc30-2c8f279438c1
# ╠═63d6bf11-581b-410e-b12a-b643a9f6e479
# ╠═19c1dadb-73dc-4c50-aa2a-27fcb845e117
# ╠═99cc6e88-cac0-470c-bea3-b7906582c223
# ╠═c22eecf1-420e-4e64-9547-7a93c4563d9c
# ╠═e307a87b-4ccd-48a6-8957-381592c23adc
# ╠═89b6eb14-701e-4e13-b71d-726b0b47df9f
# ╠═4a0e3b87-f412-4efb-ade3-9f6b6e289e07
# ╠═0d870394-9ff1-4893-aa67-c00cc4736e73
# ╠═652708aa-a500-4616-9157-a89d27afe423
# ╠═d445e43f-d88c-49b1-9f60-36a66662b73a
# ╠═257eac68-7384-4202-89b6-5a847e6d67b7
# ╠═31bddd16-626d-41e5-baff-c5d4aaa77b4a
# ╠═c8c52ac0-5dfc-4d04-92ce-945c7f07999d
# ╟─9f7243a6-c363-44e7-a5ad-597d680d4715
# ╟─e6d3978f-fbab-418e-96b3-35e15ab16d9a
# ╟─735cdb31-5ff1-482b-841d-d7bd84323154
# ╠═71b05da6-6dee-4e3b-be8c-e7bc6cb2186c
# ╟─f42db30c-5f02-4dec-aa07-3052ece1a245
# ╟─70c53dba-76f6-471e-baed-1c17d47a5f8d
# ╠═280b8277-cee8-4b8b-8343-bfc84b44f82d
# ╠═61ae8f7a-6ba0-4d41-b16d-03dd512861eb
# ╠═8a553dca-f416-4302-8682-e7537e39e0cf
# ╠═9c8cd5eb-43f6-4bc2-b6d7-36ec963a3f58
# ╠═ca849f81-4ca1-4ec6-8e25-aec1ff4cdd9c
# ╠═a01fc407-26cc-4412-8da3-2685c018b740
# ╟─8f843ed9-50ca-44e9-89bd-fdc615f6565c
# ╠═70feeaa1-7fe3-409f-ab49-bc427b3d8dc4
# ╠═5120e0f5-f319-4410-a5ef-9a3c8879ca8c
# ╟─bd39187f-d680-47f8-b255-56601d4bd3f9
# ╠═87fe8deb-4d43-4904-87c7-84dc1092b500
# ╠═7046d902-981c-495d-b114-a087f907a91b
