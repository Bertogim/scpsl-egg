#!/bin/bash
# start.sh — SCP:SL server launcher
# Part of scpsl-egg (https://github.com/Reddishye/scpsl-egg)
# Auto-generated during install; also pulled by autoupdate at runtime.

LOG_DIR="./logs"
RETENTION_DAYS="${LOG_RETENTION_DAYS:-7}"
DATE_DIR="$(date +%Y-%m-%d)"

mkdir -p "$LOG_DIR/$DATE_DIR"
LOG_FILE="$LOG_DIR/$DATE_DIR/server.log"
echo "Logging to $LOG_FILE (retention: $RETENTION_DAYS days)"

find "$LOG_DIR" -maxdepth 1 -type d -name "????-??-??" -mtime +"$RETENTION_DAYS" -exec rm -rf {} + 2>/dev/null

ulimit -s unlimited 2>/dev/null
ulimit -v unlimited 2>/dev/null
export BOX64_DYNAREC_NATIVEFLAGS=0
export BOX64_DYNAREC_STRONGMEM=1
# BIGBLOCK sin S: BIGBLOCKS es typo y box64 lo ignora (default 2 = freeze con Mono JIT)
export BOX64_DYNAREC_BIGBLOCK=0
export BOX64_DYNAREC_SAFEFLAGS=2

if [ -f ".egg/SCPDBot/scpdiscord" ]; then
    ".egg/SCPDBot/scpdiscord" --config ".egg/SCPDBot/config.yml" &
fi

LAUNCH_CMD='./LocalAdmin'
if [ "$(uname -m)" = "aarch64" ]; then LAUNCH_CMD='box64 ./LocalAdmin'; fi

STDIN_GUARD="{ timeout ${STDIN_GUARD_TIMEOUT:-30} cat > /dev/null 2>&1 || true; cat; }"
PORT_ARG=""
[ $# -gt 0 ] && PORT_ARG="$1"
# script -e forwards LocalAdmin's exit code; PIPESTATUS[1] is script's
# status. Plain `exit $?` would return tee's 0, making crashes look like
# clean shutdowns and disabling the runner's restart-on-crash loop.
eval "$STDIN_GUARD" | script -qefc "$LAUNCH_CMD $PORT_ARG --weak-http-security" /dev/null | tee -a "$LOG_FILE"
exit "${PIPESTATUS[1]}"
