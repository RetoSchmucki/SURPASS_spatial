
R

library(sf)
library(terra)

# get OSM data located in my cloud service
temp <- tempfile()
download.file("https://filedn.com/l4iF16owVCHBm81sGhdrcpX/raw_data/hotosm_arg_roads_lines_shp.zip", temp)
utils::unzip(temp, exdir = "raw_data/.")
unlink(temp)

arg_road <- st_read("raw_data/hotosm_arg_roads_lines_shp/hotosm_arg_roads_lines.shp")
arg_road_2 <- arg_road[arg_road$highway %in% c("motorway", "motorway_link", 
                                "trunk",  "primary", "secondary",
                                "tertiary", "residential", "road",
                                "unclassified"), ]
rm(list="arg_road"); gc()

dir.create("src/arg_road_aoi")

aoi_r <- rast("src/classified_aoi_subset.tif")
aoi_bbox_sf <- st_as_sf(as.polygons(ext(aoi_r)))
st_crs(aoi_bbox_sf) <- 4326

arg_road_logi <- st_intersects(arg_road_2, aoi_bbox_sf)
arg_road_aoi <- st_crop(arg_road_2[lengths(arg_road_logi) > 0, ], aoi_bbox_sf)

plot(aoi_r)
plot(st_geometry(arg_road_aoi), col = 'magenta', add = TRUE)

road_r <- terra::rasterize(
    vect(as(arg_road_aoi, "Spatial")),
    aoi_r,
    field = NULL,
    fun = "last",
    background = NA_real_,
    by = NULL)


st_write(arg_road_aoi, "src/arg_road_aoi/arg_road_aoi.shp")

writeRaster(road_r,
    filename = file.path("src","arg_road_aoi", "road_r.tif"),
    overwrite = TRUE)

# for GRASS installed on Windows using the OSGEO4W64 installation https://grass.osgeo.org/download/windows/
# Other installation might work out of the box. On Mac and Linux systems...(to be tested.)
# Note: the grass_setup.R should be verified for version and the paths.
source("R/grass_setup.R")

this_wd <- getwd()
temp_dir <- tempdir()

grassdata_path <- temp_dir
data_path <- file.path(this_wd, "src", "arg_road_aoi")
inp_path <- file.path(data_path, "road_r.tif")
out_path <- file.path(data_path, "road_r_distance.tif")

# create a location so you can start with grass tasks
loc <- rgrass7::initGRASS(
    gisBase = grass.gis.base,
    gisDbase = grassdata_path,
    mapset = "PERMANENT",
    override = TRUE)

execGRASS("g.proj", flags = "c", parameters = list(georef = inp_path))
execGRASS("r.in.gdal", flags = c("overwrite"), input = inp_path, output = "road_raster")

execGRASS("g.region", flags = "c", parameters = list(raster = "road_raster"))
execGRASS("g.region", flags = "p")
execGRASS("g.proj", flags = "p")

execGRASS("r.grow.distance", flags = "m", parameters = list(input = "road_raster", distance = "road_distance", metric = "geodesic"))
execGRASS("r.out.gdal", flags = "overwrite", parameters = list(input = "road_distance", output = out_path))

dist_rast <- rast(out_path)
dist_rast <- round(dist_rast)

writeRaster(dist_rast, filename = out_path, overwrite = TRUE, datatype = "INTU2")

# clean
unlink(grassdata_path, recursive = TRUE)
plot(dist_rast)