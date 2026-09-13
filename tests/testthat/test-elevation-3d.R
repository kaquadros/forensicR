walls <- rbind(room_rect(0, 0, 6, 5), opening(2.5, 0, 3.5, 0, "door"), opening(0, 2.0, 0, 3.2, "window"))
pts <- rbind(
  coords_baseline(c(1.5, 4.8), c(0.9, 0.4), end = c(6, 0), id = c("1 Case", "3 Firearm")),
  coords_polar(3.6, 15, station = c(3, -2), id = "6 Defect", z = 1.35, type = "defect"))
t1 <- trajectory_from_angles(c(2.0, 5.0, 1.35), 352, -3, id = "D2")

test_that("scene points carry z and type", {
  expect_true(all(c("z", "type") %in% names(pts)))
  expect_equal(pts$z[3], 1.35)
  expect_equal(pts$type, c("evidence", "evidence", "defect"))
  expect_error(coords_polar(1, 0, type = "gun"))
})

test_that("wall_from_room orders end points as seen from inside", {
  expect_equal(wall_from_room(walls, "north"), c(0, 5, 6, 5))
  expect_equal(wall_from_room(walls, "south"), c(6, 0, 0, 0))
  expect_equal(wall_from_room(walls, "east"), c(6, 5, 6, 0))
  expect_equal(wall_from_room(walls, "west"), c(0, 0, 0, 5))
  expect_error(wall_from_room(walls, "north", id = "nope"))
})

test_that("plot_wall_elevation selects items on that wall only", {
  p <- plot_wall_elevation(wall_from_room(walls, "north"), pts, t1, walls, tol = 0.2)
  expect_s3_class(p, "ggplot")
  d <- ggplot2::layer_data(p, 2)         # items layer (rect is layer 1)
  expect_true(any(abs(d$x - 2.0) < 1e-6 & abs(d$y - 1.35) < 1e-6))  # D2 anchor
  expect_false(any(abs(d$x - 1.5) < 1e-6 & abs(d$y - 0) < 1e-6))     # floor item not on wall
  pw <- plot_wall_elevation(wall_from_room(walls, "west"), pts, walls = walls)
  expect_s3_class(pw, "ggplot")
})

test_that("3D renderers run when their packages are available", {
  skip_if_not_installed("rgl")
  w <- scene_3d_widget(walls, pts, t1, n_cone = 4)
  expect_s3_class(w, "htmlwidget")
  expect_s3_class(scene_3d_widget(walls, pts, t1, n_cone = 4, grid_on = "none", grid_labels = FALSE), "htmlwidget")
  expect_s3_class(scene_3d_widget(walls, pts, t1, n_cone = 4, grid_on = "walls", grid_strength = 1), "htmlwidget")
  skip_if_not_installed("rayrender")
  skip_on_cran()
  f <- withr::local_tempfile(fileext = ".png")
  render_scene_3d(walls, pts, t1, file = f, view = "dollhouse", width = 60, height = 40, samples = 2)
  expect_true(file.exists(f))
})
