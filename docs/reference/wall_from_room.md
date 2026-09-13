# Wall segment of a rectangular room, ordered as seen from inside

Convenience for `plot_wall_elevation()`: returns the end points of one
side of a room built with `room_rect()`, ordered so that the first point
is on the viewer's *left* when standing inside the room facing that
wall.

## Usage

``` r
wall_from_room(walls, side = c("north", "south", "east", "west"), id = "room")
```

## Arguments

  - walls:
    
    A tibble from `room_rect()` (optionally with openings bound).

  - side:
    
    `"north"`, `"south"`, `"east"` or `"west"`.

  - id:
    
    Group id of the room rectangle in `walls`. Default `"room"`.

## Value

Numeric length-4 `c(x1, y1, x2, y2)`.
