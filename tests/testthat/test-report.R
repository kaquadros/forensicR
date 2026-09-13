test_that("footer names the package version", {
  f <- report_footer(as.POSIXct("2026-09-06 10:00:00", tz = "UTC"), tz = "UTC")
  expect_match(f, "forensicR 0\\.0\\.1")
  expect_match(f, "2026-09-06 10:00 UTC")
})

test_that("scene report renders with real objects as params", {
  skip_if_not(rmarkdown::pandoc_available())
  skip_on_cran()
  d <- withr::local_tempdir()
  pts <- coords_baseline(c(1, 2), c(0.5, 1), id = c("1", "2"))
  log <- evidence_log("C-1", "PD")
  log <- log_item(log, "1", "Knife", collected_by = "CSI")
  out <- render_scene_report(
    output_dir = d, formats = c("html", "docx"),
    params = list(case_id = "C-1", points = pts, evidence = log,
                  shooting = list(impact = impact_angle(8, 16),
                                  trajectory = trajectory_2pt(c(0, 0, 1), c(0, 1, 0.9))),
                  death_scene = death_scene_record(rigor = "complete"))
  )
  expect_true(all(file.exists(out)))
  html <- paste(readLines(out[["html"]], warn = FALSE), collapse = "\n")
  expect_match(html, "Report generated with forensicR")
  expect_match(html, "Knife")
  expect_match(html, "Death scene observations")
  expect_match(html, "azimuth")
})

test_that("scene report renders with no objects", {
  skip_if_not(rmarkdown::pandoc_available())
  skip_on_cran()
  d <- withr::local_tempdir()
  out <- render_scene_report(output_dir = d, formats = "html")
  html <- paste(readLines(out, warn = FALSE), collapse = "\n")
  expect_match(html, "No evidence log supplied")
})

test_that("render_scene_report can be re-run into the same directory", {
  skip_if_not(rmarkdown::pandoc_available())
  skip_on_cran()
  d <- withr::local_tempdir()
  render_scene_report(output_dir = d, formats = "html")
  expect_no_error(render_scene_report(output_dir = d, formats = "html"))
})

test_that("render_scene_report refuses to run without an output directory", {
  expect_error(render_scene_report(formats = "html"), "output_dir")
})

test_that("scene_report_skeleton refuses to run without a path", {
  expect_error(scene_report_skeleton(), "path")
})
