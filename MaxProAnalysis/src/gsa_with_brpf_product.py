#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jul 13 18:46:30 2021

@author: ajivani
"""

# Re attempt of sensitivity analysis but with the product of BrFactor and PoyntingFlux as a new factor and dropping PoyntingFlux from the joint `distribution`. 

# Uses runs from event_list_2021_06_02_21

# to be updated with 

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

# %% Pick polynomial order and QOI to build approximation
polynomial_order = 2
qoi = "Ur"

# %% Set random seed to reproduce results
random.seed(10)

# %% Build distribution
pce_inputs = ['BrMin', 'BrFactor_ADAPT', 'nChromoSi_AWSoM', 'PoyntingFluxPerBSi', 'LperpTimesSqrtBSi', 'StochasticExponent', 'rMinWaveReflection']

BrMin = cp.Uniform(0, 1)
BrFactor_ADAPT = cp.Uniform(0, 1)
nChromoSi_AWSoM = cp.Uniform(0, 1)
PoyntingFluxPerBSi = cp.Uniform(0, 1)
LperpTimeSqrtBSi = cp.Uniform(0, 1)
StochasticExponent = cp.Uniform(0, 1)
rMinWaveReflection = cp.Uniform(0, 1)

# define parameter for product
# define uniform for product

BrPF = cp.Uniform(0, 1)

distribution = cp.J(BrFactor_ADAPT, nChromoSi_AWSoM, BrPF, LperpTimeSqrtBSi, StochasticExponent, rMinWaveReflection)

# distribution = cp.J(BrMin, BrFactor_ADAPT, nChromoSi_AWSoM, BrPF, LperpTimeSqrtBSi, StochasticExponent, rMinWaveReflection)

# %% process data
ips_ops = pd.read_csv("./data/MaxPro_inputs_outputs_event_list_2021_06_02_21.txt")


removed_runs = np.loadtxt("./Outputs/QoIs/code_v_2021_05_17/event_list_2021_06_02_21/removed_runs.txt", dtype='int')


np_runs_to_keep = np.loadtxt("./Outputs/QoIs/code_v_2021_05_17/event_list_2021_06_02_21/np_less_than_hundred.txt", dtype='int')
ips_ops_successful = ips_ops.iloc[np_runs_to_keep - 1]



selected_ips = ips_ops_successful[pce_inputs]

lb = np.array([5.0, 0.54, 2e17, 0.3e6, 0.3e5, 0.1, 1])
ub = np.array([10.0, 2.7, 5e18, 1.1e6, 3e5, 0.34, 1.2])

selected_ips_std = (selected_ips - lb).multiply(1/(ub - lb))

BrPF_samples_std = selected_ips_std['BrFactor_ADAPT'] *         selected_ips_std['PoyntingFluxPerBSi']


# New lines to drop Poynting Flux column!!
selected_ips_std.drop(['BrFactor_ADAPT', 'PoyntingFluxPerBSi'], axis=1, inplace=True)
selected_ips_std['BrPF'] = BrPF_samples_std
new_column_names = ['BrMin', 'nChromoSi_AWSoM', 'BrPF', 'LperpTimesSqrtBSi', 'StochasticExponent', 'rMinWaveReflection']
selected_ips_std = selected_ips_std[new_column_names]

samples = np.array(selected_ips_std)
samples = samples.T


# %% Load and process outputs

simFileName = os.path.join("./Outputs/QoIs/code_v_2021_05_17/event_list_2021_06_02_21", qoi + "Sim_earth.txt")

qoiArray = np.loadtxt(simFileName)
qoiArrayS = qoiArray[:, np_runs_to_keep - 1]

m, n = qoiArrayS.shape
evaluations = qoiArrayS.T[:, 0:m] # Load full array

# %% 

polynomial_expansion = cp.generate_expansion(polynomial_order, distribution, normed=True)


model = lm.Lasso(alpha = 0.2, fit_intercept=False)

model_approximation = cp.fit_regression(polynomial_expansion, samples, evaluations, model=model)

# %% calculate sobol indices (main effects)

sobol_indices = cp.Sens_m(model_approximation, distribution)
# %%
sobol_indices = pd.DataFrame(sobol_indices.T)
sobol_indices.columns = ['BrMin', 'BrFactor', 'nChromoSi', 'BrPF', 'Lperp', 'StochExp', 'rMinWaveRefl']


coordinates = np.linspace(1, m, num=m)


# %% 
