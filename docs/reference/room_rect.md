# Build a rectangular room outline for scene plots

Returns a closed polyline in the format accepted by the `walls` argument
of `plot_scene()` and `plot_trajectories()`: columns `x`, `y`, `group`
and `type`. Combine several with `rbind()` and add openings with
`opening()`.

## Usage

``` r
room_rect(x0, y0, width, depth, id = "room")
```

## Arguments

  - x0, y0:
    
    Coordinates of the south-west corner.

  - width, depth:
    
    Extent along x (east) and y (north).

  - id:
    
    Group label.

## Value

A tibble with columns `x`, `y`, `group`, `type`.

## Examples

``` r
walls <- rbind(room_rect(0, 0, 6, 5),
               opening(2.5, 0, 3.5, 0, type = "door"))
```
