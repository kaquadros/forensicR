test_that("impact angle follows asin(w/l)", {
  expect_equal(impact_angle(8, 16)$angle_deg, 30)
  expect_equal(impact_angle(10, 10)$angle_deg, 90)
  expect_error(impact_angle(12, 10))
  set.seed(1)
  a <- impact_angle(8, 16, se = 0.3)
  expect_true(a$lower < 30 && a$upper > 30)
})

test_that("trajectory_from_angles round-trips its angles", {
  t <- trajectory_from_angles(c(1, 2, 1.5), azimuth_deg = 350, vertical_deg = -8)
  expect_s3_class(t, "trajectory")
  expect_equal(t$azimuth_deg, 350)
  expect_equal(t$vertical_deg, -8)
  north <- trajectory_from_angles(c(0, 0, 0), 0, 0)
  expect_equal(north$project(5), c(0, -5, 0))
  expect_equal(dim(t$sample(10)), c(10, 3))
})

test_that("trajectory_2pt angles, projection and uncertainty", {
  t <- trajectory_2pt(c(0, 0, 0), c(0, 10, -1))
  expect_equal(t$azimuth_deg, 0)
  expect_lt(t$vertical_deg, 0)
  expect_equal(t$anchor, c(0, 10, -1))          # anchored at the impact (p2)
  expect_equal(t$project(t$length), c(0, 0, 0)) # back-projecting one length returns p1
  expect_equal(trajectory_2pt(c(0, 0, 0), c(5, 0, 0))$azimuth_deg, 90)
  expect_equal(t$se_azimuth, 0)
  t2 <- trajectory_2pt(c(0, 0, 0), c(0, 1, 0), se_position = 0.01)
  expect_gt(t2$se_vertical, 0)
})

test_that("trajectory_from_defect geometry is right", {
  # North wall (faces south = 180). Perpendicular hit: flight due north.
  perp <- trajectory_from_defect(c(0, 5, 1), 10, 10, major_axis_deg = 0,
                                 wall_azimuth_deg = 180, came_from = "above", se = 0)
  expect_equal(perp$azimuth_deg, 0, tolerance = 1e-6)
  expect_equal(perp$vertical_deg, 0, tolerance = 1e-6)
  # 30 deg to the surface, vertical major axis, came from above: 60 deg downward
  down <- trajectory_from_defect(c(0, 5, 1), 5, 10, major_axis_deg = 0,
                                 wall_azimuth_deg = 180, came_from = "above", se = 0)
  expect_equal(down$vertical_deg, -60, tolerance = 1e-6)
  expect_equal(down$azimuth_deg, 0, tolerance = 1e-6)
  # Horizontal major axis, came from the right (east): flight heads west-north
  side <- trajectory_from_defect(c(0, 5, 1), 5, 10, major_axis_deg = 90,
                                 wall_azimuth_deg = 180, came_from = "right", se = 0)
  expect_equal(side$azimuth_deg, 300, tolerance = 1e-6)
  expect_equal(side$vertical_deg, 0, tolerance = 1e-6)
  expect_error(trajectory_from_defect(c(0, 5, 1), 5, 10, 0, 180, came_from = "left"))
})

test_that("near-perpendicular ellipse draws do not pile up at exactly 90 degrees", {
  set.seed(7)
  t <- trajectory_from_defect(c(1.2, 5, 1.6), 9.3, 10.0, 85, 180, "right")
  U <- t$sample(4000)
  perp <- abs(U[, 1]) < 1e-9 & abs(U[, 3]) < 1e-9
  expect_lt(mean(perp), 0.01)
  a <- impact_angle(9.3, 10.0, se = 0.5)
  expect_lt(a$upper, 90)
  # a draw can land exactly on the ambiguous orientation: sampling must not abort
  set.seed(11)
  t2 <- trajectory_from_defect(c(1.2, 5, 1.6), 9.3, 10.0, 85, 180, "right", se_orientation = 5)
  expect_no_error(t2$sample(20000))
})

test_that("origin_zone reaches heights only when geometry allows", {
  set.seed(3)
  t <- trajectory_from_angles(c(0, 0, 1.0), 0, -10, se_azimuth = 1, se_vertical = 1)
  oz <- origin_zone(t, heights = c(standing = 1.5, low = 0.5))
  exp_hd <- 0.5 / tan(10 * pi / 180)
  expect_equal(oz$horizontal_distance[1], exp_hd, tolerance = 0.05)
  expect_equal(oz$p_reachable[1], 1)
  expect_equal(oz$p_reachable[2], 0)      # downward shot cannot come from below
  expect_true(oz$y[1] < 0)                 # shooter is south of the defect
  flat <- trajectory_from_angles(c(0, 0, 1.0), 0, 0, se_vertical = 5)
  oz2 <- origin_zone(flat, heights = c(h = 1.5), max_distance = 10)
  expect_lte(oz2$hd_upper, 10)
  expect_lt(oz2$p_reachable, 1)
})

test_that("two trajectories from one origin converge on it", {
  set.seed(4)
  origin <- c(2, -4, 1.4)
  a1 <- c(1, 3, 1.1); a2 <- c(4, 3, 0.9)
  t1 <- trajectory_2pt(origin, a1, se_position = 0.002)
  t2 <- trajectory_2pt(origin, a2, se_position = 0.002)
  ix <- intersect_trajectories(t1, t2, n_sim = 500)
  expect_equal(ix$point, origin, tolerance = 1e-6)
  expect_lt(ix$miss_distance, 1e-6)
  expect_true(ix$behind_both)
  expect_gt(ix$p_behind_both, 0.95)
})

test_that("trajectory_table and plots work", {
  t1 <- trajectory_from_angles(c(0, 0, 1), 10, -5, id = "A")
  t2 <- trajectory_from_angles(c(1, 0, 1), 350, -5, id = "B")
  tab <- trajectory_table(list(t1, t2))
  expect_equal(nrow(tab), 2)
  expect_s3_class(plot_trajectories(list(t1, t2), n_draw = 5), "ggplot")
  walls <- rbind(room_rect(0, 0, 6, 5), opening(2.5, 0, 3.5, 0, "door"), opening(0, 2, 0, 3, "window"))
  expect_equal(nrow(walls), 9)
  p <- plot_trajectories(list(t1, t2), n_draw = 5, walls = walls, convergence = TRUE)
  expect_s3_class(p, "ggplot")
  ix <- intersect_trajectories(t1, t2, n_sim = 200)
  expect_s3_class(plot_trajectories(list(t1, t2), n_draw = 5, convergence = ix), "ggplot")
  expect_s3_class(plot_scene(coords_polar(1, 45), walls = walls), "ggplot")
  expect_error(plot_trajectories(list(t1, t2), n_draw = 5, convergence = list(1)))
  expect_s3_class(plot_trajectories(t1, view = "elevation", n_draw = 5), "ggplot")
  expect_error(trajectory_table(list(1)))
})
