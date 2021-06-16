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
            scatter(successfulRunInputs[!, name_x], 
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
#             figTitle = name_x * "vs" * name_y * ".pdf"
#             savefig(joinpath("./Outputs/ScatterPlots", figTitle))
end      

# ╔═╡ Cell order:
# ╠═c76ce670-0ea0-4d36-896f-105c51079928
# ╠═c0e6912a-17cc-431b-9b0e-6b54e3480256
# ╠═0a1f12f9-69c9-43be-a351-714398305c95
# ╠═7eab8e8e-e39c-492b-a21f-3f4cffd5007f
# ╠═9f41d95a-4fdb-4514-b9e3-8655db9064fb
# ╠═b1bd3c8b-9e7d-406e-a6d3-44345a5b94bb
# ╠═31bddd16-626d-41e5-baff-c5d4aaa77b4a
# ╟─e6d3978f-fbab-418e-96b3-35e15ab16d9a
# ╠═c8c52ac0-5dfc-4d04-92ce-945c7f07999d
# ╠═9f7243a6-c363-44e7-a5ad-597d680d4715
