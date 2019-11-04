# more similar ideas at https://nowosad.github.io/post/making-alternative-inset-maps-of-the-usa/
# and https://geocompr.robinlovelace.net/adv-map.html#inset-maps
library(sf)
library(wesanderson)
library(tmap)
library(dplyr)
library(lwgeom)
library(classInt)
library(grid)

# read data ---------------------------------------------------------------
med_inc = read.csv("data/Renta media por persona.csv", stringsAsFactors = FALSE)
med_inc$Codigo = substring(med_inc$X, 1, 2)

cas = read_sf("data/Comunidades_Autonomas_ETRS89_30N.shp")
cas = st_make_valid(cas)

# join data ---------------------------------------------------------------
cas1 = left_join(cas, med_inc, by = "Codigo")

# split dataset -----------------------------------------------------------
main_data = cas1[-5, ]
canaries_data = cas1[5, ]

# calculate spatial ratios ------------------------------------------------
main_range = st_bbox(main_data)[4] - st_bbox(main_data)[2]
canaries_range = st_bbox(canaries_data)[4] - st_bbox(canaries_data)[2]

main_canaries_ratio = canaries_range / main_range

# create a palette --------------------------------------------------------
pal = wes_palette("Zissou1", 5, type = "discrete")

# create breaks -----------------------------------------------------------
breaks = classInt::classIntervals(cas1$X2017, n = 5, style = "quantile")

# create a main map -------------------------------------------------------
main_map = tm_shape(main_data) +
  tm_polygons("X2017", breaks = breaks$brks, pal = pal, title = "Income per capita €") +
  tm_layout(frame = FALSE)

# create a map of Canaries Islands -----------------------------------------
canaries_map = tm_shape(canaries_data) +
  tm_polygons("X2017", breaks = breaks$brks, pal = pal, title = "Income per capita €") +
  tm_layout(legend.show = FALSE, frame = FALSE)

# create a final map ------------------------------------------------------
grid.newpage()
pushViewport(viewport(layout = grid.layout(2, 1,
                                           heights = unit(c(1, main_canaries_ratio), "null"))))
print(canaries_map, vp = viewport(height = main_canaries_ratio, x = 0.3, y = 0.1))
print(main_map, vp = viewport(layout.pos.row = 1))
grid.lines(x = c(0, 1), y = c(0.27, 0.08), gp = gpar(lty = 2))
     
# save --------------------------------------------------------------------
dir.create("maps")
png("maps/01_map.png", width = 600, height = 500)
grid.newpage()
pushViewport(viewport(layout = grid.layout(2, 1,
                                           heights = unit(c(1, main_canaries_ratio), "null"))))
print(canaries_map, vp = viewport(height = main_canaries_ratio, x = 0.3, y = 0.1))
print(main_map, vp = viewport(layout.pos.row = 1))
grid.lines(x = c(0, 1), y = c(0.27, 0.08), gp = gpar(lty = 2))
dev.off()
