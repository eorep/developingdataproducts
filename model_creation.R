#' Statistical model
#' 
#' This code the steps made to get and clean the data, try different models and export the resulted model to be used in the Shiny application.
#' @author Elmer Ore.

library(readxl)
library(dplyr)
library(recipes)
library(caret)
library(ggplot2)

# getting the data
##################
download.file("http://archive.ics.uci.edu/ml/machine-learning-databases/00350/default%20of%20credit%20card%20clients.xls", 
              "clients.xls")

data <- read_excel("clients.xls", col_names = TRUE, skip=1, range = cell_limits(c(2, 2), c(NA, NA)) )

# data exploration
##################

# 1.2% of data for education has value different than the valid values, so I set them to 4 (others)
# 0.2% of data has marital status with value 0 , so I set it to 3 (Others)
data <- data %>% 
  mutate(EDUCATION = ifelse(EDUCATION == 0, 4, EDUCATION)) %>%
  mutate(EDUCATION = ifelse(EDUCATION > 4, 4, EDUCATION )) %>%
  mutate(MARRIAGE= ifelse(MARRIAGE == 0, 3, MARRIAGE) ) %>%
  rename(PAY_1 = PAY_0, default = 'default payment next month')

# converting some numeric variables to factors.
data$SEX <- as.factor(data$SEX)
levels(data$SEX) <- c("male", "female")

data$EDUCATION <- as.factor(data$EDUCATION)
levels(data$EDUCATION) <- c("graduate school", "university", "high school", "others")

data$MARRIAGE <- as.factor(data$MARRIAGE)
levels(data$MARRIAGE) <- c("married", "single", "others")

data$default <- as.factor(data$default)
levels(data$default) <- c("credible", "no credible")

cols <- c("PAY_1", "PAY_2", "PAY_3", "PAY_4", "PAY_5", "PAY_6")
data[,cols] <- data.frame(apply(data[cols], 2, as.factor))
# note that pay 5 and pay 6 have one level less  (PAY_1)


##################
# Original code, split training and testing for validating models
# Final code, use 100% of the data with the model choosen.
##################
# # data split
# set.seed(1998)
# inTraining <- createDataPartition(data$default, p = .80, list = FALSE)
# training <- data[ inTraining,]
# testing  <- data[-inTraining,]

training = data

#Predictive models
##################

#creation of the recipe.
train_recipe <- recipe(default ~ ., data = training) %>%
  step_nzv(all_predictors()) %>%
  step_corr(all_numeric()) %>%
  step_dummy(all_nominal(), - all_outcomes()) %>%
  step_zv(all_predictors()) %>%
  step_center(all_predictors()) %>%
  step_scale(all_predictors()) 

# preparing the recipe
trained_recipe <- prep(train_recipe, training = training)

## saving the trained recipe for later use.
save(trained_recipe, file="trained_recipe.rda")

# executing the recipe.
train_data <- bake(trained_recipe, new_data = training)
##test_data <- bake(trained_recipe, new_data = testing)


# executing the model
####################
library(caret)
library(parallel)
library(doParallel)

# Configuring parallel processing
cluster <- makeCluster(5) # convention to leave 1 core for OS
registerDoParallel(cluster)

# Configuring parameters, 5 fold cross validation.
fitControl <- trainControl(method = "cv",
                            number = 5,
                            allowParallel = TRUE)

#executing the model
set.seed(1779)
fitGLM <- train(default~., method = "glm", family = "binomial",  data=train_data, trControl = fitControl)

set.seed(1780)
fitRF <- train(default~., method="rf",data=train_data, trControl = fitControl)

set.seed(1781)
fitNN <- train(default~., method="nnet",data=train_data, trControl = fitControl, 
               tuneGrid=expand.grid(size=c(10), decay=c(0.1)) )

# De-register parallel processing cluster
stopCluster(cluster)
registerDoSEQ()

#validating model
##################
fitGLM
densityplot(fitGLM, pch = "|")
predict(fitGLM, newdata = head(test_data), type="prob")

predictGLM <- predict(fitGLM, newdata = test_data)
confusionMatrix(predictGLM, test_data$default) #81.71

fitRF
predictRF <- predict(fitRF, newdata = test_data)
confusionMatrix(predictRF, test_data$default)   #81.86

fitNN
predictNN <- predict(fitNN, newdata = test_data)
confusionMatrix(predictNN, test_data$default) #81.58


# testing
##################
inputPredict <- training[1,]

inputPredict$LIMIT_BAL <- 250000
inputPredict$SEX <- as.factor("female")
inputPredict$EDUCATION <- as.factor("others")
inputPredict$MARRIAGE <- as.factor("single")
inputPredict$AGE <- 41

inputPredict <- bake(trained_recipe, new_data = inputPredict)

predict(fitGLM, newdata = inputPredict)
predict(fitGLM, newdata = inputPredict, type="prob")

glmImp <- varImp(fitGLM, scale = FALSE)
glmImp

# saving model
##################
save(fitGLM, file="GLMClassification.rda")

# saving format of the input table.
data_eval <- data[0,]
save(data_eval, file="data_format.rda")

#visualizing the model
######################
fitGLM
densityplot(fitGLM, pch = "|")
summary(fitGLM)

varImportance <- varImp(fitGLM, scale=FALSE)
ggplot(varImportance, top=12) +
       ggtitle("Top variables that affect the approval process")

# data for presentation
#######################

press <- select(data, LIMIT_BAL, MARRIAGE)
summary(press)  
library(ggplot2)  

ggplot( data=press, aes(MARRIAGE, LIMIT_BAL)) +
          geom_boxplot(varwidth = TRUE, fill = "white", colour = "blue", outlier.alpha = 0.1 ) +
  ggtitle("Distribution of credit by marital status") + 
  xlab("Marital status") +
  ylab("Credit amount")

save(press, file="press.rda")
