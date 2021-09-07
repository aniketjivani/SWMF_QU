# Code for SWMF QU Project

## Summary of results and latest updates: 
The SWQU-DA Update Document on Google Docs usually contains this. 

Link: [SWQU-DA](https://docs.google.com/document/d/1VtvgIdNSRJQ6HzxACbrxiGsVR8qiM-jQsVqsOgEhios/edit?usp=sharing)


## Brief Description
The folder MaxProAnalysis contains all scripts, data and outputs related to analysis of 200 runs suggested by the MaxPro design, as well as new runs added by Quasi MC for comparing models AWSoM, AWSoMR and AWSoM2T. These are studied for solar min (CR2208) and solar max (CR2152) with ADAPT maps and AWSoM model. 

Under MaxProAnalysis:

1) [Outputs](https://github.com/danieliong/SWMF_QU/tree/metrics/MaxProAnalysis/Outputs) 

  The QoI files are only processed for the `earth` trajectory, and not for `sta` or `stb`. 
  * Link to Solar Min QoIs: [Solar Minimum QoIs](https://github.com/danieliong/SWMF_QU/tree/metrics/MaxProAnalysis/Outputs/QoIs/code_v_2021_05_17/event_list_2021_04_16_09)
   
  * Link to Solar Max QoIs: [Solar Maximum QoIs](https://github.com/danieliong/SWMF_QU/tree/metrics/MaxProAnalysis/Outputs/QoIs/code_v_2021_05_17/event_list_2021_06_02_21)


  * Link to QoIs for AWSoM, AWSoMR, AWSoM2T (min and max): all folders under `MaxProAnalysis/Outputs/QoIs/code_v_2021_05_17` with the format `event_list_2021_07_11_MODEL_CR####`, for example: `event_list_2021_07_11_AWSoM_CR2152`. 
  * Links to QoIs for AWSoM (latest 500 runs): folders with the format `event_list_2021_07_30_MODEL_CR####`
  * Format: 

`*Sim_Earth.txt`: Each column corresponds to a separate run for that QoI.  For example, `UrSim_Earth.txt` contains runs for Ur. A few columns will be all zeroes. These correspond to failed runs. 

Rows = different time points

Columns = different runs

`*Obs_earth_sta.txt`: Observed values for the QoI. These will contain 2 columns. The first column corresponds to `OMNI` observations (the ones we will look at while comparing for the `earth` trajectory. Column 2 contains values for `sta`. 

Typically there will be 720 rows, each corresponding to a different time. The original time and date values for each row can be obtained from the `trj_*_n00005000.sat` files on the solsticedisk in the relevant folder. 

Miscellaneous: `runs_to_keep.txt` contains indices of runs that we retain for further analysis. Other runs are excluded because they do not contain physically meaningful values (eg, Ur > 900 km/s, Np > 100) . These are all based on 1-indexing. The workflow is to load this file as well as any `*Sim_Earth.txt` file for Ur, Np:

```julia
# load Ur
# load runs to keep
Ur_retained = Ur[:, runs_to_keep]
# use Ur_retained
```




2. [data](https://github.com/danieliong/SWMF_QU/tree/metrics/MaxProAnalysis/data)

   **200 MaxPro runs:** 
  * Solar Min Input List: [Solar Min Inputs](https://github.com/danieliong/SWMF_QU/blob/metrics/MaxProAnalysis/data/MaxPro_inputs_outputs_event_list_2021_04_16_09.txt)

  * Solar Max Input List: [Solar Max Inputs](https://github.com/danieliong/SWMF_QU/blob/metrics/MaxProAnalysis/data/MaxPro_inputs_outputs_event_list_2021_06_02_21.txt)

    **100 runs for model comparison purposes + latest set of 500 runs (based on QMC)**: 

    Solar Min: `SWMF_QU/MaxProAnalysis/data/QMC_Data_for_event_lists/revised_thresholds/X_design_QMC_masterList_solarMin_AWSoM_reducedThreshold.txt`

    

    Solar Max:

    `SWMF_QU/MaxProAnalysis/data/QMC_Data_for_event_lists/revised_thresholds/X_design_QMC_masterList_solarMin_AWSoM_reducedThreshold.txt`

    

​	For first 100 runs, we load run indices 0-99 and for the next 500 runs, indices 100 - 599. Runs 100-599 were conducted at higher GridResolution (1.5 instead of 0.75) hence the separate listings for QoIs. 


3) [src](https://github.com/danieliong/SWMF_QU/tree/metrics/MaxProAnalysis/src)

  * computeMetrics.jl: Calculate penalized, shifted, trimmed RMSE. Can be supplied with arguments to specify QoI file path, inputs path, path to save metrics to and others. For help, type `julia --project=. src/computeMetrics.jl --help`
  
  * exportShiftedTrimmedQoIs.jl: Process the QoIs in the relevant folders (both sim and obs) and export shifted / trimmed versions of them using the functions in the Julia module [`metricsTools.jl`](https://github.com/danieliong/SWMF_QU/blob/metrics/scripts/metricsTools.jl)

The QoIs obtained from here will have size 433 x (number of runs). The row size depends on the size of the region where QoIs are compared with the data for shifting (433 time points from 0.2 to 0.8). These do not make a significant impact on sensitivity results, so were not generated for subsequent runs after 200 MaxPro runs. They can be created using the above script however. The scripts for sensitivity analysis make use of the [ChaosPy Library](https://github.com/jonathf/chaospy/tree/master/chaospy) written in Python. These can be found under `SWMF_QU/MaxProAnalysis/src` 

  * processAllQoIs.jl: Takes in as input the unzipped L1.tgz runs, for example: [Path to unzipped runs for Solar Maximum](https://github.com/danieliong/SWMF_QU/tree/metrics/MaxProAnalysis/data/L1_runs_event_list_2021_06_02_21) and processes simulations and observations for 4 QoIs - Ur, Np, T and B. These can then be written to appropriate path under `Outputs/QoIs`.

