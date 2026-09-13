# Define a scene object (furniture, appliance, person)

Objects are rectangular or circular footprints with a height. Rectangles
are anchored at their south-west corner in their own frame and rotated
counter-clockwise by `angle` about that corner; circles are anchored at
their centre. Height, colour and label default from
`furniture_catalogue()` by `type`.

## Usage

``` r
furniture(
  id,
  type,
  x,
  y,
  width = NULL,
  depth = NULL,
  diameter = NULL,
  height = NULL,
  z0 = 0,
  angle = 0,
  shape = c("rect", "circle"),
  anchor = NULL,
  colour = NULL,
  alpha = 0.45,
  measured = TRUE,
  steps = NA_integer_,
  notes = NA_character_
)
```

## Arguments

  - id:
    
    Character. Unique label (e.g. `"Sofa"`, `"Table 1"`).

  - type:
    
    Character. A type from `furniture_catalogue()`, or any other string
    (then `height` is required).

  - x, y:
    
    Anchor position, scene units: south-west corner of a rectangle
    (before rotation) or the centre of a circle. See `anchor`.

  - width, depth:
    
    Rectangle extent along its own x and y axes.

  - diameter:
    
    Circle diameter (use with `shape = "circle"`).

  - height:
    
    Height above `z0`. Default from the catalogue.

  - z0:
    
    Height of the object's base (e.g. a shelf). Default 0.

  - angle:
    
    Rotation in degrees, counter-clockwise, about the anchor.

  - shape:
    
    `"rect"` or `"circle"`.

  - anchor:
    
    `"sw"` (default for rectangles) or `"center"`.

  - colour:
    
    Fill colour. Default from the catalogue.

  - alpha:
    
    Opacity 0 to 1 used in every view. Default `0.45`, so what is behind
    an object stays visible.

  - measured:
    
    Logical. Were the dimensions measured (TRUE) or estimated (FALSE)?
    Estimated objects are drawn with dashed outlines and flagged in the
    report table.

  - steps:
    
    For `type = "stairs"`: number of steps rising along the object's own
    x axis. The 3D view stacks them; obstruction checks use the stepped
    profile.

  - notes:
    
    Character.

## Value

A one-row tibble of class `furniture`. Combine several with `rbind()`.

## Examples

``` r
f <- rbind(
  furniture("Table", "table", x = 3, y = 2, width = 1.2, depth = 0.8, angle = 15),
  furniture("Stool", "chair", x = 1.5, y = 1.2, diameter = 0.4, shape = "circle")
)
```
