#' Provenance footer for generated reports
#'
#' Returns a single short sentence stating that the document was generated
#' with forensicR, including the package version, R version and timestamp.
#' Every report template appends this line at the bottom; it is deliberately
#' small so it does not compete with the report content or the agency header.
#'
#' @param time POSIXct. Timestamp to print. Defaults to `Sys.time()`.
#' @param tz Character. Time zone for the printed timestamp. Defaults to the
#'   session time zone.
#' @return A length-one character vector.
#' @examples
#' report_footer()
#' @export
report_footer <- function(time = Sys.time(), tz = "") {
  stopifnot(inherits(time, "POSIXt"))
  sprintf(
    "Report generated with forensicR %s (R %s.%s) on %s.",
    as.character(utils::packageVersion("forensicR")),
    R.version$major, R.version$minor,
    format(time, "%Y-%m-%d %H:%M %Z", tz = tz)
  )
}

#' Render a scene report to Word, PDF and/or HTML
#'
#' Renders an R Markdown scene report to one or more output formats. By
#' default all three formats are produced so the investigator can pick the
#' one their agency expects (Word for editing, PDF for submission, HTML for
#' quick review). Every output ends with [report_footer()].
#'
#' @param input Path to an `.Rmd` file. Defaults to a fresh copy of the
#'   packaged `scene-report` template written to `output_dir` as
#'   `scene-report.Rmd` (overwritten on every run). To customise the
#'   template, copy it with [scene_report_skeleton()] under another name,
#'   edit it, and pass that path as `input`.
#' @param output_dir Directory to write outputs to. Created if missing. There
#'   is no default: choose the case folder explicitly, for example
#'   `"case-2026-000123"`.
#' @param formats Character vector, any of `"docx"`, `"pdf"`, `"html"`.
#' @param params Named list passed to the document as `params`. The packaged
#'   template understands: `case_id`, `agency`, `investigator`, `scene_date`,
#'   `units`, `narrative` (markdown text), `points` (tibble from the
#'   `coords_*()` functions), `shooting` (a list with optional `impact`, from
#'   [impact_angle()], and `trajectory`, from [trajectory_2pt()]), `evidence`
#'   (an [evidence_log()]) and `death_scene` (a [death_scene_record()]).
#'   Sections whose object is missing print a placeholder line.
#' @param quiet Logical. Suppress pandoc/knitr output.
#' @return Invisibly, a named character vector of output file paths.
#' @seealso [report_footer()], [scene_report_skeleton()]
#' @export
render_scene_report <- function(input = NULL,
                                output_dir,
                                formats = c("docx", "pdf", "html"),
                                params = list(),
                                quiet = TRUE) {
  if (missing(output_dir)) {
    cli::cli_abort("{.arg output_dir} must be given; the report is never written to the working directory by default.")
  }
  formats <- match.arg(formats, c("docx", "pdf", "html"), several.ok = TRUE)
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  if (is.null(input)) {
    # Managed copy of the packaged template: always refreshed so re-running
    # a script picks up template updates. Pass `input` to use your own edits.
    input <- scene_report_skeleton(file.path(output_dir, "scene-report.Rmd"),
                                   overwrite = TRUE)
  }
  stopifnot(file.exists(input))

  fmt_map <- c(
    docx = "rmarkdown::word_document",
    pdf  = "rmarkdown::pdf_document",
    html = "rmarkdown::html_document"
  )
  out <- vapply(formats, function(f) {
    if (f == "pdf" && !rmarkdown::pandoc_available()) {
      cli::cli_warn("pandoc not available; skipping PDF.")
      return(NA_character_)
    }
    rmarkdown::render(
      input,
      output_format = fmt_map[[f]],
      output_dir = normalizePath(output_dir),
      params = params,
      quiet = quiet,
      envir = new.env(parent = globalenv())
    )
  }, character(1))
  cli::cli_alert_success("Rendered {length(out)} report file{?s} to {.path {output_dir}}.")
  invisible(out)
}

#' Copy the packaged scene report template
#'
#' @param path Destination path for the `.Rmd` file.
#' @param overwrite Logical. Overwrite an existing file?
#' @return The destination path, invisibly.
#' @export
scene_report_skeleton <- function(path = "scene-report.Rmd", overwrite = FALSE) {
  src <- system.file("rmarkdown", "templates", "scene-report", "skeleton",
                     "skeleton.Rmd", package = "forensicR")
  if (!nzchar(src)) cli::cli_abort("Template not found; reinstall forensicR.")
  if (file.exists(path) && !overwrite) {
    cli::cli_abort("{.path {path}} exists. Use {.code overwrite = TRUE}.")
  }
  file.copy(src, path, overwrite = overwrite)
  invisible(path)
}
