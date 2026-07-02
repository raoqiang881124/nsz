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

export WINEARCH=win64
export WINEPREFIX=/opt/wine
export WINEDEBUG=-all
PYI_LOG_LEVEL="${PYI_LOG_LEVEL:-WARN}"

case "$(uname -m)" in
	x86_64) arch=x64 ;;
	aarch64 | arm64) arch=arm64 ;;
	*) echo "Error: unsupported architecture $(uname -m)" >&2; exit 1 ;;
esac
distpath="dist/win32-$arch"

if ! xvfb-run -a wine cmd /c where strip >/dev/null 2>&1; then
	echo "error: strip.exe not found in Wine PATH. Rebuild the devcontainer image to install LLVM strip." >&2
	exit 1
fi

if $build_cli; then
	rm -rf "$distpath/nsz.exe"
	xvfb-run -a wine "C:\\Python311\\python.exe" -m PyInstaller --log-level "$PYI_LOG_LEVEL" --distpath "$distpath" dev/nsz-cli.spec
	echo "Windows CLI binary: $distpath/nsz-cli.exe"
fi

if $build_gui; then
	rm -rf build "$distpath/nsz-gui.exe"
	xvfb-run -a wine "C:\\Python311\\python.exe" -m PyInstaller --log-level "$PYI_LOG_LEVEL" --distpath "$distpath" dev/nsz-gui.spec
	echo "Windows GUI binary: $distpath/nsz-gui.exe"
fi
