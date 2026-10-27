#!/bin/bash
set -e

docker compose --env-file .env run --rm -it icepress bash
