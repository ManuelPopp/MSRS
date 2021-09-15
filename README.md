# MSRS
Landcover Classification with different spatial grain

## Sample_Grid_Cells.py
Sample_Grid_Cells.py is a tool to use with QGIS. It selects *N* random rectangles from an input grid and exports the corresponding areas from three input raster layers. I created the grid that I used in QGIS (3.14.16) using the native *Create Grid* function with cell dimensions of 1000 × 1000 m and one of the raster layers as input. Subsequently, I deleted all grid cells that were not entirely covered by the raster area and introduced a new column named *id* as integer which were set to the respective row numbers using the QGIS Field Calculator.

The Tool requires:
- a vector layer with grid cells covered by the raster area and a field "id" containing the row numbers as integers
- the RGB raster layer of the entire area
- the IR raster layer of the entire area
- the landcover classification map for the entire area

I obtained those files from the following websites:
- https://data.public.lu/fr/datasets/orthophoto-officielle-du-grand-duche-de-luxembourg-edition-2018/
- - RGB: "Ortho 2018 du pays en RGB"
- - IR: "Ortho 2018 du pays en infrarouge"
- https://data.public.lu/fr/datasets/lis-l-land-cover-2018/
- -- LIS-L Land Cover 2018: "landcover2018-raster.zip"
