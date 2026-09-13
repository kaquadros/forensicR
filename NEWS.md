# forensicR 0.0.1

Initial development version.

* Scene mapping: `coords_baseline()`, `coords_triangulation()`, `coords_polar()`,
  `plot_scene()`.
* Shooting reconstruction with uncertainty: `impact_angle()`,
  `trajectory_from_angles()`, `trajectory_2pt()`, `trajectory_from_defect()`,
  `origin_zone()`, `intersect_trajectories()`, `trajectory_table()`,
  `plot_trajectories()`.
* Scene points carry an optional height `z` and a `type` (evidence, defect,
  bloodstain). Wall elevation views: `wall_from_room()`, `plot_wall_elevation()`.
* Room outlines for plots: `room_rect()`, `opening()`; plan view can overlay
  the convergence cloud of trajectories.
* 3D reconstruction, schematic and to scale: `render_scene_3d()` (rayrender
  still image) and `scene_3d_widget()` (interactive rgl/WebGL widget); both
  optional dependencies.
* Segmented trajectories through intermediate targets: `trajectory_path()`,
  `path_deflections()` (measured deflection with Monte Carlo interval and
  joint consistency), `assumed_segment()` (explicitly flagged assumption).
  `trajectory_2pt()` is now anchored at its second point, the impact.
* Scene objects: `furniture()`, `along_wall()`, `furniture_from_corners()`,
  `furniture_catalogue()`, `furniture_table()`, `trajectory_obstructions()`.
  Objects are schematic, to-scale, semi-transparent boxes drawn in every
  view; `origin_zone()` can exclude positions inside objects.
* Evidence documentation: `evidence_log()`, `log_item()`, `log_custody()`,
  `file_hash()`, `death_scene_record()`.
* Four vignettes: getting started (one scene end to end), scene mapping,
  shooting reconstruction, reports and 3D.
* Reports: `render_scene_report()` renders one template to Word, PDF and HTML,
  each ending with a one-line provenance footer.
