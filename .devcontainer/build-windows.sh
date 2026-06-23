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

if ! xvfb-run -a wine cmd /c where strip >/dev/null 2>&1; then
	echo "error: strip.exe not found in Wine PATH. Rebuild the devcontainer image to install LLVM strip." >&2
	exit 1
fi

if $build_cli; then
	rm -rf dist/windows/nsz.exe
	xvfb-run -a wine "C:\\Python311\\python.exe" -m PyInstaller --log-level "$PYI_LOG_LEVEL" --distpath dist/windows dev/nsz-cli.spec
	echo "Windows CLI binary: dist/windows/nsz-cli.exe"
fi

if $build_gui; then
	rm -rf build dist/windows/nsz-gui.exe
	xvfb-run -a wine "C:\\Python311\\python.exe" -m PyInstaller --log-level "$PYI_LOG_LEVEL" --distpath dist/windows dev/nsz-gui.spec
	echo "Windows GUI binary: dist/windows/nsz-gui.exe"
fi
