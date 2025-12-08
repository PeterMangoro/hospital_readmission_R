# Diagnostic Script: Compare Rmd vs Shiny Predictions
# This script verifies that predictions are consistent between the Rmd and Shiny app

library(caret)
library(pROC)

cat("=== Diagnostic: Comparing Rmd vs Shiny Predictions ===\n\n")

# ============================================================================
# 1. Load Models and Data
# ============================================================================
cat("1. Loading models and data...\n")
load("model_logistic.RData")
load("data_logistic.RData")
load("data_cart.RData")
source("app_helpers.R")

cat("   ✓ Models and data loaded\n\n")

# ============================================================================
# 2. Recreate Training Split (Same as Rmd)
# ============================================================================
cat("2. Recreating train/test split (same as Rmd)...\n")
set.seed(1)
train_indices <- createDataPartition(data_logistic$readmitted, 
                                     p = 0.7, 
                                     list = FALSE)
data_test_lr <- data_logistic[-train_indices, ]

cat("   ✓ Test set: ", nrow(data_test_lr), " observations\n\n")

# ============================================================================
# 3. Test Prediction on Actual Test Data
# ============================================================================
cat("3. Testing predictions on actual test data...\n")
pred_test <- predict(model_logistic, newdata = data_test_lr, type = "response")
cat("   Test set prediction range: ", round(min(pred_test), 3), " to ", round(max(pred_test), 3), "\n")
cat("   Test set prediction mean: ", round(mean(pred_test), 3), "\n")
cat("   Test set prediction median: ", round(median(pred_test), 3), "\n\n")

# ============================================================================
# 4. Test with Default Shiny App Values
# ============================================================================
cat("4. Testing with default Shiny app values...\n")

# Get factor levels
factor_levels <- get_factor_levels()

# Default inputs from app.R
default_inputs <- list(
  time_in_hospital = 3,
  n_lab_procedures = 43,
  n_procedures = 0,
  n_medications = 16,
  n_outpatient = 0,
  n_inpatient = 0,
  n_emergency = 0,
  n_diagnoses = 3,  # Changed from 9 to median (3)
  age = factor_levels$age[3],  # Third age group
  medical_specialty = "Missing",
  diag_1 = factor_levels$diag_1[1],
  change = factor_levels$change[1],
  diabetes_med = factor_levels$diabetes_med[1],
  glucose_test = factor_levels$glucose_test[1],
  A1Ctest = factor_levels$A1Ctest[1]
)

cat("   Default inputs (updated):\n")
cat("     n_diagnoses = ", default_inputs$n_diagnoses, " (Median in data: 3)\n", sep = "")
cat("     time_in_hospital = ", default_inputs$time_in_hospital, " (Median: 4)\n", sep = "")
cat("     n_lab_procedures = ", default_inputs$n_lab_procedures, " (Median: 44)\n", sep = "")
cat("     n_medications = ", default_inputs$n_medications, " (Median: 15)\n", sep = "")
cat("     Previous visits: all 0\n\n")

# Encode and predict
data_lr_default <- encode_for_logistic(default_inputs)
pred_default <- predict(model_logistic, newdata = data_lr_default, type = "response")

cat("   Prediction with defaults: ", round(pred_default * 100, 2), "%\n\n")

# ============================================================================
# 5. Test with Median Values (More Realistic)
# ============================================================================
cat("5. Testing with median/typical values...\n")

median_inputs <- list(
  time_in_hospital = 4,  # Median
  n_lab_procedures = 44,  # Median
  n_procedures = 1,  # Median
  n_medications = 15,  # Median
  n_outpatient = 0,
  n_inpatient = 0,
  n_emergency = 0,
  n_diagnoses = 3,  # Median (was 9!)
  age = factor_levels$age[3],
  medical_specialty = "Missing",
  diag_1 = factor_levels$diag_1[1],
  change = factor_levels$change[1],
  diabetes_med = factor_levels$diabetes_med[1],
  glucose_test = factor_levels$glucose_test[1],
  A1Ctest = factor_levels$A1Ctest[1]
)

data_lr_median <- encode_for_logistic(median_inputs)
pred_median <- predict(model_logistic, newdata = data_lr_median, type = "response")

cat("   Prediction with median values: ", round(pred_median * 100, 2), "%\n\n")

# ============================================================================
# 6. Test with Low-Risk Profile
# ============================================================================
cat("6. Testing with low-risk profile...\n")

low_risk_inputs <- list(
  time_in_hospital = 2,  # Low
  n_lab_procedures = 30,  # Low
  n_procedures = 0,  # Low
  n_medications = 10,  # Low
  n_outpatient = 0,  # No previous visits
  n_inpatient = 0,
  n_emergency = 0,
  n_diagnoses = 1,  # Low
  age = factor_levels$age[1],  # Youngest
  medical_specialty = "Missing",
  diag_1 = factor_levels$diag_1[1],
  change = "no",  # No medication change
  diabetes_med = "no",  # No diabetes med
  glucose_test = "no",
  A1Ctest = "no"
)

data_lr_low <- encode_for_logistic(low_risk_inputs)
pred_low <- predict(model_logistic, newdata = data_lr_low, type = "response")

cat("   Prediction with low-risk profile: ", round(pred_low * 100, 2), "%\n\n")

# ============================================================================
# 7. Test with High-Risk Profile
# ============================================================================
cat("7. Testing with high-risk profile...\n")

high_risk_inputs <- list(
  time_in_hospital = 7,  # High
  n_lab_procedures = 60,  # High
  n_procedures = 3,  # High
  n_medications = 25,  # High
  n_outpatient = 5,  # Previous visits
  n_inpatient = 2,  # Previous inpatient
  n_emergency = 3,  # Previous emergency
  n_diagnoses = 3,  # Multiple diagnoses
  age = factor_levels$age[length(factor_levels$age)],  # Oldest
  medical_specialty = "Emergency/Trauma",
  diag_1 = factor_levels$diag_1[1],
  change = "yes",  # Medication change
  diabetes_med = "yes",  # Diabetes med
  glucose_test = "yes",
  A1Ctest = "yes"
)

data_lr_high <- encode_for_logistic(high_risk_inputs)
pred_high <- predict(model_logistic, newdata = data_lr_high, type = "response")

cat("   Prediction with high-risk profile: ", round(pred_high * 100, 2), "%\n\n")

# ============================================================================
# 8. Compare Encoded Data Structure
# ============================================================================
cat("8. Verifying encoded data structure...\n")
cat("   Training data columns: ", length(colnames(data_logistic)) - 1, " predictors\n")
cat("   Encoded data columns: ", length(colnames(data_lr_default)), " predictors\n")

missing_cols <- setdiff(colnames(data_logistic)[colnames(data_logistic) != "readmitted"], 
                        colnames(data_lr_default))
extra_cols <- setdiff(colnames(data_lr_default), 
                     colnames(data_logistic)[colnames(data_logistic) != "readmitted"])

if(length(missing_cols) > 0) {
  cat("   ⚠ WARNING: Missing columns in encoded data:\n")
  cat("      ", paste(missing_cols, collapse = ", "), "\n")
} else {
  cat("   ✓ All required columns present\n")
}

if(length(extra_cols) > 0) {
  cat("   ⚠ WARNING: Extra columns in encoded data:\n")
  cat("      ", paste(extra_cols, collapse = ", "), "\n")
}

cat("\n")

# ============================================================================
# 9. Summary
# ============================================================================
cat("=== Summary ===\n\n")
cat("Predictions:\n")
cat("  Default Shiny inputs:     ", round(pred_default * 100, 2), "%\n")
cat("  Median values:            ", round(pred_median * 100, 2), "%\n")
cat("  Low-risk profile:         ", round(pred_low * 100, 2), "%\n")
cat("  High-risk profile:        ", round(pred_high * 100, 2), "%\n")
cat("  Test set mean:            ", round(mean(pred_test) * 100, 2), "%\n")
cat("  Test set median:          ", round(median(pred_test) * 100, 2), "%\n\n")

cat("Key Findings:\n")
if(pred_default > 0.6) {
  cat("  ⚠ Default prediction is HIGH (", round(pred_default * 100, 2), "%)\n", sep = "")
  cat("     - n_diagnoses = 9 is much higher than median (3)\n")
  cat("     - This is likely causing high predictions\n")
}
if(pred_median < pred_default) {
  cat("  ✓ Using median n_diagnoses (3) reduces prediction to ", round(pred_median * 100, 2), "%\n", sep = "")
}
cat("\n")

cat("Recommendations:\n")
cat("  1. Change default n_diagnoses from 9 to 3 (median)\n")
cat("  2. Verify encoding matches training data exactly\n")
cat("  3. Consider using median values for all defaults\n\n")

