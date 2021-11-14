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
# WARNING: raw_data are not available to other user and therefore not reproducible

## START ##
# generate a small raster to share on GitHub
aoi_r <- terra::rast("raw_data/classified_aoi.tif")
plot(aoi_r)
bbox_sf <- as(as(as.polygons(draw(), crs = crs(aoi_r)), "Spatial"), "sf")
bbox_10km_sf <- st_make_grid(st_bbox(st_transform(st_buffer(st_transform(st_centroid(bbox_sf), 5343), 10000), 4326)), n = 1, what = "polygons")
crop_aoi_r <- terra::crop(aoi_r, as(bbox_10km_sf, "Spatial"))
writeRaster(crop_aoi_r, "src/classified_aoi_subset.tif", datatype = "INT1U", overwrite = TRUE)
plot(bbox_10km_sf, add = TRUE)

# generate random points for the example
plot(crop_aoi_r)
my_points <- st_sample(as(as(as.polygons(draw(), crs = crs(crop_aoi_r)), "Spatial"), "sf"), 10)
my_points_csv <- data.frame(ID = paste0("PTS-",1:10), st_coordinates(my_points))
fwrite(my_points_csv, "src/my_points.csv")
rm(list=ls()); gc()
## END ##


# load raster data (GeoTiff) in R
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

# add points or polygons on the raster map
my_points <- fread("src/my_points.csv")
my_points_sf <- st_as_sf(my_points, coords = c("X", "Y"), crs = 4326)
plot(st_geometry(my_points_sf), col = "yellow", pch = 19, cex = 1.5, add = TRUE)

# build 750 meters buffer around each points
# transform to equal area projection (Argentina, EPSG:5343) ## need confirmation/verification
my_buffers <- st_transform(st_buffer(st_transform(my_points_sf, 5343), 750), 4326)
plot(my_buffers, border= "black", lwd = 1.5, add = TRUE)

#extract value from raster for each buffer
my_extract <- extract(aoi_r, vect(as(my_buffers, "Spatial")))

my_extract_dt <- data.table(my_extract)
my_extract_dt <- my_extract_dt[, totalN := .N, by = ID][, .N, by = .(ID, classification, totalN)][, perct := N/totalN]
my_extract_dt <- merge(my_extract_dt, my_class, by.x = "classification", by.y = "land_class_no")[order(ID, classification),]

my_extract_dt[, land_class_name := factor(land_class_name, levels = my_class$land_class_name)]
my_extract_dt[, ID := factor(ID, levels = 10:1)]

# produce a bar plot with land cover proportion per within 750 meteres radius landscapes around points 1 to 10

p <- ggplot(data = my_extract_dt, aes(x = ID, y = perct, fill = land_class_name))
p + geom_bar(stat = "identity") +
    scale_fill_manual(name = "classification", values = my_class$land_class_col) +
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
