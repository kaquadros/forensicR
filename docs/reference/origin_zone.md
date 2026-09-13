# Possible origin of fire at assumed muzzle heights

Projects a trajectory back until it reaches each assumed muzzle height
and reports the horizontal distance from the defect and the XY position,
with a Monte Carlo interval from the trajectory's angular uncertainty.
This is the standard way to bound where a shooter could have been: the
trajectory alone is a line; a plausible muzzle height turns it into a
position.

## Usage

``` r
origin_zone(
  trajectory,
  heights = c(standing = 1.5, kneeling = 1, prone = 0.3),
  max_distance = 50,
  furniture = NULL,
  n_sim = 5000,
  level = 0.95
)
```

## Arguments

  - trajectory:
    
    A `trajectory`, or a `trajectory_path` (its first segment, the one
    on the shooter's side, is used).

  - heights:
    
    Named numeric vector of muzzle heights, scene units.

  - max\_distance:
    
    Largest horizontal distance considered, scene units (e.g. the room
    or lot dimension). Near-horizontal draws otherwise project to absurd
    distances; anything beyond this limit counts as not reachable.

  - furniture:
    
    Optional `furniture` tibble. Draws whose origin falls inside an
    object are counted as not reachable (nobody fires from inside a
    wardrobe); the fraction excluded this way is returned as
    `p_in_furniture`.

  - n\_sim:
    
    Monte Carlo draws.

  - level:
    
    Interval level.

## Value

A tibble with one row per height: `position`, `height`,
`horizontal_distance` (median), `hd_lower`, `hd_upper`, `x`, `y`, and
`p_reachable`, the fraction of draws in which the back-projected line
reaches that height within `max_distance` (it cannot when, e.g., the
shot travelled upward and the height is above the defect). Quantiles are
computed over the reachable draws only, so read them together with
`p_reachable`.

## Details

The default heights are illustrative shoulder-level values for standing,
kneeling and prone shooters and must be replaced by case-specific
values.

## Examples

``` r
t <- trajectory_from_angles(c(4.8, 0, 1.35), 350, -8)
origin_zone(t)
#> # A tibble: 3 × 9
#>   position height horizontal_distance hd_lower hd_upper     x       y
#>   <chr>     <dbl>               <dbl>    <dbl>    <dbl> <dbl>   <dbl>
#> 1 standing    1.5                1.01    0.466     7.50  4.97  -0.995
#> 2 kneeling    1                  9.90    3.17     32.7   6.40  -9.85 
#> 3 prone       0.3               21.9     9.25     48.4   8.59 -21.4  
#> # ℹ 2 more variables: p_reachable <dbl>, p_in_furniture <dbl>
```
