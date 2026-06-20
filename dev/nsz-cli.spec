# -*- mode: python ; coding: utf-8 -*-
# PyInstaller spec for the NSZ CLI binary (no GUI/Kivy/OpenCV/pyenchant deps).
# Build with: pyinstaller dev/nsz-cli.spec

import os
block_cipher = None

a = Analysis([os.path.join(SPECPATH, '..', 'nsz.py')],
             pathex=[],
             binaries=[],
             datas=[],
             hiddenimports=[],
             hookspath=[],
             runtime_hooks=[],
             excludes=[
                'nsz.gui',
                'kivy',
                'kivy_deps',
                'cv2',
                'enchant',
                'win32timezone',
                'zstandard.backend_cffi',
                'zstandard._cffi',
                'cffi',
                'pycparser'
            ],
             win_no_prefer_redirects=False,
             win_private_assemblies=False,
             cipher=block_cipher,
             noarchive=False)
pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)
exe = EXE(pyz,
          a.scripts,
          a.binaries,
          a.zipfiles,
          a.datas,
          [],
          name='nsz',
          debug=False,
          bootloader_ignore_signals=False,
          strip=True,
          upx=False,
          upx_exclude=[],
          runtime_tmpdir=None,
          console=True)
