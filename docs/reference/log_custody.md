# Record a custody event

Record a custody event

## Usage

``` r
log_custody(
  log,
  item_id,
  event,
  from = NA_character_,
  to = NA_character_,
  at = Sys.time(),
  notes = NA_character_
)
```

## Arguments

  - log:
    
    An `evidence_log`.

  - item\_id:
    
    Character. Must already exist in `log$items`, except for the initial
    `"collected"` event written by `log_item()`.

  - event:
    
    Character. E.g. `"collected"`, `"transferred"`, `"sealed"`,
    `"submitted to lab"`.

  - from, to:
    
    Character. Custodians.

  - at:
    
    POSIXct. Defaults to now.

  - notes:
    
    Character (optional).

## Value

The updated `evidence_log`.
