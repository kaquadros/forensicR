walls <- rbind(room_rect(0, 0, 6, 5), opening(2.5, 0, 3.5, 0, "door"))
f <- rbind(
  along_wall(walls, "north", from = 0.5, length = 2.1, depth = 0.9, id = "Sofa", type = "sofa"),
  along_wall(walls, "east", from = 1.0, length = 0.6, depth = 0.6, id = "Wardrobe", type = "wardrobe"),
  furniture("Table", "table", x = 3.0, y = 2.0, width = 1.2, depth = 0.8, angle = 15, measured = FALSE),
  furniture("Stool", "chair", x = 1.5, y = 1.2, diameter = 0.4, shape = "circle"),
  furniture("Stairs", "stairs", x = 4.5, y = 0.2, width = 1.2, depth = 0.9, steps = 6)
)

test_that("furniture constructors fill defaults and validate", {
  expect_s3_class(f, "furniture")
  expect_equal(f$height[f$id == "Sofa"], 0.85)
  expect_equal(f$colour[f$id == "Table"], "#c2884e")
  expect_equal(f$alpha, rep(0.45, 5))
  expect_error(furniture("X", "spaceship", 0, 0, 1, 1))
  expect_error(furniture("X", "table", 0, 0))
  expect_equal(furniture("X", "box", 0, 0, 1, 1, colour = "red", alpha = 0.2)$colour, "red")
  fc <- furniture_from_corners("C", "cabinet", c(5.4, 0.2), c(6.0, 2.0))
  expect_equal(c(fc$x, fc$y, fc$width, fc$depth), c(5.4, 0.2, 0.6, 1.8))
})

test_that("along_wall puts the object against the wall and inside the room", {
  fp <- furniture_footprint(f[f$id == "Sofa", ])
  expect_equal(max(fp$y), 5)                    # touches the north wall
  expect_equal(min(fp$y), 5 - 0.9)              # extends into the room
  expect_equal(range(fp$x), c(0.5, 2.6))        # from the west end (left when facing north)
  fe <- furniture_footprint(f[f$id == "Wardrobe", ])
  expect_equal(max(fe$x), 6)                    # against the east wall
  expect_equal(range(fe$y), c(5 - 1.6, 5 - 1.0)) # left end of the east wall is its north end
})

test_that("centred rectangles and circles anchor correctly", {
  fc <- furniture("T", "table", x = 2, y = 2, width = 1, depth = 0.5, anchor = "center")
  fp <- furniture_footprint(fc)
  expect_equal(c(mean(fp$x), mean(fp$y)), c(2, 2))
  fs <- furniture_footprint(f[f$id == "Stool", ])
  expect_equal(c(mean(fs$x), mean(fs$y)), c(1.5, 1.2), tolerance = 1e-6)
})

test_that("obstruction detection finds objects on the path", {
  # path going south from the north wall at 0.5 m height passes through the sofa
  t_low <- trajectory_from_angles(c(1.5, 5.0, 0.5), azimuth_deg = 0, vertical_deg = 0, id = "low")
  ob <- trajectory_obstructions(t_low, f, back = 3)
  expect_true("Sofa" %in% ob$object)
  expect_lt(ob$from[ob$object == "Sofa"], 0.05)
  expect_equal(ob$to[ob$object == "Sofa"], 0.9, tolerance = 0.02)
  # same path at 1.5 m clears the sofa (0.85 m tall)
  t_high <- trajectory_from_angles(c(1.5, 5.0, 1.5), 0, 0, id = "high")
  expect_equal(nrow(trajectory_obstructions(t_high, f, back = 3)), 0)
  # stairs: stepped profile is lower near the low end
  expect_true(inside_object(f[f$id == "Stairs", ], 5.65, 0.5, 2.3))
  expect_false(inside_object(f[f$id == "Stairs", ], 4.55, 0.5, 2.3))
})

test_that("origin_zone excludes positions inside furniture", {
  set.seed(5)
  # shot came from 2.3 m south of the north wall at 1.2 m: inside the block
  t <- trajectory_from_angles(c(1.5, 5.0, 1.0), 0, -5, se_azimuth = 0.5, se_vertical = 0.5)
  big <- furniture("Block", "box", x = 0, y = 0, width = 6, depth = 5, height = 2.5)
  oz <- origin_zone(t, heights = c(h = 1.2), furniture = big)
  expect_equal(oz$p_reachable, 0)
  expect_gt(oz$p_in_furniture, 0.9)
})

test_that("every view accepts furniture", {
  pts <- coords_baseline(1, 1, id = "1 Case")
  t1 <- trajectory_from_angles(c(2.0, 5.0, 1.35), 352, -3, id = "D2")
  expect_s3_class(plot_scene(pts, walls = walls, furniture = f), "ggplot")
  expect_s3_class(plot_scene(pts, walls = walls, furniture = f, furniture_alpha = 0.9), "ggplot")
  expect_s3_class(plot_trajectories(t1, n_draw = 5, walls = walls, furniture = f), "ggplot")
  pe <- plot_wall_elevation(wall_from_room(walls, "north"), pts, t1, walls, furniture = f)
  expect_s3_class(pe, "ggplot")
  expect_equal(nrow(furniture_table(f)), 5)
  skip_if_not_installed("rgl")
  expect_s3_class(scene_3d_widget(walls, pts, t1, furniture = f, n_cone = 3), "htmlwidget")
  skip_if_not_installed("rayrender")
  skip_on_cran()
  fpng <- withr::local_tempfile(fileext = ".png")
  render_scene_3d(walls, pts, t1, furniture = f, file = fpng, view = "dollhouse",
                  width = 60, height = 40, samples = 2)
  expect_true(file.exists(fpng))
})
