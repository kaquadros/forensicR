# Trajectory from a single defect's ellipse on a vertical surface

Combines the impact angle from the ellipse (`impact_angle()`) with the
orientation of the ellipse's major axis on the surface and a
directionality indicator (lead-in mark, pinch point, or exit beveling)
to obtain a full 3D trajectory. Use only when a rod cannot be placed.

## Usage

``` r
trajectory_from_defect(
  anchor,
  width,
  length,
  major_axis_deg,
  wall_azimuth_deg,
  came_from = c("above", "below", "left", "right"),
  se = 0.5,
  se_orientation = 5,
  id = "T1"
)
```

## Arguments

  - anchor:
    
    Numeric length-3 `c(x, y, z)` of the defect.

  - width, length:
    
    Ellipse axes.

  - major\_axis\_deg:
    
    Orientation of the major axis on the surface as seen by an observer
    on the shooter's side facing the wall: 0 = vertical, 90 =
    horizontal, measured clockwise from 12 o'clock (range 0 to 180).

  - wall\_azimuth\_deg:
    
    Azimuth of the wall's outward normal, i.e. the direction the wall
    *faces* (toward the shooter), degrees clockwise from north. A wall
    on the north side of a room faces south: 180.

  - came\_from:
    
    Which end of the major axis the bullet came from, as seen by that
    observer: `"above"`, `"below"`, `"left"` or `"right"`.

  - se:
    
    Measurement SE of the ellipse axes.

  - se\_orientation:
    
    SE of `major_axis_deg`, degrees.

  - id:
    
    Character label.

## Value

An object of class `trajectory`.

## Examples

``` r
# North wall, bullet came from above-right, 30 deg to the surface
trajectory_from_defect(c(2, 5, 1.4), width = 6, length = 12,
                       major_axis_deg = 45, wall_azimuth_deg = 180,
                       came_from = "above")
#> 
#> ── Trajectory T1 (defect ellipse) 
#> Anchor (x, y, z): 2, 5, 1.4
#> Flight azimuth: 309.2° ± 4.3° (clockwise from north)
#> Vertical angle: -37.8° ± 4.2° (downward flight)
```
