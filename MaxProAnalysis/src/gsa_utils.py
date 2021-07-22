import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from matplotlib import cm as CM
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
    
    
    return ax



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
    ax.set_ylabel("Sobol Indices Main Effects", fontsize=16)
    # ax.set_xlabel("Coordinates")
    ax.set_ylim([0, 1.0])
    # ax.title.set_text(qoi + " Sobol Indices by timestep\n")
    
    ax.set_title(qoi + " Time varying Sobol Indices", fontsize=20)
    ax.set_xticklabels(ax.get_xticks().astype(int), fontsize=16)
    ax.set_yticklabels(ax.get_yticks().round(1), fontsize=16)
    
    # dateform = mdates.DateFormatter("%b %d")
    # ax.xaxis.set_major_formatter(dateform)
    # ax.xaxis.set_major_locator(mdates.DayLocator(interval=5))
    
    
    return ax

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
    # Adapted from Matplotlib documentation on annotated heatmaps: 
        #1) https://matplotlib.org/stable/gallery/images_contours_and_fields/image_annotated_heatmap.html
    
    

    
    if slice_index is None:
        interaction_values = np.mean(interaction_effects, axis=2)
        ax.set_title("Sobol Indices Main and Interaction Effects Mean", fontsize=20)
        np.fill_diagonal(interaction_values, si.mean(axis=0).to_list())
        mask =  np.tril(interaction_values, k=-1)
        interaction_values = np.ma.array(interaction_values, mask=mask).T
    else:
        interaction_values = interaction_effects[:, :, slice_index]
        ax.set_title("Sobol Indices Main and Interaction Effects " + str(slice_index), fontsize=20)
        # replace zeros on diagonal by main effect values
        np.fill_diagonal(interaction_values, si.iloc[slice_index].to_list())
        mask =  np.tril(interaction_values, k=-1)
        interaction_values = np.ma.array(interaction_values, mask=mask).T
    
    
    fields = si.columns.to_list()
    
    
    
    # Try to change text color depending on the value of the data
    # Set default alignment to center,
    kw = dict(horizontalalignment="center",
              verticalalignment="center",
              fontweight="bold",
              fontsize=12
              )
    textcolors = ("white", "black")


    # Change axis linewidth
    for axis in ['top','bottom','left','right']:
        ax.spines[axis].set_linewidth(2.0)
    
    
    ax.xaxis.set_tick_params(which='major', size=10, width=2, direction='in', top=False)
    
    ax.yaxis.set_tick_params(which='major', size=10, width=2, direction='in', right=True)
    
    
    
    cmap = CM.get_cmap('viridis')
    cmap.set_bad('w')
    
    im = ax.imshow(interaction_values, cmap=cmap, alpha=0.7)
    
    # Set threshold for deciding textcolour
    threshold = im.norm(interaction_values.max())/2
    
    
    
    # We want to show all ticks...
    ax.set_xticks(np.arange(len(fields)))
    ax.set_yticks(np.arange(len(fields)))
    # ... and label them with the respective list entries
    ax.set_xticklabels(fields, fontsize=16)
    ax.set_yticklabels(fields, fontsize=16)
    ax.grid(which="minor", color='w', linestyle='-', linewidth=3)
    
    # Rotate the tick labels and set their alignment.
    plt.setp(ax.get_xticklabels(), rotation=45, ha="right",
             rotation_mode="anchor")
    
    # Loop over data dimensions and create text annotations.
    for i in range(len(fields)):
        for j in range(len(fields)):
                kw.update(color=textcolors[int(im.norm(interaction_values[i, j]) > threshold)])
                text = ax.text(j, i, interaction_values[i, j].round(2),
                               **kw)
    
    fig.tight_layout()
    cbar = fig.colorbar(im)
    cbar.ax.tick_params(labelsize=10) 
    
    
    return fig, ax