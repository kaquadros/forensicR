# Create an empty evidence log

An evidence log is a list of two tibbles: `items` (one row per evidence
item) and `custody` (one row per custody event). It is deliberately a
plain R object, not a database: it lives in the report's project folder
and travels with the case file.

## Usage

``` r
evidence_log(case_id, agency = NA_character_)
```

## Arguments

  - case\_id:
    
    Character. Agency case number.

  - agency:
    
    Character. Agency name.

## Value

An object of class `evidence_log`.

## Examples

``` r
log <- evidence_log("2026-001234", "Lawrence Police Department")
```
