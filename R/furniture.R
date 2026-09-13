# Furniture and other scene objects ------------------------------------------
#
# Every object is a footprint (rectangle or circle) with a height, drawn as a
# schematic, to-scale, semi-transparent box in every view. Nothing is modelled
# in detail on purpose: a demonstrative exhibit must not add detail that was
# not measured.

#' Catalogue of object types with default height, colour and label
#'
#' Used by [furniture()] and friends to fill in defaults. Heights are typical
#' values and should be replaced by measurements whenever available.
#'
#' @return A tibble with columns `type`, `height`, `colour`, `label`.
#' @export
furniture_catalogue <- function() {
  tibble::tribble(
    ~type,             ~height, ~colour,   ~label,
    "sofa",            0.85,    "#5b8def", "Sofa",
    "armchair",        0.90,    "#5b8def", "Armchair",
    "chair",           0.90,    "#7aa6f0", "Chair",
    "table",           0.75,    "#c2884e", "Table",
    "desk",            0.75,    "#c2884e", "Desk",
    "counter",         0.90,    "#a0a0a0", "Counter",
    "bed",             0.60,    "#8fbf8f", "Bed",
    "wardrobe",        2.00,    "#9c7b5a", "Wardrobe",
    "cabinet",         0.90,    "#9c7b5a", "Cabinet",
    "bookcase",        1.80,    "#9c7b5a", "Bookcase",
    "tv_stand",        0.50,    "#8a8a8a", "TV stand",
    "appliance",       0.90,    "#b0b0b0", "Appliance",
    "stairs",          2.50,    "#bdb5a5", "Stairs",
    "box",             0.50,    "#c9c9c9", "Object",
    "person_standing", 1.70,    "#e0b04c", "Person (standing)",
    "person_sitting",  1.30,    "#e0b04c", "Person (sitting)",
    "person_lying",    0.30,    "#e0b04c", "Person (lying)"
  )
}

#' Define a scene object (furniture, appliance, person)
#'
#' Objects are rectangular or circular footprints with a height. Rectangles
#' are anchored at their south-west corner in their own frame and rotated
#' counter-clockwise by `angle` about that corner; circles are anchored at
#' their centre. Height, colour and label default from
#' [furniture_catalogue()] by `type`.
#'
#' @param id Character. Unique label (e.g. `"Sofa"`, `"Table 1"`).
#' @param type Character. A type from [furniture_catalogue()], or any other
#'   string (then `height` is required).
#' @param x,y Anchor position, scene units: south-west corner of a rectangle
#'   (before rotation) or the centre of a circle. See `anchor`.
#' @param width,depth Rectangle extent along its own x and y axes.
#' @param diameter Circle diameter (use with `shape = "circle"`).
#' @param height Height above `z0`. Default from the catalogue.
#' @param z0 Height of the object's base (e.g. a shelf). Default 0.
#' @param angle Rotation in degrees, counter-clockwise, about the anchor.
#' @param shape `"rect"` or `"circle"`.
#' @param anchor `"sw"` (default for rectangles) or `"center"`.
#' @param colour Fill colour. Default from the catalogue.
#' @param alpha Opacity 0 to 1 used in every view. Default `0.45`, so what is
#'   behind an object stays visible.
#' @param measured Logical. Were the dimensions measured (TRUE) or estimated
#'   (FALSE)? Estimated objects are drawn with dashed outlines and flagged in
#'   the report table.
#' @param steps For `type = "stairs"`: number of steps rising along the
#'   object's own x axis. The 3D view stacks them; obstruction checks use
#'   the stepped profile.
#' @param notes Character.
#' @return A one-row tibble of class `furniture`. Combine several with
#'   `rbind()`.
#' @examples
#' f <- rbind(
#'   furniture("Table", "table", x = 3, y = 2, width = 1.2, depth = 0.8, angle = 15),
#'   furniture("Stool", "chair", x = 1.5, y = 1.2, diameter = 0.4, shape = "circle")
#' )
#' @export
furniture <- function(id, type, x, y, width = NULL, depth = NULL, diameter = NULL,
                      height = NULL, z0 = 0, angle = 0,
                      shape = c("rect", "circle"), anchor = NULL,
                      colour = NULL, alpha = 0.45, measured = TRUE,
                      steps = NA_integer_, notes = NA_character_) {
  shape <- match.arg(shape)
  cat_row <- furniture_catalogue()[furniture_catalogue()$type == type, ]
  if (is.null(height)) {
    if (!nrow(cat_row)) cli::cli_abort("Unknown type {.val {type}}: give `height` explicitly.")
    height <- cat_row$height
  }
  if (is.null(colour)) colour <- if (nrow(cat_row)) cat_row$colour else "#c9c9c9"
  if (is.null(anchor)) anchor <- if (shape == "circle") "center" else "sw"
  anchor <- match.arg(anchor, c("sw", "center"))
  if (shape == "circle") {
    if (is.null(diameter)) cli::cli_abort("A circle needs `diameter`.")
    width <- depth <- diameter
  } else if (is.null(width) || is.null(depth)) {
    cli::cli_abort("A rectangle needs `width` and `depth`.")
  }
  stopifnot(width > 0, depth > 0, height > 0, alpha >= 0, alpha <= 1)
  if (shape == "rect" && anchor == "center") {
    # move the anchor to the south-west corner in the rotated frame
    a <- angle * pi / 180
    ex <- c(cos(a), sin(a)); ey <- c(-sin(a), cos(a))
    x <- x - width / 2 * ex[1] - depth / 2 * ey[1]
    y <- y - width / 2 * ex[2] - depth / 2 * ey[2]
  }
  angle <- angle %% 360
  out <- tibble::tibble(
    id = as.character(id), type = type, x = x, y = y, width = width, depth = depth,
    height = height, z0 = z0, angle = angle, shape = shape, colour = colour,
    alpha = alpha, measured = measured, steps = as.integer(steps), notes = notes
  )
  class(out) <- c("furniture", class(out))
  out
}

#' Place an object against a wall, as it is measured in the field
#'
#' Position is given as the distance `from` the wall's left end (as seen
#' from inside the room, see [wall_from_room()]) to the object's left edge,
#' its `length` along the wall and its `depth` into the room.
#'
#' @param walls Walls tibble from [room_rect()].
#' @param side `"north"`, `"south"`, `"east"` or `"west"`.
#' @param from Distance from the left end of the wall to the object's left edge.
#' @param length Extent along the wall.
#' @param depth Extent into the room.
#' @param id,type Passed to [furniture()].
#' @param ... Further arguments to [furniture()] (`height`, `colour`, ...).
#' @param room_id Group id of the room rectangle in `walls`.
#' @return A one-row `furniture` tibble.
#' @examples
#' walls <- room_rect(0, 0, 6, 5)
#' along_wall(walls, "north", from = 0.5, length = 2.1, depth = 0.9, id = "Sofa", type = "sofa")
#' @export
along_wall <- function(walls, side, from, length, depth, id, type, ..., room_id = "room") {
  w <- wall_from_room(walls, side, id = room_id)
  a <- w[1:2]; b <- w[3:4]; d <- b - a; L <- sqrt(sum(d^2)); u <- d / L
  r <- walls[walls$group == room_id, ]
  centre <- c(mean(range(r$x)), mean(range(r$y)))
  n <- c(-u[2], u[1]); if (sum(n * (centre - a)) < 0) n <- -n
  # rectangle local axes: ex along the wall, ey into the room
  if (isTRUE(all.equal(n, c(-u[2], u[1])))) {
    corner <- a + from * u; ang <- atan2(u[2], u[1]) * 180 / pi
  } else {
    corner <- a + (from + length) * u; ang <- atan2(-u[2], -u[1]) * 180 / pi
  }
  furniture(id, type, x = corner[1], y = corner[2], width = length, depth = depth,
            angle = ang, ...)
}

#' Axis-aligned object from two measured opposite corners
#'
#' @param id,type Passed to [furniture()].
#' @param p1,p2 Numeric length-2 opposite corners `c(x, y)`.
#' @param ... Further arguments to [furniture()].
#' @return A one-row `furniture` tibble.
#' @export
furniture_from_corners <- function(id, type, p1, p2, ...) {
  stopifnot(length(p1) == 2, length(p2) == 2)
  furniture(id, type, x = min(p1[1], p2[1]), y = min(p1[2], p2[2]),
            width = abs(p2[1] - p1[1]), depth = abs(p2[2] - p1[2]), ...)
}

#' Footprint polygons of scene objects
#'
#' @param f A `furniture` tibble.
#' @return A tibble with columns `id`, `x`, `y`, `type`, `colour`, `alpha`,
#'   `measured`, one row per vertex.
#' @export
furniture_footprint <- function(f) {
  if (is.null(f) || !nrow(f)) return(NULL)
  do.call(rbind, lapply(seq_len(nrow(f)), function(i) {
    r <- f[i, ]
    if (r$shape == "circle") {
      th <- seq(0, 2 * pi, length.out = 33)[-33]
      px <- r$x + r$width / 2 * cos(th); py <- r$y + r$width / 2 * sin(th)
    } else {
      a <- r$angle * pi / 180
      ex <- c(cos(a), sin(a)); ey <- c(-sin(a), cos(a))
      cs <- rbind(c(0, 0), c(r$width, 0), c(r$width, r$depth), c(0, r$depth))
      px <- r$x + cs[, 1] * ex[1] + cs[, 2] * ey[1]
      py <- r$y + cs[, 1] * ex[2] + cs[, 2] * ey[2]
    }
    tibble::tibble(id = r$id, x = px, y = py, type = r$type, colour = r$colour,
                   alpha = r$alpha, measured = r$measured)
  }))
}

#' Summary table of scene objects for reports
#'
#' @param f A `furniture` tibble.
#' @return A tibble with readable columns.
#' @export
furniture_table <- function(f) {
  tibble::tibble(
    Object = f$id, Type = f$type,
    Footprint = ifelse(f$shape == "circle", sprintf("circle, %.2f dia.", f$width),
                       sprintf("%.2f x %.2f", f$width, f$depth)),
    Height = sprintf("%.2f", f$height),
    `Position (x, y)` = sprintf("%.2f, %.2f", f$x, f$y),
    Angle = sprintf("%.0f", f$angle),
    Dimensions = ifelse(f$measured, "measured", "estimated")
  )
}

# Is the point (x, y, z) inside object row r? Vectorised over points.
inside_object <- function(r, x, y, z) {
  if (r$shape == "circle") {
    inside_xy <- (x - r$x)^2 + (y - r$y)^2 <= (r$width / 2)^2
    top <- r$z0 + r$height
  } else {
    a <- r$angle * pi / 180
    dx <- x - r$x; dy <- y - r$y
    u <- dx * cos(a) + dy * sin(a); v <- -dx * sin(a) + dy * cos(a)
    inside_xy <- u >= 0 & u <= r$width & v >= 0 & v <= r$depth
    top <- r$z0 + r$height
    if (!is.na(r$steps) && r$steps > 0) {
      top <- r$z0 + r$height * ceiling(pmin(pmax(u, 1e-9), r$width) / r$width * r$steps) / r$steps
    }
  }
  inside_xy & z >= r$z0 & z <= top
}

#' Which objects does a back-projected trajectory pass through?
#'
#' Samples each trajectory backwards from its defect and reports the
#' distance intervals inside every object. A hit means the object is an
#' intermediate target or an obstruction that must be reconciled with the
#' evidence (a defect in it, or a bullet path that cannot be right).
#'
#' @param trajectories A `trajectory` or list of them.
#' @param f A `furniture` tibble.
#' @param back Distance to trace back from the defect.
#' @param step Sampling step along the line.
#' @return A tibble with `trajectory`, `object`, `from`, `to` (distances back
#'   from the defect) and `top_height`. Zero rows if nothing is hit.
#' @export
trajectory_obstructions <- function(trajectories, f, back = 6, step = 0.01) {
  tl <- as_traj_list(trajectories)
  if (is.null(f) || !nrow(f)) return(tibble::tibble(trajectory = character(), object = character(),
                                                     from = numeric(), to = numeric(), top_height = numeric()))
  d <- seq(0, back, by = step)
  out <- list()
  for (t in tl) {
    P <- t(vapply(d, t$project, numeric(3)))
    for (i in seq_len(nrow(f))) {
      r <- f[i, ]
      hit <- inside_object(r, P[, 1], P[, 2], P[, 3])
      if (!any(hit)) next
      rl <- rle(hit); ends <- cumsum(rl$lengths); starts <- ends - rl$lengths + 1
      for (k in which(rl$values)) {
        out[[length(out) + 1]] <- tibble::tibble(
          trajectory = t$id, object = r$id, from = d[starts[k]], to = d[ends[k]],
          top_height = r$z0 + r$height)
      }
    }
  }
  if (!length(out)) return(trajectory_obstructions(tl, NULL))
  do.call(rbind, out)
}

# ggplot layers for the plan view
furniture_layers <- function(f, alpha_override = NULL, label_size = 2.8) {
  fp <- furniture_footprint(f)
  if (is.null(fp)) return(NULL)
  if (!is.null(alpha_override)) fp$alpha <- alpha_override
  cent <- do.call(rbind, lapply(split(fp, fp$id), function(g)
    tibble::tibble(id = g$id[1], x = mean(g$x), y = mean(g$y))))
  fills <- stats::setNames(unique(fp$colour), unique(fp$colour))
  list(
    ggplot2::geom_polygon(data = fp, ggplot2::aes(x = .data$x, y = .data$y, group = .data$id,
                                                  fill = .data$colour, alpha = .data$alpha),
                          colour = NA),
    ggplot2::geom_path(data = rbind(fp, fp[!duplicated(fp$id), ]),  # close each ring
                       ggplot2::aes(x = .data$x, y = .data$y, group = .data$id,
                                    linetype = ifelse(.data$measured, "measured", "estimated")),
                       colour = "grey25", linewidth = 0.4),
    ggplot2::geom_text(data = cent, ggplot2::aes(x = .data$x, y = .data$y, label = .data$id),
                       size = label_size, colour = "grey15"),
    ggplot2::scale_fill_identity(), ggplot2::scale_alpha_identity(),
    ggplot2::scale_linetype_manual(values = c(measured = "solid", estimated = "22"),
                                   name = "Dimensions", drop = FALSE)
  )
}
