# Base image: Ubuntu Noble with LinuxServer.io optimizations
FROM ghcr.io/linuxserver/baseimage-ubuntu:noble

# =============================
# 1. INSTALL SYSTEM DEPENDENCIES
# =============================

# Enable 32-bit architecture for Wine compatibility
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get upgrade -y && \
    # Install Wine32 with recommends (required for proper functionality)
    apt-get install --install-recommends -y wine32 && \
    # Install essential tools: Xvfb (headless GUI), winetricks, utilities, Python, etc.
    apt-get install --no-install-recommends -y \
        xvfb wget curl jq xdotool p7zip-full winetricks winbind \
        x11vnc bc inotify-tools python3 python3-pip aria2 unzip cabextract && \
    # Ensure correct ownership for persistent config directory
    chown -R abc:abc /config && \
    # Cleanup to reduce image size
    apt-get autoclean && \
    rm -rf \
        /config/.cache \
        /config/.launchpadlib \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /tmp/*

# =============================
# 2. CONFIGURE WINE PREFIX
# =============================

USER abc
ENV HOME=/config

RUN set -eux; \
    # Configure Wine environment
    export WINEPREFIX="$HOME/.wine" \
           WINEARCH=win32 \
           DISPLAY=:99; \
    # Initialize Wine prefix
    WINEDLLOVERRIDES="mscoree,mshtml=" wineboot -u; \
    \
    # Download and make winetricks executable
    wget -O "$HOME/wt" "https://raw.githubusercontent.com/Winetricks/winetricks/9f6b3136ee218b853792b056da0985c8053b3c10/src/winetricks"; \
    chmod +x "$HOME/wt"; \
    \
    # Configure Aria2 for faster, resilient downloads
    mkdir -p "$HOME/.aria2"; \
    echo "connect-timeout=20" > "$HOME/.aria2/aria2.conf"; \
    \
    # Start virtual framebuffer for GUI-based Wine operations
    Xvfb :99 -screen 0 1024x768x24 & \
    sleep 3; \
    \
    # Install essential Windows components via winetricks (quiet mode)
    "$HOME/wt" -q wininet winhttp mfc80 mfc90 gdiplus wsh56 urlmon pptfonts corefonts dxvk dotnetdesktop6 ie8 pdh; \
    "$HOME/wt" wininet=builtin winhttp=native; \
    \
    # Download and silently install .NET 6.0 runtime & ASP.NET Core runtime
    cd "$HOME"; \
    wget "https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/6.0.36/aspnetcore-runtime-6.0.36-win-x86.exe"; \
    wget "https://builds.dotnet.microsoft.com/dotnet/Runtime/6.0.36/dotnet-runtime-6.0.36-win-x86.exe"; \
    wine aspnetcore-runtime-6.0.36-win-x86.exe /q; \
    wine dotnet-runtime-6.0.36-win-x86.exe /q; \
    rm aspnetcore-runtime-6.0.36-win-x86.exe dotnet-runtime-6.0.36-win-x86.exe; \
    \
    # Install Visual C++ runtimes
    "$HOME/wt" -q vcrun2005 vcrun2008; \
    \
    # Kill Xvfb and Wine server gracefully
    pkill Xvfb; \
    wineserver -k; \
    \
    # Cleanup unnecessary files to reduce image size
    find "$WINEPREFIX/drive_c" -type f -name '*.bak' -delete; \
    rm -rf \
        "$HOME/.cache" \
        "$HOME/.launchpadlib" \
        "$WINEPREFIX/drive_c/windows/Installer" \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /tmp/*

# =============================
# 3. DOWNLOAD & EXTRACT ORRH
# =============================

# Copy ORRH cleaner scripts into container
COPY --chmod=777 orrhcleaner/ /config/orrhcleaner/

RUN set -eux; \
    cd "$HOME"; \
    \
    # Download ORRH game files via Archive.org mirror (preserving at-risk content)
    aria2c -x8 -j8 "https://web.archive.org/web/20250902134347/https://download2290.mediafire.com/4lh9v3gy5bmgnY_9MR4bDOTQ-aLfNDG6ZN2n_n6M2eLZV3J2iKVwI6GzFUiSLnH-OtvuJZHuvKjfhdavEdtZFTskAIMnxCUlaQ52ZxJf-o5ic2nZ1NPEhv7mreHewFX_1kaIDfPoFMzh3GhWI4xr7iqFsM1Yb-PktlAePJWuMFQ/h0ekdr4ccviokgq/OnlyRetroRobloxHere-v1.2.0.1.7z"; \
    \
    # Download ORRH CLI tool
    wget "https://github.com/Mollomm1/ORRH-CLI/releases/download/V1/ORRH_CLI_x32_V1_NO_DATA.zip"; \
    \
    # Extract game data and CLI
    7z x "OnlyRetroRobloxHere-v1.2.0.1.7z" "data/" -o"$HOME/OnlyRetroRobloxHere/" -r; \
    unzip "ORRH_CLI_x32_V1_NO_DATA.zip" -d "$HOME/OnlyRetroRobloxHere"; \
    \
    # Create required directories
    mkdir -p "$HOME/OnlyRetroRobloxHere/assetpacks" "$HOME/OnlyRetroRobloxHere/maps"; \
    \
    # Cleanup archives
    rm "OnlyRetroRobloxHere-v1.2.0.1.7z" "ORRH_CLI_x32_V1_NO_DATA.zip"; \
    \
    # Download default map
    wget -O "$HOME/map.rbxl" "https://raw.githubusercontent.com/Mollomm1/NovetusDocker/refs/heads/main/default.rbxl"; \
    \
    # Run post-extraction cleanup script
    /config/orrhcleaner/clean.sh

# =============================
# 4. SETUP SERVER & DEPENDENCIES
# =============================

# Copy startup and webserver scripts
COPY --chmod=777 scripts/ /config/scripts/

RUN set -eux; \
    # Generate host-specific scripts from templates
    bash /config/scripts/hostscriptstemplate.sh; \
    \
    # Install Python web server dependencies (FastAPI + Uvicorn)
    python3 -m pip install --break-system-packages fastapi uvicorn; \
    \
    # Final cleanup
    rm -rf \
        "$HOME/.cache" \
        "$HOME/.launchpadlib" \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /tmp/*

# =============================
# 5. HEALTH CHECK & ENTRYPOINT
# =============================

# Health check: ping web server every 10s; restart container if unresponsive
HEALTHCHECK --interval=10s --timeout=2m --start-period=10s \
    CMD curl -f --retry 3 --max-time 3 --retry-delay 3 http://127.0.0.1:3000/health || \
         bash -c 'kill -s TERM -1 && (sleep 10; kill -s KILL -1)'

# Launch the main server script
ENTRYPOINT ["/config/scripts/start.sh"]