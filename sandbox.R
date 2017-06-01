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

library(reshape2)
(myNestCount <- trainingSetObservations %>%
     filter(! count_type %in% c('chicks', 'adults')) %>%
     group_by(site_id, common_name, year) %>%
     summarise(count = mean(penguin_count, na.rm=TRUE)) %>%
     dcast(site_id + common_name ~ paste0('X', year))) %>% head

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

#'## Missing data
library(reshape2)
nestCountMelt <- melt(myNestCount, id.vars=c('site_id', 'common_name'))

(nestCountBySiteAndSpecies <- nestCountMelt  %>%
    dcast(site_id + variable ~ common_name, sum) %>%
    group_by(site_id) %>%
    summarise(`adelie penguin`=sum(`adelie penguin`, na.rm=TRUE),
              `chinstrap penguin`=sum(`chinstrap penguin`, na.rm=TRUE),
              `gentoo penguin`=sum(`gentoo penguin`, na.rm=TRUE)) %>%
    mutate(total = `adelie penguin` + `chinstrap penguin` + `gentoo penguin`))

(nestCountByYear <- nestCountMelt %>%
    dcast(site_id + variable ~ common_name, sum) %>%
    group_by(variable) %>%
    summarise(`adelie penguin`=sum(`adelie penguin`, na.rm=TRUE),
              `chinstrap penguin`=sum(`chinstrap penguin`, na.rm=TRUE),
              `gentoo penguin`=sum(`gentoo penguin`, na.rm=TRUE)) %>%
     mutate(total = `adelie penguin` + `chinstrap penguin` + `gentoo penguin`) %>%
     melt(id.vars=c('variable'), variable.name='common_name', value.name='countByYear'))

(historicalData <- nestCountMelt %>% inner_join(nestCountByYear, by=c('common_name', 'variable')) %>%
     group_by(site_id, common_name, variable) %>%
     summarise(count = sum(value, na.rm=TRUE),
               countByYear = first(countByYear)) %>%
    mutate(ratio = count/countByYear) %>%
    arrange(desc(ratio)) %>%
    mutate(label=paste0(site_id, common_name)) %>%
    mutate(year=as.numeric(gsub('X', '', variable))))

(top25SiteBySpecies <- rbind(nestCountBySiteAndSpecies %>% melt(id.vars = 'site_id') %>%
                            filter(variable == 'adelie penguin') %>%
                            mutate(common_name='adelie penguin') %>%
                            arrange(desc(value)) %>%
                            head(25),
                            nestCountBySiteAndSpecies %>% melt(id.vars = 'site_id') %>%
                            filter(variable == 'gentoo penguin') %>%
                            mutate(common_name='gentoo penguin') %>%
                            arrange(desc(value)) %>%
                            head(25),
                            nestCountBySiteAndSpecies %>% melt(id.vars = 'site_id') %>%
                            filter(variable == 'chinstrap penguin') %>%
                            mutate(common_name='chinstrap penguin') %>%
                            arrange(desc(value)) %>%
                            head(25)))

top25BySpecies <- historicalData %>%
    inner_join(top25SiteBySpecies, by=c('site_id', 'common_name'))

ggplot(data=top25BySpecies, aes(x=year, y=site_id)) +
    geom_tile(aes(fill=ratio)) +
    facet_grid(common_name ~ ., scales = 'free_y')

sum(is.na(myNestCount))

#'# Model
#'

library(caret)
library(e1071)
library(ModelMetrics)
library(parallel)
dataset <- myNestCount
dataset[is.na(dataset)] <- 0

cl <- makeCluster(4)
clusterEvalQ(cl, library('caret'))
models <- parApply(cl, dataset[,21:55], 1, function(row) {
    testSetRange <- range(length(row) - 4, length(row))
    maxTrainSetRange <- length(row) - 5
    years <- as.numeric(gsub('X', '', names(row)))
    testSet <- data.frame(year=years[testSetRange], value=row[testSetRange])
    bestFit <- NA
    bestLag <- 0
    bestError <- Inf
    pb <- txtProgressBar(min=2, max=maxTrainSetRange, style=3)
    for(i in 2:maxTrainSetRange) {
        trainSet <- data.frame(year=years[(31-i):30], value=row[(31-i):30])
        tryCatch({
            fit <- train(value ~ year,
                         data=trainSet,
                         method='lm',
                         trControl=trainControl(number=1, repeats=1))
            preds <- predict(fit, testSet)
            error <- rmse(testSet$value, preds)
            if(error < bestError) {
                bestError <- error
                bestLag <- i
                bestFit <- fit
            }
        }, error = function(e) {
            print(paste('Cannot train model', i))
        })
        setTxtProgressBar(pb, i)
    }
    close(pb)
    trainSet <- rbind(data.frame(year=years[(31-bestLag):30], value=row[(31-bestLag):30]),
                      testSet)
    finalFit <- train(value ~ year,
                      data=trainSet,
                      method='lm',
                      trControl=trainControl(number=1, repeats=1))

    list(fit=finalFit, bestLag=bestLag, bestError=bestError)
})

dataset <- myNestCount %>%
    melt(id.var=c('site_id', 'common_name'), variable.name='year') %>%
    filter(as.character(year) >= 'X1975') %>%
    mutate(year=factor(gsub('X', '', year), ordered=TRUE),
           orderKey=paste(site_id, common_name, year)) %>%
    group_by(orderKey) %>%
    mutate(prev=lag(value, default=value, order_by=orderKey))

slices <- createTimeSlices(levels(dataset$year), 7, 4)

yearSplit <- 2010
trainingSet <- dataset %>% filter(year < yearSplit)
testingSet <- dataset %>% filter(year >= yearSplit)

model <- train(value ~ ., data=trainingSet, method='glm')

predict2010 <- predict(model, newdata=testingSet)

#'## Timeseries with zoo

library(zoo)
library(forecast)

dataset <- myNestCount %>%
    filter(common_name == 'gentoo penguin') %>%
    filter(site_id == 'LLAN') %>%
    melt(id.var=c('site_id', 'common_name'), variable.name='year') %>%
    mutate(year=as.numeric(gsub('X', '', year)))

series <- zoo(dataset$value)
index(series) <- dataset$year

autoplot(na.approx(series)) + geom_smooth()
autoplot(forecast(na.approx(series))) 
autoplot(auto.arima(series))

