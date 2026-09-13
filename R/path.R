# Segmented trajectories ----------------------------------------------------
#
# A bullet that passes through an intermediate target (a wardrobe, a door,
# a table) follows two or more straight segments joined at the target. Each
# measured segment is an ordinary `trajectory`; a `trajectory_path` orders
# them from the shooter's side to the terminal defect and records the joints.
# Deflection is never predicted from physics: either it is measured (both
# segments documented) or it is an explicit assumption via
# assumed_segment(), flagged as such everywhere.

# Rodrigues rotation of vector v about unit axis k by angle th (radians)
rotate_about <- function(v, k, th) {
  v * cos(th) + c(k[2] * v[3] - k[3] * v[2], k[3] * v[1] - k[1] * v[3],
                  k[1] * v[2] - k[2] * v[1]) * sin(th) + k * sum(k * v) * (1 - cos(th))
}

# distance from point P to the line through A with unit direction U
point_line_dist <- function(P, A, U) {
  w <- P - A; sqrt(max(sum(w^2) - sum(w * U)^2, 0))
}

#' Build a segmented trajectory through intermediate targets
#'
#' Segments are ordered from the shooter's side to the terminal defect. Each
#' segment is a `trajectory` whose anchor is the defect at the *end* of that
#' segment (the entry into the intermediate target for segment 1, the
#' terminal defect for the last). Joints are the exit points from each
#' intermediate target; when a following segment was measured by two points
#' its first point is used as the joint automatically, otherwise the previous
#' segment's anchor is used (thin-target approximation, reported as such).
#'
#' @param ... `trajectory` objects in order, or a single list of them.
#' @param joints Optional list of `c(x, y, z)` exit points, one per joint
#'   (`length(segments) - 1`). `NULL` entries fall back to the defaults.
#' @param id Path label.
#' @return An object of class `trajectory_path`.
#' @examples
#' s1 <- trajectory_from_angles(c(4.0, 2.6, 0.5), 69, -30, id = "into table")
#' s2 <- trajectory_2pt(c(4.25, 3.1, 0.45), c(4.9, 5.0, 0.2), se_position = 0.01, id = "to wall")
#' p <- trajectory_path(s1, s2, id = "Shot 4")
#' p
#' path_deflections(p)
#' @export
trajectory_path <- function(..., joints = NULL, id = "P1") {
  segs <- list(...)
  if (length(segs) == 1 && is.list(segs[[1]]) && !inherits(segs[[1]], "trajectory")) segs <- segs[[1]]
  if (length(segs) < 2 || !all(vapply(segs, inherits, TRUE, "trajectory"))) {
    cli::cli_abort("A path needs at least two `trajectory` segments.")
  }
  n <- length(segs)
  if (is.null(joints)) joints <- vector("list", n - 1)
  if (length(joints) != n - 1) cli::cli_abort("`joints` must have {n - 1} entr{?y/ies}.")
  joint_source <- character(n - 1)
  for (k in 2:n) {
    j <- joints[[k - 1]]
    if (is.null(j)) {
      if (!is.null(segs[[k]]$p1)) { j <- segs[[k]]$p1; joint_source[k - 1] <- "first point of next segment" }
      else if (!is.null(segs[[k]]$start)) { j <- segs[[k]]$start; joint_source[k - 1] <- "segment start" }
      else { j <- segs[[k - 1]]$anchor; joint_source[k - 1] <- "previous defect (thin target)" }
    } else joint_source[k - 1] <- "given"
    stopifnot(length(j) == 3)
    joints[[k - 1]] <- as.numeric(j)
    segs[[k]]$start <- as.numeric(j)
  }
  for (k in seq_len(n)) {
    segs[[k]]$path_id <- id
    segs[[k]]$segment_index <- k
    if (is.null(segs[[k]]$assumed)) segs[[k]]$assumed <- FALSE
  }
  structure(list(id = id, segments = segs, joints = joints, joint_source = joint_source),
            class = "trajectory_path")
}

#' Segment with an assumed (not measured) deflection
#'
#' For the case where the bullet demonstrably passed through an object but
#' its path after it was not documented. The segment continues the previous
#' direction from the joint with a cone of possible deflections of standard
#' deviation `se_deflection` (degrees, random orientation). The result is
#' an *assumption* and is flagged as such in tables, plots and reports.
#'
#' @param previous The `trajectory` this segment continues.
#' @param joint Exit point `c(x, y, z)`. Default: the previous anchor.
#' @param length Length of the assumed segment.
#' @param se_deflection Standard deviation of the deflection angle, degrees.
#' @param id Label.
#' @return A `trajectory` with `assumed = TRUE` and a virtual anchor at
#'   `joint + length * u`.
#' @export
assumed_segment <- function(previous, joint = NULL, length = 2, se_deflection = 10, id = "assumed") {
  stopifnot(inherits(previous, "trajectory"), length > 0, se_deflection >= 0)
  if (is.null(joint)) joint <- previous$anchor
  u0 <- previous$u
  sampler <- function(n) {
    base <- previous$sample(n)
    t(vapply(seq_len(n), function(i) {
      u <- base[i, ]
      perp <- c(-u[2], u[1], 0); if (sum(perp^2) < 1e-9) perp <- c(1, 0, 0)
      perp <- perp / sqrt(sum(perp^2))
      axis <- rotate_about(perp, u, stats::runif(1, 0, 2 * pi))
      d <- abs(stats::rnorm(1, 0, se_deflection)) * pi / 180
      rotate_about(u, axis, d)
    }, numeric(3)))
  }
  s <- angles_from_dir(sampler(2000))
  tr <- new_trajectory(joint + length * u0, u0, sampler, "assumed deflection", id,
                       circ_sd(s[, 1]), stats::sd(s[, 2]))
  tr$start <- as.numeric(joint)
  tr$assumed <- TRUE
  tr$se_deflection <- se_deflection
  tr
}

#' @export
print.trajectory_path <- function(x, ...) {
  cli::cli_h3("Trajectory path {x$id}: {length(x$segments)} segments")
  for (s in x$segments) {
    cli::cli_text("{s$segment_index}. {s$id} ({s$method}{if (isTRUE(s$assumed)) ', ASSUMED' else ''}): azimuth {round(s$azimuth_deg, 1)}\u00b0, vertical {round(s$vertical_deg, 1)}\u00b0")
  }
  d <- path_deflections(x, n_sim = 2000)
  for (i in seq_len(nrow(d))) {
    cli::cli_text("Joint {i} ({x$joint_source[i]}): deflection {round(d$deflection_deg[i], 1)}\u00b0 [{round(d$lower[i], 1)}, {round(d$upper[i], 1)}]")
  }
  invisible(x)
}

#' Deflection angles and joint consistency of a path
#'
#' @param path A `trajectory_path`.
#' @param n_sim Monte Carlo draws.
#' @param level Interval level.
#' @return A tibble with one row per joint: `joint`, `x`, `y`, `z`,
#'   `deflection_deg` with `lower`/`upper`, `miss_in` (distance from the
#'   joint to the incoming segment's line, median and interval) and
#'   `miss_out` (same for the outgoing segment, back-projected). Large misses
#'   relative to the measurement uncertainty mean the documented segments do
#'   not meet at the joint. `assumed` flags joints whose outgoing segment is
#'   an assumption.
#' @export
path_deflections <- function(path, n_sim = 5000, level = 0.95) {
  stopifnot(inherits(path, "trajectory_path"))
  q <- c((1 - level) / 2, 0.5, 1 - (1 - level) / 2)
  segs <- path$segments
  rows <- lapply(seq_along(path$joints), function(k) {
    a <- segs[[k]]; b <- segs[[k + 1]]; J <- path$joints[[k]]
    central <- acos(min(max(sum(a$u * b$u), -1), 1)) * 180 / pi
    UA <- a$sample(n_sim); UB <- b$sample(n_sim)
    defl <- acos(pmin(pmax(rowSums(UA * UB), -1), 1)) * 180 / pi
    miss_in <- vapply(seq_len(n_sim), function(i) point_line_dist(J, a$anchor, UA[i, ]), 1)
    miss_out <- vapply(seq_len(n_sim), function(i) point_line_dist(J, b$anchor, UB[i, ]), 1)
    qd <- stats::quantile(defl, q, names = FALSE)
    qi <- stats::quantile(miss_in, q, names = FALSE); qo <- stats::quantile(miss_out, q, names = FALSE)
    tibble::tibble(joint = k, x = J[1], y = J[2], z = J[3],
                   deflection_deg = central, lower = qd[1], upper = qd[3],
                   miss_in = point_line_dist(J, a$anchor, a$u), miss_in_upper = qi[3],
                   miss_out = point_line_dist(J, b$anchor, b$u), miss_out_upper = qo[3],
                   assumed = isTRUE(b$assumed), joint_source = path$joint_source[k])
  })
  do.call(rbind, rows)
}

# Flatten a mixed list of trajectories and paths into segments.
flatten_trajectories <- function(x) {
  if (inherits(x, "trajectory") || inherits(x, "trajectory_path")) x <- list(x)
  out <- list()
  for (el in x) {
    if (inherits(el, "trajectory_path")) out <- c(out, el$segments)
    else if (inherits(el, "trajectory")) out <- c(out, list(el))
    else cli::cli_abort("Expected `trajectory` or `trajectory_path` objects.")
  }
  out
}

# Segments that carry information about the origin of fire: standalone
# trajectories and first segments of paths (never assumed ones).
first_segments <- function(x) {
  tl <- flatten_trajectories(x)
  Filter(function(t) (is.null(t$segment_index) || t$segment_index == 1) && !isTRUE(t$assumed), tl)
}
