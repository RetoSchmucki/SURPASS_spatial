## Welcome to SURPASS spatial

A place to share scripts (codes) and tutorials for GIS and spatial analysis often used in Ecology. Whilst this repository is public, it is mainly driven and motivated by the need and tasks associated to the [SURPASS2 project](https://bee-surpass.org/) that focus on pollinators and pollination services in South America.
### Motivation
As most processes in ecology are spatially structured and strongly dependent of their spatial context, ecological data often have a spatial component that is often crucial to address the Who/What, When and Where, and get insight into the Why and How. Here I am sharing solutions and recipes to handle spatial data and derive the relevant quantities for our analysis. I am only using free and open-access tools, primarily using R, but sometime injecting some functionalities available in GRASS, QGIS and PostGIS/PostgreSQL. 
### Organisation
The repository is organised with R and Rmd scripts located in `R`, data and resources in `src` and tutorials in `tutorials`.

```
SURPASS_spatial
├─ LICENSE
├─ README.md
├─ src
│  ├─ classified_aoi_subset.tif
│  └─ my_points.csv
├─ R
│  └─ extract_data_from_raster.R
└─ tutorials
```