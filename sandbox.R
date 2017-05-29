library(knitr)
opts_chunk$set(warning = FALSE)

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
    coord_map("stereographic", orientation=c(-90, 0, 0), ylim=-60) +
    geom_path()

worldmap + geom_point(aes(x=longitude_epsg_4326, y=latitude_epsg_4326, color=common_name), inherit.aes = FALSE, data = trainingSetObservations)

ggplot(trainingSetObservations, aes(x=year, fill=common_name, weight=penguin_count)) +
    geom_bar() +
    facet_grid(common_name ~ .)

ggplot(trainingSetObservations, aes(x=month, fill=common_name, weight=penguin_count)) +
    geom_bar() +
    facet_grid(common_name ~ .)

#'## Observation sites

library(dplyr)
library(magrittr)

locations <- trainingSetObservations %>%
    group_by(site_id, site_name, ccamlr_region, longitude_epsg_4326, latitude_epsg_4326, common_name) %>%
    summarise(total = sum(penguin_count))

worldmap + geom_point(aes(x=longitude_epsg_4326, y=latitude_epsg_4326, size=total, color=common_name),
                      inherit.aes = FALSE,
                      data = locations) +
    scale_size_continuous(range = c(0.5,10)) +
    geom_text(aes(x=longitude_epsg_4326, y=latitude_epsg_4326, label = site_id), data = locations,
              inherit.aes = FALSE,
              check_overlap = TRUE,
              hjust = 0, nudge_x = 0.05)

#'## Focus on Gentoo penguin

gentooObs <- trainingSetObservations[trainingSetObservations$common_name == 'gentoo penguin',]
ggplot(gentooObs, aes(x=year, fill=common_name, weight=penguin_count)) +
    geom_bar()
gentooNest <- nestCount[nestCount$common_name == 'gentoo penguin',]
dim(gentooNest)

ggplot(gentooObs, aes(x=year, fill=common_name, weight=penguin_count)) +
    geom_bar()

worldmap + geom_point(aes(x=longitude_epsg_4326, y=latitude_epsg_4326, size=total, color=common_name),
                      inherit.aes = FALSE,
                      data = locations %>% filter(common_name == 'gentoo penguin')) +
    scale_size_continuous(range = c(0.5,10)) +
    geom_text(aes(x=longitude_epsg_4326, y=latitude_epsg_4326, label = site_id),
              data = locations %>% filter(common_name == 'gentoo penguin') %>% arrange(desc(total)) %>% head(10),
              inherit.aes = FALSE,
              check_overlap = TRUE,
              hjust = 0, nudge_x = 0.05)


gentooObs %>% group_by(site_id, count_type) %>% count() %>% arrange(desc(n))

ggplot(gentooObs %>% filter(year >= 1950), aes(x=year, y=penguin_count, color=vantage)) +
    geom_point() +
    geom_smooth() +
    facet_grid(count_type ~ .)

#'## Try to reproduce nest file

trainingSetObservations %>%
    filter(year >= 2009) %>%
    filter(! count_type %in% c('chicks', 'adults')) %>%
    group_by(site_id, common_name, year) %>%
    summarise(count = max(penguin_count)) %>%
    filter(site_id == 'BISC')

#'## Common functions

penguinPoi <- function(species) {
    locations %>% filter(common_name == species) %>% arrange(desc(total)) %>% head(5)
}

penguinPlot <- function(species, poi) {
    ggplot(trainingSetObservations %>%
           filter(common_name == species) %>%
           filter(year >= 1950) %>%
           filter(site_id %in% poi$site_id),
           aes(x=year, y=penguin_count, color=vantage)) +
        geom_point() +
        geom_smooth() +
        facet_grid(count_type + site_id ~ ., scales = 'free_y') +
        labs(title=paste('Evolution for', species))
}

#'## Interesting sites (gentoo)

poi <- penguinPoi('gentoo penguin')
poi
penguinPlot('gentoo penguin', poi)

#'## Interesting sites (adelie penguin)

poi <- penguinPoi('adelie penguin')
poi
penguinPlot('adelie penguin', poi)

#'## Interesting sites (chinstrap penguin)

poi <- penguinPoi('chinstrap penguin')
poi
penguinPlot('chinstrap penguin', poi)


#'## Interesting sites (all species)
soi <- c('ACUN',
         'AMBU',
         'BACK',
         'BEAN',
         'BIEN',
         'ADAM',
         'AKAR')

