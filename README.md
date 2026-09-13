# forensicR

Tools for crime scene investigators, built with one.

The core is **shooting incident reconstruction with explicit uncertainty**,
following the standard field workflow (Haag & Haag 2020; Hueske 2015; OSAC
2025-N-0003 terminology):

- impact angle from the defect ellipse, with a Monte Carlo interval;
- trajectories from rod/laser angles, from two points, or from a single
  defect's ellipse plus directionality;
- possible origin of fire at assumed muzzle heights, bounded by scene size;
- segmented paths through intermediate targets, with measured deflection
  angles and joint-consistency checks, or explicitly flagged assumed
  deflections when the path after the object was not documented;
- convergence of several trajectories (closest approach, miss distance,
  whether it lies behind both defects);
- plan and elevation plots showing the cone of uncertainty, not just a line.

Supporting modules:

- **Scene mapping**: baseline, triangulation and polar/total-station
  measurements to one XY frame (plus height `z`), plan view with room
  outline, and wall elevation views.
- **Scene objects**: furniture, appliances and persons as schematic boxes
  placed the way they are measured (against a wall, by a corner, by two
  corners), semi-transparent by default, drawn in every view; trajectories
  are checked for objects on their back-projected path.
- **3D reconstruction**: the same objects rendered as a schematic, to-scale
  room with numbered floor axes, evidence markers, bullet defects at height,
  trajectory rods and uncertainty cones. A rayrender still for PDF/Word, an
  interactive rgl widget for HTML (both optional dependencies).
- **Evidence documentation**: evidence items, chain of custody, photo hashes,
  and a structured death scene observation record (observations only; time
  since death is the coroner's determination).

Reports render to Word, PDF and HTML from one template, each ending with a
one-line note of the forensicR version that produced it.

## Installation

```r
# install.packages("pak")
pak::pak("allanvcq/forensicR")
```

## Quick start

```r
library(forensicR)

pts <- coords_baseline(along = c(2.4, 5.1), offset = c(1.2, -0.8), id = c("1", "2"))
plot_scene(pts)

impact_angle(width = 8, length = 16, se = 0.5)
t1 <- trajectory_from_angles(c(2.0, 5.0, 1.35), azimuth_deg = 352, vertical_deg = -3, id = "D2")
t2 <- trajectory_2pt(c(3.4, 4.2, 1.20), c(3.73, 4.92, 1.10), se_position = 0.01, id = "D3")
origin_zone(t1, heights = c(standing = 1.5), max_distance = 12)
intersect_trajectories(t1, t2)$point
plot_trajectories(list(t1, t2), view = "plan")

log <- evidence_log("2026-001234", "Lawrence Police Department")
log <- log_item(log, "1", "Cartridge case, 9 mm", location = "1", collected_by = "CSI")

render_scene_report(output_dir = "report")   # docx, pdf and html
```

## Status

Early development (0.0.1). Not yet validated for casework.
