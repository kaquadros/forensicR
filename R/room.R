#' Build a rectangular room outline for scene plots
#'
#' Returns a closed polyline in the format accepted by the `walls` argument
#' of [plot_scene()] and [plot_trajectories()]: columns `x`, `y`, `group`
#' and `type`. Combine several with `rbind()` and add openings with
#' [opening()].
#'
#' @param x0,y0 Coordinates of the south-west corner.
#' @param width,depth Extent along x (east) and y (north).
#' @param id Group label.
#' @return A tibble with columns `x`, `y`, `group`, `type`.
#' @examples
#' walls <- rbind(room_rect(0, 0, 6, 5),
#'                opening(2.5, 0, 3.5, 0, type = "door"))
#' @export
room_rect <- function(x0, y0, width, depth, id = "room") {
  stopifnot(width > 0, depth > 0)
  tibble::tibble(
    x = c(x0, x0 + width, x0 + width, x0, x0),
    y = c(y0, y0, y0 + depth, y0 + depth, y0),
    group = id, type = "wall"
  )
}

#' A door or window segment for scene plots
#'
#' @param x1,y1,x2,y2 End points of the opening along a wall.
#' @param type `"door"` or `"window"`.
#' @param id Group label; defaults to a unique one.
#' @return A tibble with columns `x`, `y`, `group`, `type`.
#' @export
opening <- function(x1, y1, x2, y2, type = c("door", "window"), id = NULL) {
  type <- match.arg(type)
  if (is.null(id)) id <- paste0(type, "_", substr(digest::digest(c(x1, y1, x2, y2)), 1, 6))
  tibble::tibble(x = c(x1, x2), y = c(y1, y2), group = id, type = type)
}

# Shared layer: walls as solid lines, doors as thick light gaps, windows dashed.
walls_layer <- function(walls) {
  if (is.null(walls)) return(NULL)
  stopifnot(all(c("x", "y", "group") %in% names(walls)))
  if (!"type" %in% names(walls)) walls$type <- "wall"
  w <- walls[walls$type == "wall", ]
  d <- walls[walls$type == "door", ]
  n <- walls[walls$type == "window", ]
  list(
    if (nrow(w)) ggplot2::geom_path(data = w, ggplot2::aes(x = .data$x, y = .data$y,
                                                          group = .data$group),
                                    colour = "grey25", linewidth = 1.1),
    if (nrow(d)) ggplot2::geom_path(data = d, ggplot2::aes(x = .data$x, y = .data$y,
                                                          group = .data$group),
                                    colour = "white", linewidth = 2.2),
    if (nrow(d)) ggplot2::geom_path(data = d, ggplot2::aes(x = .data$x, y = .data$y,
                                                          group = .data$group),
                                    colour = "grey55", linewidth = 0.6, linetype = 3),
    if (nrow(n)) ggplot2::geom_path(data = n, ggplot2::aes(x = .data$x, y = .data$y,
                                                          group = .data$group),
                                    colour = "steelblue", linewidth = 1.4)
  )
}
