# Structured death scene observation record

Captures what a crime scene investigator documents at a death scene. It
records observations only; it makes **no** estimate of time since death,
which is the medical examiner's or coroner's determination.

## Usage

``` r
death_scene_record(
  rigor = "not assessed",
  livor = "not assessed",
  livor_position = NA_character_,
  decomposition = NA_character_,
  insects = NA_character_,
  ambient_temp_c = NA_real_,
  environment = NA_character_,
  clothing = NA_character_,
  body_position = NA_character_,
  observed_at = Sys.time(),
  observed_by = NA_character_,
  notes = NA_character_
)
```

## Arguments

  - rigor:
    
    One of `"absent"`, `"developing"`, `"complete"`, `"resolving"`,
    `"not assessed"`.

  - livor:
    
    One of `"absent"`, `"unfixed"`, `"fixed"`, `"not assessed"`.

  - livor\_position:
    
    Character. Where livor is present and whether it is consistent with
    the body position found (free text).

  - decomposition:
    
    Character. Free text or agency scale.

  - insects:
    
    Character. Presence/type observed, if any.

  - ambient\_temp\_c:
    
    Numeric. Ambient temperature at the body, Celsius.

  - environment:
    
    Character. Indoor/outdoor, HVAC state, windows, sun exposure, etc.

  - clothing:
    
    Character.

  - body\_position:
    
    Character.

  - observed\_at:
    
    POSIXct. When the observations were made.

  - observed\_by:
    
    Character.

  - notes:
    
    Character.

## Value

A one-row tibble of class `death_scene_record`.
