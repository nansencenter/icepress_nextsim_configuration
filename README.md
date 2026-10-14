# Operators manual for running neXtSIM forecast for ICEPRESS

## Docker image

A Docker image is created to run all steps of processing required to forecast sea ice with neXTSIM:
* To download and preprocess input data
* To run neXtSIM to simulate sea ice
* To postprocess the forecast outputs

The image is built from four layers:
* `nextsim-base`, contains all libraries for building neXTSIM and code for downloading and preprocessing input data
* `nextsim`, compiled neXTSIM model
* `nextsim-tools`, Python library to process neXtSIM input and output data
* `nextsimf`, the forecasting platform that prepares data for running forecasts (e.g., assimilation) and post-processes the results

The image is provided upon contact with NERSC. You can build and run a Docker container from this image, or convert it to other formats, for example, Apptainer.

## Input data

The input data consists of static files, which are always the same, and dynamic files, which include oceanic and atmospheric forcing and satellite observations.
The input data resides outside the Docker container, and the directories are mounted when the container is run.

### Input data directory structure

There are four directories with input data:
1. `data`, contains symbolic links to the input files that are needed to run the simulation. The links are automatically created by the `run_forecast` script if the input files are downloaded correctly and are available.
2. `mesh`, contains static triangular mesh and NPP file.
3. `input_obs`, contains dynamic data (input satellite observations and weather forecast) and static data (bathymetry and neXTSIM output grids).
4. `input_forecast`, contains dynamic data: input oceanic forecast.

Note that `input_obs` contains more than just observations.

The input dynamic data is downloaded using scripts provided in the Docker image  (see below). NERSC provides the input static data upon contact.

The data directories can be located anywhere on the host and must be configured by the host and the container configuration file (see below).

### Static data

#### Mesh file

`mesh/large_arctic_bering_10km_JBFpatch.msh` contains initial triangular mesh at ~ 10 km resolution. The first neXtSIM run is initialised from this mesh, and subsequent runs are restarted from the final output of the previous runs.

#### NPP file

`mesh/NpsNextsim.mpp` contains mapping information used by neXtSIM

#### Bathymetry

`input_obs/BATHYMETRY/ETOPO_Arctic_2arcmin.nc` contains bathymetry of the Arctic at high resolution

#### Nextsim output grid template

`input_obs/nextsim_output_grids/topaz6_grid.nc` contains a default definition of the grid for neXtSIM outputs. This file can be changed, e.g. cropped, to output only a spatial subset of the forecast

### Dynamic data




## Configuration files

###  Overall structure

### Host configuration

### Container configuration

### Forecast configuration

## Downloading data

### Downloading and post-processing oceanic forcing

### Downloading and postprocessing atmospheric forcing

### Downloading satellite observations

#### ASIP sea ice concentration

#### OSI-SAF sea ice concentration

#### Blended sea ice thickness

## Running forecast

### run_forecast.sh

### Output data directory structure
