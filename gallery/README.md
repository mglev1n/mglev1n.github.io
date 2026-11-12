# Lab photos

Put lab photos (`.jpg`, `.jpeg`, `.png`, `.webp`, `.gif`) in this folder. The home page shows them in a
"Lab photos" section the next time the site builds. If the folder has no images, the section and its
navigation link are left out.

Captions are optional. To add them, create `captions.csv` in this folder:

```csv
file,caption
retreat-2026.jpg,Lab retreat, spring 2026
```

Wrap a caption in double quotes if it contains a comma. Photos listed in `captions.csv` appear first, in
the order listed; any other photos follow alphabetically by file name.

Resize photos before committing them; phone photos are 3–5 MB each. `scripts/resize-gallery.R` resizes
every image in `gallery/originals/` to 1600 px wide and writes it here.
