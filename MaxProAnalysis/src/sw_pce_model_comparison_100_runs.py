#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Solar Max / Solar Min (depending on arguments)
"""
# Incomplete!!

import numpy as np
import matplotlib.pyplot as plt 
import pandas as pd
import itertools
import os
import re
import math
import random

from sklearn import linear_model as lm
import chaospy as cp

from src import gsa_utils


from matplotlib.backends.backend_pdf import PdfPages

# %%

md = "AWSoM"
cr = 2152


# %%
random.seed(10)

# %% Define params, distributions
BrMin = cp.Uniform(-1, 1)
BrFactor_ADAPT = cp.Uniform(-1, 1)
nChromoSi_AWSoM = cp.Uniform(-1, 1)
PoyntingFluxPerBSi = cp.Uniform(-1, 1)
LperpTimeSqrtBSi = cp.Uniform(-1, 1)
StochasticExponent = cp.Uniform(-1, 1)
rMinWaveReflection = cp.Uniform(-1, 1)
# %% Build for ADAPT and AWSoM

pce_inputs = ['BrMin', 'BrFactor_ADAPT', 'nChromoSiAWSoM', 'PoyntingFluxPerBSi', 'LperpTimesSqrtBSi', 'StocasticExponent', 'rMinWaveReflection']

distribution = cp.J(BrMin, BrFactor_ADAPT, nChromoSi_AWSoM, PoyntingFluxPerBSi, LperpTimeSqrtBSi, StochasticExponent, rMinWaveReflection)


polynomial_order = 2

# %% process data

ips_ops = pd.read_csv("./data/QMC_Data_for_event_lists/revised_thresholds/X_design_QMC_masterList_solarMax_AWSoM_reducedThreshold.csv")

ips_ops = ips_ops[:100]

removed_runs = np.loadtxt("./Outputs/QoIs/code_v_2021_05_17/event_list_2021_07_11_AWSoM_CR2152/failed_and_excluded_runs.txt", dtype='int')

ips_ops_successful = ips_ops.drop(index=removed_runs - 1)

selected_ips = ips_ops_successful[pce_inputs]

lb = np.array([0.0, 0.54, 2e17, 0.3e6, 0.3e5, 0.1, 1])
ub = np.array([10.0, 2.7, 5e18, 1.1e6, 3e5, 0.34, 1.2])

selected_ips_std = 2 * (selected_ips - 0.5 * (lb + ub)).multiply(1/(ub - lb))
samples = np.array(selected_ips_std)
samples = samples.T
# %% 

qoi = "Np"

simFileName = os.path.join("./Outputs/QoIs/code_v_2021_05_17/", "event_list_2021_07_11_" + md + "_CR" + str(cr), qoi + "Sim_earth.txt")

qoiArray = np.loadtxt(simFileName)
qoiArrayS = np.delete(qoiArray, removed_runs - 1, axis=1)

m, n = qoiArrayS.shape
evaluations = qoiArrayS.T[:, 0:m]



polynomial_expansion = cp.generate_expansion(polynomial_order, distribution, normed=True)


model = lm.Lasso(alpha = 0.2, fit_intercept=False)

model_approximation = cp.fit_regression(polynomial_expansion, samples, evaluations, model=model)

mean = cp.E(model_approximation, distribution)
var = cp.Var(
     model_approximation, distribution)

# calculate sobol indices (main effects)
sobol_indices = cp.Sens_m(model_approximation, distribution)
sobol_indices = pd.DataFrame(sobol_indices.T)
sobol_indices.columns = ['BrMin', 'BrFactor', 'nChromoSi', 'PoyntingFlux', 'Lperp', 'StochExp', 'rMinWaveRefl']


coordinates = np.linspace(1, m, num=m)
# %% Calculate order 2 interactions (needs to be speeded up for further study)
interaction_effects = cp.Sens_m2(model_approximation, distribution)

# %% Make barplot
figBar, axBar = plt.subplots(1, figsize=(12, 10))
gsa_utils.sobol_indices_barplot(sobol_indices, qoi, ax=axBar)
figBar.legend(sobol_indices.columns, frameon=False, ncol=7, loc="lower center")
