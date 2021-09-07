#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Aug 23 12:56:01 2021

@author: ajivani
"""

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

# %% Pick time point, polynomial order and qoi to build approximation
time_pt = 425
polynomial_order = 2
qoi = "Ur"

# %% Set random seed to reproduce results
# random.seed(10)

random.seed(10) # Changing seed for sample_size 20, N=417 to 500

# %% Build distribution

pce_inputs = ['BrMin', 'BrFactor_ADAPT', 'nChromoSi_AWSoM', 'PoyntingFluxPerBSi', 'LperpTimesSqrtBSi', 'StochasticExponent', 'rMinWaveReflection']

BrMin = cp.Uniform(-1, 1)
BrFactor_ADAPT = cp.Uniform(-1, 1)
nChromoSi_AWSoM = cp.Uniform(-1, 1)
PoyntingFluxPerBSi = cp.Uniform(-1, 1)
LperpTimeSqrtBSi = cp.Uniform(-1, 1)
StochasticExponent = cp.Uniform(-1, 1)
rMinWaveReflection = cp.Uniform(-1, 1)

distribution = cp.J(BrMin, BrFactor_ADAPT, nChromoSi_AWSoM, PoyntingFluxPerBSi, LperpTimeSqrtBSi, StochasticExponent, rMinWaveReflection)

# %% Load and process inputs
ips_ops = pd.read_csv("./data/MaxPro_inputs_outputs_event_list_2021_06_02_21.txt")


removed_runs = np.loadtxt("./Outputs/QoIs/code_v_2021_05_17/event_list_2021_06_02_21/removed_runs.txt", dtype='int')


np_runs_to_keep = np.loadtxt("./Outputs/QoIs/code_v_2021_05_17/event_list_2021_06_02_21/np_less_than_hundred.txt", dtype='int')
ips_ops_successful = ips_ops.iloc[np_runs_to_keep - 1]



selected_ips = ips_ops_successful[pce_inputs]

lb = np.array([5.0, 0.54, 2e17, 0.3e6, 0.3e5, 0.1, 1])
ub = np.array([10.0, 2.7, 5e18, 1.1e6, 3e5, 0.34, 1.2])

selected_ips_std = 2 * (selected_ips - 0.5 * (lb + ub)).multiply(1/(ub - lb))
samples = np.array(selected_ips_std)
samples = samples.T
# %% Load and process outputs

simFileName = os.path.join("./Outputs/QoIs/code_v_2021_05_17/event_list_2021_06_02_21", qoi + "Sim_earth.txt")

qoiArray = np.loadtxt(simFileName)
qoiArrayS = qoiArray[:, np_runs_to_keep - 1]

m, n = qoiArrayS.shape
evaluations = qoiArrayS.T[:, 0:m] # Load full array

# evaluations = qoiArrayS.T[:, time_pt]

# %% Perform lasso to obtain model approximation

polynomial_expansion = cp.generate_expansion(polynomial_order, distribution, normed=True)


model = lm.Lasso(alpha = 0.2, fit_intercept=False)

model_approximation = cp.fit_regression(polynomial_expansion, samples, evaluations, model=model)

# %% calculate sobol indices (main effects)
sobol_indices = cp.Sens_m(model_approximation, distribution)
# %%
sobol_indices = pd.DataFrame(sobol_indices.T)
sobol_indices.columns = ['BrMin', 'BrFactor', 'nChromoSi', 'PoyntingFlux', 'Lperp', 'StochExp', 'rMinWaveRefl']


coordinates = np.linspace(1, m, num=m)


# %% Perform linear regression in a loop to obtain confidence intervals

polynomial_expansion = cp.generate_expansion(polynomial_order, distribution, normed=True)

N = 500 # 20 reruns with same sample size
sample_size = 20
si_subsets = np.zeros((N, 7))
sample_idx_used = np.zeros((sample_size, N))


# model = lm.Lasso(alpha = 0.2, fit_intercept=False)
model = lm.LinearRegression(fit_intercept=False)

start_time = time.time()

for run in range(N):
    sample_idx = random.sample(range(69), sample_size)
    # if run == 119: # only for sample size = 20
    #     sample_idx = random.sample(range(69), sample_size)
    sample_idx_used[:, run] = sample_idx
    samples_subset = samples[:, sample_idx]
    evaluations_subset = evaluations[sample_idx]
    ma_subset=cp.fit_regression(polynomial_expansion,
                                samples_subset, 
                                evaluations_subset,
                                model=model)
    si_subsets[run, :] = cp.Sens_m(ma_subset, distribution)
    elapsed_time = time.time() - start_time
    print(run)
    print(elapsed_time)







# %% Analyze results




