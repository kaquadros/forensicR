# Convert baseline (rectangular coordinate) measurements to XY

The baseline method fixes a reference line between two known points
(e.g. two wall corners). Each item is located by its distance *along*
the baseline from the origin and its perpendicular *offset* from the
line (positive to the left of the direction of travel).

## Usage

``` r
coords_baseline(
  along,
  offset,
  origin = c(0, 0),
  end = c(1, 0),
  id = NULL,
  z = NA_real_,
  type = "evidence"
)
```

## Arguments

  - along:
    
    Numeric. Distance along the baseline from the origin.

  - offset:
    
    Numeric. Perpendicular distance from the baseline. Positive values
    are to the left when walking from the origin toward the end point.

  - origin:
    
    Numeric length-2. XY of the baseline origin. Default `c(0, 0)`.

  - end:
    
    Numeric length-2. XY of the baseline end point. Default `c(1, 0)`
    (baseline runs along the positive x-axis).

  - id:
    
    Optional character vector of item labels.

  - z:
    
    Optional numeric. Height above the floor of each item (e.g. a bullet
    defect in a wall). Default `NA`, i.e. floor level / not measured.

  - type:
    
    Optional character. Item type used by the 3D renderers: `"evidence"`
    (default, numbered marker), `"defect"` (bullet defect, dark disc on
    the wall) or `"bloodstain"` (schematic red disc).

## Value

A tibble with columns `id`, `x`, `y`, `z`, `type`, `method`.

## Examples

``` r
coords_baseline(along = c(2.4, 5.1), offset = c(1.2, -0.8), id = c("A1", "A2"))
#> # A tibble: 2 × 6
#>   id        x     y     z type     method  
#>   <chr> <dbl> <dbl> <dbl> <chr>    <chr>   
#> 1 A1      2.4   1.2    NA evidence baseline
#> 2 A2      5.1  -0.8    NA evidence baseline
```
