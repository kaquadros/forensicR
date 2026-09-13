#' Create an empty evidence log
#'
#' An evidence log is a list of two tibbles: `items` (one row per evidence
#' item) and `custody` (one row per custody event). It is deliberately a
#' plain R object, not a database: it lives in the report's project folder
#' and travels with the case file.
#'
#' @param case_id Character. Agency case number.
#' @param agency Character. Agency name.
#' @return An object of class `evidence_log`.
#' @examples
#' log <- evidence_log("2026-001234", "Lawrence Police Department")
#' @export
evidence_log <- function(case_id, agency = NA_character_) {
  structure(list(
    case_id = case_id,
    agency = agency,
    items = tibble::tibble(
      item_id = character(), description = character(),
      location = character(), collected_by = character(),
      collected_at = as.POSIXct(character()), packaging = character(),
      photo_paths = list(), photo_sha256 = list(), notes = character()
    ),
    custody = tibble::tibble(
      item_id = character(), event = character(), from = character(),
      to = character(), at = as.POSIXct(character()), notes = character()
    )
  ), class = "evidence_log")
}

#' Add an evidence item to a log
#'
#' Any photo files supplied are hashed with SHA-256 at logging time so the
#' report can show that the images referenced are the ones collected.
#'
#' @param log An `evidence_log`.
#' @param item_id Character. Unique item label (e.g. `"1"`, `"A-3"`).
#' @param description Character.
#' @param location Character. Where found; ideally a scene point id.
#' @param collected_by Character.
#' @param collected_at POSIXct. Defaults to now.
#' @param packaging Character. E.g. `"paper bag, sealed, initialed"`.
#' @param photos Character vector of image paths (optional).
#' @param notes Character (optional).
#' @return The updated `evidence_log`.
#' @export
log_item <- function(log, item_id, description, location = NA_character_,
                     collected_by = NA_character_, collected_at = Sys.time(),
                     packaging = NA_character_, photos = character(),
                     notes = NA_character_) {
  stopifnot(inherits(log, "evidence_log"))
  if (item_id %in% log$items$item_id) {
    cli::cli_abort("Item {.val {item_id}} already exists in this log.")
  }
  hashes <- if (length(photos)) file_hash(photos) else character()
  log$items <- tibble::add_row(
    log$items,
    item_id = item_id, description = description, location = location,
    collected_by = collected_by, collected_at = collected_at,
    packaging = packaging, photo_paths = list(photos),
    photo_sha256 = list(hashes), notes = notes
  )
  log <- log_custody(log, item_id, "collected", from = "scene",
                     to = collected_by, at = collected_at)
  log
}

#' Record a custody event
#'
#' @param log An `evidence_log`.
#' @param item_id Character. Must already exist in `log$items`, except for
#'   the initial `"collected"` event written by [log_item()].
#' @param event Character. E.g. `"collected"`, `"transferred"`, `"sealed"`,
#'   `"submitted to lab"`.
#' @param from,to Character. Custodians.
#' @param at POSIXct. Defaults to now.
#' @param notes Character (optional).
#' @return The updated `evidence_log`.
#' @export
log_custody <- function(log, item_id, event, from = NA_character_,
                        to = NA_character_, at = Sys.time(),
                        notes = NA_character_) {
  stopifnot(inherits(log, "evidence_log"))
  if (!item_id %in% log$items$item_id) {
    cli::cli_abort("Unknown item {.val {item_id}}; add it with {.fn log_item} first.")
  }
  log$custody <- tibble::add_row(
    log$custody,
    item_id = item_id, event = event, from = from, to = to, at = at, notes = notes
  )
  log
}

#' SHA-256 hash of files
#'
#' @param paths Character vector of file paths.
#' @return Named character vector of hex digests.
#' @export
file_hash <- function(paths) {
  missing <- !file.exists(paths)
  if (any(missing)) cli::cli_abort("File{?s} not found: {.path {paths[missing]}}.")
  vapply(paths, function(p) digest::digest(p, algo = "sha256", file = TRUE),
         character(1))
}

#' Structured death scene observation record
#'
#' Captures what a crime scene investigator documents at a death scene.
#' It records observations only; it makes **no** estimate of time since
#' death, which is the medical examiner's or coroner's determination.
#'
#' @param rigor One of `"absent"`, `"developing"`, `"complete"`, `"resolving"`,
#'   `"not assessed"`.
#' @param livor One of `"absent"`, `"unfixed"`, `"fixed"`, `"not assessed"`.
#' @param livor_position Character. Where livor is present and whether it is
#'   consistent with the body position found (free text).
#' @param decomposition Character. Free text or agency scale.
#' @param insects Character. Presence/type observed, if any.
#' @param ambient_temp_c Numeric. Ambient temperature at the body, Celsius.
#' @param environment Character. Indoor/outdoor, HVAC state, windows, sun
#'   exposure, etc.
#' @param clothing Character.
#' @param body_position Character.
#' @param observed_at POSIXct. When the observations were made.
#' @param observed_by Character.
#' @param notes Character.
#' @return A one-row tibble of class `death_scene_record`.
#' @export
death_scene_record <- function(rigor = "not assessed",
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
                               notes = NA_character_) {
  rigor <- match.arg(rigor, c("not assessed", "absent", "developing",
                              "complete", "resolving"))
  livor <- match.arg(livor, c("not assessed", "absent", "unfixed", "fixed"))
  out <- tibble::tibble(
    rigor = rigor, livor = livor, livor_position = livor_position,
    decomposition = decomposition, insects = insects,
    ambient_temp_c = ambient_temp_c, environment = environment,
    clothing = clothing, body_position = body_position,
    observed_at = observed_at, observed_by = observed_by, notes = notes
  )
  class(out) <- c("death_scene_record", class(out))
  out
}

#' @export
print.evidence_log <- function(x, ...) {
  cli::cli_h2("Evidence log: case {x$case_id}")
  if (!is.na(x$agency)) cli::cli_text("Agency: {x$agency}")
  cli::cli_text("{nrow(x$items)} item{?s}, {nrow(x$custody)} custody event{?s}")
  invisible(x)
}
