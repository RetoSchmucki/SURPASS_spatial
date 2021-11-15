## Welcome to SURPASS spatial

A place to share scripts (codes) and tutorials for GIS and spatial analysis often used in Ecology. Whilst this repository is public, it is mainly driven and motivated by the need and tasks associated to the [SURPASS2 project](https://bee-surpass.org/) that focus on pollinators and pollination services in South America.
### Motivation
As most processes in ecology are spatially structured and strongly dependent of their spatial context, ecological data often come with a spatial component that is essential for understanding the Who/What, When and Where, and get insight into the Why and How. Here I am sharing solutions and recipes to handle spatial data and derive the relevant quantities for such analyses. I am only using open-access tools, primarily R, but sometime injecting additional functionalities available in GRASS, QGIS and PostGIS/PostgreSQL. 
### Organisation
The repository is organised with R and Rmd scripts located in `R`, data and resources in `src` and tutorials in `tutorials`.


```
SURPASS_spatial
├─ LICENSE
├─ src
│  ├─ my_points.csv
│  ├─ classified_aoi_subset.tif
│  └─ arg_road_aoi
│     ├─ arg_road_aoi.shp
│     ├─ arg_road_aoi.shx
│     ├─ arg_road_aoi.dbf
│     ├─ arg_road_aoi.prj
│     ├─ road_r.tif
│     └─ road_r_distance.tif
├─ R
│  ├─ extract_data_from_raster.R
│  ├─ rasterdf.r
│  ├─ distance_to_road_raster.r
│  └─ grass_setup.R
├─ tutorials
└─ README.md

```