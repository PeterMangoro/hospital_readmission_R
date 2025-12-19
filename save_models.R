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
library(xgboost)
library(nnet)

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
# 4. XGBOOST MODEL
# ============================================================================
cat("4. Training XGBoost Model...\n")

# Use same data as CART/RF (already loaded)
cat("   Using data_cart.RData: ", nrow(data_cart), " observations\n")

# Train/test split (use same indices as CART for consistency)
data_train_xgb <- data_cart[train_indices_cart, ]
data_test_xgb <- data_cart[-train_indices_cart, ]

cat("   Training set: ", nrow(data_train_xgb), " observations (70%)\n")
cat("   Testing set: ", nrow(data_test_xgb), " observations (30%)\n")

# Prepare data for XGBoost (needs numeric matrix)
# Convert factors to numeric
data_train_xgb_numeric <- data_train_xgb
data_test_xgb_numeric <- data_test_xgb

# Convert factors to numeric codes
for(col in colnames(data_train_xgb_numeric)) {
  if(is.factor(data_train_xgb_numeric[[col]])) {
    if(col != "readmitted") {
      # Convert to numeric codes
      data_train_xgb_numeric[[col]] <- as.numeric(data_train_xgb_numeric[[col]]) - 1
      data_test_xgb_numeric[[col]] <- as.numeric(data_test_xgb_numeric[[col]]) - 1
    }
  }
}

# Separate features and target
X_train <- as.matrix(data_train_xgb_numeric[, colnames(data_train_xgb_numeric) != "readmitted"])
y_train <- as.numeric(data_train_xgb_numeric$readmitted == "Readmitted")
X_test <- as.matrix(data_test_xgb_numeric[, colnames(data_test_xgb_numeric) != "readmitted"])
y_test <- as.numeric(data_test_xgb_numeric$readmitted == "Readmitted")

# Create DMatrix for XGBoost
dtrain <- xgb.DMatrix(data = X_train, label = y_train)
dtest <- xgb.DMatrix(data = X_test, label = y_test)

# Set parameters
params <- list(
  objective = "binary:logistic",
  eval_metric = "auc",
  max_depth = 6,
  eta = 0.1,
  subsample = 0.8,
  colsample_bytree = 0.8,
  min_child_weight = 1
)

# Train model
cat("   Fitting model (this may take a few minutes)...\n")
model_xgb <- xgb.train(
  params = params,
  data = dtrain,
  nrounds = 200,
  evals = list(train = dtrain, test = dtest),
  early_stopping_rounds = 20,
  verbose = 0
)

cat("   Model fitted successfully!\n")
cat("   Best iteration: ", model_xgb$best_iteration, "\n")
# Get best score from evaluation log
if(!is.null(model_xgb$evaluation_log) && nrow(model_xgb$evaluation_log) > 0) {
  best_auc <- model_xgb$evaluation_log$test_auc[model_xgb$best_iteration]
  cat("   Best AUC: ", round(best_auc, 4), "\n\n")
} else {
  cat("   Best iteration completed\n\n")
}

# Save model
xgb.save(model_xgb, "model_xgb.model")
save(model_xgb, file = "model_xgb.RData")
cat("   Saved to model_xgb.RData and model_xgb.model\n\n")

# ============================================================================
# 5. NEURAL NETWORK MODEL
# ============================================================================
cat("5. Training Neural Network Model...\n")

# Use same data as CART/RF (already loaded)
cat("   Using data_cart.RData: ", nrow(data_cart), " observations\n")

# Train/test split (use same indices as CART for consistency)
data_train_nn <- data_cart[train_indices_cart, ]
data_test_nn <- data_cart[-train_indices_cart, ]

cat("   Training set: ", nrow(data_train_nn), " observations (70%)\n")
cat("   Testing set: ", nrow(data_test_nn), " observations (30%)\n")

# Prepare data: convert factors to dummy variables using model.matrix
# For neural networks, we need all numeric inputs
X_train_nn <- model.matrix(~ . - readmitted, data = data_train_nn)[, -1]  # Remove intercept
X_test_nn <- model.matrix(~ . - readmitted, data = data_test_nn)[, -1]

# Target variable (binary)
y_train_nn <- as.numeric(data_train_nn$readmitted == "Readmitted")
y_test_nn <- as.numeric(data_test_nn$readmitted == "Readmitted")

# Scale features (important for neural networks)
X_train_nn_scaled <- scale(X_train_nn)
X_test_nn_scaled <- scale(X_test_nn, 
                          center = attr(X_train_nn_scaled, "scaled:center"),
                          scale = attr(X_train_nn_scaled, "scaled:scale"))

# Store scaling parameters for later use
scaling_params <- list(
  center = attr(X_train_nn_scaled, "scaled:center"),
  scale = attr(X_train_nn_scaled, "scaled:scale")
)

# Train neural network
cat("   Fitting model (this may take a few minutes)...\n")
model_nn <- nnet(
  x = X_train_nn_scaled,
  y = y_train_nn,
  size = 10,        # Number of hidden units
  decay = 0.1,      # Weight decay (L2 regularization)
  maxit = 200,      # Maximum iterations
  trace = FALSE
)

cat("   Model fitted successfully!\n")
cat("   Hidden units: ", model_nn$n[2], "\n")
cat("   Weights: ", length(model_nn$wts), "\n")
cat("   Convergence: ", ifelse(model_nn$convergence == 0, "Yes", "No"), "\n\n")

# Save model and scaling parameters
save(model_nn, scaling_params, file = "model_nn.RData")
save(scaling_params, file = "scaling_params_nn.RData")
cat("   Saved to model_nn.RData and scaling_params_nn.RData\n\n")

# ============================================================================
# SUMMARY
# ============================================================================
cat("=== All Models Trained and Saved Successfully ===\n")
cat("\nSaved files:\n")
cat("  - model_logistic.RData\n")
cat("  - model_cart_final.RData\n")
cat("  - model_rf.RData\n")
cat("  - model_xgb.RData and model_xgb.model\n")
cat("  - model_nn.RData and scaling_params_nn.RData\n")
cat("\nYou can now run the Shiny app!\n")

