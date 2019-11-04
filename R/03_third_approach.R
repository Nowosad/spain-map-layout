library(sf)
library(dplyr)
library(spData)
library(ggplot2)
library(wesanderson)
library(lwgeom)
library(classInt)

# helper function to move geometries --------------------------------------
place_geometry = function(geometry, bb, scale_x, scale_y,
                          scale_size = 1) {
  output_geometry = (geometry - st_centroid(geometry)) * scale_size +
    st_sfc(st_point(c(
      bb$xmin + scale_x * (bb$xmax - bb$xmin),
      bb$ymin + scale_y * (bb$ymax - bb$ymin)
    )))
  return(output_geometry)
}

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

# prepare canaries ----------------------------------------------------------
canaries_data2 = canaries_data %>% 
  mutate(geometry = place_geometry(geometry, st_bbox(main_data), -0.1, 0)) %>% 
  st_set_crs(st_crs(main_data))

canaries_data2_bbox = st_buffer(st_as_sfc(st_bbox(canaries_data2)), 10000)

# combine data ------------------------------------------------------------
all_data = rbind(main_data, canaries_data2)

# create a palette --------------------------------------------------------
pal = wes_palette("Zissou1", n = 5, type = "discrete")

# create breaks -----------------------------------------------------------
# it includes the lowest value offset
breaks = classInt::classIntervals(c(min(all_data$X2017 - 1), all_data$X2017),
                                  n = 5, style = "quantile")

# add breaks to data ------------------------------------------------------
all_data$X2017_breaks = cut(all_data$X2017, breaks$brks)

# plot --------------------------------------------------------------------
my_labels = paste(breaks$brks[-length(breaks$brks)], "-", breaks$brks[-1])

gg1 = ggplot() +
  geom_sf(data = all_data, aes(fill = X2017_breaks)) +
  scale_fill_manual(values = pal,
                    labels = my_labels,
                    name = "Income per capita €") +
  geom_sf(data = canaries_data2_bbox, fill = NA) +
  theme(
    legend.position = c(0.85, 0.2),
    axis.text.x = element_blank(),
    axis.text.y = element_blank(),
    axis.ticks = element_blank())
gg1

# save --------------------------------------------------------------------
dir.create("maps")
ggsave(gg1, filename = "maps/03_map.png", width = 8.335, height = 6.946, dpi = 72)

# save data ---------------------------------------------------------------
spain_data = select(all_data, Codigo, Texto, Texto_Alt)
saveRDS(spain_data, "data/spain_data.rds")
write_sf(spain_data, "data/spain_data.gpkg")

dir.create("data/shp")
write_sf(spain_data, "data/shp/spain_data.shp")
zip(zipfile = "data/spain_data.zip", files = dir("data/shp", full.names = TRUE), flags = "-j")
