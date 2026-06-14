"""One-shot importer: padroniza sprite-sheets de VFX baixados → assets/vfx/sprites/.

Os sheets do pacote `vfx_sequence_xN` (e o magic shield) já vêm RGBA-transparentes,
então NÃO precisamos bakear alpha (diferente do pipeline antigo de fundo preto).
Só fazemos downscale 2x (LANCZOS) pra ficar GPU-friendly e consistente com a
explosion (quadros de ~128px), mantendo o grid.

Convenção de nome: snake_case semântico, SEM contagem/tier no nome. O grid mora
nas consts do combat_vfx.dart.
"""
import os
import subprocess
import sys

try:
    from PIL import Image
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "--quiet", "Pillow"])
    from PIL import Image

DL = os.path.join(os.path.expanduser("~"), "Downloads")
DST = r"C:\Dev\Projetos\App_Noheroes\assets\vfx\sprites"
os.makedirs(DST, exist_ok=True)

# (source, dest, downscale_divisor, grid cols x rows) — grid só pra log/sanidade.
JOBS = [
    ("vfx_sequence_x32_ice_bolt.png", "ice_bolt.png", 2, (8, 4)),
    ("vfx_sequence_x16_chaos.png",    "chaos.png",    2, (8, 2)),
    ("vfx_sequence_x16_blood.png",    "blood.png",    2, (8, 2)),
    ("magic shild.png",               "magic_shield.png", 2, (5, 4)),
]

for src_name, dst_name, div, (cols, rows) in JOBS:
    src = os.path.join(DL, src_name)
    dst = os.path.join(DST, dst_name)
    im = Image.open(src).convert("RGBA")
    w, h = im.size
    nw, nh = w // div, h // div
    # sanidade: o grid precisa dividir certinho as dimensões originais.
    assert w % cols == 0 and h % rows == 0, f"{src_name}: {w}x{h} nao casa com grid {cols}x{rows}"
    out = im.resize((nw, nh), Image.LANCZOS)
    out.save(dst, optimize=True)
    fw, fh = nw // cols, nh // rows
    print(f"{dst_name:<18} {w}x{h} -> {nw}x{nh}  grid {cols}x{rows}  frame {fw}x{fh}  ({os.path.getsize(dst)//1024} KB)")

print("OK")
