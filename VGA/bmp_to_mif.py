"""
bmp_to_mif.py
-------------
Converts 256-color BMP files to Quartus MIF (Memory Initialization
File) for use with the IP Catalog ROM generator (altsyncram megafunction).

MIF is the native Quartus format for ROM initialization

Transparency R, G, B: pixels whose BMP palette entry matches the background color are
written as 0x00

Usage:
    python bmp_to_mif.py in.bmp out.mif R,G,B

Requirements:
    BMP must be 256-color
    Pillow
    numpy

"""
import numpy as np
from PIL import Image
import struct, sys, os

# 8Bit 256 Color LUT (from the SystemVerilog color_lut_8b case entries)
def build_lut8b_palette():
    pal = [(0, 0, 0)] * 256

    # 0x00-0x09  reserved system colors
    pal[0x00] = (0x00, 0x00, 0x00)
    pal[0x01] = (0x80, 0x00, 0x00)
    pal[0x02] = (0x00, 0x80, 0x00)
    pal[0x03] = (0x80, 0x80, 0x00)
    pal[0x04] = (0x00, 0x00, 0x80)
    pal[0x05] = (0x80, 0x00, 0x80)
    pal[0x06] = (0x00, 0x80, 0x80)
    pal[0x07] = (0xC0, 0xC0, 0xC0)
    pal[0x08] = (0xC0, 0xDC, 0xC0)
    pal[0x09] = (0xA6, 0xCA, 0xF0)

    # 0x0A-0xE1  216-color web-safe 6×6×6 RGB cube
    levels = [0x00, 0x33, 0x66, 0x99, 0xCC, 0xFF]
    idx = 0x0A
    for r in levels:
        for g in levels:
            for b in levels:
                pal[idx] = (r, g, b)
                idx += 1
    # 0xE2-0xF5  20 grey shades
    greys = [0x08,0x10,0x18,0x20,0x29,0x31,0x39,0x41,0x4A,0x52,0x5A,0x62,0x6A,0x73,0x7B,0x83,0x8B,0x94,0x9C,0xA4]
    for i, v in enumerate(greys):
        pal[0xE2 + i] = (v, v, v)

    # 0xF6-0xFF  reserved system colors
    pal[0xF6] = (0xFF, 0xFB, 0xF0)
    pal[0xF7] = (0xA0, 0xA0, 0xA4)
    pal[0xF8] = (0x80, 0x80, 0x80)
    pal[0xF9] = (0xFF, 0x00, 0x00)
    pal[0xFA] = (0x00, 0xFF, 0x00)
    pal[0xFB] = (0xFF, 0xFF, 0x00)
    pal[0xFC] = (0x00, 0x00, 0xFF)
    pal[0xFD] = (0xFF, 0x00, 0xFF)
    pal[0xFE] = (0x00, 0xFF, 0xFF)
    pal[0xFF] = (0xFF, 0xFF, 0xFF)

    return np.array(pal, dtype=np.int32)

LUT8B = build_lut8b_palette()

def nearest_lut_index(r, g, b):
    d = LUT8B - np.array([r, g, b], dtype=np.int32)
    idx = int(np.argmin((d ** 2).sum(axis=1)))
    return 0x0A if idx == 0 else idx

# Import BMP
def read_bmp_info(path):
    with open(path, 'rb') as f:
        sig = f.read(2)
        if sig != b'BM':
            raise ValueError(f"Not a BMP file: {path}")

        f.read(8)                                  
        pixel_offset = struct.unpack('<I', f.read(4))[0]
        dib_size     = struct.unpack('<I', f.read(4))[0]
        width        = struct.unpack('<i', f.read(4))[0]
        height       = struct.unpack('<i', f.read(4))[0]
        f.read(2)                               
        bit_count    = struct.unpack('<H', f.read(2))[0]

        if bit_count != 8:
            raise ValueError(
                f"{path}: expected 8-bit (256-color) BMP, got {bit_count}-bit")

        f.read(dib_size - 16)
        palette = []
        for _ in range(256):
            b, g, r, _ = struct.unpack('4B', f.read(4))
            palette.append((r, g, b))
    return np.array(palette, dtype=np.int32), width, abs(height)

# Covert BMP to MIF
def convert(bmp_path, mif_path, bg_color=None):
    bmp_pal, width, height = read_bmp_info(bmp_path)
    img = Image.open(bmp_path).convert('P')
    pixels = np.array(img, dtype=np.uint8)

    depth = width * height

    remap = np.zeros(256, dtype=np.uint8)
    for i in range(256):
        r, g, b = bmp_pal[i]
        if bg_color is not None and (r, g, b) == tuple(bg_color):
            remap[i] = 0x00        
        else:
            remap[i] = nearest_lut_index(r, g, b)

    # Apply remap
    out = remap[pixels]
    # Write .mif
    addr_bits = max(1, (depth - 1).bit_length())
    with open(mif_path, 'w') as f:
        f.write(f"-- Sprite ROM: {os.path.basename(bmp_path)}\n")
        f.write(f"-- {width} x {height} pixels, 8-bit palette indices\n")
        f.write(f"-- Transparent color: {bg_color}\n\n")
        f.write(f"WIDTH = 8;\n")
        f.write(f"DEPTH = {depth};\n\n")
        f.write(f"ADDRESS_RADIX = HEX;\n")
        f.write(f"DATA_RADIX = HEX;\n\n")
        f.write(f"CONTENT BEGIN\n")

        addr = 0
        for row in range(height):
            for col in range(width):
                f.write(f"\t{addr:0{(addr_bits+3)//4}X} : {out[row, col]:02X};\n")
                addr += 1

        f.write("END;\n")

    print(f"  {os.path.basename(bmp_path):28s}  {width}x{height}"f"  depth={depth}  >  {mif_path}")

SPRITES = [
    # ( input BMP,         output MIF,         background color  )
    ("Squirrel.bmp",     "Squirrel.mif",      (0,   0, 0)),
    ("Postal.bmp",       "Postal.mif",        (0,   0, 0)),
    ("Bath.bmp",      	 "Bath.mif",          (0,   0, 0)),
    ("Door.bmp",   	     "Door.mif",          (0,   0, 0)),
    ("Player.bmp",       "Player.mif",        (0,   0, 0)),
    ("Blockade.bmp",     "Blockade.mif",      (0,   0, 0)),
    ("Burger.bmp",       "Burger.mif",        (0,   0, 0)),
]

# ─────────────────────────────────────────────────────────────────────────────
# Entry point
# ─────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    if len(sys.argv) >= 3:
        bmp_in  = sys.argv[1]
        mif_out = sys.argv[2]
        bg      = None
        if len(sys.argv) == 4:
            bg = tuple(int(x) for x in sys.argv[3].split(','))
        convert(bmp_in, mif_out, bg)
    else:
        print("Converting BMP sprites to .mif files...\n")
        errors = 0
        for bmp, mif, bg in SPRITES:
            if os.path.exists(bmp):
                try:
                    convert(bmp, mif, bg)
                except Exception as e:
                    print(f"  ERROR {bmp}: {e}")
                    errors += 1
            else:
                print(f"  SKIP (not found): {bmp}")
        print(f"\n{errors} error(s).")
