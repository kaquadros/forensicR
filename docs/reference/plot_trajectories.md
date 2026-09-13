# Plot trajectories in plan or elevation view with uncertainty

Plan view: bird's-eye XY with each trajectory drawn back from its defect
by `back` units; faint lines are Monte Carlo draws and show the cone of
uncertainty. Elevation view: height against horizontal distance back
from the defect, one panel per trajectory, with assumed muzzle heights
dashed.

## Usage

``` r
plot_trajectories(
  trajectories,
  view = c("plan", "elevation"),
  back = 8,
  n_draw = 150,
  points = NULL,
  walls = NULL,
  furniture = NULL,
  furniture_alpha = NULL,
  convergence = FALSE,
  heights = c(standing = 1.5, kneeling = 1, prone = 0.3),
  units = "m"
)
```

## Arguments

  - trajectories:
    
    A `trajectory`, a `trajectory_path`, or a list of them. Path
    segments are drawn between their joints; assumed segments are dashed
    and run forward from the joint.

  - view:
    
    `"plan"` or `"elevation"`.

  - back:
    
    Distance to project back, scene units.

  - n\_draw:
    
    Number of Monte Carlo lines to draw.

  - points:
    
    Optional scene points tibble (from `coords_*()`) to overlay in plan
    view.

  - walls:
    
    Optional wall/door/window polylines for plan view; see `room_rect()`
    and `opening()`.

  - furniture:
    
    Optional `furniture` tibble drawn in plan view.

  - furniture\_alpha:
    
    Optional opacity overriding every object's own.

  - convergence:
    
    Plan view only. `TRUE` computes `intersect_trajectories()` for every
    pair and draws the Monte Carlo cloud of closest-approach points
    (only draws lying behind both defects) with the central estimate
    marked. Alternatively pass one result of `intersect_trajectories()`
    or a list of them. `FALSE` draws nothing.

  - heights:
    
    Muzzle heights to mark in elevation view.

  - units:
    
    Axis unit label.

## Value

A ggplot object.
