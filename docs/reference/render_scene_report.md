# Render a scene report to Word, PDF and/or HTML

Renders an R Markdown scene report to one or more output formats. By
default all three formats are produced so the investigator can pick the
one their agency expects (Word for editing, PDF for submission, HTML for
quick review). Every output ends with `report_footer()`.

## Usage

``` r
render_scene_report(
  input = NULL,
  output_dir,
  formats = c("docx", "pdf", "html"),
  params = list(),
  quiet = TRUE
)
```

## Arguments

  - input:
    
    Path to an `.Rmd` file. Defaults to a fresh copy of the packaged
    `scene-report` template written to `output_dir` as
    `scene-report.Rmd` (overwritten on every run). To customise the
    template, copy it with `scene_report_skeleton()` under another name,
    edit it, and pass that path as `input`.

  - output\_dir:
    
    Directory to write outputs to. Created if missing. There is no
    default: choose the case folder explicitly, for example
    `"case-2026-000123"`.

  - formats:
    
    Character vector, any of `"docx"`, `"pdf"`, `"html"`.

  - params:
    
    Named list passed to the document as `params`. The packaged template
    understands: `case_id`, `agency`, `investigator`, `scene_date`,
    `units`, `narrative` (markdown text), `points` (tibble from the
    `coords_*()` functions), `shooting` (a list with optional `impact`,
    from `impact_angle()`, and `trajectory`, from `trajectory_2pt()`),
    `evidence` (an `evidence_log()`) and `death_scene` (a
    `death_scene_record()`). Sections whose object is missing print a
    placeholder line.

  - quiet:
    
    Logical. Suppress pandoc/knitr output.

## Value

Invisibly, a named character vector of output file paths.

## See also

`report_footer()`, `scene_report_skeleton()`
