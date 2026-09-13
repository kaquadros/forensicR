# Segment with an assumed (not measured) deflection

For the case where the bullet demonstrably passed through an object but
its path after it was not documented. The segment continues the previous
direction from the joint with a cone of possible deflections of standard
deviation `se_deflection` (degrees, random orientation). The result is
an *assumption* and is flagged as such in tables, plots and reports.

## Usage

``` r
assumed_segment(
  previous,
  joint = NULL,
  length = 2,
  se_deflection = 10,
  id = "assumed"
)
```

## Arguments

  - previous:
    
    The `trajectory` this segment continues.

  - joint:
    
    Exit point `c(x, y, z)`. Default: the previous anchor.

  - length:
    
    Length of the assumed segment.

  - se\_deflection:
    
    Standard deviation of the deflection angle, degrees.

  - id:
    
    Label.

## Value

A `trajectory` with `assumed = TRUE` and a virtual anchor at `joint +
length * u`.
