#!/usr/bin/env python

import pandas as pd

metrics_path = "output/metrics_table.csv"

metrics_df = pd.read_csv(metrics_path, index_col=["qoi", "model", "mapCR"])

# Resave formatted dataframe
metrics_df.to_csv(metrics_path)

# Save latex table

latex_tbl = metrics_df.to_latex(multirow=True)

latex_path = "output/metrics_table.tex"
with open(latex_path, "w") as f:
    f.write(latex_tbl)
