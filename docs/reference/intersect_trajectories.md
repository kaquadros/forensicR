# Convergence of two trajectories

Finds the closest points between two back-projected trajectories. If the
shots came from one position, the lines should pass close to each other
*behind* both defects. The miss distance relative to its Monte Carlo
spread tells you whether a common origin is supported; the midpoint
estimates that origin.

## Usage

``` r
intersect_trajectories(t1, t2, n_sim = 5000, level = 0.95)
```

## Arguments

  - t1, t2:
    
    `trajectory` objects.

  - n\_sim:
    
    Monte Carlo draws.

  - level:
    
    Interval level.

## Value

A list with `point` (midpoint of closest approach, central estimate),
`miss_distance` (central), `behind_both` (logical, central estimate lies
behind both defects), `summary` (tibble of Monte Carlo quantiles for x,
y, z and miss distance, plus `p_behind_both`) and `samples` (tibble of
per-draw results).
