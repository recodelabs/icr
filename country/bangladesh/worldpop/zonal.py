# Sum WorldPop under-1 (f_00 + m_00) per polygon; a cell counts when its centre is inside.
import json, sys, csv
import numpy as np, rasterio
from rasterio.features import geometry_mask
from rasterio.windows import from_bounds
from shapely.geometry import shape

units_path, rasters_dir, out = sys.argv[1:4]
units = [json.loads(l) for l in open(units_path)]
rows = {u["id"]: {"location_id": u["id"], "name": u["name"], "admin_level": u["admin_level"]} for u in units}
for year in (2024, 2025, 2026):
    for sex in ("f", "m"):
        with rasterio.open(f"{rasters_dir}/bgd_{sex}_00_{year}_CN_100m_R2025A_v1.tif") as src:
            for u in units:
                g = u["gj"] if isinstance(u["gj"], dict) else json.loads(u["gj"])
                b = shape(g).bounds
                win = from_bounds(*b, transform=src.transform).round_offsets().round_lengths()
                win = win.intersection(rasterio.windows.Window(0, 0, src.width, src.height))
                a = src.read(1, window=win, masked=True)
                m = geometry_mask([g], out_shape=a.shape, transform=src.window_transform(win), invert=True)
                v = float(np.where(m & ~np.ma.getmaskarray(a), a.filled(0), 0).sum())
                k = f"wp_under1_{year}"
                rows[u["id"]][k] = rows[u["id"]].get(k, 0) + v
with open(out, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=["location_id", "name", "admin_level", "wp_under1_2024", "wp_under1_2025", "wp_under1_2026"])
    w.writeheader()
    for r in rows.values():
        w.writerow({k: (round(v, 1) if isinstance(v, float) else v) for k, v in r.items()})
