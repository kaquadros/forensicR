# Shooting incident reconstruction -------------------------------------------
#
# Scene frame used throughout: x = east, y = north, z = up. A trajectory is
# described by an anchor point on the bullet path (normally the entry defect)
# and a unit vector `u` giving the direction of FLIGHT (shooter -> impact).
# Azimuth is degrees clockwise from north (0 = north, 90 = east); vertical
# angle is degrees above horizontal (negative = downward flight).
#
# Terminology follows OSAC 2025-N-0003 "Standard Terminology for Shooting
# Reconstruction". Methods follow Haag & Haag, "Shooting Incident
# Reconstruction" (3rd ed., 2020) and Hueske, "Practical Analysis and
# Reconstruction of Shooting Incidents" (2nd ed., 2015).

dir_from_angles <- function(az_deg, vt_deg) {
  az <- az_deg * pi / 180; vt <- vt_deg * pi / 180
  cbind(cos(vt) * sin(az), cos(vt) * cos(az), sin(vt))
}

angles_from_dir <- function(u) {
  u <- matrix(u, ncol = 3)
  az <- (atan2(u[, 1], u[, 2]) * 180 / pi) %% 360
  az[abs(az - 360) < 1e-9] <- 0
  vt <- asin(pmin(pmax(u[, 3], -1), 1)) * 180 / pi
  cbind(azimuth_deg = az, vertical_deg = vt)
}

circ_sd <- function(deg) {
  # SD of angles that may wrap around 360 (e.g. azimuths near north)
  r <- deg * pi / 180
  R <- sqrt(mean(cos(r))^2 + mean(sin(r))^2)
  sqrt(-2 * log(max(R, 1e-12))) * 180 / pi
}

new_trajectory <- function(anchor, u, sampler, method, id, se_azimuth, se_vertical) {
  u <- as.numeric(u); u <- u / sqrt(sum(u^2))
  ang <- angles_from_dir(u)
  structure(list(
    id = id, method = method, anchor = as.numeric(anchor), u = u,
    azimuth_deg = unname(ang[1, 1]), vertical_deg = unname(ang[1, 2]),
    se_azimuth = se_azimuth, se_vertical = se_vertical,
    length = NA_real_,
    sample = sampler,
    project = function(dist) as.numeric(anchor) - dist * u
  ), class = "trajectory")
}

#' Impact angle from a bullet defect's ellipse
#'
#' For a projectile striking a flat surface, the angle of impact relative to
#' the surface is approximated by `asin(width / length)` of the resulting
#' elliptical defect (90 degrees is perpendicular). The relationship is
#' reliable for non-yielding surfaces (drywall, wood, sheet metal); it is
#' unreliable for glass, thick fabric, or when the defect is irregular.
#' Near 90 degrees the estimate is inherently imprecise because the ellipse
#' is almost circular; the Monte Carlo interval reflects that.
#'
#' @param width,length Numeric. Minor and major axis of the defect, same units.
#' @param se Optional numeric. Measurement standard error for both axes. If
#'   supplied, a Monte Carlo interval is added (`n_sim` draws).
#' @param n_sim Integer. Number of Monte Carlo draws.
#' @param level Confidence level for the interval.
#' @return A tibble with `angle_deg` and, if `se` is supplied, `lower`,
#'   `upper` and `level`.
#' @examples
#' impact_angle(width = 8, length = 16)          # 30 degrees
#' impact_angle(width = 8, length = 16, se = 0.5)
#' @export
impact_angle <- function(width, length, se = NULL, n_sim = 10000, level = 0.95) {
  r <- recycle2(width, length, "width", "length"); width <- r[[1]]; length <- r[[2]]
  stopifnot(all(width > 0), all(length > 0))
  if (any(width > length)) cli::cli_abort("`width` cannot exceed `length`.")
  ang <- asin(width / length) * 180 / pi
  out <- tibble::tibble(angle_deg = ang)
  if (!is.null(se)) {
    ci <- vapply(seq_along(width), function(i) {
      w <- stats::rnorm(n_sim, width[i], se)
      l <- stats::rnorm(n_sim, length[i], se)
      # A draw with w > l means the axes swapped roles: use min/max rather
      # than clamping, which would pile draws up at exactly 90 degrees.
      rr <- pmin(w, l) / pmax(w, l)
      rr <- pmin(pmax(rr, 0), 1)
      stats::quantile(asin(rr) * 180 / pi, c((1 - level) / 2, 1 - (1 - level) / 2))
    }, numeric(2))
    out$lower <- ci[1, ]
    out$upper <- ci[2, ]
    out$level <- level
  }
  out
}

#' Trajectory from angles measured at the defect (rod, laser or protractor)
#'
#' The most common field method: a trajectory rod or laser is placed through
#' the defect(s) and its vertical angle (angle finder / inclinometer) and
#' horizontal angle (protractor, or azimuth from a total station) are
#' recorded. Angular uncertainty of about 5 degrees is commonly cited for
#' rod-based work; adjust to what your method validation supports.
#'
#' @param anchor Numeric length-3 `c(x, y, z)` of the defect in scene frame.
#' @param azimuth_deg Direction of *flight*, degrees clockwise from north.
#' @param vertical_deg Degrees above horizontal; negative = downward flight.
#' @param se_azimuth,se_vertical Standard errors of the two angles, degrees.
#' @param id Character label.
#' @return An object of class `trajectory`.
#' @examples
#' t <- trajectory_from_angles(c(4.8, 0, 1.35), azimuth_deg = 350, vertical_deg = -8)
#' t
#' t$project(3)   # point 3 m back toward the shooter
#' @export
trajectory_from_angles <- function(anchor, azimuth_deg, vertical_deg,
                                   se_azimuth = 5, se_vertical = 5, id = "T1") {
  stopifnot(length(anchor) == 3)
  u <- dir_from_angles(azimuth_deg, vertical_deg)[1, ]
  sampler <- function(n) {
    dir_from_angles(stats::rnorm(n, azimuth_deg, se_azimuth),
                    stats::rnorm(n, vertical_deg, se_vertical))
  }
  new_trajectory(anchor, u, sampler, "angles at defect", id, se_azimuth, se_vertical)
}

#' Trajectory through two points on the bullet path
#'
#' Two defects (entry and exit of a wall, or defects in two surfaces), or a
#' defect and a probe tip. Positional uncertainty in each coordinate is
#' propagated to the direction.
#'
#' @param p1,p2 Numeric length-3 `c(x, y, z)`. `p1` is closer to the shooter,
#'   `p2` further along the flight. The trajectory is anchored at `p2` (the
#'   impact); `p1` is kept as `$p1` and becomes the joint when the object is
#'   used as a later segment of a [trajectory_path()].
#' @param se_position Standard error of each coordinate, scene units.
#' @param id Character label.
#' @return An object of class `trajectory` with extra elements `length`
#'   (distance between the two points) and `p1`.
#' @examples
#' t <- trajectory_2pt(c(0, 0, 1.2), c(0, 2, 1.0), se_position = 0.01)
#' t$vertical_deg
#' @export
trajectory_2pt <- function(p1, p2, se_position = 0, id = "T1") {
  stopifnot(length(p1) == 3, length(p2) == 3)
  d <- p2 - p1
  len <- sqrt(sum(d^2))
  if (len == 0) cli::cli_abort("`p1` and `p2` must differ.")
  se_ang <- sqrt(2) * se_position / len * 180 / pi
  sampler <- function(n) {
    a <- matrix(stats::rnorm(3 * n, rep(p1, each = n), se_position), ncol = 3)
    b <- matrix(stats::rnorm(3 * n, rep(p2, each = n), se_position), ncol = 3)
    dd <- b - a
    dd / sqrt(rowSums(dd^2))
  }
  tr <- new_trajectory(p2, d / len, sampler, "two points", id, se_ang, se_ang)
  tr$length <- len
  tr$p1 <- as.numeric(p1)
  tr
}

#' Trajectory from a single defect's ellipse on a vertical surface
#'
#' Combines the impact angle from the ellipse ([impact_angle()]) with the
#' orientation of the ellipse's major axis on the surface and a
#' directionality indicator (lead-in mark, pinch point, or exit beveling)
#' to obtain a full 3D trajectory. Use only when a rod cannot be placed.
#'
#' @param anchor Numeric length-3 `c(x, y, z)` of the defect.
#' @param width,length Ellipse axes.
#' @param major_axis_deg Orientation of the major axis on the surface as seen
#'   by an observer on the shooter's side facing the wall: 0 = vertical,
#'   90 = horizontal, measured clockwise from 12 o'clock (range 0 to 180).
#' @param wall_azimuth_deg Azimuth of the wall's outward normal, i.e. the
#'   direction the wall *faces* (toward the shooter), degrees clockwise from
#'   north. A wall on the north side of a room faces south: 180.
#' @param came_from Which end of the major axis the bullet came from, as
#'   seen by that observer: `"above"`, `"below"`, `"left"` or `"right"`.
#' @param se Measurement SE of the ellipse axes.
#' @param se_orientation SE of `major_axis_deg`, degrees.
#' @param id Character label.
#' @return An object of class `trajectory`.
#' @examples
#' # North wall, bullet came from above-right, 30 deg to the surface
#' trajectory_from_defect(c(2, 5, 1.4), width = 6, length = 12,
#'                        major_axis_deg = 45, wall_azimuth_deg = 180,
#'                        came_from = "above")
#' @export
trajectory_from_defect <- function(anchor, width, length, major_axis_deg,
                                   wall_azimuth_deg,
                                   came_from = c("above", "below", "left", "right"),
                                   se = 0.5, se_orientation = 5, id = "T1") {
  came_from <- match.arg(came_from)
  stopifnot(length(anchor) == 3, width > 0, length > 0)
  if (width > length) cli::cli_abort("`width` cannot exceed `length`.")
  N <- wall_azimuth_deg * pi / 180
  n_hat <- c(sin(N), cos(N), 0)             # outward normal (toward shooter)
  r_hat <- c(-cos(N), sin(N), 0)            # observer's right when facing wall
  z_hat <- c(0, 0, 1)

  build <- function(w, l, phi_deg, strict = TRUE) {
    alpha <- asin(pmin(w / l, 1))
    phi <- phi_deg * pi / 180
    a <- sin(phi) * r_hat + cos(phi) * z_hat          # major axis direction
    comp <- switch(came_from, above = a[3], below = -a[3],
                   right = sum(a * r_hat), left = -sum(a * r_hat))
    if (abs(comp) < 1e-6 && cos(alpha) > 1e-6) {
      if (strict) {
        cli::cli_abort("`came_from = \"{came_from}\"` is ambiguous for a major axis at {phi_deg} degrees.")
      }
      # Monte Carlo draw whose axis is exactly perpendicular to the stated
      # directionality: the end the bullet came from is undetermined, so pick
      # either end at random rather than abort.
      comp <- sample(c(-1, 1), 1)
    }
    m <- a * if (comp < 0) -1 else 1                    # points to came-from end
    -cos(alpha) * m - sin(alpha) * n_hat                # flight direction
  }
  u <- build(width, length, major_axis_deg)
  sampler <- function(n) {
    w <- pmax(stats::rnorm(n, width, se), 1e-6)
    l <- pmax(stats::rnorm(n, length, se), 1e-6)
    phi <- stats::rnorm(n, major_axis_deg, se_orientation)
    # If a draw makes the "width" the longer axis, the ellipse in that draw is
    # elongated the other way: swap the axes and rotate the orientation 90
    # degrees instead of clamping (clamping piles draws at exactly 90 degrees).
    swap <- w > l
    phi[swap] <- phi[swap] + 90
    ww <- pmin(w, l); ll <- pmax(w, l)
    t(vapply(seq_len(n), function(i) build(ww[i], ll[i], phi[i], strict = FALSE), numeric(3)))
  }
  s <- angles_from_dir(sampler(2000))
  new_trajectory(anchor, u, sampler, "defect ellipse", id,
                 circ_sd(s[, 1]), stats::sd(s[, 2]))
}

#' @export
print.trajectory <- function(x, ...) {
  cli::cli_h3("Trajectory {x$id} ({x$method})")
  cli::cli_text("Anchor (x, y, z): {paste(round(x$anchor, 2), collapse = ', ')}")
  cli::cli_text("Flight azimuth: {round(x$azimuth_deg, 1)}\u00b0 \u00b1 {round(x$se_azimuth, 1)}\u00b0 (clockwise from north)")
  cli::cli_text("Vertical angle: {round(x$vertical_deg, 1)}\u00b0 \u00b1 {round(x$se_vertical, 1)}\u00b0 ({if (x$vertical_deg < 0) 'downward' else 'upward'} flight)")
  invisible(x)
}

#' Summarise one or more trajectories as a table
#'
#' @param trajectories A `trajectory`, a `trajectory_path`, or a list of them.
#' @return A tibble with one row per trajectory.
#' @export
trajectory_table <- function(trajectories) {
  tl <- as_traj_list(trajectories)
  tibble::tibble(
    id = vapply(tl, `[[`, "", "id"),
    path = vapply(tl, function(t) t$path_id %||% NA_character_, ""),
    segment = vapply(tl, function(t) as.integer(t$segment_index %||% NA_integer_), 1L),
    assumed = vapply(tl, function(t) isTRUE(t$assumed), TRUE),
    method = vapply(tl, `[[`, "", "method"),
    x = vapply(tl, function(t) t$anchor[1], 1),
    y = vapply(tl, function(t) t$anchor[2], 1),
    z = vapply(tl, function(t) t$anchor[3], 1),
    azimuth_deg = vapply(tl, `[[`, 1, "azimuth_deg"),
    se_azimuth = vapply(tl, `[[`, 1, "se_azimuth"),
    vertical_deg = vapply(tl, `[[`, 1, "vertical_deg"),
    se_vertical = vapply(tl, `[[`, 1, "se_vertical")
  )
}

as_traj_list <- function(x) {
  x <- flatten_trajectories(x)
  if (!length(x)) cli::cli_abort("Expected a `trajectory`, a `trajectory_path`, or a list of them.")
  x
}

#' Possible origin of fire at assumed muzzle heights
#'
#' Projects a trajectory back until it reaches each assumed muzzle height and
#' reports the horizontal distance from the defect and the XY position, with
#' a Monte Carlo interval from the trajectory's angular uncertainty. This is
#' the standard way to bound where a shooter could have been: the trajectory
#' alone is a line; a plausible muzzle height turns it into a position.
#'
#' The default heights are illustrative shoulder-level values for standing,
#' kneeling and prone shooters and must be replaced by case-specific values.
#'
#' @param trajectory A `trajectory`, or a `trajectory_path` (its first
#'   segment, the one on the shooter's side, is used).
#' @param heights Named numeric vector of muzzle heights, scene units.
#' @param max_distance Largest horizontal distance considered, scene units
#'   (e.g. the room or lot dimension). Near-horizontal draws otherwise project
#'   to absurd distances; anything beyond this limit counts as not reachable.
#' @param furniture Optional `furniture` tibble. Draws whose origin falls
#'   inside an object are counted as not reachable (nobody fires from inside
#'   a wardrobe); the fraction excluded this way is returned as
#'   `p_in_furniture`.
#' @param n_sim Monte Carlo draws.
#' @param level Interval level.
#' @return A tibble with one row per height: `position`, `height`,
#'   `horizontal_distance` (median), `hd_lower`, `hd_upper`, `x`, `y`, and
#'   `p_reachable`, the fraction of draws in which the back-projected line
#'   reaches that height within `max_distance` (it cannot when, e.g., the shot
#'   travelled upward and the height is above the defect). Quantiles are
#'   computed over the reachable draws only, so read them together with
#'   `p_reachable`.
#' @examples
#' t <- trajectory_from_angles(c(4.8, 0, 1.35), 350, -8)
#' origin_zone(t)
#' @export
origin_zone <- function(trajectory,
                        heights = c(standing = 1.5, kneeling = 1.0, prone = 0.3),
                        max_distance = 50, furniture = NULL, n_sim = 5000, level = 0.95) {
  if (inherits(trajectory, "trajectory_path")) trajectory <- trajectory$segments[[1]]
  stopifnot(inherits(trajectory, "trajectory"), max_distance > 0)
  if (isTRUE(trajectory$assumed)) cli::cli_abort("An assumed segment carries no information about the origin of fire.")
  if (is.null(names(heights))) names(heights) <- paste0("h", seq_along(heights))
  U <- trajectory$sample(n_sim)
  anc <- trajectory$anchor
  q <- c((1 - level) / 2, 0.5, 1 - (1 - level) / 2)
  rows <- lapply(seq_along(heights), function(i) {
    h <- heights[[i]]
    d <- (anc[3] - h) / U[, 3]
    hd <- d * sqrt(U[, 1]^2 + U[, 2]^2)
    ok <- is.finite(d) & d > 0 & hd <= max_distance
    px <- anc[1] - d * U[, 1]; py <- anc[2] - d * U[, 2]
    in_f <- rep(FALSE, length(ok))
    if (!is.null(furniture) && nrow(furniture)) {
      for (j in seq_len(nrow(furniture))) {
        in_f <- in_f | inside_object(furniture[j, ], px, py, rep(h, length(px)))
      }
      in_f <- in_f & ok
      ok <- ok & !in_f
    }
    if (!any(ok)) {
      return(tibble::tibble(position = names(heights)[i], height = h,
                            horizontal_distance = NA_real_, hd_lower = NA_real_,
                            hd_upper = NA_real_, x = NA_real_, y = NA_real_,
                            p_reachable = 0, p_in_furniture = mean(in_f)))
    }
    qs <- stats::quantile(hd[ok], q)
    tibble::tibble(position = names(heights)[i], height = h,
                   horizontal_distance = unname(qs[2]), hd_lower = unname(qs[1]),
                   hd_upper = unname(qs[3]),
                   x = stats::median(px[ok]), y = stats::median(py[ok]),
                   p_reachable = mean(ok), p_in_furniture = mean(in_f))
  })
  do.call(rbind, rows)
}

#' Convergence of two trajectories
#'
#' Finds the closest points between two back-projected trajectories. If the
#' shots came from one position, the lines should pass close to each other
#' *behind* both defects. The miss distance relative to its Monte Carlo
#' spread tells you whether a common origin is supported; the midpoint
#' estimates that origin.
#'
#' @param t1,t2 `trajectory` objects.
#' @param n_sim Monte Carlo draws.
#' @param level Interval level.
#' @return A list with `point` (midpoint of closest approach, central
#'   estimate), `miss_distance` (central), `behind_both` (logical, central
#'   estimate lies behind both defects), `summary` (tibble of Monte Carlo
#'   quantiles for x, y, z and miss distance, plus `p_behind_both`) and
#'   `samples` (tibble of per-draw results).
#' @export
intersect_trajectories <- function(t1, t2, n_sim = 5000, level = 0.95) {
  stopifnot(inherits(t1, "trajectory"), inherits(t2, "trajectory"))
  cpa <- function(u1, u2) {
    w0 <- t1$anchor - t2$anchor
    b <- sum(u1 * u2); d <- sum(u1 * w0); e <- sum(u2 * w0)
    den <- 1 - b^2
    if (den < 1e-10) return(c(NA, NA, NA, NA, NA))
    s <- (b * e - d) / den; t <- (e - b * d) / den
    q1 <- t1$anchor + s * u1; q2 <- t2$anchor + t * u2
    c((q1 + q2) / 2, sqrt(sum((q1 - q2)^2)), as.numeric(s < 0 && t < 0))
  }
  central <- cpa(t1$u, t2$u)
  U1 <- t1$sample(n_sim); U2 <- t2$sample(n_sim)
  S <- t(vapply(seq_len(n_sim), function(i) cpa(U1[i, ], U2[i, ]), numeric(5)))
  samples <- tibble::tibble(x = S[, 1], y = S[, 2], z = S[, 3],
                            miss_distance = S[, 4], behind_both = S[, 5] == 1)
  ok <- stats::complete.cases(samples)
  q <- c((1 - level) / 2, 0.5, 1 - (1 - level) / 2)
  qf <- function(v) stats::quantile(v[ok], q, names = FALSE)
  summary <- tibble::tibble(
    quantity = c("x", "y", "z", "miss_distance"),
    lower = c(qf(samples$x)[1], qf(samples$y)[1], qf(samples$z)[1], qf(samples$miss_distance)[1]),
    median = c(qf(samples$x)[2], qf(samples$y)[2], qf(samples$z)[2], qf(samples$miss_distance)[2]),
    upper = c(qf(samples$x)[3], qf(samples$y)[3], qf(samples$z)[3], qf(samples$miss_distance)[3])
  )
  list(point = central[1:3], miss_distance = central[4],
       behind_both = isTRUE(central[5] == 1),
       p_behind_both = mean(samples$behind_both[ok]),
       summary = summary, samples = samples, level = level)
}

#' Plot trajectories in plan or elevation view with uncertainty
#'
#' Plan view: bird's-eye XY with each trajectory drawn back from its defect
#' by `back` units; faint lines are Monte Carlo draws and show the cone of
#' uncertainty. Elevation view: height against horizontal distance back from
#' the defect, one panel per trajectory, with assumed muzzle heights dashed.
#'
#' @param trajectories A `trajectory`, a `trajectory_path`, or a list of
#'   them. Path segments are drawn between their joints; assumed segments are
#'   dashed and run forward from the joint.
#' @param view `"plan"` or `"elevation"`.
#' @param back Distance to project back, scene units.
#' @param n_draw Number of Monte Carlo lines to draw.
#' @param points Optional scene points tibble (from `coords_*()`) to overlay
#'   in plan view.
#' @param walls Optional wall/door/window polylines for plan view; see
#'   [room_rect()] and [opening()].
#' @param furniture Optional `furniture` tibble drawn in plan view.
#' @param furniture_alpha Optional opacity overriding every object's own.
#' @param convergence Plan view only. `TRUE` computes
#'   [intersect_trajectories()] for every pair and draws the Monte Carlo
#'   cloud of closest-approach points (only draws lying behind both defects)
#'   with the central estimate marked. Alternatively pass one result of
#'   [intersect_trajectories()] or a list of them. `FALSE` draws nothing.
#' @param heights Muzzle heights to mark in elevation view.
#' @param units Axis unit label.
#' @return A ggplot object.
#' @export
plot_trajectories <- function(trajectories, view = c("plan", "elevation"),
                              back = 8, n_draw = 150, points = NULL,
                              walls = NULL, furniture = NULL, furniture_alpha = NULL,
                              convergence = FALSE,
                              heights = c(standing = 1.5, kneeling = 1.0, prone = 0.3),
                              units = "m") {
  view <- match.arg(view)
  tl <- as_traj_list(trajectories)
  lines <- do.call(rbind, lapply(tl, function(t) {
    U <- rbind(t$u, t$sample(n_draw))
    seg_len <- if (!is.null(t$start)) sqrt(sum((t$anchor - t$start)^2)) else back
    if (isTRUE(t$assumed)) {
      # assumed segments run forward from the joint
      org <- t$start; end <- sweep(seg_len * U, 2, org, "+")
    } else {
      org <- t$anchor; end <- sweep(-seg_len * U, 2, org, "+")
    }
    tibble::tibble(
      id = t$path_id %||% t$id, label = t$id,
      draw = seq_len(nrow(U)) - 1L, central = seq_len(nrow(U)) == 1L,
      assumed = isTRUE(t$assumed), forward = isTRUE(t$assumed),
      x0 = org[1], y0 = org[2], z0 = org[3],
      x1 = end[, 1], y1 = end[, 2], z1 = end[, 3],
      hd1 = seg_len * sqrt(U[, 1]^2 + U[, 2]^2)
    )
  }))
  # path segments inside an intermediate object: dotted link from the previous
  # segment's defect (entry) to this segment's joint (exit)
  links <- do.call(rbind, lapply(tl, function(t) {
    if (is.null(t$start) || is.null(t$segment_index) || t$segment_index < 2) return(NULL)
    prev <- Filter(function(u) identical(u$path_id, t$path_id) &&
                     identical(u$segment_index, t$segment_index - 1L), tl)
    if (!length(prev)) return(NULL)
    a <- prev[[1]]$anchor
    tibble::tibble(id = t$path_id, x0 = a[1], y0 = a[2], z0 = a[3],
                   x1 = t$start[1], y1 = t$start[2], z1 = t$start[3])
  }))
  if (view == "plan") {
    p <- ggplot2::ggplot() +
      walls_layer(walls) +
      furniture_layers(furniture, furniture_alpha) +
      (if (!is.null(links)) ggplot2::geom_segment(
        data = links, ggplot2::aes(x = .data$x0, y = .data$y0, xend = .data$x1, yend = .data$y1,
                                   colour = .data$id), linetype = "13", linewidth = 0.8)) +
      ggplot2::geom_segment(
        data = lines[!lines$central, ],
        ggplot2::aes(x = .data$x0, y = .data$y0, xend = .data$x1, yend = .data$y1,
                     colour = .data$id), alpha = 0.06) +
      ggplot2::geom_segment(
        data = lines[lines$central & !lines$forward, ],
        ggplot2::aes(x = .data$x0, y = .data$y0, xend = .data$x1, yend = .data$y1,
                     colour = .data$id), linewidth = 0.9,
        arrow = ggplot2::arrow(ends = "first", length = ggplot2::unit(3, "mm"))) +
      ggplot2::geom_segment(
        data = lines[lines$central & lines$forward, ],
        ggplot2::aes(x = .data$x0, y = .data$y0, xend = .data$x1, yend = .data$y1,
                     colour = .data$id), linewidth = 0.7, linetype = "22",
        arrow = ggplot2::arrow(ends = "last", length = ggplot2::unit(3, "mm"))) +
      ggplot2::geom_point(data = lines[lines$central, ],
                          ggplot2::aes(x = .data$x0, y = .data$y0), size = 2) +
      ggplot2::coord_equal() +
      ggplot2::labs(x = paste0("x, east (", units, ")"), y = paste0("y, north (", units, ")"),
                    colour = "Trajectory",
                    caption = "Arrow points toward the origin of fire; faint lines are Monte Carlo draws.") +
      ggplot2::theme_minimal()
    if (!is.null(points)) {
      p <- p + ggplot2::geom_point(data = points, ggplot2::aes(x = .data$x, y = .data$y),
                                   shape = 4) +
        ggplot2::geom_text(data = points, ggplot2::aes(x = .data$x, y = .data$y,
                                                       label = .data$id),
                           vjust = -0.7, size = 2.8)
    }
    conv <- convergence_list(tl, convergence)
    if (length(conv)) {
      # Keep the cloud inside the drawn region: closest-approach draws from
      # wide fans can land tens of metres away and would swamp the axes.
      xr <- range(c(lines$x0, lines$x1)); yr <- range(c(lines$y0, lines$y1))
      cloud <- do.call(rbind, lapply(seq_along(conv), function(k) {
        ix <- conv[[k]]
        s <- ix$samples[ix$samples$behind_both %in% TRUE, c("x", "y")]
        s <- s[s$x >= xr[1] & s$x <= xr[2] & s$y >= yr[1] & s$y <= yr[2], ]
        if (nrow(s) > 600) s <- s[sample.int(nrow(s), 600), ]
        if (nrow(s)) s$k <- k
        s
      }))
      centre <- do.call(rbind, lapply(seq_along(conv), function(k) {
        ix <- conv[[k]]
        tibble::tibble(x = ix$point[1], y = ix$point[2], k = k)
      }))
      legend <- paste(sprintf("%d: %s, miss %.2f %s (%.0f%% of draws behind both defects)",
                              seq_along(conv), vapply(conv, `[[`, "", "pair"),
                              vapply(conv, `[[`, 1, "miss_distance"), units,
                              100 * vapply(conv, `[[`, 1, "p_behind_both")),
                      collapse = "\n")
      p <- p +
        ggplot2::geom_point(data = cloud, ggplot2::aes(x = .data$x, y = .data$y),
                            colour = "grey20", alpha = 0.08, size = 0.7) +
        ggplot2::geom_point(data = centre, ggplot2::aes(x = .data$x, y = .data$y),
                            shape = 23, fill = "gold", colour = "black", size = 4) +
        ggplot2::geom_text(data = centre, ggplot2::aes(x = .data$x, y = .data$y,
                                                       label = .data$k),
                           size = 2.6, fontface = "bold") +
        ggplot2::labs(caption = paste(
          "Arrow points toward the origin of fire; faint lines are Monte Carlo draws.",
          "Grey cloud: closest-approach draws behind both defects; diamonds: central estimates.",
          legend, sep = "\n")) +
        ggplot2::theme(plot.caption = ggplot2::element_text(hjust = 0))
    }
    return(p)
  }
  hdf <- tibble::tibble(position = names(heights), height = unname(heights))
  ggplot2::ggplot() +
    ggplot2::geom_segment(data = lines[!lines$central, ],
                          ggplot2::aes(x = 0, y = .data$z0, xend = .data$hd1, yend = .data$z1),
                          alpha = 0.06) +
    ggplot2::geom_segment(data = lines[lines$central, ],
                          ggplot2::aes(x = 0, y = .data$z0, xend = .data$hd1, yend = .data$z1),
                          linewidth = 0.9) +
    ggplot2::geom_hline(data = hdf, ggplot2::aes(yintercept = .data$height), linetype = 2,
                        colour = "grey40") +
    ggplot2::geom_text(data = hdf, ggplot2::aes(x = back, y = .data$height,
                                                label = .data$position),
                       hjust = 1, vjust = -0.4, size = 2.8, colour = "grey30") +
    ggplot2::geom_point(data = lines[lines$central, ], ggplot2::aes(x = 0, y = .data$z0), size = 2) +
    ggplot2::facet_wrap(~ label) +
    ggplot2::coord_equal() +
    ggplot2::labs(x = paste0("horizontal distance back from defect (", units, ")"),
                  y = paste0("height (", units, ")")) +
    ggplot2::theme_minimal()
}


# Resolve the `convergence` argument of plot_trajectories() into a list of
# intersect_trajectories() results, each tagged with a `pair` label.
convergence_list <- function(tl, convergence) {
  if (isFALSE(convergence) || is.null(convergence)) return(list())
  if (isTRUE(convergence)) {
    tl <- first_segments(tl)
    if (length(tl) < 2) return(list())
    pairs <- utils::combn(seq_along(tl), 2)
    return(lapply(seq_len(ncol(pairs)), function(k) {
      i <- pairs[1, k]; j <- pairs[2, k]
      ix <- intersect_trajectories(tl[[i]], tl[[j]], n_sim = 2000)
      ix$pair <- paste(tl[[i]]$id, tl[[j]]$id, sep = " / ")
      ix
    }))
  }
  if (!is.null(convergence$samples)) convergence <- list(convergence)
  lapply(seq_along(convergence), function(k) {
    ix <- convergence[[k]]
    if (is.null(ix$samples)) cli::cli_abort("`convergence` must be TRUE/FALSE or intersect_trajectories() results.")
    if (is.null(ix$pair)) ix$pair <- paste("pair", k)
    ix
  })
}


`%||%` <- function(a, b) if (is.null(a)) b else a
