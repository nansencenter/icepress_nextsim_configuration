# User manual for running neXtSIM forecast for ICEPRESS

## 1. Docker image

A Docker image is created to run all steps of processing required to forecast sea ice with neXtSIM:
* To download and preprocess input data
* To run neXtSIM to simulate sea ice
* To post-process the forecast outputs

The image is built from four layers:
* `nextsim-base`, contains all libraries for building neXTSIM and code for downloading and preprocessing input data
* `nextsim`, compiled neXTSIM model
* `nextsim-tools`, Python library to process neXtSIM input and output data
* `nextsimf`, the forecasting platform that prepares data for running forecasts (e.g., assimilation) and post-processes the results

The image is provided upon contact with NERSC. You can build and run a Docker container from this image, or convert it to other formats, for example, Apptainer.

## 2. Input data

The input data consists of static files, which are always the same, and dynamic files, which include oceanic and atmospheric forcing and satellite observations.
The input data resides outside the Docker container, and the container mounts the directories when it runs.

### 2.1. Input data directory structure

There are five directories with input data:
1. `data` contains symbolic links to the input files that are needed to run the simulation. The links are automatically created by the `run_forecast` script if the input files are downloaded correctly and are available.
2. `mesh` contains a static triangular mesh and an MPP file.
3. `input_obs` contains dynamic data (input satellite observations) and static data (bathymetry and neXtSIM output grids).
4. `input_forecast` contains dynamic data: input oceanic and weather forecasts.
5. `working` contains configuration and authentication files. 

The input dynamic data is downloaded using scripts provided in the Docker image  (see below). NERSC provides the input static data upon contact.

The data directories can be located anywhere on the host and must be configured for the host and for the container (see below).

### 2.2. Static data

#### 2.2.1. Mesh file

`mesh/large_arctic_bering_10km_JBFpatch.msh` contains an initial triangular mesh at ~ 10 km resolution. The first neXtSIM run is initialised from this mesh, and subsequent runs restart from the previous run's final output.
`mesh/large_arctic_bering_10km.msh` contains a triangular mesh at ~ 10 km resolution. It is used for postprocessing.
#### 2.2.2. NPP file

`mesh/NpsNextsim.mpp` contains mapping information used by neXtSIM

#### 2.2.3. Bathymetry

`input_obs/BATHYMETRY/ETOPO_Arctic_2arcmin.nc` contains bathymetry of the Arctic at high resolution

#### 2.2.4. Nextsim output grid template

`input_obs/nextsim_output_grids/topaz6_grid.nc` contains a default definition of the grid for neXtSIM outputs. This file can be changed, e.g. cropped, to output only a spatial subset of the forecast

### 2.3. Dynamic data

Dynamic data consists of ocean and weather forecast data, and satellite observations.

#### 2.3.1. Ocean and weather forecasts

The weather forecast is from the NCEP Global Forecast System (GFS). It is downloaded from the THREDDS server and saved as NetCDF files in `input_forecast`. Use [`download_weather_forcing.sh`](./download_weather_forcing.sh) to download it.

The ocean forecast is the Arctic TOPAZ forecast from the Arctic Marine Forecasting Center, provided through the Copernicus Marine Service. Use [`download_ocean_forcing.sh`](./download_ocean_forcing.sh) to download it.

#### 2.3.2. Satellite observations

Satellite observations consist of sea ice concentration from AMSR-3 and the Arctic High Resolution product, available through the Copernicus Marine Service. The downloaded observations are stored in `input_obs`. Use [`download_osisaf_sic.sh`](./download_osisaf_sic.sh) for AMSR-3 sea ice concentration and [`download_asip_icecharts.sh`](./download_asip_icecharts.sh) for the Arctic High Resolution product.


## 3. Configuration files

### 3.1. Overall structure

The configuration is split across three files:

1. The host environment file (`.env`) defines the locations of the data directories on the host.
2. `docker-compose.yml` defines the corresponding paths inside the container and mounts the host directories at those paths.
3. `config_files/icepress.cfg`, located in the working directory, contains settings for running the forecast.

### 3.2. Host configuration

Set the directory paths in `.env` for the host where the forecast will run. The `.env.example` file provides a template:

* `INPUT_OBSERVATIONS` is the host path to the observations directory.
* `INPUT_FORECAST` is the host path to the forecast input directory.
* `OUTPUT` is the host path for forecast output.
* `DATA_DIR` is the host path to the data directory.
* `MESH_DIR` is the host path to the mesh directory.
* `WORK_DIR` is the host path to the working directory.

### 3.3. Container configuration

In `docker-compose.yml`, the `environment` section sets the directory variables used by the applications inside the container. The `volumes` section mounts the corresponding host directories into the container:

| Host variable | Container variable | Container path |
| --- | --- | --- |
| `INPUT_OBSERVATIONS` | `INPUT_OBS_DATA_DIR` | `/input_obs` |
| `INPUT_FORECAST` | `INPUT_FORECAST_DATA_DIR` | `/input_forecast` |
| `OUTPUT` | `OUTPUT_FORECAST_DATA_DIR` | `/output` |
| `DATA_DIR` | `NEXTSIM_DATA_DIR` | `/data` |
| `MESH_DIR` | `NEXTSIM_MESH_DIR` | `/mesh` |
| `WORK_DIR` | `NEXTSIM_ENV_ROOT_DIR` | `/env_root` |

For example, the host directory set by `INPUT_OBSERVATIONS` is mounted at `/input_obs` in the container, and `INPUT_OBS_DATA_DIR` is set to that container path. The other directory variables follow the same pattern.

### 3.4. Forecast configuration

The forecast configuration file is `config_files/icepress.cfg` in the working directory. Since `WORK_DIR` is mounted at `/env_root`, the file is available inside the container at `/env_root/config_files/icepress.cfg`. It contains settings for the forecast run, including assimilation, forcing types, mesh, simulation, restart, and output configuration.

The file is organized into sections:

* **`[forecast]`** controls restart and reforecast behavior. `allow_no_restart=true` allows the forecast to start from scratch when no suitable restart is available. `restart_tolerance` sets how old a restart can be and still be used, in days: with the current value of `1`, a restart older than one day is not used and the forecast starts from scratch. Increasing this to `2` allows a restart up to two days old. `reforecast=false` disables reforecast mode; in this configuration, available analysis data can be used rather than requiring forecast data from the ocean and weather systems.
* **`[assimilation]`** configures assimilation of satellite observations. The current settings enable assimilation using `AssimConcASIP`, which assimilates sea ice concentration from the ASIP product. The other parameters tune the assimilation; the current values are the working defaults for this setup.
* **`[cmems]`, `[cmems_mpf_dim]`, and `[cmems_mpf]`** configure preparation and metadata for Copernicus Marine Service products. They are not used in the ICEPRESS forecast workflow.
* **`[compress_moorings]`** and **`[local_storage]`** control compression and storage retention for the Copernicus Marine Service workflow. They are not used by ICEPRESS.
* **`[mpi]`** configures parallel execution. `num_tasks` sets the number of MPI processes (currently `8`), `mpi_run_command` specifies the MPI launcher, and `num_tasks_option_name` specifies the option used to pass the process count to it.
* **`[nextsim]`** contains the neXtSIM model configuration, including mesh and forcing types, simulation settings, thermodynamics, dynamics, restarts, and output. These parameters determine how the model is initialized and run; do not modify them unless you intend to change the model configuration. Within this section, `moorings.use_moorings=true` enables mooring output, and the `moorings.*` settings define its grid, output frequency, file length, and variables. The mooring NetCDF files are written to the configured output directory.
* **`[plot_moorings]`** configures plots from the output mooring NetCDF files, including the variables and plot settings. Plotting is currently disabled by `plot_moorings=false`; set it to `true` to enable it.


## 4. Downloading data

### 4.1. Authenticate with Copernicus Marine

Create an account on the Copernicus Marine Service website if you do not already have one. From the repository directory, start an interactive container:

```sh
./run_bash.sh
```

At the container prompt, run the Copernicus Marine login command and enter your account username and password when prompted:

```sh
copernicusmarine login
```

Docker Compose mounts the host directory `${WORK_DIR}/.copernicusmarine` at `/root/.copernicusmarine` in the container. The login credentials are therefore saved in that mounted directory on the host and can be reused by the download scripts.

### 4.2. Downloading and post-processing oceanic forcing

To download the oceanic forcing run the wrapper script from the repository directory:

```sh
./download_ocean_forcing.sh
```

The wrapper starts a container using the `.env` settings and `docker-compose.yml`. Docker Compose mounts the configured input and output directories into the container. The wrapper runs the TOPAZ5 forecast download script with the `-p` option, which limits the download to the latest files and avoids retrieving older files unnecessarily. The downloaded data is saved in the host's `input_forecast` directory. The script then post-processes the data into daily files for the forecasting platform to use.

### 4.3. Downloading and post-processing atmospheric forcing

To download the atmospheric forcing, run the wrapper script from the repository directory:

```sh
./download_weather_forcing.sh
```

Like the oceanic forcing wrapper, [`download_weather_forcing.sh`](./download_weather_forcing.sh) starts a Docker container using `.env` and `docker-compose.yml`, with the configured data directories mounted inside the container. It runs the Python script `/nextsim-env/data/download/download_NCEP025_daily.py`.

The Python script connects to the NCEP THREDDS server, fetches only the Global Forecast System (GFS) variables needed by the model, and saves the data as NetCDF files. To remain compatible with the forecasting platform's ECMWF input structure, it saves these files in `ECMWF_forecast_arctic/` under the input forecast directory (`/input_forecast/ECMWF_forecast_arctic` inside the container). Although the directory uses the ECMWF name, the downloaded data comes from NCEP GFS.

### 4.4. Downloading satellite observations

Like the forcing download scripts, the observation wrappers start a Docker container using `.env` and `docker-compose.yml`, mount the configured data directories, and run the download scripts inside the container. Both products are saved in the observations directory configured by `INPUT_OBSERVATIONS` on the host, mounted at `/input_obs` inside the container.

The wrappers use flags to request the latest files, but these downloads can still include quite a few files. Allow several gigabytes of disk space for the observations.

#### 4.4.1. ASIP sea ice concentration

Run the ASIP wrapper from the repository directory:

```sh
./download_asip_icecharts.sh
```

[`download_asip_icecharts.sh`](./download_asip_icecharts.sh) runs the Python script `/nextsim-env/data/download/download_asip_cmt.py` with the `-lfo` flag to download the latest ASIP files. The ASIP product comes from the Copernicus Marine Service, so the Copernicus Marine credentials must already be in place as described in the oceanic forcing authentication instructions above. The container reuses the credentials stored in the mounted `.copernicusmarine` directory.

#### 4.4.2. OSI-SAF AMSR3 sea ice concentration

Run the OSI-SAF wrapper from the repository directory:

```sh
./download_osisaf_sic.sh
```

[`download_osisaf_sic.sh`](./download_osisaf_sic.sh) runs `/nextsim-env/data/download/data_grab_osisaf_conc_amsr.sh` with `-latest -north` to download the latest Northern Hemisphere sea ice concentration files from the OSI-SAF FTP server. This download does not use the Copernicus Marine credentials.


## 5. Running forecast

### 5.1. run_forecast.sh

Run the forecast wrapper from the repository directory after downloading and processing all forcing data and downloading the observations:

```sh
./run_forecast.sh -d 20261027 -l 1
```

[`run_forecast.sh`](./run_forecast.sh) starts the Docker container using `.env` and `docker-compose.yml`, mounts the configured directories, and runs `run_forecast.py` with the `icepress` forecast configuration. It accepts two lowercase options:

* `-d YYYYMMDD` sets the forecast start date, usually today or yesterday. If omitted, it defaults to yesterday.
* `-l N` sets the forecast length in days. If omitted, it defaults to `1`. A forecast can span several days, provided the downloaded forcing data covers the required period.

#### 5.1.1. Required input data

Before starting the run, check that the downloaded files cover the requested dates:

* Oceanic forcing must be available from the day before the forecast starts, throughout the forecast, and through one day after it ends.
* Atmospheric forcing must cover the entire model run.
* With the current ASIP assimilation configuration, sea ice concentration observations for the day before the forecast starts are assimilated when available.

#### 5.1.2. First run and subsequent runs

The forecasting platform looks for a restart from a previous run within the `restart_tolerance` configured in `[forecast]`. With the current value of `1`, the restart must be no more than one day old. A missing or older restart cannot be used to continue a previous simulation.

The current setting `allow_no_restart=true` allows the model to start from scratch when no suitable restart is available, including on the first run. In that case, the model's sea ice concentration and thickness are initialized from TOPAZ fields, so the initial fields will be relatively smooth.

On the next day, download the required forcing and observations again and run the wrapper with the new start date. If the previous run's restart is within the tolerance, the platform reuses it, assimilates the available observations, and continues the forecast from the analyzed state.

### 5.2. Output data directory structure

Forecast output is saved in the host directory configured by `OUTPUT`, mounted at `/output` inside the container. A subdirectory named after the forecast configuration is created there: for `icepress.cfg`, this is `icepress`. Within it, each forecast run has a directory named by its start date in `YYYYMMDD` format. For example, `/output/icepress/20261027` contains the forecast starting on 27 October 2026.

Each run directory contains the following outputs:

* **Mooring NetCDF files**, for example `Moorings_2026d300.nc`, contain the forecast fields on the output grid. The filename identifies the year and day of year; day 300 of 2026 is 27 October. Each output day is exported to a separate file named `Moorings_YYYYdDDD.nc`, where `YYYY` is the year and `DDD` is the three-digit day of year of the output, not necessarily the forecast start date. The `moorings.*` settings in the `[nextsim]` section of `config_files/icepress.cfg` control the variables, spatial grid, output frequency, and file length. The current configuration writes daily files containing sea ice velocity, concentration, thickness, snow thickness, young-ice concentration, and ridge ratio. Sea ice pressure is planned for future output and is not included in the current configuration.
* **The neXtSIM configuration and log files** record the configuration used to run the model. These can be used to check the settings actually applied to a particular forecast.
* **`inputs/`** contains restart files from the previous run, updated during assimilation when observations are available. These use neXtSIM's native format and consist of four files for each restart timestamp: `field_<timestamp>.dat`, `field_<timestamp>.bin`, `mesh_<timestamp>.dat`, and `mesh_<timestamp>.bin`. Together, they store the triangular mesh and the model variables needed to restart the forecast.
* **`logs/`** contains model execution logs. Inspect these when a run fails or the model crashes to help identify the cause.
* **`innovation_plots/`** contains PNG plots showing updates to individual variables during assimilation. These plots are produced when assimilation is performed and `plot_innovations=true` is enabled in `[assimilation]`.
