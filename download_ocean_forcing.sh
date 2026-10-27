#!/bin/bash
set -e

docker compose --env-file .env run --rm icepress bash /nextsim-env/data/download/data_grab_TOPAZ5FC_daily.sh -p