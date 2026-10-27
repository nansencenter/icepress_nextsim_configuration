#!/bin/bash
set -e

docker compose --env-file .env run --rm icepress python /nextsim-env/data/download/download_NCEP025_daily.py

