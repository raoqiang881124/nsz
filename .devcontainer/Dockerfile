FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    WINEARCH=win64 \
    WINEPREFIX=/opt/wine \
    WINEDEBUG=-all \
    WIN_PYTHON_VERSION=3.11.9 \
    WIN_PYTHON_DIR="C:\\Python311" \
    WIN_LLVM_VERSION=18.1.8

# Native Linux build toolchain + Wine for cross-building the Windows binary.
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        software-properties-common \
        gnupg2 \
        wget \
        ca-certificates \
        cabextract \
        xvfb \
        build-essential \
        python3 \
        python3-venv \
        python3-pip \
        python3-dev \
        libffi-dev \
        libmtdev1 \
        libgl1 \
        libegl1 \
        libgles2 \
        libx11-6 \
        libxext6 \
        libxrender1 \
        libxrandr2 \
        libxfixes3 \
        libxcursor1 \
        libxi6 \
        libxinerama1 \
        libxxf86vm1 \
        git \
    && wget -nc https://dl.winehq.org/wine-builds/winehq.key -O /tmp/winehq.key \
    && gpg --dearmor -o /usr/share/keyrings/winehq-archive-keyring.gpg /tmp/winehq.key \
    && echo "deb [signed-by=/usr/share/keyrings/winehq-archive-keyring.gpg] https://dl.winehq.org/wine-builds/ubuntu/ jammy main" \
        > /etc/apt/sources.list.d/winehq.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends winehq-stable winetricks \
    && rm -rf /var/lib/apt/lists/* /tmp/winehq.key

COPY dev/requirements-pyinstaller.txt /tmp/requirements-pyinstaller.txt

# Native virtualenv used for the Linux build.
RUN python3 -m venv /opt/venv-linux
ENV PATH="/opt/venv-linux/bin:${PATH}"
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir ruff \
    && pip install --no-cache-dir -r /tmp/requirements-pyinstaller.txt

# Windows Python (run under Wine) used for the cross-compiled Windows build.
RUN wine wineboot --init \
    && wineserver --wait \
    && wget -q "https://www.python.org/ftp/python/${WIN_PYTHON_VERSION}/python-${WIN_PYTHON_VERSION}-amd64.exe" -O /tmp/win-python.exe \
    && xvfb-run -a wine /tmp/win-python.exe /quiet InstallAllUsers=1 PrependPath=1 TargetDir="${WIN_PYTHON_DIR}" \
    && wineserver --wait \
    && rm -f /tmp/win-python.exe

RUN xvfb-run -a wine "${WIN_PYTHON_DIR}\\python.exe" -m pip install --no-cache-dir --upgrade pip \
    && xvfb-run -a wine "${WIN_PYTHON_DIR}\\python.exe" -m pip install --no-cache-dir -r /tmp/requirements-pyinstaller.txt \
    && wineserver --wait

# Install Windows LLVM tools under Wine and expose strip.exe for PyInstaller.
RUN wget -q "https://github.com/llvm/llvm-project/releases/download/llvmorg-${WIN_LLVM_VERSION}/LLVM-${WIN_LLVM_VERSION}-win64.exe" -O /tmp/win-llvm.exe \
    && xvfb-run -a wine /tmp/win-llvm.exe /S \
    && wineserver --wait \
    && cp "/opt/wine/drive_c/Program Files/LLVM/bin/llvm-strip.exe" "/opt/wine/drive_c/Python311/Scripts/strip.exe" \
    && xvfb-run -a wine cmd /c where strip \
    && rm -f /tmp/win-llvm.exe

WORKDIR /workspaces/nsz
