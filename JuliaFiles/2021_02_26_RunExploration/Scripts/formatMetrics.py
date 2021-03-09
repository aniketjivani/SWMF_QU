#!/usr/bin/env python

import json

import numpy as np
import pandas as pd

# relvar = pd.read_csv("output/relvar_96runs.csv")
# relvar["model"] = np.concatenate([["AWSoM"]*8, ["AWSoMR"]*8])
# relvar.set_index(["model","mapCR"], inplace=True)

# relvar_tbl = relvar.to_latex()
# with open("output/relvar_tbl.tex", "w") as f:
#     f.write(relvar_tbl)

rmse = pd.read_csv("output/rmse_96runs.csv")
rmse["model"] = np.concatenate([["AWSoM"] * 8, ["AWSoMR"] * 8])
rmse.set_index(["model", "mapCR"], inplace=True)

rmse_tbl = rmse.to_latex()
with open("output/rmse_tbl.tex", "w") as f:
    f.write(rmse_tbl)

shifted_rmse = pd.read_csv("output/shifted_rmse_96runs.csv")
shifted_rmse["model"] = np.concatenate([["AWSoM"] * 8, ["AWSoMR"] * 8])
shifted_rmse.set_index(["model", "mapCR"], inplace=True)

rmse_tbl = shifted_rmse.to_latex()
with open("output/shifted_rmse_tbl.tex", "w") as f:
    f.write(rmse_tbl)

with open("output/shifted_metrics_dict.json", "r") as f:
    shifted_rmse_json = json.load(f)


def format_traj_res(traj_res):

    new_traj_dict = traj_res.copy()

    rmse_dict = new_traj_dict.pop('RMSEdict')
    del new_traj_dict['RMSE']

    new_traj_dict.update(rmse_dict)

    return new_traj_dict


shifted_rmse = {
    qoi: {eval(key): format_traj_res(val)
          for key, val in traj_dict.items()}
    for qoi, traj_dict in shifted_rmse_json.items()
}


def format_df(rmse_dict):
    df = pd.DataFrame(rmse_dict).T.swaplevel()
    df.sort_index(inplace=True)
    df = df.applymap(lambda x: round(x, 3))
    return df


shifted_rmse_dfs = {key: format_df(val)
                    for key, val in shifted_rmse.items()}

for key in shifted_rmse_dfs.keys():
    caption = f"Shifted \& trimmed RMSE for {key}"
    df_latex = shifted_rmse_dfs[key].to_latex(multirow=True, caption=caption)

    with open(f"output/shifted_rmse_{key}.tex", "w") as f:
        f.write(df_latex)
