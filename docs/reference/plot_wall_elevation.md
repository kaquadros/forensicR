# Elevation view of one wall

The standard companion to the plan view: the wall drawn face-on with the
position and height of everything on or near it (bullet defects, stains,
openings). Items are selected by their perpendicular distance to the
wall line; heights come from the `z` column of the points. Trajectory
anchors are added as defects, with a short arrow showing the projected
direction of flight *into* the wall.

## Usage

``` r
plot_wall_elevation(
  wall,
  points = NULL,
  trajectories = NULL,
  walls = NULL,
  tol = 0.15,
  height = 2.5,
  door_height = 2,
  window_sill = 0.9,
  window_head = 2.1,
  units = "m",
  title = NULL,
  furniture = NULL,
  tol_furniture = 0.35,
  furniture_alpha = NULL
)
```

## Arguments

  - wall:
    
    Numeric length-4 `c(x1, y1, x2, y2)`; the first point appears on the
    left. See `wall_from_room()`.

  - points:
    
    Optional scene points tibble with `z`.

  - trajectories:
    
    Optional `trajectory` or list of them.

  - walls:
    
    Optional walls tibble; door and window openings lying on this wall
    are drawn.

  - tol:
    
    Maximum perpendicular distance from the wall line for an item to be
    shown, scene units.

  - height:
    
    Wall (ceiling) height.

  - door\_height, window\_sill, window\_head:
    
    Heights used to draw openings.

  - units:
    
    Axis unit label.

  - title:
    
    Plot title. Default built from the wall end points.

  - furniture:
    
    Optional `furniture` tibble. Objects whose footprint comes within
    `tol_furniture` of the wall are drawn as semi-transparent boxes with
    their height.

  - tol\_furniture:
    
    Distance from the wall within which objects are shown.

  - furniture\_alpha:
    
    Optional opacity overriding every object's own.

## Value

A ggplot object.
