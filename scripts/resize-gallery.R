# Resize lab photos for the website gallery.
# Put full-size photos in gallery/originals/ (not committed), then run from the repo root:
#   Rscript scripts/resize-gallery.R
# Requires the magick package (install.packages("magick")); the site build does not need it.
library(magick)

src_dir <- "gallery/originals"
out_dir <- "gallery"
files <- list.files(src_dir, pattern = "\\.(jpe?g|png|webp|heic)$", ignore.case = TRUE, full.names = TRUE)

for (f in files) {
  out <- file.path(out_dir, paste0(tools::file_path_sans_ext(basename(f)), ".jpg"))
  image_read(f) |>
    image_orient() |>
    image_strip() |>
    image_scale("1600x1600>") |>
    image_write(out, format = "jpeg", quality = 82)
  message("Wrote ", out)
}
