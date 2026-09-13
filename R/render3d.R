# 3D scene reconstruction --------------------------------------------------
#
# Two back ends share one description of the room:
#   * render_scene_3d(): photoreal still via 'rayrender' (for PDF/Word).
#   * scene_3d_widget(): interactive WebGL widget via 'rgl' (for HTML).
# Both are Suggests; functions fail with a clear message if not installed.
#
# Scene frame: x = east, y = north, z = up. rayrender uses y-up, so scene
# (x, y, z) maps to rayrender (x, z, -y), which preserves handedness.

rr <- function(p) c(p[1], p[3], -p[2])

# Text label as a quad with an RGBA alpha texture. rayrender::text3d() writes
# an RGB mask that this rayrender version ignores, so we build the RGBA file
# ourselves. `orientation = "floor"` lays the text flat; "billboard" stands
# it upright, rotated to face `camera` (scene coordinates).
rr_label <- function(label, at, height = 0.1, color = "#111111",
                     orientation = c("floor", "billboard"), camera = NULL,
                     angle_floor = 0) {
  orientation <- match.arg(orientation)
  f <- tempfile(fileext = ".png")
  n <- max(nchar(label), 1)
  # text mask drawn with base graphics: white text on black, then used as alpha
  # Linux: prefer cairo over Xlib; elsewhere leave the platform default
  # (quartz on macOS, windows on Windows), which need no X server.
  png_type <- if (Sys.info()[["sysname"]] == "Linux") {
    if (isTRUE(capabilities("cairo"))) "cairo" else "Xlib"
  } else {
    getOption("bitmapType")
  }
  grDevices::png(f, width = n * 60, height = 72, type = png_type)
  graphics::par(mar = c(0, 0, 0, 0), bg = "black")
  graphics::plot.new(); graphics::plot.window(c(0, 1), c(0, 1))
  graphics::text(0.5, 0.5, label, col = "white", cex = 3.2, font = 2)
  grDevices::dev.off()
  mask <- png::readPNG(f)
  if (length(dim(mask)) == 3) mask <- mask[, , 1]
  rgba <- array(0, c(dim(mask), 4)); rgba[, , 4] <- mask
  png::writePNG(rgba, f)
  mat <- rayrender::diffuse(color = color, alpha_texture = f)
  p <- rr(at)
  if (orientation == "floor") {
    # A floor quad reads correctly when viewed from the north; flip it 180
    # degrees about the vertical when the camera is south of the label.
    if (!is.null(camera) && camera[2] < at[2]) angle_floor <- angle_floor + 180
    return(rayrender::xz_rect(x = p[1], y = p[2], z = p[3], xwidth = n * height * 0.6,
                              zwidth = height, angle = c(0, angle_floor, 0), material = mat))
  }
  theta <- 0
  if (!is.null(camera)) {
    c3 <- rr(camera); d <- c(c3[1] - p[1], c3[3] - p[3])
    if (sum(d^2) > 0) theta <- atan2(d[1], d[2]) * 180 / pi
  }
  rayrender::xy_rect(x = p[1], y = p[2], z = p[3], xwidth = n * height * 0.6,
                     ywidth = height, angle = c(0, theta, 0), material = mat)
}

marker_label <- function(id) {
  num <- regmatches(id, regexpr("^[0-9]+", id))
  if (length(num) && nzchar(num)) num else substr(id, 1, 3)
}

room_bbox <- function(walls, points, trajectories) {
  xs <- c(walls$x, points$x); ys <- c(walls$y, points$y)
  if (length(trajectories)) {
    xs <- c(xs, vapply(trajectories, function(t) t$anchor[1], 1))
    ys <- c(ys, vapply(trajectories, function(t) t$anchor[2], 1))
  }
  list(x = range(xs, na.rm = TRUE), y = range(ys, na.rm = TRUE))
}

wall_segments <- function(walls) {
  w <- walls[walls$type == "wall", ]
  out <- list()
  for (g in unique(w$group)) {
    s <- w[w$group == g, ]
    for (i in seq_len(nrow(s) - 1)) {
      out[[length(out) + 1]] <- c(s$x[i], s$y[i], s$x[i + 1], s$y[i + 1])
    }
  }
  out
}

# Camera presets in scene coordinates -----------------------------------------
camera_preset <- function(view, bbox, walls, wall_height) {
  cx <- mean(bbox$x); cy <- mean(bbox$y)
  W <- diff(bbox$x); D <- diff(bbox$y)
  door <- walls[walls$type == "door", ]
  if (view == "door" && nrow(door)) {
    dm <- c(mean(door$x[1:2]), mean(door$y[1:2]))
    inward <- c(cx, cy) - dm; inward <- inward / sqrt(sum(inward^2))
    from <- c(dm + 0.3 * inward, 1.6)
    return(list(lookfrom = from, lookat = c(cx, cy, 1.1), fov = 70, omit = NULL))
  }
  switch(view,
    door = , corner = list(lookfrom = c(bbox$x[1] + 0.4, bbox$y[1] + 0.4, 1.6),
                           lookat = c(cx, cy, 1.0), fov = 90, omit = NULL),
    overhead = list(lookfrom = c(cx, cy - 0.01, max(W, D) * 1.6),
                    lookat = c(cx, cy, 0), fov = 50, omit = NULL),
    dollhouse = list(lookfrom = c(cx, bbox$y[1] - max(W, D) * 1.0, wall_height * 2.6),
                     lookat = c(cx, cy, wall_height / 2.5), fov = 45, omit = "south"))
}

#' Render a 3D reconstruction of the scene (rayrender)
#'
#' Builds a schematic, to-scale 3D model of the room from the same objects
#' used by the 2D plots and renders it with 'rayrender': walls with door and
#' window panels, a floor grid with numbered x/y axes, numbered evidence
#' markers, bullet defects at their measured height, schematic bloodstain
#' discs, trajectories as rods and their angular uncertainty as translucent
#' cones. Deliberately schematic: courtroom demonstratives must be accurate
#' and non-prejudicial, so nothing is rendered photo-realistically.
#'
#' @param walls Walls tibble; see [room_rect()] and [opening()].
#' @param points Optional scene points tibble (`z` and `type` used).
#' @param trajectories Optional `trajectory` or list of them.
#' @param file Output PNG path.
#' @param view Camera preset: `"door"` (inside, at the door, eye level),
#'   `"corner"`, `"overhead"`, or `"dollhouse"` (from outside, south wall
#'   removed). Ignored if `lookfrom` is given.
#' @param lookfrom,lookat Optional explicit camera position and target in
#'   scene coordinates `c(x, y, z)`.
#' @param fov Field of view in degrees. Default depends on `view`.
#' @param furniture Optional `furniture` tibble; see [furniture()]. Objects
#'   are drawn as semi-transparent boxes (or cylinders) with a label on top.
#' @param furniture_alpha Optional opacity overriding every object's own.
#' @param wall_height Ceiling height.
#' @param back Length of trajectory rods behind the defect.
#' @param cone Logical. Draw the uncertainty cone for each trajectory.
#' @param grid Grid spacing, scene units. `0` disables all grid lines.
#' @param grid_on Where to draw grid lines: any of `"floor"` and `"walls"`
#'   (wall grids carry the z axis: verticals at each x/y tick and horizontals
#'   at each height tick). Use `"none"` for no lines but keep labels.
#' @param grid_strength Number in 0 to 1 controlling how strongly grid lines
#'   stand out (line darkness and thickness). Wall lines are always drawn
#'   fainter than floor lines.
#' @param grid_labels Logical. Draw the numbers: x/y along the floor edges and
#'   z at the start of each wall's horizontal grid line.
#' @param omit_wall Optional side (`"north"`, `"south"`, `"east"`, `"west"`)
#'   to leave out so an outside camera can see in.
#' @param width,height,samples Passed to [rayrender::render_scene()].
#' @param ... Further arguments to [rayrender::render_scene()].
#' @return The output file path, invisibly.
#' @export
render_scene_3d <- function(walls, points = NULL, trajectories = NULL,
                            furniture = NULL, furniture_alpha = NULL,
                            file = "scene3d.png",
                            view = c("door", "corner", "overhead", "dollhouse"),
                            lookfrom = NULL, lookat = NULL, fov = NULL,
                            wall_height = 2.5, back = 3, cone = TRUE, grid = 1,
                            grid_on = c("floor", "walls"), grid_strength = 0.6,
                            grid_labels = TRUE, omit_wall = NULL,
                            width = 1000, height = 750, samples = 128, ...) {
  if (!requireNamespace("rayrender", quietly = TRUE)) {
    cli::cli_abort("Install {.pkg rayrender} to render 3D scenes.")
  }
  view <- match.arg(view)
  grid_on <- match.arg(grid_on, c("floor", "walls", "none"), several.ok = TRUE)
  grid_strength <- min(max(grid_strength, 0), 1)
  tl <- if (is.null(trajectories)) list() else as_traj_list(trajectories)
  if (!"type" %in% names(walls)) walls$type <- "wall"
  bbox <- room_bbox(walls, points, tl)
  cam <- camera_preset(view, bbox, walls, wall_height)
  if (is.null(lookfrom)) lookfrom <- cam$lookfrom
  if (is.null(lookat)) {
    lookat <- cam$lookat
    if (view %in% c("door", "corner") && length(tl)) {
      anc <- t(vapply(tl, `[[`, numeric(3), "anchor"))
      lookat <- c(colMeans(anc)[1:2], min(1.3, mean(anc[, 3])))
    }
  }
  if (is.null(fov)) fov <- cam$fov
  if (is.null(omit_wall)) omit_wall <- cam$omit

  R <- rayrender::diffuse
  wall_col <- "#ddd8ce"
  scene <- rayrender::xz_rect(x = mean(bbox$x), z = -mean(bbox$y), y = 0,
                              xwidth = diff(bbox$x) + 0.4, zwidth = diff(bbox$y) + 0.4,
                              material = R(color = "#d9d3c7"))
  # light: large soft panel above the room
  scene <- rayrender::add_object(scene, rayrender::xz_rect(
    x = mean(bbox$x), z = -mean(bbox$y), y = wall_height + 2.5,
    xwidth = diff(bbox$x) * 1.5, zwidth = diff(bbox$y) * 1.5, flipped = TRUE,
    material = rayrender::light(intensity = 1.5, invisible = TRUE)))

  # walls
  omit_seg <- function(seg) {
    if (is.null(omit_wall)) return(FALSE)
    mid <- c(mean(seg[c(1, 3)]), mean(seg[c(2, 4)]))
    switch(omit_wall,
      south = isTRUE(all.equal(mid[2], bbox$y[1])), north = isTRUE(all.equal(mid[2], bbox$y[2])),
      west  = isTRUE(all.equal(mid[1], bbox$x[1])), east  = isTRUE(all.equal(mid[1], bbox$x[2])),
      FALSE)
  }
  for (seg in wall_segments(walls)) {
    if (omit_seg(seg)) next
    dx <- seg[3] - seg[1]; dy <- seg[4] - seg[2]; L <- sqrt(dx^2 + dy^2)
    mid <- c(mean(seg[c(1, 3)]), mean(seg[c(2, 4)]))
    scene <- rayrender::add_object(scene, rayrender::cube(
      x = mid[1], y = wall_height / 2, z = -mid[2],
      xwidth = L, ywidth = wall_height, zwidth = 0.1,
      angle = c(0, atan2(dy, dx) * 180 / pi, 0), material = R(color = wall_col)))
  }
  # door / window panels, slightly proud of the wall face on both sides
  for (g in unique(walls$group[walls$type %in% c("door", "window")])) {
    s <- walls[walls$group == g, ]
    if (omit_seg(c(s$x[1], s$y[1], s$x[2], s$y[2]))) next
    dx <- s$x[2] - s$x[1]; dy <- s$y[2] - s$y[1]; L <- sqrt(dx^2 + dy^2)
    mid <- c(mean(s$x[1:2]), mean(s$y[1:2]))
    is_door <- s$type[1] == "door"
    zc <- if (is_door) 1.0 else 1.5; h <- if (is_door) 2.0 else 1.2
    scene <- rayrender::add_object(scene, rayrender::cube(
      x = mid[1], y = zc, z = -mid[2], xwidth = L, ywidth = h, zwidth = 0.14,
      angle = c(0, atan2(dy, dx) * 180 / pi, 0),
      material = R(color = if (is_door) "#8c6b4a" else "#9fc5e8")))
  }
  # grid: floor lines, wall lines (z axis), numbered axes
  mix <- function(a, b, w) grDevices::rgb(t((1 - w) * grDevices::col2rgb(a) + w * grDevices::col2rgb(b)) / 255)
  floor_col <- mix("#d9d3c7", "#3a3a3a", 0.25 + 0.75 * grid_strength)
  wallgrid_col <- mix(wall_col, "#3a3a3a", 0.15 + 0.45 * grid_strength)
  floor_r <- 0.003 + 0.006 * grid_strength
  wall_r <- 0.002 + 0.003 * grid_strength
  if (grid > 0) {
    xt <- seq(ceiling(bbox$x[1]), floor(bbox$x[2]), by = grid)
    yt <- seq(ceiling(bbox$y[1]), floor(bbox$y[2]), by = grid)
    zt <- seq(grid, wall_height - 1e-9, by = grid)
    if ("floor" %in% grid_on) {
      for (x in xt) scene <- rayrender::add_object(scene, rayrender::segment(
        start = rr(c(x, bbox$y[1], 0.004)), end = rr(c(x, bbox$y[2], 0.004)), radius = floor_r,
        material = R(color = floor_col)))
      for (y in yt) scene <- rayrender::add_object(scene, rayrender::segment(
        start = rr(c(bbox$x[1], y, 0.004)), end = rr(c(bbox$x[2], y, 0.004)), radius = floor_r,
        material = R(color = floor_col)))
    }
    if ("walls" %in% grid_on) {
      cx <- mean(bbox$x); cy <- mean(bbox$y)
      for (seg in wall_segments(walls)) {
        if (omit_seg(seg)) next
        a2 <- seg[1:2]; b2 <- seg[3:4]; d2 <- b2 - a2; L <- sqrt(sum(d2^2))
        u2 <- d2 / L; n2 <- c(-u2[2], u2[1])
        if (sum(n2 * (c(cx, cy) - a2)) < 0) n2 <- -n2       # inward normal
        off <- 0.056 * n2                                     # just proud of the wall face
        # verticals: where the wall crosses an x or y tick (axis-aligned walls)
        ticks <- c()
        if (abs(u2[2]) < 1e-9) ticks <- (xt - a2[1]) / u2[1]
        else if (abs(u2[1]) < 1e-9) ticks <- (yt - a2[2]) / u2[2]
        else ticks <- seq(grid, L - 1e-9, by = grid)
        ticks <- ticks[ticks > 0.02 & ticks < L - 0.02]
        for (tk in ticks) {
          p2 <- a2 + tk * u2 + off
          scene <- rayrender::add_object(scene, rayrender::segment(
            start = rr(c(p2, 0)), end = rr(c(p2, wall_height)), radius = wall_r,
            material = R(color = wallgrid_col)))
        }
        for (z in zt) {
          scene <- rayrender::add_object(scene, rayrender::segment(
            start = rr(c(a2 + off, z)), end = rr(c(b2 + off, z)), radius = wall_r,
            material = R(color = wallgrid_col)))
          if (grid_labels) {
            # height number at the start of each wall line, like the x/y numbers on the floor
            lp <- a2 + 0.22 * u2 + 0.16 * n2
            scene <- rayrender::add_object(scene, rr_label(
              format(z), c(lp, z + 0.11), height = 0.2, color = "#1f3a93",
              orientation = "billboard", camera = lookfrom))
          }
        }
      }
    }
    if (grid_labels) {
      for (x in xt) scene <- rayrender::add_object(scene, rr_label(
        format(x), c(x, bbox$y[1] + 0.25, 0.01), height = 0.24, color = "#1f3a93", camera = lookfrom))
      for (y in yt) scene <- rayrender::add_object(scene, rr_label(
        format(y), c(bbox$x[1] + 0.25, y, 0.01), height = 0.24, color = "#1f3a93", camera = lookfrom))
    }
  }
  # furniture / objects: semi-transparent boxes via a uniform alpha texture
  if (!is.null(furniture) && nrow(furniture)) {
    alpha_files <- list()
    alpha_file <- function(a) {
      key <- sprintf("%.3f", a)
      if (is.null(alpha_files[[key]])) {
        f <- tempfile(fileext = ".png"); arr <- array(0, c(4, 4, 4)); arr[, , 4] <- a
        png::writePNG(arr, f); alpha_files[[key]] <<- f
      }
      alpha_files[[key]]
    }
    for (i in seq_len(nrow(furniture))) {
      r <- furniture[i, ]
      al <- if (is.null(furniture_alpha)) r$alpha else furniture_alpha
      mat <- if (al >= 0.999) R(color = r$colour) else R(color = r$colour, alpha_texture = alpha_file(al))
      if (r$shape == "circle") {
        scene <- rayrender::add_object(scene, rayrender::cylinder(
          x = r$x, y = r$z0 + r$height / 2, z = -r$y, radius = r$width / 2,
          length = r$height, material = mat))
        cx <- r$x; cy <- r$y
      } else {
        a <- r$angle * pi / 180
        ex <- c(cos(a), sin(a)); ey <- c(-sin(a), cos(a))
        nstep <- if (!is.na(r$steps) && r$steps > 0) r$steps else 1L
        for (k in seq_len(nstep)) {
          w_k <- r$width / nstep
          h_k <- if (nstep > 1) r$height * k / nstep else r$height
          c0 <- c(r$x, r$y) + ((k - 0.5) * w_k) * ex + (r$depth / 2) * ey
          scene <- rayrender::add_object(scene, rayrender::cube(
            x = c0[1], y = r$z0 + h_k / 2, z = -c0[2],
            xwidth = w_k, ywidth = h_k, zwidth = r$depth,
            angle = c(0, r$angle, 0), material = mat))
        }
        cc <- c(r$x, r$y) + (r$width / 2) * ex + (r$depth / 2) * ey
        cx <- cc[1]; cy <- cc[2]
      }
      scene <- rayrender::add_object(scene, rr_label(
        r$id, c(cx, cy, r$z0 + r$height + 0.16), height = 0.14, color = "#222222",
        orientation = "billboard", camera = lookfrom))
    }
  }
  # points
  if (!is.null(points) && nrow(points)) {
    if (!"z" %in% names(points)) points$z <- NA_real_
    if (!"type" %in% names(points)) points$type <- "evidence"
    for (i in seq_len(nrow(points))) {
      px <- points$x[i]; py <- points$y[i]; pz <- points$z[i]; ty <- points$type[i]
      if (is.na(px) || is.na(py)) next
      if (ty == "bloodstain") {
        scene <- rayrender::add_object(scene, rayrender::disk(
          x = px, y = 0.004, z = -py, radius = 0.18, material = R(color = "#8b1a1a")))
      } else if (ty == "defect") {
        zz <- if (is.na(pz)) 1.0 else pz
        scene <- rayrender::add_object(scene, rayrender::sphere(
          x = px, y = zz, z = -py, radius = 0.04, material = R(color = "#111111")))
        scene <- rayrender::add_object(scene, rr_label(
          marker_label(points$id[i]), c(px, py, zz + 0.14), height = 0.14,
          orientation = "billboard", camera = lookfrom))
      } else {
        # numbered evidence marker: yellow tent card with the number on both faces
        lab <- marker_label(points$id[i])
        scene <- rayrender::add_object(scene, rayrender::cube(
          x = px, y = 0.08, z = -py, xwidth = 0.2, ywidth = 0.16, zwidth = 0.03,
          material = R(color = "#f5c518")))
        scene <- rayrender::add_object(scene, rr_label(
          lab, c(px, py, 0.28), height = 0.16, orientation = "billboard", camera = lookfrom))
      }
    }
  }
  # trajectories
  pal <- c("#c1121f", "#0b7a75", "#1d4ed8", "#e07a00", "#6a1b9a")
  colour_key <- unique(vapply(tl, function(t) t$path_id %||% t$id, ""))
  for (k in seq_along(tl)) {
    t <- tl[[k]]
    col <- pal[(match(t$path_id %||% t$id, colour_key) - 1) %% length(pal) + 1]
    is_assumed <- isTRUE(t$assumed)
    seg_len <- if (!is.null(t$start)) sqrt(sum((t$anchor - t$start)^2)) else back
    a <- t$anchor; b <- if (!is.null(t$start)) t$start else t$project(back)
    if (!is_assumed) {
      scene <- rayrender::add_object(scene, rayrender::sphere(
        x = a[1], y = a[3], z = -a[2], radius = 0.045, material = R(color = "#111111")))
      scene <- rayrender::add_object(scene, rayrender::cone(
        start = rr(a - 0.25 * t$u), end = rr(a - 0.02 * t$u), radius = 0.07,
        material = R(color = col)))
    }
    scene <- rayrender::add_object(scene, rayrender::segment(
      start = rr(a), end = rr(b), radius = if (is_assumed) 0.010 else 0.022, material = R(color = col)))
    if (!is.null(t$start) && !is.null(t$segment_index) && t$segment_index > 1) {
      prev <- Filter(function(u) identical(u$path_id, t$path_id) &&
                       identical(u$segment_index, t$segment_index - 1L), tl)
      if (length(prev)) scene <- rayrender::add_object(scene, rayrender::segment(
        start = rr(prev[[1]]$anchor), end = rr(t$start), radius = 0.008, material = R(color = "#777777")))
    }
    draw_cone <- cone && (is.null(t$segment_index) || t$segment_index == 1 || is_assumed)
    if (draw_cone) {
      if (is_assumed) { a <- t$start; b <- t$anchor; back_k <- seg_len } else back_k <- seg_len
      # wireframe cone: generators from the defect to a ring at `back`
      se <- sqrt(t$se_azimuth^2 + t$se_vertical^2) * pi / 180
      radius <- back_k * tan(min(se, 60 * pi / 180))
      if (is.finite(radius) && radius > 0.005) {
        u <- t$u
        v1 <- c(-u[2], u[1], 0); if (sum(v1^2) < 1e-9) v1 <- c(1, 0, 0)
        v1 <- v1 / sqrt(sum(v1^2)); v2 <- c(u[2] * v1[3] - u[3] * v1[2],
                                            u[3] * v1[1] - u[1] * v1[3],
                                            u[1] * v1[2] - u[2] * v1[1])
        ring <- lapply(seq(0, 2 * pi, length.out = 25), function(th)
          b + radius * (cos(th) * v1 + sin(th) * v2))
        for (i in seq_len(24)) scene <- rayrender::add_object(scene, rayrender::segment(
          start = rr(ring[[i]]), end = rr(ring[[i + 1]]), radius = 0.009, material = R(color = col)))
        for (i in seq(1, 24, by = 3)) scene <- rayrender::add_object(scene, rayrender::segment(
          start = rr(a), end = rr(ring[[i]]), radius = 0.006, material = R(color = col)))
      }
    }
    # label pulled 0.12 units back along the flight line so it is not buried
    # inside the wall thickness when the defect sits on a wall
    a <- t$anchor
    lp <- a - 0.12 * t$u
    scene <- rayrender::add_object(scene, rr_label(
      t$id, c(lp[1], lp[2], a[3] + 0.22), height = 0.15, color = col,
      orientation = "billboard", camera = lookfrom))
  }
  rayrender::render_scene(
    scene, width = width, height = height, fov = fov, samples = samples,
    lookfrom = rr(lookfrom), lookat = rr(lookat), aperture = 0,
    filename = file, preview = FALSE, interactive = FALSE, progress = FALSE,
    ambient_light = TRUE, backgroundhigh = "#c9d6e3", backgroundlow = "#f4f4f4", ...)
  invisible(file)
}

#' Interactive 3D scene widget (rgl / WebGL)
#'
#' Same schematic model as [render_scene_3d()], as an interactive widget the
#' reader can rotate, zoom and walk around in an HTML report. Walls are
#' semi-transparent so the inside stays visible from any angle.
#'
#' @inheritParams render_scene_3d
#' @param wall_alpha Wall transparency (0 to 1).
#' @inheritParams render_scene_3d
#' @param n_cone Number of lines used to sketch each uncertainty cone.
#' @param width,height Widget size in pixels.
#' @return An `rglwidget` htmlwidget.
#' @export
scene_3d_widget <- function(walls, points = NULL, trajectories = NULL,
                            furniture = NULL, furniture_alpha = NULL,
                            wall_height = 2.5, back = 3, cone = TRUE, grid = 1,
                            grid_on = c("floor", "walls"), grid_strength = 0.6,
                            grid_labels = TRUE, wall_alpha = 0.35, n_cone = 24,
                            width = 800, height = 600) {
  if (!requireNamespace("rgl", quietly = TRUE)) {
    cli::cli_abort("Install {.pkg rgl} to build interactive 3D scenes.")
  }
  tl <- if (is.null(trajectories)) list() else as_traj_list(trajectories)
  if (!"type" %in% names(walls)) walls$type <- "wall"
  bbox <- room_bbox(walls, points, tl)
  old <- options(rgl.useNULL = TRUE); on.exit(options(old), add = TRUE)
  rgl::open3d(useNULL = TRUE)
  rgl::bg3d("white")
  # floor
  rgl::quads3d(c(bbox$x[1], bbox$x[2], bbox$x[2], bbox$x[1]),
               c(bbox$y[1], bbox$y[1], bbox$y[2], bbox$y[2]), rep(0, 4),
               col = "#d9d3c7", lit = FALSE)
  grid_on <- match.arg(grid_on, c("floor", "walls", "none"), several.ok = TRUE)
  grid_strength <- min(max(grid_strength, 0), 1)
  if (grid > 0) {
    xt <- seq(ceiling(bbox$x[1]), floor(bbox$x[2]), by = grid)
    yt <- seq(ceiling(bbox$y[1]), floor(bbox$y[2]), by = grid)
    zt <- seq(grid, wall_height - 1e-9, by = grid)
    if ("floor" %in% grid_on) {
      for (x in xt) rgl::lines3d(c(x, x), bbox$y, c(0.002, 0.002), col = "grey30",
                                 alpha = 0.3 + 0.7 * grid_strength, lwd = 1 + grid_strength)
      for (y in yt) rgl::lines3d(bbox$x, c(y, y), c(0.002, 0.002), col = "grey30",
                                 alpha = 0.3 + 0.7 * grid_strength, lwd = 1 + grid_strength)
    }
    if ("walls" %in% grid_on) {
      cx <- mean(bbox$x); cy <- mean(bbox$y)
      for (seg in wall_segments(walls)) {
        a2 <- seg[1:2]; b2 <- seg[3:4]; d2 <- b2 - a2; L <- sqrt(sum(d2^2))
        u2 <- d2 / L; n2 <- c(-u2[2], u2[1])
        if (sum(n2 * (c(cx, cy) - a2)) < 0) n2 <- -n2
        off <- 0.01 * n2
        ticks <- if (abs(u2[2]) < 1e-9) (xt - a2[1]) / u2[1] else if (abs(u2[1]) < 1e-9) (yt - a2[2]) / u2[2] else seq(grid, L - 1e-9, by = grid)
        ticks <- ticks[ticks > 0.02 & ticks < L - 0.02]
        al <- 0.15 + 0.45 * grid_strength
        for (tk in ticks) { p2 <- a2 + tk * u2 + off
          rgl::lines3d(c(p2[1], p2[1]), c(p2[2], p2[2]), c(0, wall_height), col = "grey30", alpha = al) }
        for (z in zt) {
          rgl::lines3d(c(a2[1], b2[1]) + off[1], c(a2[2], b2[2]) + off[2], c(z, z),
                       col = "grey30", alpha = al)
          if (grid_labels) { lp <- a2 + 0.22 * u2 + 0.16 * n2
            rgl::text3d(lp[1], lp[2], z + 0.1, texts = format(z), col = "#1f3a93", cex = 0.7) }
        }
      }
    }
    if (grid_labels) {
      rgl::text3d(xt, bbox$y[1] - 0.25, 0.01, texts = format(xt), col = "#1f3a93", cex = 0.8)
      rgl::text3d(bbox$x[1] - 0.25, yt, 0.01, texts = format(yt), col = "#1f3a93", cex = 0.8)
    }
  }
  for (seg in wall_segments(walls)) {
    rgl::quads3d(c(seg[1], seg[3], seg[3], seg[1]), c(seg[2], seg[4], seg[4], seg[2]),
                 c(0, 0, wall_height, wall_height), col = "#b8b2a7", alpha = wall_alpha, lit = FALSE)
    rgl::lines3d(c(seg[1], seg[3]), c(seg[2], seg[4]), c(wall_height, wall_height), col = "grey20")
  }
  for (g in unique(walls$group[walls$type %in% c("door", "window")])) {
    s <- walls[walls$group == g, ]
    is_door <- s$type[1] == "door"
    z0 <- if (is_door) 0 else 0.9; z1 <- if (is_door) 2.0 else 2.1
    rgl::quads3d(c(s$x[1], s$x[2], s$x[2], s$x[1]), c(s$y[1], s$y[2], s$y[2], s$y[1]),
                 c(z0, z0, z1, z1), col = if (is_door) "#8c6b4a" else "#9fc5e8", alpha = 0.8, lit = FALSE)
  }
  if (!is.null(furniture) && nrow(furniture)) {
    fp <- furniture_footprint(furniture)
    for (i in seq_len(nrow(furniture))) {
      r <- furniture[i, ]
      al <- if (is.null(furniture_alpha)) r$alpha else furniture_alpha
      v <- fp[fp$id == r$id, ]
      nstep <- if (!is.na(r$steps) && r$steps > 0 && r$shape == "rect") r$steps else 1L
      if (nstep > 1) {
        a <- r$angle * pi / 180; ex <- c(cos(a), sin(a)); ey <- c(-sin(a), cos(a))
        for (k in seq_len(nstep)) {
          w_k <- r$width / nstep; h_k <- r$height * k / nstep
          c0 <- c(r$x, r$y) + ((k - 1) * w_k) * ex
          cs <- rbind(c(0, 0), c(w_k, 0), c(w_k, r$depth), c(0, r$depth))
          vx <- c0[1] + cs[, 1] * ex[1] + cs[, 2] * ey[1]; vy <- c0[2] + cs[, 1] * ex[2] + cs[, 2] * ey[2]
          rgl_extrude(vx, vy, r$z0, r$z0 + h_k, r$colour, al)
        }
      } else {
        rgl_extrude(v$x, v$y, r$z0, r$z0 + r$height, r$colour, al)
      }
      rgl::text3d(mean(v$x), mean(v$y), r$z0 + r$height + 0.12, texts = r$id, cex = 0.7)
    }
  }
  if (!is.null(points) && nrow(points)) {
    if (!"z" %in% names(points)) points$z <- NA_real_
    if (!"type" %in% names(points)) points$type <- "evidence"
    for (i in seq_len(nrow(points))) {
      px <- points$x[i]; py <- points$y[i]; pz <- points$z[i]; ty <- points$type[i]
      if (is.na(px) || is.na(py)) next
      if (ty == "bloodstain") {
        th <- seq(0, 2 * pi, length.out = 40)
        rgl::polygon3d(px + 0.15 * cos(th), py + 0.15 * sin(th), rep(0.003, 40), col = "#8b1a1a", lit = FALSE)
      } else if (ty == "defect") {
        rgl::spheres3d(px, py, if (is.na(pz)) 1 else pz, radius = 0.03, col = "black")
        rgl::text3d(px, py, (if (is.na(pz)) 1 else pz) + 0.1, texts = points$id[i], cex = 0.7)
      } else {
        rgl::spheres3d(px, py, 0.06, radius = 0.06, col = "#f5c518")
        rgl::text3d(px, py, 0.22, texts = marker_label(points$id[i]), cex = 0.8, font = 2)
      }
    }
  }
  pal <- c("#d7263d", "#1b998b", "#2e86de", "#f4a259", "#6a4c93")
  colour_key <- unique(vapply(tl, function(t) t$path_id %||% t$id, ""))
  for (k in seq_along(tl)) {
    t <- tl[[k]]
    col <- pal[(match(t$path_id %||% t$id, colour_key) - 1) %% length(pal) + 1]
    is_assumed <- isTRUE(t$assumed)
    seg_len <- if (!is.null(t$start)) sqrt(sum((t$anchor - t$start)^2)) else back
    a <- t$anchor; b <- if (!is.null(t$start)) t$start else t$project(back)
    if (!is_assumed) rgl::spheres3d(a[1], a[2], a[3], radius = 0.035, col = "black")
    rgl::lines3d(c(a[1], b[1]), c(a[2], b[2]), c(a[3], b[3]), col = col, lwd = if (is_assumed) 2 else 5)
    if (!is.null(t$start) && !is.null(t$segment_index) && t$segment_index > 1) {
      prev <- Filter(function(u) identical(u$path_id, t$path_id) &&
                       identical(u$segment_index, t$segment_index - 1L), tl)
      if (length(prev)) { pa <- prev[[1]]$anchor
        rgl::lines3d(c(pa[1], t$start[1]), c(pa[2], t$start[2]), c(pa[3], t$start[3]), col = "grey40", lwd = 2) }
    }
    rgl::text3d(a[1], a[2], a[3] + 0.12, texts = t$id, cex = 0.75)
    draw_cone <- cone && (is.null(t$segment_index) || t$segment_index == 1 || is_assumed)
    if (draw_cone) {
      U <- t$sample(n_cone)
      for (j in seq_len(nrow(U))) {
        e <- if (is_assumed) t$start + seg_len * U[j, ] else a - seg_len * U[j, ]
        rgl::lines3d(c(a[1], e[1]), c(a[2], e[2]), c(a[3], e[3]), col = col, alpha = 0.25, lwd = 1)
      }
    }
  }
  rgl::aspect3d("iso")
  rgl::view3d(theta = 20, phi = -60, zoom = 0.8)
  rgl::rglwidget(width = width, height = height)
}


# Extrude a footprint polygon (vx, vy) from z0 to z1 as rgl quads + top face.
rgl_extrude <- function(vx, vy, z0, z1, col, alpha) {
  n <- length(vx); j <- c(2:n, 1)
  qx <- as.vector(rbind(vx, vx[j], vx[j], vx)); qy <- as.vector(rbind(vy, vy[j], vy[j], vy))
  qz <- rep(c(z0, z0, z1, z1), n)
  rgl::quads3d(qx, qy, qz, col = col, alpha = alpha, lit = TRUE)
  if (n == 4) rgl::quads3d(vx, vy, rep(z1, 4), col = col, alpha = alpha, lit = TRUE)
  else rgl::polygon3d(vx, vy, rep(z1, n), col = col, alpha = alpha, lit = TRUE)
}
