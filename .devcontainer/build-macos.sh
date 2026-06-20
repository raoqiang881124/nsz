#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# macOS binaries must be built on macOS with a local Python toolchain.
if [[ "$(uname -s)" != "Darwin" ]]; then
	echo "Error: macOS build must run on macOS (Darwin)."
	exit 1
fi

pip3 install --no-cache-dir -r dev/requirements-pyinstaller.txt

PYI_LOG_LEVEL="${PYI_LOG_LEVEL:-WARN}"
rm -rf build dist/macos
pyinstaller --log-level "$PYI_LOG_LEVEL" --distpath dist/macos dev/nsz-cli.spec
echo "macOS CLI binary: dist/macos/nsz-cli"

rm -rf build
pyinstaller --log-level "$PYI_LOG_LEVEL" --distpath dist/macos dev/nsz-gui.spec
echo "macOS GUI binary: dist/macos/nsz-gui"
