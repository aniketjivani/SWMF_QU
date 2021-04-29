# %%
import matplotlib.pyplot as plt
from utils import DataProcessor, plot_all_trajectories, plot_param
import re
import os

# %%
obs = DataProcessor(type="obs", dir="~/Dropbox/Results")
sim = DataProcessor(type="sim", dir="~/Dropbox/Results", cached=False,
                    verbose=True)

# Choices for observed data
sources = ['omni', 'sta', 'stb']

# Choices for simulated data
locations = ['earth', 'sta', 'stb']
params = ['0.3e6', '0.35e6', '0.4e6', '0.45e6', '0.5e6', '0.55e6']
vars = ['Rho', 'V_tot', 'Temperature', 'B_tot']

# Test utils
# sim(param='0.4e6')
# sim(vars=vars, param='0.35e6')
# sim.get_run_nums('0.3e6'),
# fig, axes = plot_trajectories(vars=vars, location="earth", param="0.3e6")

# %% 

# Make plots 
plot_all_trajectories(locations=locations, params=params, vars=vars)

# for param in params:
#     plot_param(param, vars, locations, save=False, verbose=True, cached=True)

# %%
obs(location='earth')
sim(param='0.35e6', location="earth", run_num=1, verbose=True)

