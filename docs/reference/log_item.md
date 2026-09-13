# Add an evidence item to a log

Any photo files supplied are hashed with SHA-256 at logging time so the
report can show that the images referenced are the ones collected.

## Usage

``` r
log_item(
  log,
  item_id,
  description,
  location = NA_character_,
  collected_by = NA_character_,
  collected_at = Sys.time(),
  packaging = NA_character_,
  photos = character(),
  notes = NA_character_
)
```

## Arguments

  - log:
    
    An `evidence_log`.

  - item\_id:
    
    Character. Unique item label (e.g. `"1"`, `"A-3"`).

  - description:
    
    Character.

  - location:
    
    Character. Where found; ideally a scene point id.

  - collected\_by:
    
    Character.

  - collected\_at:
    
    POSIXct. Defaults to now.

  - packaging:
    
    Character. E.g. `"paper bag, sealed, initialed"`.

  - photos:
    
    Character vector of image paths (optional).

  - notes:
    
    Character (optional).

## Value

The updated `evidence_log`.
