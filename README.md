# MSRS
Landcover Classification with different spatial grain

## Sample_Grid_Cells.py
Sample_Grid_Cells.py is a tool to use with QGIS. It selects *N* random rectangles from an input grid and exports the corresponding areas from three input raster layers. I created the grid that I used in QGIS (3.14.16) using the native *Create Grid* function with cell dimensions of 5000 × 5000 m and one of the raster layers as input. Subsequently, I deleted all grid cells that were not entirely covered by the raster area and introduced a new column named *id* as integer which were set to the respective row numbers using the QGIS Field Calculator. For the given cell dimensions, this resulted in 75 grid cells of which I randomly selected 25 for further analyses.

The Tool requires:
- a vector layer with grid cells covered by the raster area and a field "id" containing the row numbers as integers
- the RGB raster layer of the entire area
- the IR raster layer of the entire area
- the landcover classification map for the entire area

I obtained those files from the following websites:
- https://data.public.lu/fr/datasets/orthophoto-officielle-du-grand-duche-de-luxembourg-edition-2018/
- - RGB: "Ortho 2018 du pays en RGB" (URL stable: https://data.public.lu/fr/datasets/r/ce8b1b84-c11d-40af-9448-1395ce67eed8)
- - IR: "Ortho 2018 du pays en infrarouge" (URL stable: https://data.public.lu/fr/datasets/r/2d8e6281-896a-466e-bd33-a05330ded5b6)
- https://data.public.lu/fr/datasets/lis-l-land-cover-2018/
- - LIS-L Land Cover 2018: "landcover2018-raster.zip"

## SimplifyRasters.R
SimplifyRasters.R is an R script to aggregate various landcover classes. Adapted to the specific case of the LIS-L Land Cover 2018 data listed above. This data set contains groups of very similar classes that can be aggregated to fewer, larger classes. In this case, the resulting classes are
1) buildings
2) roads
3) agriculture/bare soil
4) forest
5) water
