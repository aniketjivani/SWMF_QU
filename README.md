# Code for SWMF QU Project

## Summary of results and latest updates: 
The SWQU-DA Update Document on Google Docs usually contains this. 


## Brief Description
The folder MaxProAnalysis contains all scripts, data and outputs related to analysis of 200 runs suggested by the MaxPro design. These are studied for solar min (CR2208) and solar max (CR2152) with ADAPT maps and AWSoM model. 

Under MaxProAnalysis:

1) [Outputs](https://github.com/danieliong/SWMF_QU/tree/metrics/MaxProAnalysis/Outputs) 

  The QoI files are only processed for the `earth` trajectory, and not for `sta` or `stb`. 
  * Link to Solar Min QoIs: [Solar Minimum QoIs](https://github.com/danieliong/SWMF_QU/tree/metrics/MaxProAnalysis/Outputs/QoIs/code_v_2021_05_17/event_list_2021_04_16_09)
   
  * Link to Solar Max QoIs: [Solar Maximum QoIs](https://github.com/danieliong/SWMF_QU/tree/metrics/MaxProAnalysis/Outputs/QoIs/code_v_2021_05_17/event_list_2021_06_02_21)
  
  * Format: 

`*Sim_Earth.txt`: Each column corresponds to a separate run for that QoI.  For example, `UrSim_Earth.txt` contains runs for Ur. A few columns will be all zeroes. These correspond to failed runs. There are no failed runs in the solar min case. 

`*Obs_earth_sta.txt`: Observed values for the QoI. These will contain 2 columns. The first column corresponds to `OMNI` observations (the ones we will look at while comparing for the `earth` trajectory. Column 2 contains values for `sta`. 

Typically there will be 720 rows, each corresponding to a different time. The original time and date values for each row can be obtained from the `trj_*_n00005000.sat` files on the solsticedisk in the relevant folder. 

Miscellaneous: `removed_runs.txt` contains runs that failed in solar max (the first 9) and the ones that were excluded by hand for Ur (remaining indices). These are all based on 1-indexing. 

Failed runs can be identified by the value in the `Outcomes` column for the corresponding `event_list` file (see below for links to solar min and max event lists). A value of 0 means the run failed.  


2) [data](https://github.com/danieliong/SWMF_QU/tree/metrics/MaxProAnalysis/data)
  * Solar Min Input List: [Solar Min Inputs]
(https://github.com/danieliong/SWMF_QU/blob/metrics/MaxProAnalysis/data/MaxPro_inputs_outputs_event_list_2021_04_16_09.txt)

  * Solar Max Input List: [Solar Max Inputs]
(https://github.com/danieliong/SWMF_QU/blob/metrics/MaxProAnalysis/data/MaxPro_inputs_outputs_event_list_2021_06_02_21.txt)
  

3) [src](https://github.com/danieliong/SWMF_QU/tree/metrics/MaxProAnalysis/src)

  * computeMetrics.jl: Calculate penalized, shifted, trimmed RMSE. Can be supplied with arguments to specify QoI file path, inputs path, path to save metrics to and others. For help, type `julia --project=. src/computeMetrics.jl --help`
  
  * exportShiftedTrimmedQoIs.jl: Process the QoIs in the relevant folders (both sim and obs) and export shifted / trimmed versions of them using the functions in the Julia module [`metricsTools.jl`](https://github.com/danieliong/SWMF_QU/blob/metrics/scripts/metricsTools.jl)

  * processAllQoIs.jl: Takes in as input the unzipped L1.tgz runs, for example: [Path to unzipped runs for Solar Maximum](https://github.com/danieliong/SWMF_QU/tree/metrics/MaxProAnalysis/data/L1_runs_event_list_2021_06_02_21) and processes simulations and observations for 4 QoIs - Ur, Np, T and B. These can then be written to appropriate path under `Outputs/QoIs`.


