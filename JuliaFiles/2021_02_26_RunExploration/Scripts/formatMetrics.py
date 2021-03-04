#!/usr/bin/env python

import pandas as pd
import numpy as np

relvar = pd.read_csv("output/relvar_96runs.csv")
relvar["model"] = np.concatenate([["AWSoM"]*8, ["AWSoMR"]*8])
relvar.set_index(["model","mapCR"], inplace=True)

relvar_tbl = relvar.to_latex()
with open("output/relvar_tbl.tex", "w") as f:
    f.write(relvar_tbl)

rmse = pd.read_csv("output/rmse_96runs.csv")
rmse["model"] = np.concatenate([["AWSoM"]*8, ["AWSoMR"]*8])
rmse.set_index(["model","mapCR"], inplace=True)

rmse_tbl = rmse.to_latex()
with open("output/rmse_tbl.tex", "w") as f:
    f.write(rmse_tbl)
