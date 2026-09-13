# Impact angle from a bullet defect's ellipse

For a projectile striking a flat surface, the angle of impact relative
to the surface is approximated by `asin(width / length)` of the
resulting elliptical defect (90 degrees is perpendicular). The
relationship is reliable for non-yielding surfaces (drywall, wood, sheet
metal); it is unreliable for glass, thick fabric, or when the defect is
irregular. Near 90 degrees the estimate is inherently imprecise because
the ellipse is almost circular; the Monte Carlo interval reflects that.

## Usage

``` r
impact_angle(width, length, se = NULL, n_sim = 10000, level = 0.95)
```

## Arguments

  - width, length:
    
    Numeric. Minor and major axis of the defect, same units.

  - se:
    
    Optional numeric. Measurement standard error for both axes. If
    supplied, a Monte Carlo interval is added (`n_sim` draws).

  - n\_sim:
    
    Integer. Number of Monte Carlo draws.

  - level:
    
    Confidence level for the interval.

## Value

A tibble with `angle_deg` and, if `se` is supplied, `lower`, `upper` and
`level`.

## Examples

``` r
impact_angle(width = 8, length = 16)          # 30 degrees
#> # A tibble: 1 × 1
#>   angle_deg
#>       <dbl>
#> 1        30
impact_angle(width = 8, length = 16, se = 0.5)
#> # A tibble: 1 × 4
#>   angle_deg lower upper level
#>       <dbl> <dbl> <dbl> <dbl>
#> 1        30  25.8  34.8  0.95
```
