# Trajectory through two points on the bullet path

Two defects (entry and exit of a wall, or defects in two surfaces), or a
defect and a probe tip. Positional uncertainty in each coordinate is
propagated to the direction.

## Usage

``` r
trajectory_2pt(p1, p2, se_position = 0, id = "T1")
```

## Arguments

  - p1, p2:
    
    Numeric length-3 `c(x, y, z)`. `p1` is closer to the shooter, `p2`
    further along the flight. The trajectory is anchored at `p2` (the
    impact); `p1` is kept as `$p1` and becomes the joint when the object
    is used as a later segment of a `trajectory_path()`.

  - se\_position:
    
    Standard error of each coordinate, scene units.

  - id:
    
    Character label.

## Value

An object of class `trajectory` with extra elements `length` (distance
between the two points) and `p1`.

## Examples

``` r
t <- trajectory_2pt(c(0, 0, 1.2), c(0, 2, 1.0), se_position = 0.01)
t$vertical_deg
#> [1] -5.710593
```
