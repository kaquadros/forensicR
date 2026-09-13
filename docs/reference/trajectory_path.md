# Build a segmented trajectory through intermediate targets

Segments are ordered from the shooter's side to the terminal defect.
Each segment is a `trajectory` whose anchor is the defect at the *end*
of that segment (the entry into the intermediate target for segment 1,
the terminal defect for the last). Joints are the exit points from each
intermediate target; when a following segment was measured by two points
its first point is used as the joint automatically, otherwise the
previous segment's anchor is used (thin-target approximation, reported
as such).

## Usage

``` r
trajectory_path(..., joints = NULL, id = "P1")
```

## Arguments

  - ...:
    
    `trajectory` objects in order, or a single list of them.

  - joints:
    
    Optional list of `c(x, y, z)` exit points, one per joint
    (`length(segments) - 1`). `NULL` entries fall back to the defaults.

  - id:
    
    Path label.

## Value

An object of class `trajectory_path`.

## Examples

``` r
s1 <- trajectory_from_angles(c(4.0, 2.6, 0.5), 69, -30, id = "into table")
s2 <- trajectory_2pt(c(4.25, 3.1, 0.45), c(4.9, 5.0, 0.2), se_position = 0.01, id = "to wall")
p <- trajectory_path(s1, s2, id = "Shot 4")
p
#> 
#> ── Trajectory path Shot 4: 2 segments 
#> 1. into table (angles at defect): azimuth 69°, vertical -30°
#> 2. to wall (two points): azimuth 18.9°, vertical -7.1°
#> Joint 1 (first point of next segment): deflection 52.2° [43.6, 60.5]
path_deflections(p)
#> # A tibble: 1 × 13
#>   joint     x     y     z deflection_deg lower upper miss_in miss_in_upper
#>   <int> <dbl> <dbl> <dbl>          <dbl> <dbl> <dbl>   <dbl>         <dbl>
#> 1     1  4.25   3.1  0.45           52.2  43.7  60.7   0.411         0.464
#> # ℹ 4 more variables: miss_out <dbl>, miss_out_upper <dbl>, assumed <lgl>,
#> #   joint_source <chr>
```
