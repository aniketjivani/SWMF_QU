#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Aug 24 20:46:13 2021

@author: ajivani
"""

"""
we compare sobol indices obtained from salib and chaospy on a toy problem
SALib is another library for sensitivity analysis that comes equipped with a 
number of methods for doing so. 
"""


from SALib.sample import saltelli
from SALib.analyze import sobol
from SALib.test_functions import Ishigami
import numpy as np
import matplotlib.pyplot as plt
import chaospy as cp

import pandas as pd
import itertools
import os
import re
import math
import random
import time


from sklearn import linear_model as lm

# %% Define model inputs and generate samples

problem = {
    'num_vars': 3,
    'names': ['x1', 'x2', 'x3'],
    'bounds': [[-3.14159265359, 3.14159265359],
               [-3.14159265359, 3.14159265359],
               [-3.14159265359, 3.14159265359]]
}


param_values = saltelli.sample(problem, 1024)

# %% Get model evaluations
Y = Ishigami.evaluate(param_values)

# %% Compute first, second and total order indices

Si = sobol.analyze(problem, Y)


# %% Print first order indices
print(Si['S1'])

# %% Print Interactions
print("x1-x2:", Si['S2'][0,1])
print("x1-x3:", Si['S2'][0,2])
print("x2-x3:", Si['S2'][1,2])

# %% Solve same problem with Chaospy
samples = param_values.T
evaluations = Y

# %% main effects
# change x1, x2, x3 to cp.Uniform(-1, 1) for correct results - we will need higher 
# order PE to capture indices correctly. 
# x1 = cp.Uniform(-3.14159265359, 3.14159265359)
# x2 = cp.Uniform(-3.14159265359, 3.14159265359)
# x3 = cp.Uniform(-3.14159265359, 3.14159265359)


x1 = cp.Uniform(-1, 1)
x2 = cp.Uniform(-1, 1)
x3 = cp.Uniform(-1, 1)

distribution = cp.J(x1, x2, x3)

polynomial_expansion = cp.generate_expansion(5, distribution, normed=True)
model = lm.LinearRegression(fit_intercept=False)

model_approximation = cp.fit_regression(polynomial_expansion,
                                        samples,
                                        evaluations)
sobol_indices = cp.Sens_m(model_approximation, distribution)

print(sobol_indices)

# %% interaction effects

interaction_effects = cp.Sens_m2(model_approximation, distribution)


