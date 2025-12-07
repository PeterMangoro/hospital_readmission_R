# Script to train and save all three models for Shiny app
# This script replicates the model training from the Rmd files

# Load required libraries
library(ggplot2)
library(dplyr)
library(pROC)
library(caret)
library(rpart)
library(rpart.plot)
library(randomForest)

# Set seed for reproducibility
set.seed(1)

cat("=== Training and Saving Models for Shiny App ===\n\n")

# ============================================================================
# 1. LOGISTIC REGRESSION MODEL
# ============================================================================
cat("1. Training Logistic Regression Model...\n")

# Load data
load("data_logistic.RData")
cat("   Loaded data_logistic.RData: ", nrow(data_logistic), " observations\n")

# Train/test split
train_indices <- createDataPartition(data_logistic$readmitted, 
                                     p = 0.7, 
                                     list = FALSE)

data_train <- data_logistic[train_indices, ]
data_test <- data_logistic[-train_indices, ]

cat("   Training set: ", nrow(data_train), " observations (70%)\n")
cat("   Testing set: ", nrow(data_test), " observations (30%)\n")

# Build model formula
predictor_vars <- setdiff(colnames(data_train), "readmitted")
formula_str <- paste("readmitted ~", paste(predictor_vars, collapse = " + "))
formula_obj <- as.formula(formula_str)

# Fit the model
cat("   Fitting model...\n")
model_logistic <- glm(formula_obj, 
                     data = data_train, 
                     family = binomial(link = "logit"))

cat("   Model fitted successfully!\n")
cat("   Coefficients: ", length(coef(model_logistic)), "\n\n")

# Save model
save(model_logistic, file = "model_logistic.RData")
cat("   Saved to model_logistic.RData\n\n")

# ============================================================================
# 2. CART MODEL
# ============================================================================
cat("2. Training CART Model...\n")

# Load data
load("data_cart.RData")
cat("   Loaded data_cart.RData: ", nrow(data_cart), " observations\n")

# Train/test split
train_indices_cart <- createDataPartition(data_cart$readmitted, 
                                         p = 0.7, 
                                         list = FALSE)

data_train_cart <- data_cart[train_indices_cart, ]
data_test_cart <- data_cart[-train_indices_cart, ]

cat("   Training set: ", nrow(data_train_cart), " observations (70%)\n")
cat("   Testing set: ", nrow(data_test_cart), " observations (30%)\n")

# Build model formula
predictor_vars_cart <- setdiff(colnames(data_train_cart), "readmitted")
formula_cart <- as.formula(paste("readmitted ~", paste(predictor_vars_cart, collapse = " + ")))

# Fit the CART model
cat("   Fitting model...\n")
model_cart <- rpart(formula_cart,
                   data = data_train_cart,
                   method = "class",
                   parms = list(split = "gini"),
                   control = rpart.control(
                     minsplit = 20,
                     minbucket = 7,
                     cp = 0.01,
                     maxdepth = 10,
                     xval = 10
                   ))

# Find optimal CP for pruning
cat("   Pruning tree...\n")
cp_table <- model_cart$cptable
optimal_cp_index <- which.min(cp_table[, "xerror"])
xerror_min <- cp_table[optimal_cp_index, "xerror"]
xerror_se <- cp_table[optimal_cp_index, "xstd"]
xerror_1se <- xerror_min + xerror_se
cp_1se_index <- which(cp_table[, "xerror"] <= xerror_1se)[1]
cp_1se <- cp_table[cp_1se_index, "CP"]

# Prune the tree
model_cart_final <- prune(model_cart, cp = cp_1se)

cat("   Model fitted and pruned successfully!\n")
cat("   Tree nodes: ", length(unique(model_cart_final$where)), "\n\n")

# Save model
save(model_cart_final, file = "model_cart_final.RData")
cat("   Saved to model_cart_final.RData\n\n")

# ============================================================================
# 3. RANDOM FOREST MODEL
# ============================================================================
cat("3. Training Random Forest Model...\n")

# Use same data as CART (already loaded)
cat("   Using data_cart.RData: ", nrow(data_cart), " observations\n")

# Train/test split (use same indices as CART for consistency)
data_train_rf <- data_cart[train_indices_cart, ]
data_test_rf <- data_cart[-train_indices_cart, ]

cat("   Training set: ", nrow(data_train_rf), " observations (70%)\n")
cat("   Testing set: ", nrow(data_test_rf), " observations (30%)\n")

# Build model formula
predictor_vars_rf <- setdiff(colnames(data_train_rf), "readmitted")
formula_rf <- as.formula(paste("readmitted ~", paste(predictor_vars_rf, collapse = " + ")))

# Calculate mtry
mtry_value <- floor(sqrt(length(predictor_vars_rf)))

# Fit the Random Forest model
cat("   Fitting model (this may take a few minutes)...\n")
model_rf <- randomForest(
  formula_rf,
  data = data_train_rf,
  ntree = 500,
  mtry = mtry_value,
  importance = TRUE,
  proximity = FALSE,
  do.trace = 50
)

cat("   Model fitted successfully!\n")
cat("   Number of trees: ", model_rf$ntree, "\n")
cat("   Features per split (mtry): ", model_rf$mtry, "\n\n")

# Save model
save(model_rf, file = "model_rf.RData")
cat("   Saved to model_rf.RData\n\n")

# ============================================================================
# SUMMARY
# ============================================================================
cat("=== All Models Trained and Saved Successfully ===\n")
cat("\nSaved files:\n")
cat("  - model_logistic.RData\n")
cat("  - model_cart_final.RData\n")
cat("  - model_rf.RData\n")
cat("\nYou can now run the Shiny app!\n")

