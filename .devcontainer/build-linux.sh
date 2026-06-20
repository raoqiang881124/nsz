#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

source /opt/venv-linux/bin/activate
PYI_LOG_LEVEL="${PYI_LOG_LEVEL:-WARN}"
rm -rf build dist
pyinstaller --log-level "$PYI_LOG_LEVEL" --distpath dist/linux dev/nsz-cli.spec
echo "Linux CLI binary: dist/linux/nsz"

rm -rf build
# Kivy provider discovery can touch X11 paths during analysis; run under a
# virtual display so headless container builds are consistent.
xvfb-run -a pyinstaller --log-level "$PYI_LOG_LEVEL" --distpath dist/linux dev/nsz-gui.spec
echo "Linux GUI binary: dist/linux/nsz-gui"
