# Trajectory from angles measured at the defect (rod, laser or protractor)

The most common field method: a trajectory rod or laser is placed
through the defect(s) and its vertical angle (angle finder /
inclinometer) and horizontal angle (protractor, or azimuth from a total
station) are recorded. Angular uncertainty of about 5 degrees is
commonly cited for rod-based work; adjust to what your method validation
supports.

## Usage

``` r
trajectory_from_angles(
  anchor,
  azimuth_deg,
  vertical_deg,
  se_azimuth = 5,
  se_vertical = 5,
  id = "T1"
)
```

## Arguments

  - anchor:
    
    Numeric length-3 `c(x, y, z)` of the defect in scene frame.

  - azimuth\_deg:
    
    Direction of *flight*, degrees clockwise from north.

  - vertical\_deg:
    
    Degrees above horizontal; negative = downward flight.

  - se\_azimuth, se\_vertical:
    
    Standard errors of the two angles, degrees.

  - id:
    
    Character label.

## Value

An object of class `trajectory`.

## Examples

``` r
t <- trajectory_from_angles(c(4.8, 0, 1.35), azimuth_deg = 350, vertical_deg = -8)
t
#> 
#> ── Trajectory T1 (angles at defect) 
#> Anchor (x, y, z): 4.8, 0, 1.35
#> Flight azimuth: 350° ± 5° (clockwise from north)
#> Vertical angle: -8° ± 5° (downward flight)
t$project(3)   # point 3 m back toward the shooter
#> [1]  5.315875 -2.925671  1.767519
```
