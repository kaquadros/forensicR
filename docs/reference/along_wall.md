# Place an object against a wall, as it is measured in the field

Position is given as the distance `from` the wall's left end (as seen
from inside the room, see `wall_from_room()`) to the object's left edge,
its `length` along the wall and its `depth` into the room.

## Usage

``` r
along_wall(walls, side, from, length, depth, id, type, ..., room_id = "room")
```

## Arguments

  - walls:
    
    Walls tibble from `room_rect()`.

  - side:
    
    `"north"`, `"south"`, `"east"` or `"west"`.

  - from:
    
    Distance from the left end of the wall to the object's left edge.

  - length:
    
    Extent along the wall.

  - depth:
    
    Extent into the room.

  - id, type:
    
    Passed to `furniture()`.

  - ...:
    
    Further arguments to `furniture()` (`height`, `colour`, ...).

  - room\_id:
    
    Group id of the room rectangle in `walls`.

## Value

A one-row `furniture` tibble.

## Examples

``` r
walls <- room_rect(0, 0, 6, 5)
along_wall(walls, "north", from = 0.5, length = 2.1, depth = 0.9, id = "Sofa", type = "sofa")
#> # A tibble: 1 × 15
#>   id    type      x     y width depth height    z0 angle shape colour  alpha
#>   <chr> <chr> <dbl> <dbl> <dbl> <dbl>  <dbl> <dbl> <dbl> <chr> <chr>   <dbl>
#> 1 Sofa  sofa    2.6     5   2.1   0.9   0.85     0   180 rect  #5b8def  0.45
#> # ℹ 3 more variables: measured <lgl>, steps <int>, notes <chr>
```
