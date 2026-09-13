# Interactive 3D scene widget (rgl / WebGL)

Same schematic model as `render_scene_3d()`, as an interactive widget
the reader can rotate, zoom and walk around in an HTML report. Walls are
semi-transparent so the inside stays visible from any angle.

## Usage

``` r
scene_3d_widget(
  walls,
  points = NULL,
  trajectories = NULL,
  furniture = NULL,
  furniture_alpha = NULL,
  wall_height = 2.5,
  back = 3,
  cone = TRUE,
  grid = 1,
  grid_on = c("floor", "walls"),
  grid_strength = 0.6,
  grid_labels = TRUE,
  wall_alpha = 0.35,
  n_cone = 24,
  width = 800,
  height = 600
)
```

## Arguments

  - walls:
    
    Walls tibble; see `room_rect()` and `opening()`.

  - points:
    
    Optional scene points tibble (`z` and `type` used).

  - trajectories:
    
    Optional `trajectory` or list of them.

  - furniture:
    
    Optional `furniture` tibble; see `furniture()`. Objects are drawn as
    semi-transparent boxes (or cylinders) with a label on top.

  - furniture\_alpha:
    
    Optional opacity overriding every object's own.

  - wall\_height:
    
    Ceiling height.

  - back:
    
    Length of trajectory rods behind the defect.

  - cone:
    
    Logical. Draw the uncertainty cone for each trajectory.

  - grid:
    
    Grid spacing, scene units. `0` disables all grid lines.

  - grid\_on:
    
    Where to draw grid lines: any of `"floor"` and `"walls"` (wall grids
    carry the z axis: verticals at each x/y tick and horizontals at each
    height tick). Use `"none"` for no lines but keep labels.

  - grid\_strength:
    
    Number in 0 to 1 controlling how strongly grid lines stand out (line
    darkness and thickness). Wall lines are always drawn fainter than
    floor lines.

  - grid\_labels:
    
    Logical. Draw the numbers: x/y along the floor edges and z at the
    start of each wall's horizontal grid line.

  - wall\_alpha:
    
    Wall transparency (0 to 1).

  - n\_cone:
    
    Number of lines used to sketch each uncertainty cone.

  - width, height:
    
    Widget size in pixels.

## Value

An `rglwidget` htmlwidget.
