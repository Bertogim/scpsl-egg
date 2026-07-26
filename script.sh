#!/bin/bash
# steamcmd Base Installation Script
#
# Server Files: /mnt/server

# Architecture detection for ARM64 (Oracle Ampere) support
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
  echo "$(tput setaf 6)Detected ARM64 architecture - enabling Box64 compatibility mode$(tput sgr0)"
  DD_ARCH="arm64"
else
  DD_ARCH="x64"
fi

echo "
$(tput setaf 4)  ____________________________       ______________
$(tput setaf 4) /   _____/\_   ___ \______   \ /\  /   _____/|    |
$(tput setaf 4) \_____  \ /    \  \/|     ___/ \/  \_____  \ |    |
$(tput setaf 4) /        ||     \___|    |     /\  /        \|    |___
$(tput setaf 4)/_________/ \________/____|     \/ /_________/|________|
$(tput setaf 1) ___                 __          __   __
$(tput setaf 1)|   | ____   _______/  |______  |  | |  |   ___________
$(tput setaf 1)|   |/    \ /  ___/\   __\__  \ |  | |  | _/ __ \_  __ |
$(tput setaf 1)|   |   |  |\___ \  |  |  / __ \|  |_|  |_\  ___/|  | \/
$(tput setaf 1)|___|___|__/______| |__| (______|____|____/\___  |__|
$(tput sgr0)
"

echo "
$(tput setaf 2)This installer was created by $(tput setaf 1)Parkeymon$(tput setaf 2) and maintained by $(tput setaf 6)EsserGaming$(tput setaf 2).$(tput sgr0)
"

# Egg version checking, do not touch!
currentVersion="4.0.1"
latestVersion=$(curl --silent "https://api.github.com/repos/EsserGaming/scpsl-egg/releases/latest" | jq -r .tag_name)

if [ "${currentVersion}" == "${latestVersion}" ]; then
  echo "$(tput setaf 2)Installer is up to date"
else

  echo "
  $(tput setaf 1)THE INSTALLER IS NOT UP TO DATE!

    Current Version: $(tput setaf 1)${currentVersion}
    Latest: $(tput setaf 2)${latestVersion}

  $(tput setaf 3)Please update to the latest version found here: https://github.com/EsserGaming/scpsl-egg/releases/latest
$(tput setaf 4)Installation will start now...

  "
fi

# Download SteamDepotDownloader and install it (architecture-aware).
cd /tmp || { 
  echo "$(tput setaf 1) FAILED TO MOUNT TO /TMP"
  exit 
}
mkdir -p /mnt/server/.DepotDownloader
curl -sSL -o "DepotDownloader-linux-${DD_ARCH}.zip" "https://github.com/SteamRE/DepotDownloader/releases/latest/download/DepotDownloader-linux-${DD_ARCH}.zip"
unzip -oq "DepotDownloader-linux-${DD_ARCH}.zip" -d /mnt/server/.DepotDownloader
cd /mnt/server/.DepotDownloader || {
  echo "$(tput setaf 1) FAILED TO MOUNT TO /mnt/server/.DepotDownloader"
  exit
}

# Install SCP: Secret Laboratory using SteamDepotDownloader
chown -R root:root /mnt
export HOME=/mnt/server

if [ "${BRANCH_TAG}" == "" ]; then
  echo "$(tput setaf 4)Installing SCP:SL..$(tput sgr0)"
  ./DepotDownloader -app 996560 -depot 996562 -dir /mnt/server -validate > /dev/null # silence output
  echo "$(tput setaf 2)Done.$(tput sgr0)"
else
  echo "$(tput setaf 4)Installing SCP:SL $(tput bold)on custom branch (output enabled)..$(tput sgr0)" 
  ./DepotDownloader -app 996560 -depot 996562 -branch ${BRANCH_TAG} -dir /mnt/server -validate # keeping this normal if debugging is needed
fi

# Exit if /mnt/server doesn't exist
cd /mnt/server || {
  echo "$(tput setaf 1) FAILED TO MOUNT TO /mnt/server"
  exit
}

# Ensure permissions are correct
chmod +x LocalAdmin SCPSL.x86_64

#Install SCPDiscord Bot
if [ "${INSTALL_SCPDBOT}" == "true" ]; then
  mkdir -p /mnt/server/.egg/SCPDBot
  # Remove old SCPDiscord bot
  rm /mnt/server/.egg/SCPDBot/scpdiscord >/dev/null 2>&1

  echo "$(tput setaf 5)Installing latest SCPDiscord Bot."
  wget -q https://github.com/KarlOfDuty/SCPDiscord/releases/latest/download/scpdiscord -P /mnt/server/.egg/SCPDBot
  chmod +x /mnt/server/.egg/SCPDBot/scpdiscord
else
  echo $(tput setaf 3)"Skipping SCPDiscord Bot install."$(tput sgr0)
fi

 #Install SCPDiscord Plugin
 if [ "${INSTALL_SCPDPLUGIN}" == "true" ]; then
  rm '/mnt/server/.config/SCP Secret Laboratory/LabAPI/plugins/global/SCPDiscord.dll' >/dev/null 2>&1
  echo "$(tput setaf 5)Installing SCPDiscord Plugin."

  echo "$(tput setaf 5)SCPDiscord: Grabbing plugin and dependencies.."
  wget -q https://github.com/KarlOfDuty/SCPDiscord/releases/latest/download/dependencies.zip -P '/mnt/server/.config/SCP Secret Laboratory/LabAPI/dependencies/global'
  wget -q https://github.com/KarlOfDuty/SCPDiscord/releases/latest/download/SCPDiscord.dll -P '/mnt/server/.config/SCP Secret Laboratory/LabAPI/plugins/global'


  echo "$(tput setaf 5)SCPDiscord: Extracting dependencies.."
  unzip -oq '/mnt/server/.config/SCP Secret Laboratory/LabAPI/dependencies/global/dependencies.zip' -d '/mnt/server/.config/SCP Secret Laboratory/LabAPI/dependencies/global/'
  rm '/mnt/server/.config/SCP Secret Laboratory/LabAPI/dependencies/global/dependencies.zip' >/dev/null 2>&1
else
  echo $(tput setaf 3)"Skipping SCPDiscord Plugin install."$(tput sgr0)
fi


# EXILED installation
if [[ "${INSTALL_EXILED}" == "true" ]]; then

  if [ "$ARCH" = "aarch64" ]; then
    # ARM64 - extract Exiled.tar.gz instead of running x86_64 installer
    echo "$(tput setaf 4)Installing EXILED via tar.gz (ARM64)...$(tput sgr0)"

    if [ "${EXILED_PRE}" = "true" ]; then
      local_tag=$(curl -sL "https://api.github.com/repos/ExMod-Team/EXILED/releases" | jq -r '.[0].tag_name')
      exiled_url="https://github.com/ExMod-Team/EXILED/releases/download/${local_tag}/Exiled.tar.gz"
    elif [ "${EXILED_PRE}" != "false" ]; then
      exiled_url="https://github.com/ExMod-Team/EXILED/releases/download/${EXILED_PRE}/Exiled.tar.gz"
    else
      exiled_url="https://github.com/ExMod-Team/EXILED/releases/latest/download/Exiled.tar.gz"
    fi

    tmpdir=$(mktemp -d)
    wget -q "$exiled_url" -O "$tmpdir/Exiled.tar.gz"
    tar -xzf "$tmpdir/Exiled.tar.gz" -C "$tmpdir"

    mkdir -p '/mnt/server/.config/SCP Secret Laboratory/LabAPI/plugins/global'
    mkdir -p '/mnt/server/.config/SCP Secret Laboratory/LabAPI/dependencies/global'

    cp -r "$tmpdir/EXILED/Plugins/"* '/mnt/server/.config/SCP Secret Laboratory/LabAPI/plugins/global/' 2>/dev/null
    cp -r "$tmpdir/SCP Secret Laboratory/LabAPI/plugins/global/"* '/mnt/server/.config/SCP Secret Laboratory/LabAPI/plugins/global/' 2>/dev/null
    cp -r "$tmpdir/SCP Secret Laboratory/LabAPI/dependencies/global/"* '/mnt/server/.config/SCP Secret Laboratory/LabAPI/dependencies/global/' 2>/dev/null

    rm -rf "$tmpdir"
    echo "$(tput setaf 2)EXILED installation via tar.gz complete.$(tput sgr0)"

  else
    # x86_64 - use normal installer
    echo "$(tput setaf 4)Downloading $(tput setaf 1)EXILED $(tput setaf 4)installer."
    mkdir -p .config/
    rm Exiled.Installer-Linux >/dev/null 2>&1
    wget -q https://github.com/ExMod-Team/EXILED/releases/latest/download/Exiled.Installer-Linux
    chmod +x ./Exiled.Installer-Linux

    if [[ "${EXILED_PRE}" == "true" ]]; then
      echo "$(tput setaf 4)Installing latest $(tput setaf 1)EXILED $(tput setaf 4)pre-release.."
      ./Exiled.Installer-Linux -p /mnt/server/ --pre-releases >/dev/null

    elif [[ "${EXILED_PRE}" == "false" ]]; then
      echo "$(tput setaf 4)Installing latest $(tput setaf 1)EXILED $(tput setaf 4)release.."
      ./Exiled.Installer-Linux -p /mnt/server/ --skip-version-select >/dev/null

    else
      echo "$(tput setaf 4)Installing $(tput setaf 1)EXILED$ $(tput setaf 4)version: $(tput bold)$(tput setaf 1)${EXILED_PRE}$(tput sgr0)"
      ./Exiled.Installer-Linux -p /mnt/server/ --target-version "${EXILED_PRE}" # un-silenced in case debugging is needed
    fi
  fi

else
  echo $(tput setaf 3)"Skipping Exiled installation."$(tput sgr0)
fi


# For ARM64: wrap SCPDiscord with FEX
if [ "$ARCH" = "aarch64" ]; then
  echo "$(tput setaf 4)Setting up FEX SCPDiscord wrapper...$(tput sgr0)"
  if [ -f "/mnt/server/.egg/SCPDBot/scpdiscord" ]; then
    mv "/mnt/server/.egg/SCPDBot/scpdiscord" "/mnt/server/.egg/SCPDBot/scpdiscord.bin"
    printf '#!/bin/bash\nDIR="$(cd "$(dirname "$0")" && pwd)"\nexec FEXInterpreter "$DIR/scpdiscord.bin" "$@"\n' > "/mnt/server/.egg/SCPDBot/scpdiscord"
    chmod +x "/mnt/server/.egg/SCPDBot/scpdiscord"
    echo "  Wrapped .egg/SCPDBot/scpdiscord with FEX"
  fi
fi

echo "$(tput setaf 4)Installing FEX emu...$(tput sgr0)"

export DEBIAN_FRONTEND=noninteractive

if [ "$ARCH" = "aarch64" ]; then
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
          --progress=bar:force \
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
    fi
fi

rm -rf /var/lib/apt/lists/*


cat > /mnt/server/start.sh << 'STARTEOF'
#!/bin/bash
# Server start script with daily log rotation
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
export BOX64_DYNAREC_NATIVEFLAGS=0
# STRONGMEM=1 forces x86 TSO memory model — critical for Mono/C#.
# ARM64 weak ordering breaks Mono threading (null deref at +0x10).
export BOX64_DYNAREC_STRONGMEM=1
# BIGBLOCK=0 (sin S — BIGBLOCKS es typo y box64 lo ignora): Mono JIT
# genera muchos bloques pequeños. Sin esto box64 los fusiona y puede
# corromper registros (R14=0 en LocalAdmin).
export BOX64_DYNAREC_BIGBLOCK=0
# SAFEFLAGS=2: flags exactos en todos los CALL/RET — Mono vive de señales
# y excepciones; con el default 1 un flag corrupto cuelga el proceso.
export BOX64_DYNAREC_SAFEFLAGS=2
export BOX64_LD_LIBRARY_PATH=/usr/lib/mono/4.5:/usr/lib/x86_64-linux-gnu

# Start SCPDiscord in background if installed
if [ -f ".egg/SCPDBot/scpdiscord" ]; then
    ".egg/SCPDBot/scpdiscord" --config ".egg/SCPDBot/config.yml" &
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
STARTEOF
chmod +x /mnt/server/start.sh

# Cleanup
echo "$(tput setaf 5)Cleaning up..$(tput sgr 0)"
rm /mnt/server/core >/dev/null 2>&1
rm /mnt/server/Exiled.Installer-Linux >/dev/null 2>&1
rm /mnt/server/config-gameplay.txt >/dev/null 2>&1
rm -r /mnt/server/? >/dev/null 2>&1
rm -r /mnt/server/.local >/dev/null 2>&1

echo "$(tput setaf 2)Installation Complete!$(tput sgr 0)"
