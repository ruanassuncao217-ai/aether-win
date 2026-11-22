#!/usr/bin/env python3
"""Gera o wallpaper futurista do AETHER-WIN (grade em perspectiva + anel HUD + particulas).

Uso:
    python generate_wallpaper.py                       # 3840x2160, ciano
    python generate_wallpaper.py --accent magenta --width 2560 --height 1440 --seed 7
Requer: pip install pillow numpy
"""
import argparse
import math
import random

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

ACCENTS = {
    "cyan": (0, 229, 255),
    "magenta": (255, 0, 200),
    "violet": (139, 92, 246),
    "green": (0, 255, 156),
}


def colorize(mask: Image.Image, rgb) -> Image.Image:
    a = np.asarray(mask, dtype=np.float32)[..., None] / 255.0
    return Image.fromarray((a * np.array(rgb, dtype=np.float32)).astype("uint8"), "RGB")


def glow(img: Image.Image, radius: float, strength: float = 1.0) -> Image.Image:
    blurred = img.filter(ImageFilter.GaussianBlur(radius))
    if strength != 1.0:
        blurred = Image.fromarray(np.clip(np.asarray(blurred, dtype=np.float32) * strength, 0, 255).astype("uint8"))
    return ImageChops.add(img, blurred)


def radial_background(w: int, h: int) -> Image.Image:
    y, x = np.ogrid[:h, :w]
    cx, cy = w * 0.5, h * 0.40
    d = np.sqrt(((x - cx) / w) ** 2 + ((y - cy) / h) ** 2)
    d = np.clip(d / 0.72, 0, 1)[..., None]
    c0 = np.array([9, 16, 36], dtype=np.float32)
    c1 = np.array([1, 2, 6], dtype=np.float32)
    return Image.fromarray((c0 * (1 - d) + c1 * d).astype("uint8"), "RGB")


def perspective_grid(w: int, h: int, horizon: float) -> Image.Image:
    hy = int(h * horizon)
    layer = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(layer)
    lw = max(1, h // 1080)
    n = 28
    for i in range(1, n + 1):  # linhas horizontais (espacamento cresce com a proximidade)
        t = i / n
        y = hy + (h - hy) * (t ** 2.4)
        d.line([(0, y), (w, y)], fill=255, width=lw)
    for k in range(-34, 35):  # linhas que convergem ao ponto de fuga
        xb = w / 2 + k * w * 0.075
        d.line([(w / 2, hy), (xb, h)], fill=255, width=lw)
    # esmaece perto do horizonte e nas bordas laterais
    yy = np.linspace(0, 1, h, dtype=np.float32)[:, None]
    fade_y = np.clip((yy - horizon) / (1 - horizon), 0, 1) ** 0.6
    xx = np.linspace(-1, 1, w, dtype=np.float32)[None, :]
    fade_x = np.clip(1.15 - np.abs(xx) ** 1.8, 0, 1)
    arr = np.asarray(layer, dtype=np.float32) * fade_y * fade_x * 0.75
    return Image.fromarray(arr.astype("uint8"), "L")


def hud_ring(w: int, h: int, cx: float, cy: float, r: float):
    """Retorna (mascara_principal, mascara_secundaria) com aneis, arcos e marcas."""
    main = Image.new("L", (w, h), 0)
    alt = Image.new("L", (w, h), 0)
    dm, da = ImageDraw.Draw(main), ImageDraw.Draw(alt)
    lw = max(2, h // 700)

    def box(rad):
        return [cx - rad, cy - rad, cx + rad, cy + rad]

    dm.ellipse(box(r), outline=255, width=lw)
    dm.ellipse(box(r * 0.82), outline=140, width=max(1, lw // 2))
    dm.arc(box(r * 1.08), 200, 320, fill=255, width=lw * 3)
    dm.arc(box(r * 1.08), 20, 60, fill=200, width=lw * 3)
    da.arc(box(r * 0.92), 300, 360, fill=255, width=lw * 3)
    da.arc(box(r * 0.92), 110, 150, fill=220, width=lw * 2)
    da.ellipse(box(r * 0.55), outline=200, width=lw)
    dm.ellipse(box(r * 0.30), outline=160, width=lw)
    for i in range(120):  # marcas de graduacao
        a = math.radians(i * 3)
        major = i % 10 == 0
        r1, r2 = r * (0.94 if major else 0.97), r * 1.0
        dm.line(
            [(cx + math.cos(a) * r1, cy + math.sin(a) * r1), (cx + math.cos(a) * r2, cy + math.sin(a) * r2)],
            fill=255 if major else 120,
            width=lw if major else max(1, lw // 2),
        )
    # retículo central
    s = r * 0.12
    dm.line([(cx - s, cy), (cx + s, cy)], fill=255, width=lw)
    dm.line([(cx, cy - s), (cx, cy + s)], fill=255, width=lw)
    return main, alt


def particles(w: int, h: int, rng: random.Random, count: int) -> Image.Image:
    layer = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(layer)
    for _ in range(count):
        x, y = rng.random() * w, rng.random() * h * 0.72
        s = rng.choice([1, 1, 1, 2, 2, 3]) * max(1, h // 1080)
        v = rng.randint(70, 230)
        d.ellipse([x, y, x + s, y + s], fill=v)
    return layer


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--width", type=int, default=3840)
    ap.add_argument("--height", type=int, default=2160)
    ap.add_argument("--accent", choices=ACCENTS.keys(), default="cyan")
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--out", default="aether-wallpaper-4k.png")
    a = ap.parse_args()

    w, h = a.width, a.height
    rng = random.Random(a.seed)
    c_main = ACCENTS[a.accent]
    c_alt = (255, 0, 200) if a.accent != "magenta" else (0, 229, 255)
    horizon = 0.62

    img = radial_background(w, h)

    # brilho do horizonte
    band = Image.new("L", (w, h), 0)
    ImageDraw.Draw(band).rectangle([0, int(h * horizon) - h // 400, w, int(h * horizon) + h // 400], fill=255)
    img = ImageChops.add(img, glow(colorize(band, c_alt), h * 0.02, 1.2))

    # grade em perspectiva
    img = ImageChops.add(img, glow(colorize(perspective_grid(w, h, horizon), c_main), h * 0.004, 1.4))

    # anel HUD
    m_main, m_alt = hud_ring(w, h, w * 0.5, h * 0.36, h * 0.21)
    img = ImageChops.add(img, glow(colorize(m_main, c_main), h * 0.006, 1.6))
    img = ImageChops.add(img, glow(colorize(m_alt, c_alt), h * 0.006, 1.6))

    # nucleo luminoso
    core = Image.new("L", (w, h), 0)
    cx, cy, cr = w * 0.5, h * 0.36, h * 0.025
    ImageDraw.Draw(core).ellipse([cx - cr, cy - cr, cx + cr, cy + cr], fill=255)
    img = ImageChops.add(img, glow(colorize(core, c_main), h * 0.03, 2.0))

    # particulas
    img = ImageChops.add(img, glow(colorize(particles(w, h, rng, 420), (200, 230, 255)), 2, 0.8))

    # vinheta + leve granulacao
    arr = np.asarray(img, dtype=np.float32)
    y, x = np.ogrid[:h, :w]
    v = 1 - 0.45 * np.clip((((x - w / 2) / (w / 2)) ** 2 + ((y - h / 2) / (h / 2)) ** 2) / 2, 0, 1)[..., None]
    noise = np.random.default_rng(a.seed).normal(0, 0.7, (h, w, 1)).astype(np.float32)
    out = np.clip(arr * v + noise, 0, 255).astype("uint8")
    Image.fromarray(out, "RGB").save(a.out, optimize=True)
    print(f"OK -> {a.out} ({w}x{h}, acento {a.accent})")


if __name__ == "__main__":
    main()
