library(knitr)
opts_chunk$set(warning = FALSE)

#'# Penguin walk II

#'## Data loading

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

#'## Observation sites

library(dplyr)
library(magrittr)

locations <- trainingSetObservations %>%
    group_by(site_id, site_name, ccamlr_region, longitude_epsg_4326, latitude_epsg_4326, common_name) %>%
    summarise(total = sum(penguin_count))

library(reshape2)

(myNestCount <- trainingSetObservations %>%
     filter(! count_type %in% c('chicks', 'adults')) %>%
     group_by(site_id, common_name, year) %>%
     summarise(count = mean(penguin_count, na.rm=TRUE)) %>%
     dcast(site_id + common_name ~ paste0('X', year))) %>% head

#'# Model
#'
#' One linear model by site/species

library(caret)
library(e1071)
library(ModelMetrics)
library(parallel)
library(foreach)
library(doParallel)
library(elasticnet)
dataset <- myNestCount
dataset[is.na(dataset)] <- 0

load(file='models-lm.RData')
selectedLag <- median(sapply(models, function(model) model$bestLag))

cols <- c('common_name', 'ccamlr_region', paste0('X', 1980:2014))

byCNAndSite <- dataset %>%
    melt(id.vars=c('common_name', 'site_id'), variable.name='year', value.name='current') %>%
    mutate(year=as.numeric(gsub('X', '', year))) %>%
    group_by(common_name, site_id)

dataWithLag <- Reduce(function (acc, x) {
    acc[[paste0('current.', x)]] <- with(acc, lag(current, default=0, order_by=year))
    acc
}, 1:10, byCNAndSite) %>% 
    inner_join(locations) %>%
    select(-site_id, -site_name, -longitude_epsg_4326, -latitude_epsg_4326)
dataWithLag[is.na(dataWithLag)] <- 0

trainset <- dataWithLag %>% filter(year < 2010)
testset <- dataWithLag %>% filter(year >= 2010)
dim(trainset)
dim(testset)

method <- 'rf'
model <- train(current ~ . - site_id,
               preProcess=c('center', 'scale'),
               data=trainset, method='rf')


save(model, file=paste0('model-', method, '.RData'))


predictions <- predict(model, newdata=testset)
rmse(testset$current, predictions)

uniqueLocations <- trainingSetObservations %>%
    distinct(site_id, ccamlr_region)

(dataForPreds2014 <-
    dataset %>%
    right_join(submissionFormat, by=c('site_id', 'common_name')) %>%
    right_join(uniqueLocations, by=c('site_id')) %>%
    select(-X2014.x) %>%
    rename(X2014=X2014.y) %>%
    dim
    
    melt(id.vars=c('common_name', 'site_id'), variable.name='year', value.name='current') %>%
    mutate(year=as.numeric(gsub('X', '', year))) %>%
    group_by(common_name, site_id) %>%
    Reduce(function (acc, x) {
        acc[[paste0('current.', x)]] <- with(acc, lag(current, default=0, order_by=year))
        acc
    }, 1:10, .) %>% 
    inner_join(locations) %>%
    select(-site_id, -site_name, -longitude_epsg_4326, -latitude_epsg_4326) %>%
    filter(year==2014) %>%
    predict(model, newdata=.) 
)


dim(submissionFormat)
