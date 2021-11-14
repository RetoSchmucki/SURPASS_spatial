# ======================
# Objective: load raster data and extract values around points using a buffer
# Author: Reto Schmucki - retoschm[@]ceh.ac.uk
# Date: 12/11/2021
# ======================

R

if(!requireNamespace("devtools")) install.packages("devtools")
if(!requireNamespace("sf")) install.packages("sf")
if(!requireNamespace("terra")) install.packages("terra")
if(!requireNamespace("data.table")) install.packages("data.talbe")
if(!requireNamespace("ggplot2")) install.packages("ggplot2")
if(!requireNamespace("landscapetools")) devtools::install_github("ropensci/landscapetools")

library(sf)
library(terra)
library(data.table)
library(ggplot2)
library(landscapetools)

# Do not evaluate (execute) this first part!
# WARNING: raw_data are not available from the GitHub repo, but are accessed from the cloud reproducible

## START ##
# generate a small raster to share on GitHub
aoi_r_url <- "https://filedn.com/l4iF16owVCHBm81sGhdrcpX/raw_data/classified_aoi.tif"
aoi_r <- terra::rast(aoi_r_url)

# define a smaller bounding box (10km) around a central point (lon = -71.55, lat = -42)
centroid_pnt <- st_as_sf(data.frame(id = "pt1", lon = -71.55, lat = -42), coords = c("lon", "lat"), crs = 4326)
bbox_10km_sf <- st_make_grid(st_bbox(st_transform(st_buffer(st_transform(centroid_pnt, 5343), 10000), 4326)), n = 1, what = "polygons")

# visualise in a figure the original raster and the new bounding box defined around the point
plot(aoi_r)
plot(bbox_10km_sf, add = TRUE)

# crop the larger raster, using the bounding box as cookie cutter
crop_aoi_r <- terra::crop(aoi_r, as(bbox_10km_sf, "Spatial"))
writeRaster(crop_aoi_r, "src/classified_aoi_subset.tif", datatype = "INT1U", overwrite = TRUE)

# generate random points for this example.
set.seed(235398) #set the seed for random number generation and reproducibility

# restrict the sample within 1500 meters from the edges.
my_points <- st_sample(st_transform(st_buffer(st_transform(bbox_10km_sf, 5343), -1500), 4326) , 10)
plot(st_geometry(my_points), pch = 19, add = TRUE)

# get points coordinates and save in a .csv
my_points_csv <- data.frame(ID = paste0("PTS-",1:10), st_coordinates(my_points))
fwrite(my_points_csv, "src/my_points.csv")

# clear all objects
rm(list=ls()); gc()
## END ##


# load the smaller raster data (GeoTiff) generated above
aoi_r <- terra::rast("src/classified_aoi_subset.tif")

# define land cover class used with name, value and color)
my_lc_class <- data.frame(lc_class_name = c("woodland", "water", "unveggetated", "shrub",
                                            "urban", "grass", "crop", "montane_herb",
                                            "montane_bare"),
                        lc_class_no = c(1:9),
                        lc_class_col = c("#339470", "#05b0d6", "#987a3a", "#9ab87a",
                                            "#e93f6f", "#a4bd00", "#ff9f1a", "#f4f2bd",
                                            "#9bc0bb"))

# produce a fist land cover map from the raster
plot(aoi_r, 
    type = "classes",
    levels = my_lc_class$lc_class_name,
    col = my_lc_class$lc_class_col)

# add points to the raster map
my_points <- fread("src/my_points.csv")
my_points_sf <- st_as_sf(my_points, coords = c("X", "Y"), crs = 4326)
plot(st_geometry(my_points_sf), col = "yellow", pch = 19, cex = 1.5, add = TRUE)

# build 750 meters buffer around each points
# transform to equal area projection (Argentina, EPSG:5343) 
my_buffers <- st_transform(st_buffer(st_transform(my_points_sf, 5343), 750), 4326)
plot(my_buffers, col = NA, border= "black", lwd = 1.5, add = TRUE)

#extract value from raster for each buffer
my_extract <- extract(aoi_r, vect(as(my_buffers, "Spatial")))

my_extract_dt <- data.table(my_extract)
my_extract_dt <- my_extract_dt[, totalN := .N, by = ID][, .N, by = .(ID, classification, totalN)][, perct := N/totalN]
my_extract_dt <- merge(my_extract_dt, my_lc_class, by.x = "classification", by.y = "lc_class_no")[order(ID, classification),]

my_extract_dt[, lc_class_name := factor(lc_class_name, levels = rev(my_lc_class$lc_class_name))]
my_extract_dt[, ID := factor(ID, levels = 10:1)]

# produce a bar plot with land cover proportion per within 750 meteres radius landscapes around points 1 to 10

p <- ggplot(data = my_extract_dt, aes(x = ID, y = perct, fill = lc_class_name))
p + geom_bar(stat = "identity") +
    scale_fill_manual(name = "classification", values = rev(my_lc_class$lc_class_col)) +
    scale_y_continuous(labels = scales::percent, expand = expansion(mult = c(0, 0.03))) +
    geom_hline(yintercept = c(0, 0.25, 0.5, 0.75), color = "grey50", linetype = 2) +
    geom_hline(yintercept = c(0), color = "grey25", linetype = 1) +
    guides(fill = guide_legend(
        reverse = TRUE,
        title.position = "top",
        label.position = "bottom",
        keywidth = 3,
        nrow = 1
    )) +
    theme_bw() +
    theme(
        legend.position = "top",
        legend.justification = "left",
        legend.margin = margin(t = 5, r = 0, b = 0, l = 0),
        axis.text.x = element_text(face = "bold", hjust = 0.5, size = 12),
        axis.text.y = element_text(face = "bold", hjust = 1, size = 12),
        axis.ticks.length = unit(0.2, "cm"),
        axis.ticks.x = element_blank(),
        panel.border = element_blank(),
        panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank()
    ) +
    labs(
        x = NULL, y = NULL,
        fill = "Classification",
        caption = "derived from Sentinel-2, 12/11/2021",
        subtitle = "Percentage per land cover class",
        title = "SURPASS Land Cover Map"
    ) +
    coord_flip()

# -> todo
# produce a pretty land cover map
# explore show_landscape()
