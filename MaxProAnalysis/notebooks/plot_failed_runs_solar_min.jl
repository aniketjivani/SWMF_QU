### A Pluto.jl notebook ###
# v0.14.4

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

# ╔═╡ ba46b044-2ab6-4854-822d-592a4d6c3265
using VegaLite

# ╔═╡ c0e6912a-17cc-431b-9b0e-6b54e3480256
begin
	mg = "ADAPT"
	md = "AWSoM"
	cr = 2208
end

# ╔═╡ 0a1f12f9-69c9-43be-a351-714398305c95
begin
	ips, _ = readdlm("../data/MaxPro_inputs_outputs_event_list_2021_04_16_09.txt", ',', header=true)
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
	runsToKeep = readdlm("../Outputs/QoIs/code_v_2021_05_17/event_list_2021_04_16_09/np_less_than_hundred.txt", Int64)[:]

	removedRuns = setdiff(1:200, runsToKeep)

end

# ╔═╡ aa61a977-fc14-4111-ba14-6991273c6607
runsToKeep

# ╔═╡ 13e4bc15-680a-4a05-84d0-9caf90764ab1
removedRuns2 = setdiff(1:200, runsToKeep)

# ╔═╡ b1bd3c8b-9e7d-406e-a6d3-44345a5b94bb
begin
	successfulRunInputs = ipTable[runsToKeep, :];
	# failedRunInputs = ipTable[failedRuns, :]
	excludedRunInputs = ipTable[removedRuns, :];
	first(excludedRunInputs, 5)
end

# ╔═╡ d445e43f-d88c-49b1-9f60-36a66662b73a
ipRange = 1:200

# ╔═╡ 257eac68-7384-4202-89b6-5a847e6d67b7
# collect(ipRange[Not(vcat(np_runs_to_keep, failedRuns))])

# ╔═╡ 31bddd16-626d-41e5-baff-c5d4aaa77b4a
cur_colors = palette(:default)

# ╔═╡ 4cdf239c-f145-4ee4-a397-59a771570d93
md"""
145 runs are retained in the Solar Minimum case, having Np < 100
"""

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
            # scatter!(failedRunInputs[!, name_x],
            #          failedRunInputs[!, name_y], 
            #          label = "Failed Runs",
            #          markerstrokewidth=0)
            scatter!(excludedRunInputs[!, name_x],
                     excludedRunInputs[!, name_y], 
                     label = "Excluded Runs",
                     markerstrokewidth=0,
					 marker=cur_colors[3])
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
                    text("Excluded", cur_colors[3], :above, 12, :bold))
            # annotate!(0.8 * maximum(ipTable[!, name_x]), 
            #         1.015 * maximum(ipTable[!, name_y]), 
            #         text("Excluded", cur_colors[3], :above, 12, :bold))
#             annotate!(, 0.2e18, text("Failed", cur_colors[2], :below, 10, :bold))
#             annotate!(1.62, 4.95e18, text("Excluded", cur_colors[3], :above, 10, :bold))
            plot!(xlabel=name_x, ylabel=name_y)
            plot!(legend=false)
			plot!(title="Inputs coloured by excluded runs for Np")
#             figTitle = name_x * "vs" * name_y * ".pdf"
#             savefig(joinpath("./Outputs/ScatterPlots", figTitle))
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
	contour(BrFactor, PoyntingFlux, energy, f=true, nlev=9, c=ccol)
	
	
	scatter!(successfulRunInputs[!, x_var], 
			successfulRunInputs[!, y_var],
			label = "Successful Runs ",
			markerstrokewidth=2, 
			marker=cur_colors[1],
			markersize=7)
	# scatter!(failed_runs_Np[!, x_var],
	# 		 failed_runs_Np[!, y_var], 
	# 		 label = "Failed Runs",
	# 		 # markerstrokewidth=0,
	# 		marker=cur_colors[2],
	# 	 	markersize=6)
	scatter!(excludedRunInputs[!, x_var],
			 excludedRunInputs[!, y_var], 
			 label = "Excluded Runs",
			 markerstrokewidth=2,
			 marker=cur_colors[3],
			 markersize=7)
	plot!(BrFactor, 7.7*10^5 ./ BrFactor, linewidth = 3)
	plot!(BrFactor, 1.25*10^6 ./ BrFactor, linewidth = 3)
	
	annotate!(1.35 * minimum(ipTable[!, x_var]), 
			1.02 * maximum(ipTable[!, y_var]), 
			text("Successful", cur_colors[1], :above, 12, :bold))
	# annotate!(0.5 * (minimum(ipTable[!, x_var]) + maximum(ipTable[!, x_var])), 
	# 		1.02 * maximum(ipTable[!, y_var]), 
	# 		text("Failed", cur_colors[2], :above, 12, :bold))
	annotate!(0.8 * maximum(ipTable[!, x_var]), 
			1.02 * maximum(ipTable[!, y_var]), 
			text("Excluded", cur_colors[3], :above, 12, :bold))

	plot!(xlim=(0.5, 2.7))
	plot!(ylim=(2.5e5, 1.1e6))
	
	
	plot!(xlabel=x_var, ylabel=y_var)
	plot!(legend=false)
	plot!(title="Inputs coloured by excluded runs for Np")
	# plot!(xlim=extrema(BrFactor))
	# plot!(ylim=extrema(PoyntingFlux))
	plot!(size=(1000, 800))

end

# ╔═╡ 97e653ee-91a7-483a-aff6-b6b23a4060da
### TO DO
# Quasi MC - qmcPy for new samples
# Coloured by RMSE plots 

# ╔═╡ 5569dfed-61ed-4b8d-9d52-cbd23929cba8
md"""
We add further insight to the above plot by viewing runs coloured by their respective RMSE values indicating their proximity to the observed data."""

# ╔═╡ 51c79087-d6c4-43c8-a55e-501f21a9e6fd
md"""
![](SolarMinimum_BrF_PoyntingFlux_rmseNp.png)
"""

# ╔═╡ 6f4f9d93-6ade-4485-ad7e-ff0efb2a9e1f


# ╔═╡ cf6c8426-bbc7-4099-a5d4-ea6e507c74b4
begin
	metrics = DataFrame(CSV.File("../Outputs/QoIs/code_v_2021_05_17/event_list_2021_04_16_09/metrics.csv"))
end

# ╔═╡ 78e13f6f-004b-4819-96e9-d8c24361cf6b
RMSE_Np = metrics.rmse_Np

# ╔═╡ bf4d9d07-31c5-4857-a3b7-40cae1fe1da2
df = DataFrame(BrFactor = ipTable[!, "BrFactor"],
			   PoyntingFlux = ipTable[!, "PoyntingFlux"],
			   RMSE = RMSE_Np)

# ╔═╡ 45372f88-47aa-4d53-b765-192fd46e1ae6
df |> @vlplot(:point, x=:BrFactor, y=:PoyntingFlux, color=:RMSE)

# ╔═╡ 6dfc687d-c67e-4ceb-b75c-2f7d5cad0cb5


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


# ╔═╡ Cell order:
# ╠═c76ce670-0ea0-4d36-896f-105c51079928
# ╠═c0e6912a-17cc-431b-9b0e-6b54e3480256
# ╠═0a1f12f9-69c9-43be-a351-714398305c95
# ╠═7eab8e8e-e39c-492b-a21f-3f4cffd5007f
# ╠═9f41d95a-4fdb-4514-b9e3-8655db9064fb
# ╠═aa61a977-fc14-4111-ba14-6991273c6607
# ╠═13e4bc15-680a-4a05-84d0-9caf90764ab1
# ╠═b1bd3c8b-9e7d-406e-a6d3-44345a5b94bb
# ╠═d445e43f-d88c-49b1-9f60-36a66662b73a
# ╠═257eac68-7384-4202-89b6-5a847e6d67b7
# ╠═31bddd16-626d-41e5-baff-c5d4aaa77b4a
# ╠═c8c52ac0-5dfc-4d04-92ce-945c7f07999d
# ╟─4cdf239c-f145-4ee4-a397-59a771570d93
# ╟─9f7243a6-c363-44e7-a5ad-597d680d4715
# ╟─e6d3978f-fbab-418e-96b3-35e15ab16d9a
# ╠═280b8277-cee8-4b8b-8343-bfc84b44f82d
# ╠═97e653ee-91a7-483a-aff6-b6b23a4060da
# ╟─5569dfed-61ed-4b8d-9d52-cbd23929cba8
# ╠═ba46b044-2ab6-4854-822d-592a4d6c3265
# ╠═bf4d9d07-31c5-4857-a3b7-40cae1fe1da2
# ╠═45372f88-47aa-4d53-b765-192fd46e1ae6
# ╠═51c79087-d6c4-43c8-a55e-501f21a9e6fd
# ╠═6f4f9d93-6ade-4485-ad7e-ff0efb2a9e1f
# ╠═cf6c8426-bbc7-4099-a5d4-ea6e507c74b4
# ╟─78e13f6f-004b-4819-96e9-d8c24361cf6b
# ╠═6dfc687d-c67e-4ceb-b75c-2f7d5cad0cb5
# ╟─8f843ed9-50ca-44e9-89bd-fdc615f6565c
# ╠═70feeaa1-7fe3-409f-ab49-bc427b3d8dc4
# ╠═5120e0f5-f319-4410-a5ef-9a3c8879ca8c
