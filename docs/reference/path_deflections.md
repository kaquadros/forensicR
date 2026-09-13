# Deflection angles and joint consistency of a path

Deflection angles and joint consistency of a path

## Usage

``` r
path_deflections(path, n_sim = 5000, level = 0.95)
```

## Arguments

  - path:
    
    A `trajectory_path`.

  - n\_sim:
    
    Monte Carlo draws.

  - level:
    
    Interval level.

## Value

A tibble with one row per joint: `joint`, `x`, `y`, `z`,
`deflection_deg` with `lower`/`upper`, `miss_in` (distance from the
joint to the incoming segment's line, median and interval) and
`miss_out` (same for the outgoing segment, back-projected). Large misses
relative to the measurement uncertainty mean the documented segments do
not meet at the joint. `assumed` flags joints whose outgoing segment is
an assumption.
