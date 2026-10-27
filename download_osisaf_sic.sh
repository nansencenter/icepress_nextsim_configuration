#!/bin/bash
set -e

docker compose --env-file .env run --rm icepress bash /nextsim-env/data/download/data_grab_osisaf_conc_amsr.sh -latest -north
