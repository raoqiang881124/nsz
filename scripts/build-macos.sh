#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

build_cli=true
build_gui=true
case "${1:-}" in
	--cli) build_gui=false ;;
	--gui) build_cli=false ;;
	"") ;;
	*) echo "Usage: $0 [--cli|--gui]" >&2; exit 1 ;;
esac

# macOS binaries must be built on macOS with a local Python toolchain.
if [[ "$(uname -s)" != "Darwin" ]]; then
	echo "Error: macOS build must run on macOS (Darwin)."
	exit 1
fi

pip3 install --no-cache-dir -r dev/requirements-pyinstaller.txt

PYI_LOG_LEVEL="${PYI_LOG_LEVEL:-WARN}"

if $build_cli; then
	rm -rf dist/macos/nsz
	pyinstaller --log-level "$PYI_LOG_LEVEL" --distpath dist/macos dev/nsz-cli.spec
	echo "macOS CLI binary: dist/macos/nsz-cli"
fi

if $build_gui; then
	rm -rf build dist/macos/nsz-gui
	pyinstaller --log-level "$PYI_LOG_LEVEL" --distpath dist/macos dev/nsz-gui.spec
	echo "macOS GUI binary: dist/macos/nsz-gui"
fi
