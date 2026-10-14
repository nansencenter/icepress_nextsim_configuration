source host_config.sh

docker run \
    --rm -it \
    --env-file container_config.env \
    -v "$INPUT_OBS_DATA_DIR":"/input_obs" \
    -v "$INPUT_FORECAST_DATA_DIR":"/input_forecast" \
    -v "$OUTPUT_FORECAST_DATA_DIR":"/output" \
    -v "$NEXTSIM_DATA_DIR":"/data" \
    -v "$NEXTSIM_MESH_DIR":"/mesh" \
    -v "$NEXTSIM_ENV_ROOT_DIR":"/env_root" \
    pynextsimf bash -c "run_forecast.py icepress 20261002 1"