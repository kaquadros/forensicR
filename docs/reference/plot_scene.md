# Plot scene points as a simple sketch

Plot scene points as a simple sketch

## Usage

``` r
plot_scene(
  points,
  units = "m",
  walls = NULL,
  furniture = NULL,
  furniture_alpha = NULL
)
```

## Arguments

  - points:
    
    A tibble from one of the `coords_*()` functions, or several of them
    row-bound together.

  - units:
    
    Character. Axis unit label, e.g. `"m"` or `"ft"`.

  - walls:
    
    Optional tibble of wall/door/window polylines with columns `x`, `y`,
    `group` and `type`; see `room_rect()` and `opening()`.

  - furniture:
    
    Optional `furniture` tibble; see `furniture()`.

  - furniture\_alpha:
    
    Optional opacity overriding every object's own.

## Value

A ggplot object.
