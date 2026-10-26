#!/usr/bin/env python3
"""Rebuild the map data embedded in docs/nz-average-speed-cameras/index.html.

The page's SITES array (camera positions, detection points, distances, statuses)
is the source of truth and is edited by hand. This script reads it and rewrites
the one-line `const MAP=...;` near the top of the page:

  - each section's road line, routed through its cameras by the public OSRM
    demo server (router.project-osrm.org), with the road distance of each gap;
  - a basemap per site from OpenStreetMap via the Overpass API: roads, rail,
    rivers, lakes, coastline (turned into land polygons) and place names,
    clipped to a frame around the section and simplified;
  - a New Zealand outline for the overview, from Natural Earth 1:10m via the
    world-atlas package on jsDelivr.

Every download is cached in .cache/ next to this script, so a re-run after
editing SITES only fetches what changed. Uses curl for HTTP. Run:

    python3 scripts/nz-average-speed-cameras/build_map.py
"""
import hashlib, json, math, os, re, subprocess, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
PAGE = os.path.join(ROOT, "docs", "nz-average-speed-cameras", "index.html")
CACHE = os.path.join(HERE, ".cache")
UA = "unashamedai-map/1.0 (+https://unashamedai.broadley.org.nz)"
OVERPASS = "https://overpass-api.de/api/interpreter"
OSRM = "https://router.project-osrm.org/route/v1/driving/"
WORLD = "https://cdn.jsdelivr.net/npm/world-atlas@2.0.2/countries-10m.json"


# ---------- fetching, cached ----------
def cached(kind, key, fetch):
    os.makedirs(CACHE, exist_ok=True)
    fn = os.path.join(CACHE, f"{kind}-{hashlib.sha1(key.encode()).hexdigest()[:16]}.json")
    if os.path.exists(fn):
        return json.load(open(fn))
    data = fetch()
    json.dump(data, open(fn, "w"))
    return data

def curl_json(args, tries=40, wait=12):
    for attempt in range(tries):
        p = subprocess.run(["curl", "-sS", "--max-time", "200", "-A", UA, "-H", "Accept: application/json", *args],
                           capture_output=True, text=True)
        try:
            return json.loads(p.stdout)
        except ValueError:
            print(f"  retry {attempt+1}: {(p.stdout or p.stderr)[:70].strip()!r}", flush=True)
            time.sleep(wait)
    sys.exit("giving up: " + args[-1])

def route(cams):
    coords = ";".join(f"{lon},{lat}" for lat, lon in cams)
    url = f"{OSRM}{coords}?overview=full&geometries=geojson&steps=false"
    r = cached("route", url, lambda: curl_json([url], tries=5, wait=3))
    rt = r["routes"][0]
    return [[c[1], c[0]] for c in rt["geometry"]["coordinates"]], [round(l["distance"]) for l in rt["legs"]]

OVERPASS_Q = """[out:json][timeout:180];
(
 way["highway"~"^(motorway|trunk|primary|secondary|tertiary|unclassified|residential|living_street|motorway_link|trunk_link|primary_link|secondary_link|tertiary_link)$"]({bb});
 way["railway"="rail"]({bb});
 way["waterway"="river"]({bb});
 way["natural"="water"]({bb});
 relation["natural"="water"]({bb});
 way["natural"="coastline"]({bb});
 node["place"~"^(city|town|village|hamlet|suburb|locality)$"]({bb});
);
out geom;"""

def overpass(bb):
    q = OVERPASS_Q.replace("{bb}", ",".join(map(str, bb)))
    return cached("osm", q, lambda: curl_json(["--data-urlencode", "data=" + q, OVERPASS]))["elements"]


# ---------- geometry ----------
def dp(pts, tol):
    """Douglas-Peucker simplification."""
    if len(pts) < 3: return pts
    keep = [False] * len(pts); keep[0] = keep[-1] = True
    stack = [(0, len(pts) - 1)]
    while stack:
        a, b = stack.pop()
        ax, ay = pts[a]; bx, by = pts[b]; dx, dy = bx - ax, by - ay; L = math.hypot(dx, dy)
        best, bi = -1, -1
        for i in range(a + 1, b):
            px, py = pts[i]
            d = abs(dy * px - dx * py + bx * ay - by * ax) / L if L else math.hypot(px - ax, py - ay)
            if d > best: best, bi = d, i
        if best > tol: keep[bi] = True; stack += [(a, bi), (bi, b)]
    return [p for p, k in zip(pts, keep) if k]

def clip_line(pts, x0, y0, x1, y1):
    """Clip a polyline to a rectangle (Liang-Barsky per segment); returns the inside pieces."""
    out, cur = [], []
    def lb(p, q):
        (xa, ya), (xb, yb) = p, q; dx, dy = xb - xa, yb - ya; t0, t1 = 0.0, 1.0
        for pp, qq in ((-dx, xa - x0), (dx, x1 - xa), (-dy, ya - y0), (dy, y1 - ya)):
            if pp == 0:
                if qq < 0: return None
            else:
                r = qq / pp
                if pp < 0: t0 = max(t0, r)
                else: t1 = min(t1, r)
        if t0 > t1: return None
        return (xa + t0 * dx, ya + t0 * dy), (xa + t1 * dx, ya + t1 * dy), t0 > 0, t1 < 1
    for i in range(1, len(pts)):
        r = lb(pts[i - 1], pts[i])
        if r is None:
            if len(cur) > 1: out.append(cur)
            cur = []; continue
        a, b, enter, leave = r
        if not cur or enter:
            if len(cur) > 1: out.append(cur)
            cur = [a]
        cur.append(b)
        if leave: out.append(cur); cur = []
    if len(cur) > 1: out.append(cur)
    return out

def clip_poly(ring, x0, y0, x1, y1):
    """Sutherland-Hodgman clip of a ring to a rectangle."""
    def clip(pts, inside, inter):
        res = []
        for i in range(len(pts)):
            c, p = pts[i], pts[i - 1]
            if inside(c):
                if not inside(p): res.append(inter(p, c))
                res.append(c)
            elif inside(p): res.append(inter(p, c))
        return res
    ix = lambda x: lambda p, c: (x, p[1] + (c[1] - p[1]) * (x - p[0]) / (c[0] - p[0]))
    iy = lambda y: lambda p, c: (p[0] + (c[0] - p[0]) * (y - p[1]) / (c[1] - p[1]), y)
    pts = ring
    for inside, inter in ((lambda p: p[0] >= x0, ix(x0)), (lambda p: p[0] <= x1, ix(x1)),
                          (lambda p: p[1] >= y0, iy(y0)), (lambda p: p[1] <= y1, iy(y1))):
        if not pts: break
        pts = clip(pts, inside, inter)
    return pts

def area(ring):
    return abs(sum(ring[i - 1][0] * ring[i][1] - ring[i][0] * ring[i - 1][1] for i in range(len(ring)))) / 2

def join_ways(ways):
    """Join (node ids, coords) ways end to end into chains and rings."""
    chains = [(list(n), list(c)) for n, c in ways]
    changed = True
    while changed:
        changed = False
        for i in range(len(chains)):
            ni, ci = chains[i]
            if ni[0] == ni[-1]: continue
            for j in range(len(chains)):
                if i == j: continue
                nj, cj = chains[j]
                if nj[0] == nj[-1]: continue
                if ni[-1] == nj[0]: chains[i] = (ni + nj[1:], ci + cj[1:])
                elif ni[-1] == nj[-1]: chains[i] = (ni + nj[::-1][1:], ci + cj[::-1][1:])
                elif ni[0] == nj[-1]: chains[i] = (nj + ni[1:], cj + ci[1:])
                elif ni[0] == nj[0]: chains[i] = (nj[::-1] + ni[1:], cj[::-1] + ci[1:])
                else: continue
                del chains[j]; changed = True; break
            if changed: break
    return chains

def land_from_coast(coast_ways, wb, sb, eb, nb):
    """OSM coastline runs with land on its left. Clip it to the frame and close
    each piece by walking the frame edge anticlockwise to the next piece."""
    chains = join_ways(coast_ways)
    X0, Y0, X1, Y1 = wb, sb, eb, nb
    def tpos(p):
        x, y = p
        if abs(y - Y0) < 1e-9: return (x - X0) / (X1 - X0)
        if abs(x - X1) < 1e-9: return 1 + (y - Y0) / (Y1 - Y0)
        if abs(y - Y1) < 1e-9: return 2 + (X1 - x) / (X1 - X0)
        return 3 + (Y1 - y) / (Y1 - Y0)
    on_edge = lambda p: min(abs(p[0] - X0), abs(p[0] - X1), abs(p[1] - Y0), abs(p[1] - Y1)) < 1e-9
    corners = [(1.0, (X1, Y0)), (2.0, (X1, Y1)), (3.0, (X0, Y1)), (4.0, (X0, Y0))]
    pieces, islands = [], []
    for ids, c in chains:
        if ids[0] == ids[-1] and all(X0 < x < X1 and Y0 < y < Y1 for x, y in c):
            islands.append(c); continue
        for pc in clip_line(c, X0, Y0, X1, Y1):
            if on_edge(pc[0]) and on_edge(pc[-1]):
                pieces.append({"pts": pc, "te": tpos(pc[0]), "tx": tpos(pc[-1])})
    rings, used = [], set()
    for i0 in range(len(pieces)):
        if i0 in used: continue
        used.add(i0); ring = list(pieces[i0]["pts"]); cur = i0
        for _ in range(500):
            tx = pieces[cur]["tx"]
            nxt = min(range(len(pieces)), key=lambda j: (pieces[j]["te"] - tx) % 4)
            d = (pieces[nxt]["te"] - tx) % 4
            ring += [cp for _, cp in sorted(((ct - tx) % 4, cp) for ct, cp in corners if 0 < (ct - tx) % 4 < d)]
            if nxt == i0: break
            used.add(nxt); ring += pieces[nxt]["pts"]; cur = nxt
        rings.append(ring)
    return rings + islands


# ---------- one site ----------
HW = {"motorway": "H", "trunk": "H", "motorway_link": "H", "trunk_link": "H", "primary": "M", "primary_link": "M",
      "secondary": "M", "secondary_link": "M", "tertiary": "S", "tertiary_link": "S", "unclassified": "S",
      "residential": "R", "living_street": "R"}
PRANK = {"city": 0, "town": 1, "village": 2, "suburb": 3, "hamlet": 3, "locality": 4}

def frame_for(geom):
    lats = [p[0] for p in geom]; lons = [p[1] for p in geom]
    s, n, w, e = min(lats), max(lats), min(lons), max(lons)
    kx = 111320 * math.cos(math.radians((s + n) / 2)); ky = 111320
    wm, hm = (e - w) * kx, (n - s) * ky
    m = max(1500, 0.28 * max(wm, hm))
    W, H = wm + 2 * m, hm + 2 * m
    if W < H * 1.3:
        extra = (H * 1.3 - W) / 2; w -= extra / kx; e += extra / kx
    return [round(s - m / ky, 5), round(w - m / kx, 5), round(n + m / ky, 5), round(e + m / kx, 5)]

def build_site(site):
    geom, legs = route(site["cams"])
    sb, wb, nb, eb = frame_for(geom)
    osm = overpass([sb, wb, nb, eb])
    lat0, lon0 = (sb + nb) / 2, (wb + eb) / 2
    kx = 111320 * math.cos(math.radians(lat0))
    P = lambda la, lo: ((lo - lon0) * kx, -(la - lat0) * 111320)        # local metres, y down
    x0, y0 = P(nb, wb); x1, y1 = P(sb, eb)
    tol = max(2.0, math.hypot(x1 - x0, y1 - y0) / 5000)
    min_area = (tol * 12) ** 2                     # drop ponds too small to see at this frame's scale
    flat = lambda pts: [v for p in pts for v in (round(p[0]), round(p[1]))]
    # residential streets only near the section (towns at the edge of a big frame add weight, not context)
    NEAR = 1500
    grid = {(int(x // NEAR), int(y // NEAR)) for x, y in (P(*p) for p in geom)}
    near = lambda pts: any((int(x // NEAR) + i, int(y // NEAR) + j) in grid for x, y in pts for i in (-1, 0, 1) for j in (-1, 0, 1))
    roads, rail, rivers, water, places, coast = [], [], [], [], [], []
    for el in osm:
        t = el.get("tags", {})
        if el["type"] == "node":
            if "name" in t and t.get("place") in PRANK:
                x, y = P(el["lat"], el["lon"])
                if x0 <= x <= x1 and y0 <= y <= y1: places.append([t["name"], PRANK[t["place"]], round(x), round(y)])
        elif el["type"] == "way":
            g = [P(p["lat"], p["lon"]) for p in el.get("geometry", []) if p]
            if len(g) < 2: continue
            if "highway" in t:
                c = HW[t["highway"]]; label = ""
                if c == "R" and not near(g): continue
                if c != "R":
                    ref = t.get("ref", ""); nm = t.get("name", "")
                    sh = ref.replace(";", "/") if ref.startswith("SH") else ""
                    nm = "" if nm.lower().startswith("state highway") else nm
                    label = sh + (" · " if sh and nm else "") + nm
                for piece in clip_line(g, x0, y0, x1, y1):
                    piece = dp(piece, tol)
                    if len(piece) >= 2: roads.append([c, label, flat(piece)])
            elif t.get("railway") == "rail":
                rail += [flat(dp(pc, tol)) for pc in clip_line(g, x0, y0, x1, y1)]
            elif "waterway" in t:
                rivers += [[t.get("name", ""), flat(dp(pc, tol))] for pc in clip_line(g, x0, y0, x1, y1)]
            elif t.get("natural") == "coastline":
                coast.append((el["nodes"], [(p["lon"], p["lat"]) for p in el["geometry"]]))
            elif t.get("natural") == "water" and el["nodes"][0] == el["nodes"][-1]:
                r = clip_poly(dp(g, tol), x0, y0, x1, y1)
                if len(r) >= 3 and area(r) >= min_area: water.append([t.get("name", ""), [flat(r)]])
        elif el["type"] == "relation" and t.get("natural") == "water":
            groups = {"outer": [], "inner": []}
            for m in el.get("members", []):
                if m["type"] != "way" or not m.get("geometry"): continue
                coords = [(p["lat"], p["lon"]) for p in m["geometry"] if p]
                key = [(round(a, 7), round(b, 7)) for a, b in coords]
                groups["inner" if m.get("role") == "inner" else "outer"].append((key, coords))
            rings = []
            for grp in groups.values():
                for ids, coords in join_ways(grp):
                    if ids[0] != ids[-1]: continue
                    r = clip_poly(dp([P(*c) for c in coords], tol), x0, y0, x1, y1)
                    if len(r) >= 3 and area(r) >= min_area: rings.append(flat(r))
            if rings: water.append([t.get("name", ""), rings])
    land = None
    if coast:
        land = [flat(dp([P(y, x) for x, y in r], tol)) for r in land_from_coast(coast, wb, sb, eb, nb)]
    return {"o": [round(lat0, 6), round(lon0, 6)], "bb": [round(x0), round(y0), round(x1), round(y1)],
            "roads": roads, "rail": rail, "rivers": rivers, "water": water, "land": land,
            "places": sorted(places, key=lambda p: p[1]), "route": flat(dp([P(*p) for p in geom], 1.0)),
            "legs": legs}, geom


# ---------- New Zealand outline ----------
NZ_O = (-41.0, 173.5)
def nz_proj(la, lo):  # units of 100 m
    return ((lo - NZ_O[1]) * 111.32 * math.cos(math.radians(NZ_O[0])) * 10, -(la - NZ_O[0]) * 1113.2)

def nz_outline():
    topo = cached("world", WORLD, lambda: curl_json([WORLD], tries=3, wait=5))
    sc, tr = topo["transform"]["scale"], topo["transform"]["translate"]
    arcs = []
    for a in topo["arcs"]:
        x = y = 0; pts = []
        for dx, dy in a: x += dx; y += dy; pts.append((x * sc[0] + tr[0], y * sc[1] + tr[1]))
        arcs.append(pts)
    arc = lambda i: arcs[i] if i >= 0 else arcs[~i][::-1]
    nz = next(g for g in topo["objects"]["countries"]["geometries"] if g.get("properties", {}).get("name") == "New Zealand")
    out = []
    for poly in nz["arcs"]:
        ring = []
        for i in poly[0]: ring += arc(i)[(1 if ring else 0):]
        lons = [p[0] for p in ring]; lats = [p[1] for p in ring]
        if min(lons) < 165 or max(lons) > 179.5 or min(lats) < -47.6: continue   # main islands only
        pts = dp([nz_proj(la, lo) for lo, la in ring], 6)
        if abs(sum(pts[i - 1][0] * pts[i][1] - pts[i][0] * pts[i - 1][1] for i in range(len(pts)))) / 2 < 300: continue
        out.append([v for p in pts for v in (round(p[0]), round(p[1]))])
    return out


def main():
    html = open(PAGE, encoding="utf-8").read()
    m = re.search(r"const SITES=\[\n(.*?)\n\];", html, re.S)
    sites = json.loads("[" + m.group(1) + "]")
    base, nzroutes = {}, {}
    for s in sites:
        print(s["id"], flush=True)
        base[s["id"]], geom = build_site(s)
        nzroutes[s["id"]] = [v for p in dp([nz_proj(*p) for p in geom], 3) for v in (round(p[0]), round(p[1]))]
    data = {"BASE": base, "NZ": {"o": list(NZ_O), "land": nz_outline(), "routes": nzroutes}}
    line = "const MAP=" + json.dumps(data, separators=(",", ":"), ensure_ascii=False) + ";"
    html, n = re.subn(r"^const MAP=.*;$", lambda _: line, html, count=1, flags=re.M)
    if n != 1: sys.exit("could not find the `const MAP=` line in " + PAGE)
    open(PAGE, "w", encoding="utf-8").write(html)
    print(f"wrote {PAGE} ({len(html) // 1024} KB, map data {len(line) // 1024} KB)")

if __name__ == "__main__":
    main()
