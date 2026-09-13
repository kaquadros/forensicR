test_that("baseline along positive x-axis is identity", {
  p <- coords_baseline(along = c(3, 5), offset = c(2, -1))
  expect_equal(p$x, c(3, 5))
  expect_equal(p$y, c(2, -1))
})

test_that("baseline respects a rotated baseline", {
  p <- coords_baseline(along = 1, offset = 0, origin = c(0, 0), end = c(0, 4))
  expect_equal(unlist(p[, c("x", "y")]), c(x = 0, y = 1))
})

test_that("triangulation recovers a 3-4-5 triangle", {
  p <- coords_triangulation(d1 = 3, d2 = 4, p1 = c(0, 0), p2 = c(5, 0))
  expect_equal(p$x, 1.8)
  expect_equal(p$y, 2.4)
  q <- coords_triangulation(3, 4, c(0, 0), c(5, 0), side = "right")
  expect_equal(q$y, -2.4)
})

test_that("triangulation warns when distances cannot meet", {
  expect_warning(p <- coords_triangulation(1, 1, c(0, 0), c(5, 0)))
  expect_true(is.na(p$x))
})

test_that("polar uses north-clockwise azimuth", {
  p <- coords_polar(distance = 10, azimuth = c(0, 90, 180, 270))
  expect_equal(round(p$x, 8), c(0, 10, 0, -10))
  expect_equal(round(p$y, 8), c(10, 0, -10, 0))
})

test_that("plot_scene returns a ggplot", {
  expect_s3_class(plot_scene(coords_polar(1, 45)), "ggplot")
})
