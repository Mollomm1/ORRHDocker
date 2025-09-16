FROM ghcr.io/linuxserver/baseimage-ubuntu:noble

#
# Install deps
#

RUN dpkg --add-architecture i386 && apt update && apt upgrade -y && \
    apt install --install-recommends -y wine32 && \
    apt install --no-install-recommends -y xvfb wget curl jq xdotool p7zip-full winetricks winbind x11vnc bc inotify-tools python3 python3-pip aria2 unzip cabextract && \
    chown -R abc:abc /config && \
    apt-get autoclean && \
    rm -rf \
      /config/.cache \
      /config/.launchpadlib \
      /var/lib/apt/lists/* \
      /var/tmp/* \
      /tmp/*

#
# Setup wineprefix.
#

USER abc

ENV HOME=/config

RUN export WINEPREFIX=/config/.wine && export WINEARCH=win32 && \
    WINEDLLOVERRIDES="mscoree,mshtml=" wineboot -u && \
    wget -O $HOME/wt https://raw.githubusercontent.com/Winetricks/winetricks/9f6b3136ee218b853792b056da0985c8053b3c10/src/winetricks && chmod +x $HOME/wt && \
    mkdir /config/.aria2 && \
    echo "connect-timeout=20" > /config/.aria2/aria2.conf && \
    (Xvfb :99 -screen 0 1024x768x24 & ) && export DISPLAY=:99 && \
    $HOME/wt -q wininet winhttp mfc80 mfc90 gdiplus wsh56 urlmon pptfonts corefonts dxvk dotnetdesktop6 ie8 pdh && \
    $HOME/wt wininet=builtin winihttp=native && \
    cd $HOME && \
    wget https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/6.0.36/aspnetcore-runtime-6.0.36-win-x86.exe && \
    wget https://builds.dotnet.microsoft.com/dotnet/Runtime/6.0.36/dotnet-runtime-6.0.36-win-x86.exe && \
    wine aspnetcore-runtime-6.0.36-win-x86.exe /q && \
    wine dotnet-runtime-6.0.36-win-x86.exe /q && \
    rm aspnetcore-runtime-6.0.36-win-x86.exe dotnet-runtime-6.0.36-win-x86.exe && \
    $HOME/wt -q vcrun2005 vcrun2008 && \
    pkill Xvfb && \
    wineserver -k && \
    find /config/.wine/drive_c -type f -name '*.bak' -delete && \
    rm -rf \
      /config/.cache \
      /config/.launchpadlib \
      /config/.wine/drive_c/windows/Installer \
      /var/lib/apt/lists/* \
      /var/tmp/* \
      /tmp/*

#
# Download and decompress ORRH and then clean it
# 

COPY --chmod=777 orrhcleaner/ /config/orrhcleaner/

RUN cd $HOME && \
    aria2c -x8 -j8 https://web.archive.org/web/20250902134347/https://download2290.mediafire.com/4lh9v3gy5bmgnY_9MR4bDOTQ-aLfNDG6ZN2n_n6M2eLZV3J2iKVwI6GzFUiSLnH-OtvuJZHuvKjfhdavEdtZFTskAIMnxCUlaQ52ZxJf-o5ic2nZ1NPEhv7mreHewFX_1kaIDfPoFMzh3GhWI4xr7iqFsM1Yb-PktlAePJWuMFQ/h0ekdr4ccviokgq/OnlyRetroRobloxHere-v1.2.0.1.7z && \
    wget https://github.com/Mollomm1/ORRH-CLI/releases/download/V1/ORRH_CLI_x32_V1_NO_DATA.zip && \
    7z x OnlyRetroRobloxHere-v1.2.0.1.7z "data/" -o/config/OnlyRetroRobloxHere/ -r && \
    unzip ORRH_CLI_x32_V1_NO_DATA.zip -d /config/OnlyRetroRobloxHere && \
    mkdir /config/OnlyRetroRobloxHere/assetpacks /config/OnlyRetroRobloxHere/maps  && \
    rm OnlyRetroRobloxHere-v1.2.0.1.7z ORRH_CLI_x32_V1_NO_DATA.zip && \
    wget -O /config/map.rbxl https://raw.githubusercontent.com/Mollomm1/NovetusDocker/refs/heads/main/default.rbxl && \
    /config/orrhcleaner/clean.sh

#
# Copy setup scripts and webserver to container, and install webserver deps
#

COPY --chmod=777 scripts/ /config/scripts/

RUN bash /config/scripts/hostscriptstemplate.sh && \
    python3 -m pip install --break-system-packages fastapi uvicorn && \
    rm -rf \
      /config/.cache \
      /config/.launchpadlib \
      /var/lib/apt/lists/* \
      /var/tmp/* \
      /tmp/*

#
# Health Check, to ensure the server is still running.
#

HEALTHCHECK --interval=10s --timeout=2m --start-period=10s \
    CMD curl -f --retry 3 --max-time 3 --retry-delay 3 http://127.0.0.1:3000/health || bash -c 'kill -s 15 -1 && (sleep 10; kill -s 9 -1)'

ENTRYPOINT ["/config/scripts/start.sh"]