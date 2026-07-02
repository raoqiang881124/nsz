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

case "$(uname -m)" in
	x86_64) arch=x64 ;;
	arm64) arch=arm64 ;;
	*) echo "Error: unsupported architecture $(uname -m)" >&2; exit 1 ;;
esac
distpath="dist/darwin-$arch"

if $build_cli; then
	rm -rf "$distpath/nsz"
	python3 -m PyInstaller --log-level "$PYI_LOG_LEVEL" --distpath "$distpath" dev/nsz-cli.spec
	echo "macOS CLI binary: $distpath/nsz"
fi

if $build_gui; then
	rm -rf build "$distpath/nsz-gui"
	python3 -m PyInstaller --log-level "$PYI_LOG_LEVEL" --distpath "$distpath" dev/nsz-gui.spec
	echo "macOS GUI binary: $distpath/nsz-gui"
fi
