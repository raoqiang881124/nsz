#!/bin/sh
# Builds the NSZ GUI binary for the current OS (Linux, Windows, or macOS).
set -e

pip3 install -r ./requirements-pyinstaller.txt
cd ..
rm -rf build
rm -rf dist
pyinstaller dev/nsz-gui.spec
cd dist/nsz-gui
read -p "Press any key to test ..."
if [ -f ./nsz-gui.exe ]; then
    ./nsz-gui.exe
else
    ./nsz-gui
fi
