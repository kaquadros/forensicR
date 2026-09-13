# Convert polar (azimuth/distance) measurements to XY

For total-station or compass-and-tape work. Azimuths follow the survey
convention: degrees clockwise from north (north = 0, east = 90).

## Usage

``` r
coords_polar(
  distance,
  azimuth,
  station = c(0, 0),
  id = NULL,
  z = NA_real_,
  type = "evidence"
)
```

## Arguments

  - distance:
    
    Numeric. Horizontal distance from the station.

  - azimuth:
    
    Numeric. Degrees clockwise from north.

  - station:
    
    Numeric length-2. XY of the instrument. Default `c(0, 0)`.

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
coords_polar(distance = 10, azimuth = 90)   # 10 units due east
#> # A tibble: 1 × 6
#>   id        x        y     z type     method
#>   <chr> <dbl>    <dbl> <dbl> <chr>    <chr> 
#> 1 P01      10 6.12e-16    NA evidence polar 
```
