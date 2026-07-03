FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LINUX_PYTHON_DIR=/opt/venv-linux \
    WINEARCH=win64 \
    WINEPREFIX=/opt/wine \
    WINEDEBUG=-all \
    WIN_PYTHON_VERSION=3.11.9 \
    WIN_PYTHON_DIR="C:\\Python311" \
    WIN_LLVM_VERSION=18.1.8 \
    WORKSPACE_DIR=/workspaces/nsz

# Native Linux build toolchain + Wine for cross-building the Windows binary.
RUN <<-EOF
    set -ex
    dpkg --add-architecture i386
    apt-get update
    apt-get install -y --no-install-recommends \
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
        git
    wget -nc https://dl.winehq.org/wine-builds/winehq.key -O /tmp/winehq.key
    gpg --dearmor -o /usr/share/keyrings/winehq-archive-keyring.gpg /tmp/winehq.key
    echo "deb [signed-by=/usr/share/keyrings/winehq-archive-keyring.gpg] https://dl.winehq.org/wine-builds/ubuntu/ jammy main" \
        > /etc/apt/sources.list.d/winehq.list
    apt-get update
    apt-get install -y --no-install-recommends winehq-stable winetricks
    rm -rf /var/lib/apt/lists/* /tmp/winehq.key
EOF

# Windows Python (run under Wine) used for the cross-compiled Windows build.
RUN <<-EOF
    set -ex
    wine wineboot --init
    wineserver --wait
    wget -q "https://www.python.org/ftp/python/${WIN_PYTHON_VERSION}/python-${WIN_PYTHON_VERSION}-amd64.exe" -O /tmp/win-python.exe
    xvfb-run -a wine /tmp/win-python.exe /quiet InstallAllUsers=1 PrependPath=1 TargetDir="${WIN_PYTHON_DIR}"
    wineserver --wait
    rm -f /tmp/win-python.exe
EOF

COPY dev/requirements-pyinstaller.txt /tmp/requirements-pyinstaller.txt

# Install Windows Python build requirements.
RUN <<-EOF
    set -ex
    xvfb-run -a wine "${WIN_PYTHON_DIR}\\python.exe" -m pip install --no-cache-dir --upgrade pip
    xvfb-run -a wine "${WIN_PYTHON_DIR}\\python.exe" -m pip install --no-cache-dir -r /tmp/requirements-pyinstaller.txt
    wineserver --wait
EOF

# Install Windows LLVM tools under Wine and expose strip.exe for PyInstaller.
RUN <<-EOF
    set -ex
    wget -q "https://github.com/llvm/llvm-project/releases/download/llvmorg-${WIN_LLVM_VERSION}/LLVM-${WIN_LLVM_VERSION}-win64.exe" -O /tmp/win-llvm.exe
    xvfb-run -a wine /tmp/win-llvm.exe /S
    wineserver --wait
    cp "${WINEPREFIX}/drive_c/Program Files/LLVM/bin/llvm-strip.exe" "${WINEPREFIX}/drive_c/Python311/Scripts/strip.exe"
    xvfb-run -a wine cmd /c where strip
    rm -f /tmp/win-llvm.exe
EOF

# Run as a non-root user.
WORKDIR "${WORKSPACE_DIR}"
RUN <<-EOF
    set -ex
    useradd -m -s /bin/bash vscode
    mkdir -p "${LINUX_PYTHON_DIR}"
    chmod o+r /tmp/requirements-pyinstaller.txt
    chown -R vscode:vscode "${LINUX_PYTHON_DIR}" "${WINEPREFIX}" "${WORKSPACE_DIR}"
EOF
USER vscode

# Native virtualenv used for the Linux build.
#ENV PATH="${LINUX_PYTHON_DIR}/bin:${PATH}"
RUN <<-EOF
    set -ex
    python3 -m venv "${LINUX_PYTHON_DIR}"
    . "${LINUX_PYTHON_DIR}/bin/activate"
    pip install --no-cache-dir --upgrade pip
    pip install --no-cache-dir ruff
    pip install --no-cache-dir -r /tmp/requirements-pyinstaller.txt
EOF
