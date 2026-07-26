
#!/bin/bash
# Server start script with daily log rotation
echo "Script Started"

LOG_DIR="./logs"
RETENTION_DAYS="${LOG_RETENTION_DAYS:-7}"
DATE_DIR="$(date +%Y-%m-%d)"

mkdir -p "$LOG_DIR/$DATE_DIR"
LOG_FILE="$LOG_DIR/$DATE_DIR/server.log"
echo "Logging to $LOG_FILE (retention: $RETENTION_DAYS days)"

# Cleanup old logs
find "$LOG_DIR" -maxdepth 1 -type d -name "????-??-??" -mtime +"$RETENTION_DAYS" -exec rm -rf {} + 2>/dev/null

# Box64 workarounds for ARM64 — disable dynarec Native Flags optimization
# (causes corrupted args in sysconf calls on Neoverse-N1)
ulimit -s unlimited 2>/dev/null
ulimit -v unlimited 2>/dev/null

# Start SCPDiscord in background if installed
if [ -f ".egg/SCPDBot/scpdiscord" ]; then
    ".egg/SCPDBot/scpdiscord" --config ".egg/SCPDBot/config.yml" &
fi

ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
    echo "$(tput setaf 4)Installing FEX emu...$(tput sgr0)"

    ROOTFS_DIR="/home/container/.config/fex-emu/RootFS"
    ROOTFS_FILE="$ROOTFS_DIR/Ubuntu_22_04.sqsh"
    CONFIG_FILE="/home/container/.config/fex-emu/Config.json"

    echo "$(tput setaf 4)Installing FEX RootFS...$(tput sgr0)"

    if [ ! -f "$ROOTFS_FILE" ]; then
        mkdir -p "$ROOTFS_DIR"
        mkdir -p "$(dirname "$CONFIG_FILE")"

        echo "$(tput setaf 4)Obtaining FEX RootFS URL...$(tput sgr0)"

        ROOTFS_URL=$(curl -fsSL https://rootfs.fex-emu.gg/RootFS_links.json | \
        jq -r '.v1 | to_entries[] |
        select(.value.DistroMatch=="ubuntu" and
               .value.DistroVersion=="22.04" and
               .value.Type=="squashfs") |
        .value.URL')

        if [ -z "$ROOTFS_URL" ] || [ "$ROOTFS_URL" = "null" ]; then
            echo "$(tput setaf 1)Failed to obtain FEX RootFS URL.$(tput sgr0)"
            exit 1
        fi

        echo "$(tput setaf 4)Downloading Ubuntu 22.04 RootFS (~1 GB)...$(tput sgr0)"

        wget \
          --show-progress \
          --progress=bar:force:noscroll \
          -O "$ROOTFS_FILE" \
          "$ROOTFS_URL"


        RET=$?
        echo "wget exit=$RET"

        sync

        echo "After download:"
        ls -lah "$ROOTFS_DIR"

        if [ -f "$ROOTFS_FILE" ]; then
            stat "$ROOTFS_FILE"
        else
            echo "ERROR: $ROOTFS_FILE does not exist"
        fi

        echo "$(tput setaf 2)Download complete.$(tput sgr0)"

        cat > "$CONFIG_FILE" <<EOF
{
  "Config": {
    "RootFS": "Ubuntu_22_04.sqsh"
  }
}
EOF

        ls -lh "$ROOTFS_DIR"
        echo "$(tput setaf 2)FEX RootFS installed successfully.$(tput sgr0)"
    else
        echo "$(tput setaf 2)FEX RootFS already installed.$(tput sgr0)"
        
        
        if [ ! -d "$HOME/.config/fex-emu/RootFS/Ubuntu_22_04" ]; then
            echo "$(tput setaf 4)Extracting RootFS...$(tput sgr0)"

            unsquashfs \
                -d "$HOME/.config/fex-emu/RootFS/Ubuntu_22_04" \
                "$HOME/.config/fex-emu/RootFS/Ubuntu_22_04.sqsh"

            cat > "$CONFIG_FILE" <<EOF
{
  "Config": {
    "RootFS": "Ubuntu_22_04"
  }
}
EOF

            echo "$(tput setaf 2)Extraction complete.$(tput sgr0)"
        else
            echo "$(tput setaf 2)RootFS already extracted.$(tput sgr0)"
        fi

    fi
fi


LAUNCH_CMD='./LocalAdmin'
if [ "$(uname -m)" = "aarch64" ]; then
    LAUNCH_CMD='FEXInterpreter ./LocalAdmin'
fi
# Use script(1) to create a PTY so LocalAdmin outputs line-buffered + ANSI colors
# (Without PTY, pipe makes stdout fully-buffered and strips color codes)
# stdin guard: discard keystrokes during first 30s of init via timeout,
# then forward normally. Prevents typed-ahead input from reaching game
# process during Unity silent init phase.
STDIN_GUARD="{ timeout ${STDIN_GUARD_TIMEOUT:-30} cat > /dev/null 2>&1 || true; cat; }"
PORT_ARG=""
[ $# -gt 0 ] && PORT_ARG="$1"
# script -e forwards LocalAdmin's exit code; PIPESTATUS[1] is script's
# status. Plain `exit $?` would return tee's 0, making crashes look like
# clean shutdowns and disabling the runner's restart-on-crash loop.
eval "$STDIN_GUARD" | script -qefc "$LAUNCH_CMD $PORT_ARG --weak-http-security" /dev/null | tee -a "$LOG_FILE"
exit "${PIPESTATUS[1]}"