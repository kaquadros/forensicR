# Convert triangulation measurements to XY

Locates each item from its distances to two fixed reference points. Two
mirror-image solutions exist; `side` picks the one to the left
(`"left"`, default) or right of the line from `p1` to `p2`.

## Usage

``` r
coords_triangulation(
  d1,
  d2,
  p1,
  p2,
  side = c("left", "right"),
  id = NULL,
  z = NA_real_,
  type = "evidence"
)
```

## Arguments

  - d1, d2:
    
    Numeric. Distances from the item to reference points `p1`, `p2`.

  - p1, p2:
    
    Numeric length-2. XY of the two reference points.

  - side:
    
    `"left"` or `"right"` of the directed line `p1 -> p2`.

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

A tibble with columns `id`, `x`, `y`, `z`, `type`, `method`. Rows whose
distances cannot meet (no triangle) get `NA` coordinates with a warning.

## Examples

``` r
coords_triangulation(d1 = 3, d2 = 4, p1 = c(0, 0), p2 = c(5, 0))
#> # A tibble: 1 × 6
#>   id        x     y     z type     method       
#>   <chr> <dbl> <dbl> <dbl> <chr>    <chr>        
#> 1 P01     1.8   2.4    NA evidence triangulation
```
