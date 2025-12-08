# Verification Script: Compare All Model Predictions (Rmd vs Shiny)
# This script verifies that Logistic Regression, CART, and Random Forest
# predictions match between the Rmd report and Shiny app

library(caret)
library(pROC)
library(randomForest)

cat("=== Verification: All Model Predictions (Rmd vs Shiny) ===\n\n")

# ============================================================================
# 1. Load Models and Data
# ============================================================================
cat("1. Loading models and data...\n")
load("model_logistic.RData")
load("model_cart_final.RData")
load("model_rf.RData")
load("data_logistic.RData")
load("data_cart.RData")
source("app_helpers.R")

cat("   ✓ All models and data loaded\n\n")

# ============================================================================
# 2. Recreate Training Split (Same as Rmd)
# ============================================================================
cat("2. Recreating train/test split (same as Rmd)...\n")
set.seed(1)
train_indices_lr <- createDataPartition(data_logistic$readmitted, p = 0.7, list = FALSE)
train_indices_cart <- createDataPartition(data_cart$readmitted, p = 0.7, list = FALSE)

data_test_lr <- data_logistic[-train_indices_lr, ]
data_test_cart <- data_cart[-train_indices_cart, ]

cat("   ✓ Test sets created\n")
cat("     - Logistic Regression test set: ", nrow(data_test_lr), " observations\n")
cat("     - CART/RF test set: ", nrow(data_test_cart), " observations\n\n")

# ============================================================================
# 3. Test Predictions on Actual Test Data
# ============================================================================
cat("3. Testing predictions on actual test data...\n")

# Logistic Regression
pred_lr_test <- predict(model_logistic, newdata = data_test_lr, type = "response")
cat("   Logistic Regression:\n")
cat("     Range: ", round(min(pred_lr_test), 3), " to ", round(max(pred_lr_test), 3), "\n")
cat("     Mean: ", round(mean(pred_lr_test), 3), "\n")
cat("     Median: ", round(median(pred_lr_test), 3), "\n")

# CART
pred_cart_test <- predict(model_cart_final, newdata = data_test_cart, type = "prob")[, "Readmitted"]
cat("   CART:\n")
cat("     Range: ", round(min(pred_cart_test), 3), " to ", round(max(pred_cart_test), 3), "\n")
cat("     Mean: ", round(mean(pred_cart_test), 3), "\n")
cat("     Median: ", round(median(pred_cart_test), 3), "\n")

# Random Forest (formula interface - can include readmitted, it will be ignored)
pred_rf_test <- predict(model_rf, newdata = data_test_cart, type = "prob")[, "Readmitted"]
cat("   Random Forest:\n")
cat("     Range: ", round(min(pred_rf_test), 3), " to ", round(max(pred_rf_test), 3), "\n")
cat("     Mean: ", round(mean(pred_rf_test), 3), "\n")
cat("     Median: ", round(median(pred_rf_test), 3), "\n\n")

# ============================================================================
# 4. Test with Default Shiny App Values
# ============================================================================
cat("4. Testing with default Shiny app values...\n")

# Get factor levels
factor_levels <- get_factor_levels()

# Default inputs from app.R (after fix)
default_inputs <- list(
  time_in_hospital = 3,
  n_lab_procedures = 43,
  n_procedures = 0,
  n_medications = 16,
  n_outpatient = 0,
  n_inpatient = 0,
  n_emergency = 0,
  n_diagnoses = 3,  # Fixed from 9 to 3
  age = factor_levels$age[3],
  medical_specialty = "Missing",
  diag_1 = factor_levels$diag_1[1],
  change = factor_levels$change[1],
  diabetes_med = factor_levels$diabetes_med[1],
  glucose_test = factor_levels$glucose_test[1],
  A1Ctest = factor_levels$A1Ctest[1]
)

# Encode for each model
data_lr_default <- encode_for_logistic(default_inputs)
data_cart_default <- encode_for_cart(default_inputs)

# Make predictions
pred_lr_default <- predict(model_logistic, newdata = data_lr_default, type = "response")
pred_cart_default <- predict(model_cart_final, newdata = data_cart_default, type = "prob")[, "Readmitted"]
# Random Forest (formula interface - can include readmitted, it will be ignored)
# But encode_for_cart doesn't include readmitted, so we need to add it temporarily
data_cart_default_with_response <- data_cart_default
data_cart_default_with_response$readmitted <- factor("Not Readmitted", levels = c("Not Readmitted", "Readmitted"))
pred_rf_default <- predict(model_rf, newdata = data_cart_default_with_response, type = "prob")[, "Readmitted"]

cat("   Default inputs predictions:\n")
cat("     Logistic Regression: ", round(pred_lr_default * 100, 2), "%\n")
cat("     CART:                ", round(pred_cart_default * 100, 2), "%\n")
cat("     Random Forest:       ", round(pred_rf_default * 100, 2), "%\n\n")

# ============================================================================
# 5. Test with Sample from Test Data (Direct Comparison)
# ============================================================================
cat("5. Testing with sample from test data (direct comparison)...\n")

# Pick a few random samples from test data
set.seed(42)
sample_indices <- sample(nrow(data_test_cart), min(5, nrow(data_test_cart)))

# For each sample, compare Rmd-style prediction vs Shiny-style prediction
cat("   Comparing predictions for ", length(sample_indices), " test samples:\n\n")

all_match <- TRUE
for(i in seq_along(sample_indices)) {
  idx <- sample_indices[i]
  
  # Get actual test data row
  test_row_cart <- data_test_cart[idx, ]
  
  # Make prediction using Rmd method (direct from test data)
  pred_cart_rmd <- predict(model_cart_final, newdata = test_row_cart, type = "prob")[, "Readmitted"]
  pred_rf_rmd <- predict(model_rf, newdata = test_row_cart, type = "prob")[, "Readmitted"]
  
  # Convert test row to Shiny input format
  shiny_inputs <- list(
    time_in_hospital = test_row_cart$time_in_hospital,
    n_lab_procedures = test_row_cart$n_lab_procedures,
    n_procedures = test_row_cart$n_procedures,
    n_medications = test_row_cart$n_medications,
    n_outpatient = test_row_cart$n_outpatient,
    n_inpatient = test_row_cart$n_inpatient,
    n_emergency = test_row_cart$n_emergency,
    n_diagnoses = test_row_cart$n_diagnoses,
    age = as.character(test_row_cart$age),
    medical_specialty = as.character(test_row_cart$medical_specialty),
    diag_1 = as.character(test_row_cart$diag_1),
    change = as.character(test_row_cart$change),
    diabetes_med = as.character(test_row_cart$diabetes_med),
    glucose_test = as.character(test_row_cart$glucose_test),
    A1Ctest = as.character(test_row_cart$A1Ctest)
  )
  
  # Encode and predict using Shiny method
  data_cart_shiny <- encode_for_cart(shiny_inputs)
  pred_cart_shiny <- predict(model_cart_final, newdata = data_cart_shiny, type = "prob")[, "Readmitted"]
  # Random Forest needs readmitted column (formula interface), add it temporarily
  data_cart_shiny_rf <- data_cart_shiny
  data_cart_shiny_rf$readmitted <- factor("Not Readmitted", levels = c("Not Readmitted", "Readmitted"))
  pred_rf_shiny <- predict(model_rf, newdata = data_cart_shiny_rf, type = "prob")[, "Readmitted"]
  
  # Compare
  cart_diff <- abs(pred_cart_rmd - pred_cart_shiny)
  rf_diff <- abs(pred_rf_rmd - pred_rf_shiny)
  
  cart_match <- cart_diff < 0.0001  # Allow tiny floating point differences
  rf_match <- rf_diff < 0.0001
  
  if(cart_match && rf_match) {
    cat("   Sample ", i, ": ✓ MATCH\n", sep = "")
    cat("      CART: Rmd=", round(pred_cart_rmd, 4), ", Shiny=", round(pred_cart_shiny, 4), 
        " (diff=", round(cart_diff, 6), ")\n", sep = "")
    cat("      RF:  Rmd=", round(pred_rf_rmd, 4), ", Shiny=", round(pred_rf_shiny, 4), 
        " (diff=", round(rf_diff, 6), ")\n", sep = "")
  } else {
    cat("   Sample ", i, ": ✗ MISMATCH\n", sep = "")
    cat("      CART: Rmd=", round(pred_cart_rmd, 4), ", Shiny=", round(pred_cart_shiny, 4), 
        " (diff=", round(cart_diff, 6), ")\n", sep = "")
    cat("      RF:  Rmd=", round(pred_rf_rmd, 4), ", Shiny=", round(pred_rf_shiny, 4), 
        " (diff=", round(rf_diff, 6), ")\n", sep = "")
    all_match <- FALSE
  }
}

cat("\n")

# ============================================================================
# 6. Verify Data Structure Match
# ============================================================================
cat("6. Verifying data structure match...\n")

# Check CART encoding
test_inputs <- default_inputs
data_cart_encoded <- encode_for_cart(test_inputs)

# Check column names match
cart_cols_match <- all(colnames(data_cart_encoded) %in% colnames(data_cart))
cart_cols_exact <- setequal(colnames(data_cart_encoded), colnames(data_cart))

if(cart_cols_match && cart_cols_exact) {
  cat("   ✓ CART data structure matches perfectly\n")
} else {
  cat("   ⚠ CART data structure issues:\n")
  missing_cols <- setdiff(colnames(data_cart), colnames(data_cart_encoded))
  extra_cols <- setdiff(colnames(data_cart_encoded), colnames(data_cart))
  if(length(missing_cols) > 0) {
    cat("      Missing columns: ", paste(missing_cols, collapse = ", "), "\n")
  }
  if(length(extra_cols) > 0) {
    cat("      Extra columns: ", paste(extra_cols, collapse = ", "), "\n")
  }
}

# Check factor levels match
factor_issues <- c()
for(col in c("age", "medical_specialty", "diag_1", "change", "diabetes_med", "glucose_test", "A1Ctest")) {
  if(col %in% colnames(data_cart) && col %in% colnames(data_cart_encoded)) {
    levels_train <- levels(data_cart[[col]])
    levels_encoded <- levels(data_cart_encoded[[col]])
    if(!setequal(levels_train, levels_encoded)) {
      factor_issues <- c(factor_issues, col)
    }
  }
}

if(length(factor_issues) == 0) {
  cat("   ✓ All factor levels match\n")
} else {
  cat("   ⚠ Factor level mismatches in: ", paste(factor_issues, collapse = ", "), "\n")
}

cat("\n")

# ============================================================================
# 7. Summary
# ============================================================================
cat("=== Summary ===\n\n")

cat("Test Results:\n")
cat("  ✓ All models loaded successfully\n")
cat("  ✓ Test data predictions calculated\n")
cat("  ✓ Default input predictions calculated\n")

if(all_match) {
  cat("  ✓ CART and RF predictions MATCH between Rmd and Shiny\n")
} else {
  cat("  ✗ CART and/or RF predictions DO NOT MATCH - investigation needed\n")
}

cat("\nPrediction Ranges (Test Data):\n")
cat("  Logistic Regression: ", round(min(pred_lr_test), 3), " - ", round(max(pred_lr_test), 3), 
    " (mean: ", round(mean(pred_lr_test), 3), ")\n", sep = "")
cat("  CART:                ", round(min(pred_cart_test), 3), " - ", round(max(pred_cart_test), 3), 
    " (mean: ", round(mean(pred_cart_test), 3), ")\n", sep = "")
cat("  Random Forest:       ", round(min(pred_rf_test), 3), " - ", round(max(pred_rf_test), 3), 
    " (mean: ", round(mean(pred_rf_test), 3), ")\n", sep = "")

cat("\nDefault Input Predictions:\n")
cat("  Logistic Regression: ", round(pred_lr_default * 100, 2), "%\n")
cat("  CART:                ", round(pred_cart_default * 100, 2), "%\n")
cat("  Random Forest:       ", round(pred_rf_default * 100, 2), "%\n")

cat("\n")

