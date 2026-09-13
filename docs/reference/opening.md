# A door or window segment for scene plots

A door or window segment for scene plots

## Usage

``` r
opening(x1, y1, x2, y2, type = c("door", "window"), id = NULL)
```

## Arguments

  - x1, y1, x2, y2:
    
    End points of the opening along a wall.

  - type:
    
    `"door"` or `"window"`.

  - id:
    
    Group label; defaults to a unique one.

## Value

A tibble with columns `x`, `y`, `group`, `type`.
