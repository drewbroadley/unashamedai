#!/usr/bin/env python3
"""Render the link-preview card docs/nz-average-speed-cameras/img/og-image.png.

Fills og-card.html (next to this script) with the page's SITES and MAP data and
screenshots it at 1200x630 with headless Chrome. Re-run when a site's status
changes, since the card shows the counts. Needs Google Chrome; set CHROME to
its binary if it isn't in the usual macOS place. Run:

    python3 scripts/nz-average-speed-cameras/render_og.py [site-id]
"""
import os, re, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
PAGE = os.path.join(ROOT, "docs", "nz-average-speed-cameras", "index.html")
OUT = os.path.join(ROOT, "docs", "nz-average-speed-cameras", "img", "og-image.png")
CHROME = os.environ.get("CHROME", "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")
SITE = sys.argv[1] if len(sys.argv) > 1 else "whitford"

page = open(PAGE, encoding="utf-8").read()
data = re.search(r"^const MAP=.*;$", page, re.M).group(0)
sites = re.search(r"const SITES=\[\n.*?\n\];", page, re.S).group(0)
card = open(os.path.join(HERE, "og-card.html"), encoding="utf-8").read()
card = card.replace("/*MAPDATA*/", data).replace("/*SITES*/", sites)

with tempfile.TemporaryDirectory() as tmp:
    html = os.path.join(tmp, "card.html")
    open(html, "w", encoding="utf-8").write(card)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                    "--window-size=1200,630", "--virtual-time-budget=8000", f"--user-data-dir={tmp}/profile",
                    f"--screenshot={OUT}", f"file://{html}?site={SITE}"], check=True, capture_output=True)
print("wrote", OUT)
