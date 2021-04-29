import os
import re
from os import path

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import methodtools

from matplotlib.backends.backend_pdf import PdfPages

class DataProcessor():
    def __init__(self, 
                 type="obs", 
                 dir=None, 
                 cached=False, 
                 verbose=False,
                 **kwargs):
        
        self.type = type
        self.dir = dir
        self.kwargs = kwargs
        self.cached = cached 
        self.verbose = verbose

    def __call__(self, vars='all', *args, **kwargs):
        # Remaining arguments go into get_*_filename function
        # verbose=True prints information about how data is processed. 

        # self.kwargs overrides kwargs
        # kwargs.update(self.kwargs)
        
        kwargs_ = self.kwargs.copy()
        kwargs_.update(kwargs) 

        if self.type == "obs":
            filename = self.get_obs_filename(*args, dir=self.dir, **kwargs_)
        elif self.type == "sim":
            filename = self.get_sim_filename(*args, dir=self.dir, **kwargs_)

        if self.cached:
            data = self.get_cached_data(filename, verbose=self.verbose)
        else:
            data = self.read_data(filename, verbose=self.verbose)
            data = self.format_time(data, copy=False, verbose=self.verbose)
            data = self.process_data(data, copy=False, verbose=self.verbose)
        
        if vars != 'all':
            data = data[vars]

        return data

    @staticmethod
    def get_obs_filename(location="earth", time="2012_05_11T20_00_00",
                         dir=None, **kwargs):

        if dir is None:
            dir = os.getcwd()

        # Make names consistent with simulation runs
        source = "omni" if location=="earth" else location

        rel_filename = f"{source}_{time}.out"
        filename = path.join(dir, "obsdata", rel_filename)

        return filename
    
    
    def _get_sim_dir(self, param='0.35e6',
                     model="AWSoMR", mag_method="HARMONICS_adapt", time="201205162000",
                     param_name="MapTime_PoyntingFluxPerBSi",
                     **kwargs):

        # kwargs.update(self.kwargs)
        # kwargs_ = self.kwargs.copy()
        # kwargs_.update(kwargs)
        
        dirs = next(os.walk(path.expanduser(self.dir)))[1]

        r_dir = re.compile(
            f'.*_{model}_{mag_method}_{time}_{param_name}_{param}')
        sim_dir_name = [d for d in dirs if r_dir.match(d)][0]
        sim_dir = path.expanduser(path.join(self.dir, sim_dir_name))
        
        return sim_dir

    def get_sim_filename(self, location="earth", param='0.35e6', run_num=1,
                         model="AWSoMR", mag_method="HARMONICS_adapt", time="201205162000",
                         param_name="MapTime_PoyntingFluxPerBSi",
                         type="trj", ext="sat", dir=None, **kwargs):
        
        sim_dir = self._get_sim_dir(param=param, model=model, 
                                    mag_method=mag_method, time=time, 
                                    param_name=param_name, dir=dir)

        path_ = path.join(sim_dir, f"run{run_num:02}", "IH")
        r_file = re.compile(
            f"{type}_{location}_.*\.{ext}$")
        rel_filename = [f for f in os.listdir(path_) if r_file.match(f)][0]

        filename = path.join(path_, rel_filename)
        return filename

    def read_data(self, filename, verbose=False):

        if verbose:
            print(f"* Reading data from {filename}.")

        if self.type == "obs":
            data = pd.read_table(
                filename, skiprows=3, delim_whitespace=True, index_col=0)
        elif self.type == "sim":
            data = pd.read_table(
                filename, skiprows=1, delim_whitespace=True)

        return data
    
    def get_run_nums(self, param, **kwargs):

        # kwargs.update(self.kwargs)
        # kwargs_ = self.kwargs.copy()
        # kwargs_.update(kwargs)

        def get_run_num(file):
            r_run = re.compile('run(\d+)$')
            return int(r_run.search(file).group(1))

        sim_dir = self._get_sim_dir(param, **kwargs)
        run_files = next(os.walk(sim_dir))[1]
        run_nums = [get_run_num(f) for f in run_files]
        run_nums.sort()

        return run_nums


    def format_time(self, data, copy=True, verbose=False):
        time_cols_dict = {
            'year': 'year',
            'mo': 'month',
            'dy': 'day',
            'hr': 'hour',
            'mn': 'minute',
            'sc': 'second',
        }
        if self.type == "sim":
            time_cols_dict['msc'] = "ms"
        
        data_ = data.copy() if copy else data

        # Convert time columns to pd.DatetimeIndex
        try:
            new_time_cols = time_cols_dict.values()
            data_.rename(columns=time_cols_dict, inplace=True)
            data_['time'] = pd.to_datetime(
                data_[new_time_cols])        
            data_.set_index('time', inplace=True)
            data_.drop(columns=new_time_cols, inplace=True)
        except KeyError:
            # Check if time already processed 
            if not isinstance(data_.index, pd.DatetimeIndex):
                raise ValueError("Times are missing.")
        else:
            if verbose:
                print("* Replaced time columns with DateTimeIndex.")
        
        return data_
    
    def process_data(self, data, copy=True, verbose=False):
        
        data_ = data.copy() if copy else data
        
        if self.type == "sim":
            # Drop iteration column 
            if "it" in data_.columns:
                data_.drop(columns=["it"], inplace=True)
            if verbose:
                print("* Dropped column it.")

            # Compute B_tot, temperature, V_tot, Rho for simulated data
            data_.eval(
                '''
                B_tot = ((Bx**2 + By**2 + Bz**2)**0.5) * 1e5  
                Temperature = ((P * (1.67e-24/Rho)) / 1.3807e-23) * 1e-7
                V_tot = (Ux*X + Uy*Y + Uz*Z) / ((X**2 + Y**2 + Z**2)**0.5)
                Rho = (Rho / 1.67e-24)
                ''',
                inplace=True
            )
            if verbose:
                print("* Computed B_tot, Temperature, V_tot.")
        
        # Replace negative values in magnitude variables with np.nan
        for var in ['Rho', 'V_tot', 'Temperature','B_tot']:
            neg_val_mask = (data_[var] < 0)
            data_[var][neg_val_mask] = np.nan
            if verbose:
                n_neg_val = np.sum(neg_val_mask)
                if n_neg_val > 0:
                    print(f"* Replaced {n_neg_val} negative value(s) in {var} with np.nan.")
            
        return data_

    @methodtools.lru_cache(maxsize=64)
    def get_cached_data(self, filename, verbose=False):
        data = self.read_data(filename, verbose=verbose)
        data = self.format_time(data, copy=True, verbose=verbose)
        data = self.process_data(data, copy=True, verbose=verbose)
        return data

def plot_trajectories(location, param, vars, dir="~/Dropbox/Results",
                      figsize=(15,10), **sim_params):

    obs = DataProcessor(type="obs", dir=dir)
    sim = DataProcessor(type="sim", dir=dir, **sim_params)

    obs_data = obs(vars=vars, location=location)

    run_nums = sim.get_run_nums(param=param)

    fig, axes = plt.subplots(nrows=len(vars), ncols=1, figsize=figsize, 
                             sharex=True)

    for i, var in enumerate(vars):
        obs_data[var].plot(ax=axes[i], color='red')

        for num in run_nums:
            sim_data = sim(vars=vars, run_num=num, location=location, 
                           param=param)
            sim_data[var].plot(ax=axes[i], color='grey', alpha=0.7)

        axes[i].set_ylabel(var)
        axes[i].set_xlabel("")

    return fig, axes


def plot_location(location, vars, params,
                  save=True, pdf=None, filename=None,
                  plot_dir="plots", dir="~/Dropbox/Results",
                  **kwargs):

    if filename is None:
        filename = f"traj_plots_{location}.pdf"
    filename = path.join(plot_dir, filename)

    create_new_pdf = (save and pdf is None)
    if create_new_pdf:
        pdf = PdfPages(filename)

    for param in params:
        fig, axes = plot_trajectories(vars=vars,
                                      location=location,
                                      param=param,
                                      dir=dir,
                                      **kwargs)
        # fig.suptitle(str(param))
        axes[len(vars)-1].set_xlabel(f"{location}, {param}")
        fig.tight_layout()

        if save:
            pdf.savefig(fig)
        else:
            fig.show()

    if create_new_pdf:
        pdf.close()

    return None


def plot_param(param, vars, locations,
               save=True, pdf=None, filename=None, plot_dir="plots",
               dir="~/Dropbox/Results", **kwargs):

    if filename is None:
        filename = f"traj_plots_{param}.pdf"
    filename = path.join(plot_dir, filename)

    create_new_pdf = (save and pdf is None)
    if create_new_pdf:
        pdf = PdfPages(filename)

    for location in locations:
        fig, axes = plot_trajectories(vars=vars,
                                      location=location,
                                      param=param,
                                      dir=dir,
                                      **kwargs)
        # fig.suptitle(str(location))
        axes[len(vars)-1].set_xlabel(f"{location}, {param}")
        fig.tight_layout()

        if save:
            pdf.savefig(fig)
        else:
            fig.show()

    if create_new_pdf:
        pdf.close()

    return None


def plot_all_trajectories(locations, params, vars, by="params",
                          save=True, filename="traj_plots_all.pdf",
                          plot_dir="plots", dir="~/Dropbox/Results",
                          **kwargs):

    filename = path.join(plot_dir, filename)

    if save:
        pdf = PdfPages(filename)

    if by == "params":
        for param in params:
            plot_param(param, vars, locations, save=save, pdf=pdf, **kwargs)
    elif by == "locations":
        for location in locations:
            plot_location(location, vars, params, save=save, pdf=pdf, **kwargs)

    if save:
        pdf.close()

    return None
