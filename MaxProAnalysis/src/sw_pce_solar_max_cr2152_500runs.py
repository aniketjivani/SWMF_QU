#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# this is sensitivity analysis performed for event_list_2021_07_30_AWSoM_CR2152
# from summary, we have 432 successful runs to work with. 

# %% Import packages

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import itertools
import os
import re
import math
import random
import time


from sklearn import linear_model as lm
import chaospy as cp

from src import gsa_utils
from matplotlib.backends.backend_pdf import PdfPages

# %% Pick polynomial order, qoi and other settings to build approximation
polynomial_order = 2
qoi = "Ur"
mg = "ADAPT"
md = "AWSoM"
cr = 2152

# %% Set random seed to reproduce results - currently not in use
random.seed(10) 

# %% Build distribution

pce_inputs = ['BrMin', 'BrFactor_ADAPT', 'nChromoSiAWSoM', 'PoyntingFluxPerBSi', 'LperpTimesSqrtBSi', 'StocasticExponent', 'rMinWaveReflection']

BrMin = cp.Uniform(-1, 1)
BrFactor_ADAPT = cp.Uniform(-1, 1)
nChromoSi_AWSoM = cp.Uniform(-1, 1)
PoyntingFluxPerBSi = cp.Uniform(-1, 1)
LperpTimeSqrtBSi = cp.Uniform(-1, 1)
StochasticExponent = cp.Uniform(-1, 1)
rMinWaveReflection = cp.Uniform(-1, 1)

distribution = cp.J(BrMin, BrFactor_ADAPT, nChromoSi_AWSoM, PoyntingFluxPerBSi, LperpTimeSqrtBSi, StochasticExponent, rMinWaveReflection)

# %% Specify paths
QOIS_PATH = os.path.join("./Outputs/QoIs/code_v_2021_05_17/", "event_list_2021_07_30_AWSoM_CR" + str(cr))

# %% Load and process inputs
ips_ops = pd.read_csv(os.path.join("./data/QMC_Data_for_event_lists/revised_thresholds/", "X_design_QMC_masterList_solarMax" + "_" + "AWSoM" + "_" + "reducedThreshold.txt"), delimiter="\t")

ips_ops = ips_ops.iloc[range(100, 600)]

runs_to_keep = np.loadtxt(os.path.join(QOIS_PATH, "runs_to_keep.txt"), dtype='int')

ips_ops_successful = ips_ops.iloc[runs_to_keep - 1 - 100]

selected_ips = ips_ops_successful[pce_inputs]

lb = np.array([0.0, 0.54, 2e17, 0.3e6, 0.3e5, 0.1, 1])
ub = np.array([10.0, 2.7, 5e18, 1.1e6, 3e5, 0.34, 1.2])

selected_ips_std = 2 * (selected_ips - 0.5 * (lb + ub)).multiply(1/(ub - lb))
samples = np.array(selected_ips_std)
samples = samples.T
# %% Load and process outputs

simFileName = os.path.join(QOIS_PATH, qoi + "Sim_earth.txt")

qoiArray = np.loadtxt(simFileName)
qoiArrayS = qoiArray[:, runs_to_keep - 1 - 100]

m, n = qoiArrayS.shape
evaluations = qoiArrayS.T[:, 0:m] # Load full array

# evaluations = qoiArrayS.T[:, time_pt]

# %% Perform lasso to obtain model approximation

polynomial_expansion = cp.generate_expansion(polynomial_order, distribution, normed=True)

# TO-DO: Put cross validation procedure to select alpha in here!!

model = lm.Lasso(alpha = 0.5, fit_intercept=False)



model_approximation = cp.fit_regression(polynomial_expansion, samples, evaluations, model=model)

# %% calculate sobol indices (main effects)
sobol_indices = cp.Sens_m(model_approximation, distribution)
# %%
sobol_indices = pd.DataFrame(sobol_indices.T)
sobol_indices.columns = ['BrMin', 'BrFactor', 'nChromoSi', 'PoyntingFlux', 'Lperp', 'StochExp', 'rMinWaveRefl']


coordinates = np.linspace(1, m, num=m)


#%% interaction effects
interaction_effects = cp.Sens_m2(model_approximation, distribution)
# %% Make barplot
figBar, axBar = plt.subplots(1, figsize=(12, 10))
gsa_utils.sobol_indices_barplot(sobol_indices, qoi, ax=axBar)
figBar.legend(sobol_indices.columns, frameon=False, ncol=7, loc="lower center")
