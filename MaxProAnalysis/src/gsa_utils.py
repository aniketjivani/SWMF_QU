#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jun  1 11:39:25 2021

@author: ajivani
"""


import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import pandas as pd
import numpy as np
# %% Stacked Bar Plot


def sobol_indices_plot(si, qoi, ax=None, **kwargs):
    if ax is None:
        ax = plt.gca()
        
    # s = pd.Series(obs_dates)
    # si.set_index(s)
    si[si.columns].plot.line(ax=ax, legend=False)
    # ax.legend(bbox_to_anchor=(1.05,1), loc='upper left')
    ax.set_ylabel("Sobol Indices Main Effects")
    ax.set_xlim([0, len(si)])
    
    # ax.set_xlabel("Coordinates")
    ax.title.set_text(qoi)
    
    # dateform = mdates.DateFormatter("%b %d")
    # ax.xaxis.set_major_formatter(dateform)
    # ax.xaxis.set_major_locator(mdates.DayLocator(interval=7))
    
    
    return(ax)



def sobol_indices_barplot(si, qoi, ax=None, **kwargs):
    if ax is None:
        ax=plt.gca()
    fields = si.columns.to_list()
    
    # s = pd.Series(obs_dates)
    # si.set_index(s)
    
    bottom = len(si) * [0]
    for idx, name in enumerate(fields):
        ax.bar(si.index, si[name], bottom=bottom)
        bottom = bottom + si[name]
    ax.set_ylabel("Sobol Indices Main Effects")
    # ax.set_xlabel("Coordinates")
    ax.set_ylim([0, 1.0])
    ax.title.set_text(qoi + " Sobol Indices by timestep\n")
    
    
    # dateform = mdates.DateFormatter("%b %d")
    # ax.xaxis.set_major_formatter(dateform)
    # ax.xaxis.set_major_locator(mdates.DayLocator(interval=5))
    
    
    return(ax)

# %% 
def interaction_effect_heatmap(si, interaction_effects, slice_index=None, fig=None, ax=None, **kwargs):
    """
    Parameters
    ----------
    si : DataFrame
        DataFrame of Sobol Indices main effects. Dimensions M x K
        where M is the number of parameters and K is the number of time points.
    interaction_effects : 3D array 
        Contains pairwise interactions of each parameter at different time points. Dimension = M x M x K 
    slice_index : int
        Time point where we wish to view the interaction heatmap. If None, we view the mean interaction effect heatmap.
    fig : TYPE, optional
        Figure handle to plot
    ax : TYPE, optional
        Axis handle to plot.
    **kwargs : TYPE
        DESCRIPTION.

    Returns
    -------
    fig, ax: Handles of figure and axis containing the heatmap. 

    """
    # Adapted from Matplotlib documentation on annotated heatmaps: https://matplotlib.org/stable/gallery/images_contours_and_fields/image_annotated_heatmap.html
    
    if slice_index is None:
        interaction_values = np.max(interaction_effects, axis=2)
        ax.set_title("Sobol Indices Interaction Effects Mean")
        np.fill_diagonal(interaction_values, si.max(axis=0).to_list())
    else:
        interaction_values = interaction_effects[:, :, slice_index]
        ax.set_title("Sobol Indices Interaction Effects " + str(slice_index))
        # replace zeros on diagonal by main effect values
        np.fill_diagonal(interaction_values, si.iloc[slice_index].to_list())
    
    
    fields = si.columns.to_list()
    
    im = ax.imshow(interaction_values, cmap='viridis')
    
    # We want to show all ticks...
    ax.set_xticks(np.arange(len(fields)))
    ax.set_yticks(np.arange(len(fields)))
    # ... and label them with the respective list entries
    ax.set_xticklabels(fields)
    ax.set_yticklabels(fields)
    
    
    # Rotate the tick labels and set their alignment.
    plt.setp(ax.get_xticklabels(), rotation=45, ha="right",
             rotation_mode="anchor")
    
    # Loop over data dimensions and create text annotations.
    for i in range(len(fields)):
        for j in range(len(fields)):
            text = ax.text(j, i, interaction_values[i, j].round(2),
                           ha="center", va="center", color="w")
    
    
    fig.tight_layout()
    fig.colorbar(im)
    
    return fig, ax