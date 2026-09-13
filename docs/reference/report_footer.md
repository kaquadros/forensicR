# Provenance footer for generated reports

Returns a single short sentence stating that the document was generated
with forensicR, including the package version, R version and timestamp.
Every report template appends this line at the bottom; it is
deliberately small so it does not compete with the report content or the
agency header.

## Usage

``` r
report_footer(time = Sys.time(), tz = "")
```

## Arguments

  - time:
    
    POSIXct. Timestamp to print. Defaults to `Sys.time()`.

  - tz:
    
    Character. Time zone for the printed timestamp. Defaults to the
    session time zone.

## Value

A length-one character vector.

## Examples

``` r
report_footer()
#> [1] "Report generated with forensicR 0.0.1 (R 4.4.1) on 2026-09-13 16:10 EDT."
```
