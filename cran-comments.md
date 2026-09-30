## forensicR 0.0.6 - resubmission

This is a resubmission of a new package. Following the review of 0.0.3:

* The Description no longer starts with "Tools for".
* The Description cites the references for the methods, in the form
  authors (year, ISBN:...).
* R/render3d.R: graphical parameters and options are reset with an immediate
  call of on.exit(). The par() call only affects a png device that the
  function opens itself and closes on exit.

## Test environments

* local Ubuntu 22.04, R 4.5.1
* GitHub Actions: macOS (release), Windows (release), Ubuntu (devel, release, oldrel)
* win-builder: R-devel, R-release, R-oldrelease

## R CMD check results

0 ERRORs, 0 WARNINGs, 0 NOTEs apart from "New submission".

The words "Haag" and "Hueske" in the Description are author names of the
cited references.
