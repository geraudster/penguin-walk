#'# Penguin walk I

#'## Data loading

#+ cache=TRUE
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

#'## Data preparation

trainingSetObservations$month <- factor(trainingSetObservations$month,
                                        levels = 1:12,
                                        labels = month.abb)


#'## Some plots
#' _adelie penguin_ <div style="width:300px; height=200px">![Image of Adelie Penguin](https://upload.wikimedia.org/wikipedia/commons/2/26/Manchot_Adelie_-_Adelie_Penguin.jpg)</div>
#' _chinstrap penguin_ <div style="width:300px; height=200px">![Image of Chinstrap Penguin](https://upload.wikimedia.org/wikipedia/commons/6/69/Manchot_01.jpg)</div>
#' _gentoo penguin_ <div style="width:300px; height=200px">![Image of Gentoo Penguin](https://upload.wikimedia.org/wikipedia/commons/c/c5/Manchot_papou_-_Gentoo_Penguin.jpg)</div>

library(ggplot2)
world <- map_data("world")
worldmap <- ggplot(world, aes(x=long, y=lat, group=group)) +
    scale_y_continuous(breaks=c(-90,-75,-60,-45)) +
    scale_x_continuous(breaks=(-2:2) * 45) +
    coord_map("stereographic", orientation=c(-90, 0, 0), ylim=-50) +
    geom_point(aes(x=longitude_epsg_4326, y=latitude_epsg_4326, color=common_name), inherit.aes = FALSE, data = trainingSetObservations) +
    geom_path()

worldmap

ggplot(trainingSetObservations, aes(x=year, fill=common_name, weight=penguin_count)) +
    geom_bar() +
    facet_grid(common_name ~ .)

ggplot(trainingSetObservations, aes(x=month, fill=common_name, weight=penguin_count)) +
    geom_bar() +
    facet_grid(common_name ~ .)
