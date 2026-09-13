# Which objects does a back-projected trajectory pass through?

Samples each trajectory backwards from its defect and reports the
distance intervals inside every object. A hit means the object is an
intermediate target or an obstruction that must be reconciled with the
evidence (a defect in it, or a bullet path that cannot be right).

## Usage

``` r
trajectory_obstructions(trajectories, f, back = 6, step = 0.01)
```

## Arguments

  - trajectories:
    
    A `trajectory` or list of them.

  - f:
    
    A `furniture` tibble.

  - back:
    
    Distance to trace back from the defect.

  - step:
    
    Sampling step along the line.

## Value

A tibble with `trajectory`, `object`, `from`, `to` (distances back from
the defect) and `top_height`. Zero rows if nothing is hit.
