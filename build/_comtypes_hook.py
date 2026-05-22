# -*- coding: utf-8 -*-
"""PyInstaller runtime hook for comtypes generated wrappers.

comtypes may need to generate Python modules for COM type libraries at runtime.
Installed applications usually live under Program Files, which is not writable
for normal users, so keep generated wrappers in a per-user temp directory.
"""

import os
import tempfile

import comtypes
import comtypes.client
import comtypes.gen


gen_dir = os.path.join(tempfile.gettempdir(), "wxauto_comtypes_gen")
os.makedirs(gen_dir, exist_ok=True)

comtypes.client.gen_dir = gen_dir
if gen_dir not in comtypes.gen.__path__:
    comtypes.gen.__path__.insert(0, gen_dir)
