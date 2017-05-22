                                        # Penguin walk I

## Data loading

dir.create('data', recursive = TRUE)

dataUrls <- c('https://s3.amazonaws.com/drivendata/data/47/public/training_set_observations.csv',
              'https://s3.amazonaws.com/drivendata/data/47/public/training_set_nest_counts.csv',
              'https://s3.amazonaws.com/drivendata/data/47/public/submission_format.csv',
              'https://s3.amazonaws.com/drivendata/data/47/public/training_set_e_n.csv')

sapply(dataUrls, function (url) {
    destfile <- paste('data', basename(url), sep='/')
    download.file(url, destfile = destfile)
    c(destfile = file.info(destfile)['size'])
})


submissionFormat <- read.csv('data/submission_format.csv')
trainingSetError <- read.csv('data/training_set_e_n.csv')
nestCount <- read.csv('data/training_set_nest_counts.csv')
trainingSetObservations <- read.csv('data/training_set_observations.csv')

str(nestCount)
str(trainingSetError)
str(trainingSetObservations)

## Some plots

library(plyr)
library(ggmap)

bbox <- make_bbox(longitude_epsg_4326, latitude_epsg_4326, data = trainingSetObservations)
map <- get_map(bbox, source = 'osm')
plot.map <- ggmap(map)
# map <- map + stat_density2d(aes(x=longitude, y=latitude, fill = ..level.., alpha = ..level.., colour = status_group),
#                             data = filtered.data,
#                             size = 0.01, bins = 16, geom = "polygon")
plot.map <- plot.map + geom_point(aes(x=longitude, y=latitude, color=status_group), data = filtered.data) +
  scale_color_manual(values=c("green", "orange", "red"), 
                     name="Status")

library(ggplot2)
world <- map_data("world")
worldmap <- ggplot(world, aes(x=long, y=lat, group=group)) +
    scale_y_continuous(breaks=c(-90,-75,-60,-45)) +
    scale_x_continuous(breaks=(-2:2) * 45) +
    coord_map("stereographic", orientation=c(-90, 0, 0), ylim=-60) +
    geom_point(aes(x=longitude_epsg_4326, y=latitude_epsg_4326, color=common_name), inherit.aes = FALSE, data = trainingSetObservations) +
    geom_path()

