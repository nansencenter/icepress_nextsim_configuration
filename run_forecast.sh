#!/bin/bash
set -e

if date -d "yesterday" >/dev/null 2>&1; then
    DATE=$(date -d "-1 day" +%Y%m%d)
else
    DATE=$(date -v -1d +%Y%m%d)
fi
LENGTH=1

while getopts "d:l:" opt; do
    case "$opt" in
        d)
            DATE="$OPTARG"
            ;;
        l)
            LENGTH="$OPTARG"
            ;;
        *)
            echo "Usage: $0 [-d YYYYMMDD] [-l N]" >&2
            exit 1
            ;;
    esac
done

shift $((OPTIND - 1))

if [ "$#" -gt 0 ]; then
    echo "Usage: $0 [-d YYYYMMDD] [-l N]" >&2
    exit 1
fi

echo "Running forecast for date: $DATE with length: $LENGTH"

docker compose --env-file .env run --rm -it icepress bash -c "run_forecast.py icepress $DATE $LENGTH"
