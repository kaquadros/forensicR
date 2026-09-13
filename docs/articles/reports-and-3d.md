# Reports, the 3D views and the interactive model

## The report in one call

`render_scene_report()` renders one R Markdown template to Word, PDF and
HTML. You pass the objects you built as `params`; any section whose
object is missing prints a placeholder line instead of failing.

``` r
out <- render_scene_report(
  output_dir = "report",
  formats = c("docx", "pdf", "html"),      # any subset
  params = list(
    case_id      = "2026-004417",
    agency       = "Douglas County Sheriff's Office",
    investigator = "K. Quadros",
    scene_date   = as.Date("2026-09-06"),
    units        = "m",
    narrative    = "Single-family residence, living room. ...",   # markdown text
    points       = scene,          # coords_*() tibble
    walls        = walls,          # room_rect() + opening()
    furniture    = furn,           # furniture() tibble
    wall_height  = 2.5,
    shooting     = list(
      impact       = impact_angle(c(9.1, 6.0), c(9.3, 12.5), se = 0.5),
      trajectories = list(t_rod, t_2pt, shot4),     # trajectories and/or paths
      heights      = c(standing = 1.5, kneeling = 1.0, prone = 0.3),
      max_distance = 12
    ),
    evidence     = log,            # evidence_log()
    death_scene  = ds,             # death_scene_record()
    scene3d      = TRUE            # 3D figure (PDF/Word) or widget (HTML)
  )
)
out          # named paths of the files produced
```

### What the report contains

1.  Case header and narrative.
2.  Scene sketch, table of points with heights, table of objects, and an
    elevation of each wall.
3.  Shooting reconstruction: impact angles, trajectory table with
    uncertainties, plan view with convergence, elevation view, origin at
    assumed heights per trajectory, objects on the paths, segmented
    paths and their deflections, convergence table.
4.  Evidence log with photo hashes.
5.  Chain of custody.
6.  Death scene observations (observations only; no estimate of time
    since death, which is the coroner’s determination).

Every output ends with one line stating the forensicR version, the R
version and the time of rendering.

### Word first

The intended workflow is: render, open the `.docx`, paste in the agency
header and photographs, edit the wording, print to PDF for approval. If
a measurement is corrected later, re-render and the figures and tables
update together. The template is deliberately plain so that it takes
your agency’s styles when pasted.

To make Word output match a house style automatically, copy the
template, add a `reference_docx` to its `word_document` output options
and pass the copy as `input`:

``` r
scene_report_skeleton("my-agency-report.Rmd")   # editable copy of the template
render_scene_report(input = "my-agency-report.Rmd", output_dir = "report", params = list(...))
```

## The 3D views

Both 3D back ends draw the *same* objects as the 2D plots: walls with
door and window panels, a floor grid with numbered x and y axes and
height numbers up the walls, numbered evidence markers, bullet defects
at their measured height, schematic bloodstain discs, furniture as
semi-transparent boxes, trajectories as rods with arrowheads, and
uncertainty cones as wireframes. They are schematic on purpose: a
courtroom demonstrative must be to scale and must not add detail that
was not measured.

### Still image (rayrender)

``` r
render_scene_3d(walls, scene, trajs, furniture = furn,
                file = "scene3d.png",
                view = "dollhouse",        # or "door", "corner", "overhead"
                grid_on = c("floor", "walls"), grid_strength = 0.6, grid_labels = TRUE,
                furniture_alpha = NULL,    # per-object opacity unless overridden
                samples = 128)             # more samples = less grain, more time
```

\<img src=“figures/getting-started-dollhouse.png” class=“r-plt”
alt=“view =”dollhouse“: from outside, south wall removed.”
width=“100%” /\>

view = “dollhouse”: from outside, south wall removed.

\<img src=“figures/getting-started-door.png” class=“r-plt” alt=“view
=”door“: standing in the doorway at eye level, looking at the defects.
The rings are the bases of the uncertainty cones, i.e. roughly where the
shooter stood.” width=“100%” /\>

view = “door”: standing in the doorway at eye level, looking at the
defects. The rings are the bases of the uncertainty cones, i.e. roughly
where the shooter stood.

Camera presets can be replaced by explicit `lookfrom` and `lookat`
positions in scene coordinates, and any wall can be removed with
`omit_wall` so an outside camera can see in. Rendering a 1000 by 750
image at 128 samples takes roughly 20 to 40 seconds on a laptop.

### Interactive model (rgl)

``` r
w <- scene_3d_widget(walls, scene, trajs, furniture = furn)
w                                                   # in RStudio's viewer
htmlwidgets::saveWidget(w, "scene3d.html", selfcontained = TRUE)   # to share
```

The HTML report embeds this widget when `scene3d = TRUE`. It needs WebGL
in the reader’s browser. If WebGL is unavailable the report hides the
empty widget and shows the still image with a note, so the reader never
sees a blank space. To enable WebGL in Chrome: turn on hardware
acceleration in *Settings, System*; if that is not enough, enable
“Override software rendering list” in `chrome://flags`; on machines
without a usable GPU start Chrome with `--use-angle=swiftshader
--enable-unsafe-swiftshader`. Firefox usually has WebGL on by default.

## Installing the optional pieces

``` r
install.packages(c("rayrender", "rgl"))   # 3D still image and interactive model
tinytex::install_tinytex()                # if you have no LaTeX and want PDF output
```

Without them everything else works: plots, tables, Word and HTML
reports.
