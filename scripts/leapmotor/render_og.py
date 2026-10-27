#!/usr/bin/env python3
"""Render the link-preview cards for the Leapmotor how-to pages.

Pastes the drawing sprites (the <svg> of <symbol>s at the top of each guide page)
into og-card.html (next to this script) and screenshots it at 1200x630 with
headless Chrome, once per card, to docs/leapmotor/<page>/img/og-image.png.
Re-run after changing a page's drawings or a card's wording. Needs Google
Chrome; set CHROME to its binary if it isn't in the usual macOS place. Run:

    python3 scripts/leapmotor/render_og.py
"""
import os, re, subprocess, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
DOCS = os.path.join(ROOT, "docs", "leapmotor")
CHROME = os.environ.get("CHROME", "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")
CARDS = {"wallpaper": "c10-change-wallpaper", "soft-reset": "c10-soft-reset"}

sprites = []
for page in CARDS.values():
    html = open(os.path.join(DOCS, page, "index.html"), encoding="utf-8").read()
    sprites.append(re.search(r'<svg aria-hidden="true" style="position:absolute.*?</svg>', html, re.S).group(0))
card = open(os.path.join(HERE, "og-card.html"), encoding="utf-8").read().replace("<!--SPRITES-->", "\n".join(sprites))

with tempfile.TemporaryDirectory() as tmp:
    src = os.path.join(tmp, "card.html")
    open(src, "w", encoding="utf-8").write(card)
    for name, page in CARDS.items():
        out = os.path.join(DOCS, page, "img", "og-image.png")
        os.makedirs(os.path.dirname(out), exist_ok=True)
        subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                        "--window-size=1200,630", "--virtual-time-budget=8000", f"--user-data-dir={tmp}/profile",
                        f"--screenshot={out}", f"file://{src}?card={name}"], check=True, capture_output=True)
        print("wrote", out)
