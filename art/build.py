"""Renders icon.svg to the addon's icon.tga (128x128, 32-bit uncompressed) and a PNG preview.

Needs: pip install resvg_py pillow
Usage: python art/build.py <addon folder that receives icon.tga>
"""
import io
import sys
from pathlib import Path

import resvg_py
from PIL import Image

here = Path(__file__).parent
out_dir = Path(sys.argv[1])
png = bytes(resvg_py.svg_to_bytes(svg_path=str(here / "icon.svg"), width=128, height=128))
image = Image.open(io.BytesIO(png)).convert("RGBA")
image.save(here / "icon-128.png")
image.save(out_dir / "icon.tga", format="TGA", compression=None, orientation=-1)
