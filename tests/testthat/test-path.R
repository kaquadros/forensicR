# Shot from S through a table (entry E, exit X) to the wall (W)
S <- c(2.4, 2.0, 1.5); E <- c(4.0, 2.6, 0.5); X <- c(4.25, 3.1, 0.45); W <- c(4.9, 5.0, 0.2)
s1 <- trajectory_2pt(S, E, se_position = 0.005, id = "into table")
s2 <- trajectory_2pt(X, W, se_position = 0.005, id = "to wall")

test_that("trajectory_path orders segments and finds joints", {
  p <- trajectory_path(s1, s2, id = "Shot 4")
  expect_s3_class(p, "trajectory_path")
  expect_equal(p$joints[[1]], X)
  expect_equal(p$joint_source, "first point of next segment")
  expect_equal(p$segments[[2]]$start, X)
  expect_equal(p$segments[[1]]$segment_index, 1)
  expect_error(trajectory_path(s1))
  expect_error(trajectory_path(s1, s2, joints = list(X, X)))
  # explicit joint and thin-target fallback
  s2a <- trajectory_from_angles(W, s2$azimuth_deg, s2$vertical_deg, id = "to wall (rod)")
  p2 <- trajectory_path(s1, s2a)
  expect_equal(p2$joints[[1]], E)
  expect_match(p2$joint_source, "thin target")
  p3 <- trajectory_path(s1, s2a, joints = list(X))
  expect_equal(p3$joints[[1]], X)
})

test_that("deflection angle and joint consistency are right", {
  set.seed(2)
  p <- trajectory_path(s1, s2, id = "Shot 4")
  d <- path_deflections(p, n_sim = 2000)
  u1 <- (E - S) / sqrt(sum((E - S)^2)); u2 <- (W - X) / sqrt(sum((W - X)^2))
  expect_equal(d$deflection_deg, acos(sum(u1 * u2)) * 180 / pi, tolerance = 1e-6)
  expect_true(d$lower < d$deflection_deg && d$upper > d$deflection_deg)
  expect_lt(d$miss_out, 1e-6)              # joint lies on segment 2 by construction
  expect_gt(d$miss_in, 0.05)               # ... but not on the continuation of segment 1
  expect_false(d$assumed)
})

test_that("assumed segments continue the previous direction with a cone", {
  set.seed(3)
  a <- assumed_segment(s1, joint = X, length = 2, se_deflection = 10, id = "after table")
  expect_true(a$assumed)
  expect_equal(a$u, s1$u)
  expect_equal(a$start, X)
  U <- a$sample(3000)
  ang <- acos(pmin(U %*% s1$u, 1)) * 180 / pi
  expect_equal(mean(ang), 10 * sqrt(2 / pi), tolerance = 0.15)   # mean of |N(0, 10)|
  p <- trajectory_path(s1, a, id = "Shot 5")
  expect_true(path_deflections(p, n_sim = 500)$assumed)
  expect_error(origin_zone(a))
})

test_that("paths work in origin_zone, tables, plots and 3D", {
  set.seed(4)
  p <- trajectory_path(s1, s2, id = "Shot 4")
  oz <- origin_zone(p, heights = c(standing = 1.5), max_distance = 12)
  expect_equal(oz$horizontal_distance, sqrt(sum((E - S)[1:2]^2)), tolerance = 0.05)
  tt <- trajectory_table(list(p, s1))
  expect_equal(tt$path, c("Shot 4", "Shot 4", NA))
  expect_equal(tt$segment, c(1L, 2L, NA))
  expect_s3_class(plot_trajectories(p, n_draw = 5), "ggplot")
  expect_s3_class(plot_trajectories(p, view = "elevation", n_draw = 5), "ggplot")
  a <- assumed_segment(s1, joint = X, id = "after table")
  expect_s3_class(plot_trajectories(trajectory_path(s1, a), n_draw = 5, convergence = TRUE), "ggplot")
  walls <- room_rect(0, 0, 6, 5)
  skip_if_not_installed("rgl")
  expect_s3_class(scene_3d_widget(walls, NULL, list(p, trajectory_path(s1, a)), n_cone = 3), "htmlwidget")
  skip_if_not_installed("rayrender"); skip_on_cran()
  f <- withr::local_tempfile(fileext = ".png")
  render_scene_3d(walls, NULL, list(p, trajectory_path(s1, a)), file = f, view = "dollhouse",
                  width = 60, height = 40, samples = 2)
  expect_true(file.exists(f))
})
