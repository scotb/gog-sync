#!/bin/bash
# Usage: ./gog-sync.sh [--download] [--download-all] [--repair] [--tty] [--show-all-output] [--game-name <name>] [--exact-match]


log_file="gog-sync.log"
cd ~/gog-archive

start_time=$(date +%s)
# Determine mode for logging
if [ "$LIST_ALL" = true ]; then
    MODE="ListAll"
elif [ "$DOWNLOAD_ALL" = true ]; then
    MODE="DownloadAll"
elif [ -n "$DOWNLOAD_FLAG" ]; then
    MODE="Download"
elif [ -n "$REPAIR_FLAG" ]; then
    MODE="Repair"
else
    MODE="ListUpdated"
fi
DOWNLOAD_DIR="/downloads"
THREADS="8"

echo "==== GOG Sync Run Start: $(date) ====" | tee -a "$log_file"
echo "Mode: $MODE" | tee -a "$log_file"
echo "Download Directory: $DOWNLOAD_DIR" | tee -a "$log_file"
echo "Threads: $THREADS" | tee -a "$log_file"
echo "TTY: $TTY_FLAG" | tee -a "$log_file"
echo "ShowAllOutput: $SHOW_ALL_OUTPUT" | tee -a "$log_file"
echo "VerboseLog: $VERBOSE_LOG" | tee -a "$log_file"


DOWNLOAD_FLAG=""
DOWNLOAD_ALL=false
REPAIR_FLAG=""
LIST_ALL=false
TTY_FLAG=""
SHOW_ALL_OUTPUT=false
VERBOSE_LOG=false
GAME_NAME=""
EXACT_MATCH=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --download-all)
            DOWNLOAD_ALL=true
            ;;
        --download)
            DOWNLOAD_FLAG="--download"
            ;;
        --repair)
            REPAIR_FLAG="--repair"
            ;;
        --list-all)
            LIST_ALL=true
            ;;
        --tty)
            TTY_FLAG="-t"
            ;;
        --show-all-output)
            SHOW_ALL_OUTPUT=true
            ;;
        --verbose-log)
            VERBOSE_LOG=true
            ;;
        --game-name)
            shift
            GAME_NAME="$1"
            ;;
        --exact-match)
            EXACT_MATCH=true
            ;;
    esac
    shift
done


# Build lgogdownloader command
GAME_ARG=""
if [ -n "$GAME_NAME" ]; then
    if [ "$EXACT_MATCH" = true ]; then
        GAME_ARG="--game ^${GAME_NAME}$"
    else
        GAME_ARG="--game ${GAME_NAME}"
    fi
fi
if [ "$LIST_ALL" = true ]; then
    LGOG_COMMAND="lgogdownloader --list $GAME_ARG --directory /downloads --threads 8"
elif [ "$DOWNLOAD_ALL" = true ]; then
    LGOG_COMMAND="lgogdownloader --download $GAME_ARG --directory /downloads --threads 8"
elif [ -n "$DOWNLOAD_FLAG" ]; then
    LGOG_COMMAND="lgogdownloader --download --updated $GAME_ARG --directory /downloads --threads 8"
elif [ -n "$REPAIR_FLAG" ]; then
    LGOG_COMMAND="lgogdownloader --repair --download $GAME_ARG --directory /downloads --threads 8"
else
    LGOG_COMMAND="lgogdownloader --list --updated $GAME_ARG --directory /downloads --threads 8"
fi

echo "Running command: docker-compose run --rm $TTY_FLAG gogrepo $LGOG_COMMAND"
echo "Running command: docker-compose run --rm $TTY_FLAG gogrepo $LGOG_COMMAND" >> "$log_file"

if [[ "$LGOG_COMMAND" == *"--list"* ]]; then
    # Always show all output when listing
    docker-compose run --rm $TTY_FLAG gogrepo $LGOG_COMMAND 2>&1 | tee -a "$log_file"
elif [ "$SHOW_ALL_OUTPUT" = true ]; then
    docker-compose run --rm $TTY_FLAG gogrepo $LGOG_COMMAND 2>&1 | tee -a "$log_file"
elif [ "$VERBOSE_LOG" = true ]; then
    # Only output errors, warnings, and the final summary (not per-file or progress lines)
    last_summary=""
    docker-compose run --rm $TTY_FLAG gogrepo $LGOG_COMMAND 2>&1 \
        | sed -r 's/[^\x09\x0A\x0D\x20-\x7E]//g' \
        | while IFS= read -r line; do
            if [[ "$line" =~ ^(Total:|Remaining:) ]]; then
                last_summary="$line"
            elif [[ "$line" =~ (ERROR|WARNING|Run completed|====) ]] && [[ -n "${line// }" ]]; then
                echo "$line" | tee -a "$log_file"
            fi
        done
    if [ -n "$last_summary" ]; then
        echo "$last_summary" | tee -a "$log_file"
    fi
else
    docker-compose run --rm $TTY_FLAG gogrepo $LGOG_COMMAND 2>&1 | grep -iE "WARNING|ERROR" | tee -a "$log_file" | awk 'NR % 1000 == 0 { printf "."; fflush() }'
fi

end_time=$(date +%s)
elapsed=$((end_time - start_time))
echo "==== GOG Sync Run End: $(date -d @$end_time) (Elapsed: ${elapsed} seconds) ====" | tee -a "$log_file"