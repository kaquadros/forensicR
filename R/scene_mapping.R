#' Convert baseline (rectangular coordinate) measurements to XY
#'
#' The baseline method fixes a reference line between two known points
#' (e.g. two wall corners). Each item is located by its distance *along*
#' the baseline from the origin and its perpendicular *offset* from the
#' line (positive to the left of the direction of travel).
#'
#' @param along Numeric. Distance along the baseline from the origin.
#' @param offset Numeric. Perpendicular distance from the baseline. Positive
#'   values are to the left when walking from the origin toward the end point.
#' @param origin Numeric length-2. XY of the baseline origin. Default `c(0, 0)`.
#' @param end Numeric length-2. XY of the baseline end point. Default `c(1, 0)`
#'   (baseline runs along the positive x-axis).
#' @param id Optional character vector of item labels.
#' @param z Optional numeric. Height above the floor of each item (e.g. a
#'   bullet defect in a wall). Default `NA`, i.e. floor level / not measured.
#' @param type Optional character. Item type used by the 3D renderers:
#'   `"evidence"` (default, numbered marker), `"defect"` (bullet defect,
#'   dark disc on the wall) or `"bloodstain"` (schematic red disc).
#' @return A tibble with columns `id`, `x`, `y`, `z`, `type`, `method`.
#' @examples
#' coords_baseline(along = c(2.4, 5.1), offset = c(1.2, -0.8), id = c("A1", "A2"))
#' @export
coords_baseline <- function(along, offset, origin = c(0, 0), end = c(1, 0),
                            id = NULL, z = NA_real_, type = "evidence") {
  r <- recycle2(along, offset, "along", "offset"); along <- r[[1]]; offset <- r[[2]]
  stopifnot(length(origin) == 2, length(end) == 2)
  d <- end - origin
  len <- sqrt(sum(d^2))
  if (len == 0) cli::cli_abort("`origin` and `end` must differ.")
  u <- d / len                 # unit vector along the baseline
  n <- c(-u[2], u[1])          # left-hand normal
  x <- origin[1] + along * u[1] + offset * n[1]
  y <- origin[2] + along * u[2] + offset * n[2]
  new_scene_points(id, x, y, "baseline", z, type)
}

#' Convert triangulation measurements to XY
#'
#' Locates each item from its distances to two fixed reference points.
#' Two mirror-image solutions exist; `side` picks the one to the left
#' (`"left"`, default) or right of the line from `p1` to `p2`.
#'
#' @param d1,d2 Numeric. Distances from the item to reference points `p1`, `p2`.
#' @param p1,p2 Numeric length-2. XY of the two reference points.
#' @param side `"left"` or `"right"` of the directed line `p1 -> p2`.
#' @param id Optional character vector of item labels.
#' @inheritParams coords_baseline
#' @return A tibble with columns `id`, `x`, `y`, `z`, `type`, `method`. Rows
#'   whose distances cannot meet (no triangle) get `NA` coordinates with a
#'   warning.
#' @examples
#' coords_triangulation(d1 = 3, d2 = 4, p1 = c(0, 0), p2 = c(5, 0))
#' @export
coords_triangulation <- function(d1, d2, p1, p2, side = c("left", "right"),
                                 id = NULL, z = NA_real_, type = "evidence") {
  side <- match.arg(side)
  r <- recycle2(d1, d2, "d1", "d2"); d1 <- r[[1]]; d2 <- r[[2]]
  stopifnot(length(p1) == 2, length(p2) == 2)
  d <- p2 - p1
  base <- sqrt(sum(d^2))
  if (base == 0) cli::cli_abort("`p1` and `p2` must differ.")
  u <- d / base
  n <- c(-u[2], u[1]) * if (side == "left") 1 else -1
  a <- (d1^2 - d2^2 + base^2) / (2 * base)   # distance from p1 along the base
  h2 <- d1^2 - a^2
  bad <- h2 < 0
  if (any(bad)) {
    cli::cli_warn("{sum(bad)} item{?s} cannot be located: distances do not form a triangle.")
    h2[bad] <- NA_real_
  }
  h <- sqrt(h2)
  x <- p1[1] + a * u[1] + h * n[1]
  y <- p1[2] + a * u[2] + h * n[2]
  new_scene_points(id, x, y, "triangulation", z, type)
}

#' Convert polar (azimuth/distance) measurements to XY
#'
#' For total-station or compass-and-tape work. Azimuths follow the survey
#' convention: degrees clockwise from north (north = 0, east = 90).
#'
#' @param distance Numeric. Horizontal distance from the station.
#' @param azimuth Numeric. Degrees clockwise from north.
#' @param station Numeric length-2. XY of the instrument. Default `c(0, 0)`.
#' @param id Optional character vector of item labels.
#' @inheritParams coords_baseline
#' @return A tibble with columns `id`, `x`, `y`, `z`, `type`, `method`.
#' @examples
#' coords_polar(distance = 10, azimuth = 90)   # 10 units due east
#' @export
coords_polar <- function(distance, azimuth, station = c(0, 0), id = NULL,
                         z = NA_real_, type = "evidence") {
  r <- recycle2(distance, azimuth, "distance", "azimuth")
  distance <- r[[1]]; azimuth <- r[[2]]
  stopifnot(length(station) == 2)
  theta <- azimuth * pi / 180
  x <- station[1] + distance * sin(theta)
  y <- station[2] + distance * cos(theta)
  new_scene_points(id, x, y, "polar", z, type)
}

#' Plot scene points as a simple sketch
#'
#' @param points A tibble from one of the `coords_*()` functions, or several
#'   of them row-bound together.
#' @param units Character. Axis unit label, e.g. `"m"` or `"ft"`.
#' @param walls Optional tibble of wall/door/window polylines with columns
#'   `x`, `y`, `group` and `type`; see [room_rect()] and [opening()].
#' @param furniture Optional `furniture` tibble; see [furniture()].
#' @param furniture_alpha Optional opacity overriding every object's own.
#' @return A ggplot object.
#' @export
plot_scene <- function(points, units = "m", walls = NULL, furniture = NULL,
                       furniture_alpha = NULL) {
  stopifnot(all(c("id", "x", "y") %in% names(points)))
  ggplot2::ggplot(points, ggplot2::aes(x = .data$x, y = .data$y)) +
    walls_layer(walls) +
    furniture_layers(furniture, furniture_alpha) +
    ggplot2::geom_point(size = 2) +
    ggplot2::geom_text(ggplot2::aes(label = .data$id), vjust = -0.8, size = 3) +
    ggplot2::coord_equal() +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = 0.12)) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = 0.08)) +
    ggplot2::labs(x = paste0("x (", units, ")"), y = paste0("y (", units, ")")) +
    ggplot2::theme_minimal()
}

new_scene_points <- function(id, x, y, method, z = NA_real_, type = "evidence") {
  n <- length(x)
  if (is.null(id)) id <- sprintf("P%02d", seq_len(n))
  stopifnot(length(id) == n)
  if (length(z) == 1L) z <- rep(z, n)
  if (length(type) == 1L) type <- rep(type, n)
  stopifnot(length(z) == n, length(type) == n)
  type <- match.arg(type, c("evidence", "defect", "bloodstain"), several.ok = TRUE)
  tibble::tibble(id = as.character(id), x = x, y = y, z = as.numeric(z),
                 type = type, method = method)
}

# Recycle length-1 arguments so `coords_polar(10, c(0, 90))` works.
recycle2 <- function(a, b, a_name, b_name) {
  if (length(a) == 1L && length(b) > 1L) a <- rep(a, length(b))
  if (length(b) == 1L && length(a) > 1L) b <- rep(b, length(a))
  if (length(a) != length(b)) {
    cli::cli_abort("{.arg {a_name}} and {.arg {b_name}} must have the same length (or length 1).")
  }
  list(a, b)
}
