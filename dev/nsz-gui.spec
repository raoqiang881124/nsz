# -*- mode: python ; coding: utf-8 -*-
# PyInstaller spec for the NSZ GUI binary. Builds on Linux, Windows, and macOS.
# Build with: pyinstaller dev/nsz-gui.spec

import os
import sys
import glob

from kivy.tools.packaging.pyinstaller_hooks import (
    get_factory_modules,
    hookspath as kivy_hookspath,
    runtime_hooks as kivy_runtime_hooks,
    kivy_modules,
)

block_cipher = None

# Avoid importing Kivy window providers while evaluating the spec in headless
# build environments. Use static hidden imports with Kivy's alternate hook.
kivyHiddenImports = list(set(get_factory_modules() + kivy_modules + [
    'kivy.core.window',
    'kivy.core.window.window_sdl2',
    'kivy.core.text.text_sdl2',
    'kivy.core.image.img_sdl2',
    'kivy.core.clipboard.clipboard_sdl2',
]))

# Kivy bundles SDL2/GLEW itself on Linux and macOS. On Windows those libraries
# come from the separate kivy_deps.sdl2/kivy_deps.glew wheels and need to be
# collected manually so PyInstaller ships the required DLLs.
extraBinaries = []
extraHiddenImports = []
if sys.platform.startswith('win'):
    from kivy_deps import sdl2, glew, angle

    # angle provides libEGL.dll/libGLESv2.dll/d3dcompiler_47.dll, which SDL2
    # needs to create a GLES2 context via ANGLE (DirectX) instead of native
    # OpenGL. Without these, the GUI fails to start on machines whose GPU
    # driver doesn't support OpenGL (VMs, RDP sessions, old/basic drivers).
    rawDepBins = sdl2.dep_bins + glew.dep_bins + angle.dep_bins
    extraBinaries = []
    for dep in rawDepBins:
        depPath = dep[0] if isinstance(dep, (tuple, list)) else dep
        if os.path.isdir(depPath):
            for dllPath in glob.glob(os.path.join(depPath, '*.dll')):
                extraBinaries.append((os.path.basename(dllPath), dllPath, 'BINARY'))
        elif os.path.isfile(depPath):
            extraBinaries.append((os.path.basename(depPath), depPath, 'BINARY'))
    extraHiddenImports = ['win32timezone']


def _binary_name(entry):
    if isinstance(entry, (tuple, list)) and entry:
        return os.path.basename(str(entry[0]))
    return os.path.basename(str(entry))


def _filter_linux_x11_binaries(entries):
    if not sys.platform.startswith('linux'):
        return entries

    # Prefer host X11/GL loader libs on Linux. Bundling these can cause
    # GLX visual selection failures on systems with different graphics stacks.
    excluded = {
        'libX11.so.6',
        'libXext.so.6',
        'libXrender.so.1',
        'libXfixes.so.3',
        'libXcursor.so.1',
        'libXi.so.6',
        'libXrandr.so.2',
        'libxcb.so.1',
        'libXau.so.6',
        'libXdmcp.so.6',
        # Prefer host C/C++ runtime and low-level support libs to avoid
        # incompatibilities with Mesa drivers on rolling distros.
        'libstdc++.so.6',
        'libgcc_s.so.1',
        'libz.so.1',
        'libffi.so.8',
        'libexpat.so.1',
        'libbsd.so.0',
        'libmd.so.0',
    }
    return [entry for entry in entries if _binary_name(entry) not in excluded]

a = Analysis([os.path.join(SPECPATH, '..', 'nsz.py')],
             pathex=[],
             binaries=[],
             datas=[
                (os.path.join(SPECPATH, '..', 'nsz', 'gui', 'json', '*.json'), 'nsz/gui/json'),
                (os.path.join(SPECPATH, '..', 'nsz', 'gui', 'layout', '*.kv'), 'nsz/gui/layout'),
                (os.path.join(SPECPATH, '..', 'nsz', 'gui', 'shaders', '*.shader'), 'nsz/gui/shaders'),
                (os.path.join(SPECPATH, '..', 'nsz', 'gui', 'fonts', '*'), 'nsz/gui/fonts'),
                (os.path.join(SPECPATH, '..', 'nsz', 'gui', 'txt', '*.txt'), 'nsz/gui/txt'),
                (os.path.join(SPECPATH, '..', 'nsz', 'gui', 'nsZip.png'), 'nsz/gui'),
            ],
             hiddenimports=extraHiddenImports + kivyHiddenImports,
             hookspath=kivy_hookspath(),
             runtime_hooks=kivy_runtime_hooks(),
             excludes=[],
             win_no_prefer_redirects=False,
             win_private_assemblies=False,
             cipher=block_cipher,
             noarchive=False)
pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)
collectedBinaries = _filter_linux_x11_binaries(list(a.binaries) + extraBinaries)
# Build onefile on every platform to avoid a distributed _internal directory.
exe = EXE(
    pyz,
    a.scripts,
    collectedBinaries,
    a.zipfiles,
    a.datas,
    [],
    exclude_binaries=False,
    name='nsz-gui',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=True,
)
