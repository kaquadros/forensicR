# Render a 3D reconstruction of the scene (rayrender)

Builds a schematic, to-scale 3D model of the room from the same objects
used by the 2D plots and renders it with 'rayrender': walls with door
and window panels, a floor grid with numbered x/y axes, numbered
evidence markers, bullet defects at their measured height, schematic
bloodstain discs, trajectories as rods and their angular uncertainty as
translucent cones. Deliberately schematic: courtroom demonstratives must
be accurate and non-prejudicial, so nothing is rendered
photo-realistically.

## Usage

``` r
render_scene_3d(
  walls,
  points = NULL,
  trajectories = NULL,
  furniture = NULL,
  furniture_alpha = NULL,
  file = "scene3d.png",
  view = c("door", "corner", "overhead", "dollhouse"),
  lookfrom = NULL,
  lookat = NULL,
  fov = NULL,
  wall_height = 2.5,
  back = 3,
  cone = TRUE,
  grid = 1,
  grid_on = c("floor", "walls"),
  grid_strength = 0.6,
  grid_labels = TRUE,
  omit_wall = NULL,
  width = 1000,
  height = 750,
  samples = 128,
  ...
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

  - file:
    
    Output PNG path.

  - view:
    
    Camera preset: `"door"` (inside, at the door, eye level),
    `"corner"`, `"overhead"`, or `"dollhouse"` (from outside, south wall
    removed). Ignored if `lookfrom` is given.

  - lookfrom, lookat:
    
    Optional explicit camera position and target in scene coordinates
    `c(x, y, z)`.

  - fov:
    
    Field of view in degrees. Default depends on `view`.

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

  - omit\_wall:
    
    Optional side (`"north"`, `"south"`, `"east"`, `"west"`) to leave
    out so an outside camera can see in.

  - width, height, samples:
    
    Passed to `rayrender::render_scene()`.

  - ...:
    
    Further arguments to `rayrender::render_scene()`.

## Value

The output file path, invisibly.
