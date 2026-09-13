#' Wall segment of a rectangular room, ordered as seen from inside
#'
#' Convenience for [plot_wall_elevation()]: returns the end points of one
#' side of a room built with [room_rect()], ordered so that the first point
#' is on the viewer's *left* when standing inside the room facing that wall.
#'
#' @param walls A tibble from [room_rect()] (optionally with openings bound).
#' @param side `"north"`, `"south"`, `"east"` or `"west"`.
#' @param id Group id of the room rectangle in `walls`. Default `"room"`.
#' @return Numeric length-4 `c(x1, y1, x2, y2)`.
#' @export
wall_from_room <- function(walls, side = c("north", "south", "east", "west"),
                           id = "room") {
  side <- match.arg(side)
  r <- walls[walls$group == id, ]
  if (!nrow(r)) cli::cli_abort("No group {.val {id}} in `walls`.")
  x0 <- min(r$x); x1 <- max(r$x); y0 <- min(r$y); y1 <- max(r$y)
  switch(side,
    north = c(x0, y1, x1, y1),   # facing north: west on the left
    south = c(x1, y0, x0, y0),   # facing south: east on the left
    east  = c(x1, y1, x1, y0),   # facing east: north on the left
    west  = c(x0, y0, x0, y1))   # facing west: south on the left
}

#' Elevation view of one wall
#'
#' The standard companion to the plan view: the wall drawn face-on with the
#' position and height of everything on or near it (bullet defects, stains,
#' openings). Items are selected by their perpendicular distance to the wall
#' line; heights come from the `z` column of the points. Trajectory anchors
#' are added as defects, with a short arrow showing the projected direction
#' of flight *into* the wall.
#'
#' @param wall Numeric length-4 `c(x1, y1, x2, y2)`; the first point appears
#'   on the left. See [wall_from_room()].
#' @param points Optional scene points tibble with `z`.
#' @param trajectories Optional `trajectory` or list of them.
#' @param walls Optional walls tibble; door and window openings lying on
#'   this wall are drawn.
#' @param tol Maximum perpendicular distance from the wall line for an item
#'   to be shown, scene units.
#' @param furniture Optional `furniture` tibble. Objects whose footprint comes
#'   within `tol_furniture` of the wall are drawn as semi-transparent boxes
#'   with their height.
#' @param tol_furniture Distance from the wall within which objects are shown.
#' @param furniture_alpha Optional opacity overriding every object's own.
#' @param height Wall (ceiling) height.
#' @param door_height,window_sill,window_head Heights used to draw openings.
#' @param units Axis unit label.
#' @param title Plot title. Default built from the wall end points.
#' @return A ggplot object.
#' @export
plot_wall_elevation <- function(wall, points = NULL, trajectories = NULL,
                                walls = NULL, tol = 0.15, height = 2.5,
                                door_height = 2.0, window_sill = 0.9,
                                window_head = 2.1, units = "m", title = NULL,
                                furniture = NULL, tol_furniture = 0.35,
                                furniture_alpha = NULL) {
  stopifnot(length(wall) == 4)
  a <- wall[1:2]; b <- wall[3:4]
  d <- b - a; L <- sqrt(sum(d^2))
  if (L == 0) cli::cli_abort("Wall end points must differ.")
  u <- d / L; n <- c(-u[2], u[1])
  along <- function(x, y) (x - a[1]) * u[1] + (y - a[2]) * u[2]
  offset <- function(x, y) (x - a[1]) * n[1] + (y - a[2]) * n[2]
  on_wall <- function(x, y) abs(offset(x, y)) <= tol & along(x, y) >= -tol & along(x, y) <= L + tol

  items <- tibble::tibble(s = numeric(), z = numeric(), id = character(), type = character())
  if (!is.null(points) && nrow(points)) {
    if (!"z" %in% names(points)) points$z <- NA_real_
    if (!"type" %in% names(points)) points$type <- "evidence"
    keep <- on_wall(points$x, points$y)
    if (any(keep)) {
      items <- rbind(items, tibble::tibble(
        s = along(points$x[keep], points$y[keep]),
        z = ifelse(is.na(points$z[keep]), 0, points$z[keep]),
        id = points$id[keep], type = points$type[keep]))
    }
  }
  arrows <- NULL
  if (!is.null(trajectories)) {
    tl <- as_traj_list(trajectories)
    for (t in tl) {
      if (on_wall(t$anchor[1], t$anchor[2])) {
        s0 <- along(t$anchor[1], t$anchor[2])
        items <- rbind(items, tibble::tibble(s = s0, z = t$anchor[3], id = t$id, type = "defect"))
        # projected flight direction on the wall plane, drawn as the last 0.3 units before impact
        ds <- sum(t$u[1:2] * u); dz <- t$u[3]
        nrm <- sqrt(ds^2 + dz^2)
        if (nrm > 1e-9) {
          arrows <- rbind(arrows, tibble::tibble(
            s0 = s0 - 0.3 * ds / nrm, z0 = t$anchor[3] - 0.3 * dz / nrm, s1 = s0, z1 = t$anchor[3]))
        }
      }
    }
  }
  open_rects <- NULL
  if (!is.null(walls) && "type" %in% names(walls)) {
    op <- walls[walls$type %in% c("door", "window"), ]
    for (g in unique(op$group)) {
      seg <- op[op$group == g, ]
      if (nrow(seg) >= 2 && all(on_wall(seg$x, seg$y))) {
        ss <- range(along(seg$x, seg$y))
        ty <- seg$type[1]
        open_rects <- rbind(open_rects, tibble::tibble(
          xmin = ss[1], xmax = ss[2],
          ymin = if (ty == "door") 0 else window_sill,
          ymax = if (ty == "door") door_height else window_head, type = ty))
      }
    }
  }
  furn_rects <- NULL
  if (!is.null(furniture) && nrow(furniture)) {
    fp <- furniture_footprint(furniture)
    for (g in unique(fp$id)) {
      v <- fp[fp$id == g, ]; r <- furniture[furniture$id == g, ][1, ]
      offs <- offset(v$x, v$y); al <- along(v$x, v$y)
      if (min(abs(offs)) <= tol_furniture && max(al) > 0 && min(al) < L) {
        furn_rects <- rbind(furn_rects, tibble::tibble(
          id = g, xmin = max(min(al), 0), xmax = min(max(al), L),
          ymin = r$z0, ymax = r$z0 + r$height, colour = r$colour,
          alpha = if (is.null(furniture_alpha)) r$alpha else furniture_alpha,
          measured = r$measured))
      }
    }
  }
  if (is.null(title)) {
    title <- sprintf("Wall elevation: (%.1f, %.1f) to (%.1f, %.1f), viewed from inside",
                     a[1], a[2], b[1], b[2])
  }
  p <- ggplot2::ggplot() +
    ggplot2::annotate("rect", xmin = 0, xmax = L, ymin = 0, ymax = height,
                      fill = "grey97", colour = "grey25", linewidth = 1)
  if (!is.null(furn_rects)) {
    p <- p +
      ggplot2::geom_rect(data = furn_rects,
        ggplot2::aes(xmin = .data$xmin, xmax = .data$xmax, ymin = .data$ymin, ymax = .data$ymax,
                     fill = .data$colour, alpha = .data$alpha,
                     linetype = ifelse(.data$measured, "solid", "22")),
        colour = "grey25", linewidth = 0.4) +
      ggplot2::geom_text(data = furn_rects,
        ggplot2::aes(x = (.data$xmin + .data$xmax) / 2, y = .data$ymax, label = .data$id),
        vjust = -0.4, size = 2.6, colour = "grey15") +
      ggplot2::scale_fill_identity() + ggplot2::scale_alpha_identity() +
      ggplot2::scale_linetype_identity()
  }
  if (!is.null(open_rects)) {
    open_rects$fill <- ifelse(open_rects$type == "door", "grey85", "lightblue")
    p <- p + ggplot2::geom_rect(data = open_rects,
      ggplot2::aes(xmin = .data$xmin, xmax = .data$xmax, ymin = .data$ymin, ymax = .data$ymax),
      fill = open_rects$fill, colour = "grey40", alpha = 0.6) +
      ggplot2::geom_text(data = open_rects,
        ggplot2::aes(x = (.data$xmin + .data$xmax) / 2, y = .data$ymin, label = .data$type),
        vjust = 1.4, size = 2.5, colour = "grey30")
  }
  if (nrow(items)) {
    p <- p +
      ggplot2::geom_point(data = items, ggplot2::aes(x = .data$s, y = .data$z, shape = .data$type,
                                                     colour = .data$type), size = 3) +
      ggplot2::geom_text(data = items, ggplot2::aes(x = .data$s, y = .data$z, label = .data$id),
                         vjust = -1, size = 2.8) +
      ggplot2::scale_shape_manual(values = c(evidence = 4, defect = 16, bloodstain = 17), name = NULL) +
      ggplot2::scale_colour_manual(values = c(evidence = "black", defect = "black",
                                              bloodstain = "firebrick"), name = NULL)
  }
  if (!is.null(arrows)) {
    p <- p + ggplot2::geom_segment(data = arrows,
      ggplot2::aes(x = .data$s0, y = .data$z0, xend = .data$s1, yend = .data$z1),
      arrow = ggplot2::arrow(length = ggplot2::unit(2.5, "mm")), colour = "grey30")
  }
  p + ggplot2::coord_equal(xlim = c(-0.1, L + 0.1), ylim = c(-0.1, height + 0.2), expand = FALSE) +
    ggplot2::labs(x = paste0("distance along wall from left (", units, ")"),
                  y = paste0("height (", units, ")"), title = title) +
    ggplot2::theme_minimal() +
    ggplot2::theme(legend.position = "bottom")
}
