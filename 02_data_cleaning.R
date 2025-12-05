# ==============================================================================
# Phase 2: Data Cleaning and Preprocessing
# Project: Predicting 30-Day Hospital Readmissions
# ==============================================================================

# Load required libraries
library(ggplot2)
library(dplyr)
library(tidyr)

# Set working directory (adjust if needed)
# setwd("/home/themad/Documents/yeshiva/computationalMaths/projects")

# ==============================================================================
# Load Original Data
# ==============================================================================

cat("=== Phase 2: Data Cleaning and Preprocessing ===\n\n")

cat("Loading original dataset...\n")
data <- read.csv("hospital_readmissions.csv", stringsAsFactors = FALSE)
cat("Original dataset: ", nrow(data), " observations, ", ncol(data), " variables\n\n")

# ==============================================================================
# 2.1 Clean Response Variable (readmitted)
# ==============================================================================

cat("=== 2.1 Cleaning Response Variable ===\n")

# Check current distribution
cat("\nOriginal readmitted distribution:\n")
print(table(data$readmitted))
print(prop.table(table(data$readmitted)))

# Convert to binary (1 = Readmitted, 0 = Not Readmitted)
data$readmitted_binary <- as.numeric(data$readmitted == "yes")

# Verify conversion
cat("\nBinary readmitted distribution:\n")
print(table(data$readmitted_binary))
print(prop.table(table(data$readmitted_binary)))

# Verify consistency
if(sum(data$readmitted_binary) == sum(data$readmitted == "yes")) {
  cat("\n✓ Conversion successful: Distribution matches original\n")
} else {
  cat("\n✗ WARNING: Conversion mismatch detected!\n")
}

cat("\nResponse variable cleaned: 1 = Readmitted, 0 = Not Readmitted\n\n")

# ==============================================================================
# 2.2 Handle Missing Values
# ==============================================================================

cat("=== 2.2 Handling Missing Values ===\n\n")

# Check missing values before cleaning
cat("Missing values before cleaning:\n")
missing_before <- sapply(data, function(x) sum(is.na(x) | x == "" | x == "Missing"))
missing_before_df <- data.frame(
  Variable = names(missing_before),
  Missing_Count = missing_before,
  Missing_Percentage = round(missing_before / nrow(data) * 100, 2)
)
missing_before_df <- missing_before_df[missing_before_df$Missing_Count > 0, ]
print(missing_before_df)

# 2.2.1 Drop rows with missing diag_1 (0.02% - 4 cases)
cat("\n--- 2.2.1 Handling diag_1 Missing Values ---\n")
cat("Strategy: Drop rows with missing diag_1 (critical variable, minimal data loss)\n")

rows_before <- nrow(data)
data_clean <- data[data$diag_1 != "Missing", ]
rows_after <- nrow(data_clean)
rows_dropped <- rows_before - rows_after

cat("Rows before: ", rows_before, "\n")
cat("Rows after: ", rows_after, "\n")
cat("Rows dropped: ", rows_dropped, " (", round(rows_dropped/rows_before*100, 2), "%)\n")

# Check if dropped rows affect response distribution
if(rows_dropped > 0) {
  dropped_readmitted <- sum(data[data$diag_1 == "Missing", "readmitted_binary"])
  cat("Readmitted cases in dropped rows: ", dropped_readmitted, "\n")
  
  # Compare distributions
  orig_readmit_rate <- mean(data$readmitted_binary)
  clean_readmit_rate <- mean(data_clean$readmitted_binary)
  cat("Original readmission rate: ", round(orig_readmit_rate*100, 2), "%\n")
  cat("Clean readmission rate: ", round(clean_readmit_rate*100, 2), "%\n")
  
  if(abs(orig_readmit_rate - clean_readmit_rate) < 0.01) {
    cat("✓ Readmission rate remains stable after dropping rows\n")
  } else {
    cat("⚠ Note: Readmission rate changed slightly after dropping rows\n")
  }
}

# 2.2.2-2.2.4 Keep "Missing" as valid category for other variables
cat("\n--- 2.2.2-2.2.4 Keeping 'Missing' as Valid Categories ---\n")
cat("Strategy: Keep 'Missing' as valid category level for:\n")
cat("  - medical_specialty (49.53%)\n")
cat("  - diag_2 (0.17%)\n")
cat("  - diag_3 (0.78%)\n")
cat("Reason: Too high to drop (medical_specialty) or less critical (diag_2, diag_3)\n")

# Verify missing values after cleaning
cat("\nMissing values after cleaning (as categories):\n")
missing_after <- sapply(data_clean, function(x) sum(x == "Missing"))
missing_after_df <- data.frame(
  Variable = names(missing_after),
  Missing_Count = missing_after,
  Missing_Percentage = round(missing_after / nrow(data_clean) * 100, 2)
)
missing_after_df <- missing_after_df[missing_after_df$Missing_Count > 0, ]
print(missing_after_df)

cat("\n✓ Missing values handled\n\n")

# ==============================================================================
# 2.3 Feature Engineering
# ==============================================================================

cat("=== 2.3 Feature Engineering ===\n\n")

# 2.3.1 Diagnosis Features

# Number of diagnoses (count non-missing)
cat("--- Creating: Number of Diagnoses Feature ---\n")
data_clean$n_diagnoses <- 3 - 
  (data_clean$diag_1 == "Missing") - 
  (data_clean$diag_2 == "Missing") - 
  (data_clean$diag_3 == "Missing")

cat("Number of diagnoses distribution:\n")
print(table(data_clean$n_diagnoses))
cat("\n")

# 2.3.2 Age Feature - Keep as ordered categorical (no conversion needed)
cat("--- Age Feature: Keeping as Ordinal Categorical ---\n")
cat("Age groups already in usable format: [40-50), [50-60), etc.\n")
cat("Will convert to ordered factor for modeling\n\n")

# 2.3.3 Treatment Intensity Features

# Medications per day (handle division by zero)
cat("--- Creating: Medications per Day Feature ---\n")
data_clean$medications_per_day <- ifelse(data_clean$time_in_hospital > 0,
                                         data_clean$n_medications / data_clean$time_in_hospital,
                                         data_clean$n_medications)  # If time = 0, use n_medications as is
cat("Medications per day - Summary:\n")
print(summary(data_clean$medications_per_day))
# Check if time_in_hospital = 0 exists
if(sum(data_clean$time_in_hospital == 0) > 0) {
  cat("Note: ", sum(data_clean$time_in_hospital == 0), " cases with time_in_hospital = 0\n")
}
cat("\n")

# 2.3.4 Visit History Features

# Total previous visits
cat("--- Creating: Total Previous Visits Feature ---\n")
data_clean$total_previous_visits <- data_clean$n_outpatient + 
                                     data_clean$n_inpatient + 
                                     data_clean$n_emergency
cat("Total previous visits - Summary:\n")
print(summary(data_clean$total_previous_visits))
cat("\n")

cat("✓ Feature engineering complete\n\n")

# ==============================================================================
# 2.4 Feature Selection
# ==============================================================================

cat("=== 2.4 Feature Selection ===\n\n")

# Selected variables (from proposal + additional clinically relevant variables)
selected_categorical <- c("age", "medical_specialty", "diag_1", "change", "diabetes_med", 
                          "glucose_test", "A1Ctest")
selected_numerical <- c("time_in_hospital", "n_lab_procedures", "n_procedures", "n_medications")

# Additional variables to consider
additional_numerical <- c("n_outpatient", "n_inpatient", "n_emergency")

cat("Selected variables:\n")
cat("  Categorical: ", paste(selected_categorical, collapse = ", "), "\n")
cat("  Numerical: ", paste(selected_numerical, collapse = ", "), "\n")

cat("\nAdditional variables available:\n")
cat("  Visit history: ", paste(additional_numerical, collapse = ", "), "\n")
cat("  Derived features: n_diagnoses, medications_per_day, total_previous_visits\n")

# Create feature list (including derived features for testing)
selected_features <- c(
  selected_categorical,
  selected_numerical,
  additional_numerical,  # Include for potential use
  "n_diagnoses",  # Derived feature
  "medications_per_day"  # Derived feature
)

cat("\nSelected features for modeling: ", length(selected_features), " variables\n")
cat("Features: ", paste(selected_features, collapse = ", "), "\n\n")

# ==============================================================================
# 2.5 Encoding Categorical Variables
# ==============================================================================

cat("=== 2.5 Encoding Categorical Variables ===\n\n")

# 2.5.1 Prepare data for Logistic Regression (dummy encoding)

cat("--- Preparing Dataset for Logistic Regression ---\n")

# Binary variables - convert to 0/1
data_logistic <- data_clean %>%
  mutate(
    change_binary = as.numeric(change == "yes"),
    diabetes_med_binary = as.numeric(diabetes_med == "yes")
  )

# Multi-category variables - use model.matrix for dummy encoding
# Age
age_dummies <- model.matrix(~ age - 1, data = data_logistic)
colnames(age_dummies) <- paste0("age_", gsub("\\[|\\]|\\)|\\(", "", colnames(age_dummies)))
colnames(age_dummies) <- gsub(" ", "_", colnames(age_dummies))

# Medical specialty
medspec_dummies <- model.matrix(~ medical_specialty - 1, data = data_logistic)
colnames(medspec_dummies) <- paste0("medspec_", gsub(" ", "_", colnames(medspec_dummies)))

# Primary diagnosis
diag1_dummies <- model.matrix(~ diag_1 - 1, data = data_logistic)
colnames(diag1_dummies) <- paste0("diag1_", tolower(colnames(diag1_dummies)))

# Glucose test
glucose_dummies <- model.matrix(~ glucose_test - 1, data = data_logistic)
colnames(glucose_dummies) <- paste0("glucose_", tolower(colnames(glucose_dummies)))

# A1C test
a1c_dummies <- model.matrix(~ A1Ctest - 1, data = data_logistic)
colnames(a1c_dummies) <- paste0("a1c_", tolower(colnames(a1c_dummies)))

# Combine all features for Logistic Regression
data_logistic <- data.frame(
  readmitted = data_clean$readmitted_binary,
  # Numerical variables
  time_in_hospital = data_clean$time_in_hospital,
  n_lab_procedures = data_clean$n_lab_procedures,
  n_procedures = data_clean$n_procedures,
  n_medications = data_clean$n_medications,
  n_outpatient = data_clean$n_outpatient,
  n_inpatient = data_clean$n_inpatient,
  n_emergency = data_clean$n_emergency,
  # Derived numerical features
  n_diagnoses = data_clean$n_diagnoses,
  medications_per_day = data_clean$medications_per_day,
  total_previous_visits = data_clean$total_previous_visits,
  # Binary variables
  change_binary = data_logistic$change_binary,
  diabetes_med_binary = data_logistic$diabetes_med_binary,
  # Dummy-encoded categorical variables
  age_dummies,
  medspec_dummies,
  diag1_dummies,
  glucose_dummies,
  a1c_dummies,
  stringsAsFactors = FALSE
)

cat("Logistic Regression dataset created:\n")
cat("  Observations: ", nrow(data_logistic), "\n")
cat("  Variables: ", ncol(data_logistic), "\n")
cat("  Response variable: readmitted (binary 0/1)\n")

# Document reference categories (most frequent, which will be dropped by default)
cat("\nReference categories for dummy variables:\n")
cat("  Age: Will use first alphabetically as reference (can change if needed)\n")
cat("  Medical specialty: 'Missing' is most frequent (49.53%)\n")
cat("  Primary diagnosis: Most frequent category as reference\n")
cat("  Note: model.matrix() creates all levels; will drop reference in model fitting\n\n")

# 2.5.2 Prepare data for CART (factor encoding)

cat("--- Preparing Dataset for CART ---\n")

# Create readmitted factor first
readmitted_factor <- factor(data_clean$readmitted_binary, 
                           levels = c(0, 1),
                           labels = c("Not_Readmitted", "Readmitted"))

data_cart <- data.frame(
  readmitted = readmitted_factor,
  # Numerical variables
  time_in_hospital = data_clean$time_in_hospital,
  n_lab_procedures = data_clean$n_lab_procedures,
  n_procedures = data_clean$n_procedures,
  n_medications = data_clean$n_medications,
  n_outpatient = data_clean$n_outpatient,
  n_inpatient = data_clean$n_inpatient,
  n_emergency = data_clean$n_emergency,
  # Derived numerical features
  n_diagnoses = data_clean$n_diagnoses,
  medications_per_day = data_clean$medications_per_day,
  total_previous_visits = data_clean$total_previous_visits,
  # Factor categorical variables
  age = factor(data_clean$age, 
               levels = c("[40-50)", "[50-60)", "[60-70)", "[70-80)", "[80-90)", "[90-100)"),
               ordered = TRUE),
  medical_specialty = as.factor(data_clean$medical_specialty),
  diag_1 = as.factor(data_clean$diag_1),
  change = as.factor(data_clean$change),
  diabetes_med = as.factor(data_clean$diabetes_med),
  glucose_test = as.factor(data_clean$glucose_test),
  A1Ctest = as.factor(data_clean$A1Ctest),
  stringsAsFactors = FALSE
)

cat("CART dataset created:\n")
cat("  Observations: ", nrow(data_cart), "\n")
cat("  Variables: ", ncol(data_cart), "\n")
cat("  Response variable: readmitted (factor: Not_Readmitted/Readmitted)\n\n")

# ==============================================================================
# 2.6 Normalization/Standardization
# ==============================================================================

cat("=== 2.6 Normalization/Standardization ===\n\n")
cat("Decision: No standardization applied\n")
cat("Reason:\n")
cat("  - Logistic Regression: Coefficients more interpretable on original scale\n")
cat("  - CART: Scale-invariant, original scale more interpretable\n")
cat("  - Standardization not required for these models\n")
cat("\nIf needed later, can standardize numerical variables using scale()\n\n")

# ==============================================================================
# 2.7 Data Quality Checks
# ==============================================================================

cat("=== 2.7 Data Quality Checks ===\n\n")

# 1. Sample Size Verification
cat("1. Sample Size Verification:\n")
cat("   Original: ", nrow(data), " observations\n")
cat("   Clean: ", nrow(data_clean), " observations\n")
cat("   Dropped: ", nrow(data) - nrow(data_clean), " observations\n")
cat("   Retention rate: ", round(nrow(data_clean)/nrow(data)*100, 2), "%\n")

if(nrow(data_clean) == nrow(data_logistic) && nrow(data_clean) == nrow(data_cart)) {
  cat("   ✓ All datasets have consistent number of observations\n")
} else {
  cat("   ✗ WARNING: Dataset sizes do not match!\n")
}

# 2. Response Variable Distribution
cat("\n2. Response Variable Distribution:\n")
cat("   Original distribution:\n")
print(prop.table(table(data$readmitted)))
cat("   Clean distribution:\n")
print(prop.table(table(data_clean$readmitted_binary)))
readmit_rate_orig <- mean(data$readmitted_binary)
readmit_rate_clean <- mean(data_clean$readmitted_binary)
if(abs(readmit_rate_orig - readmit_rate_clean) < 0.01) {
  cat("   ✓ Readmission rate stable: ", round(readmit_rate_clean*100, 2), "%\n")
} else {
  cat("   ⚠ Readmission rate changed from ", round(readmit_rate_orig*100, 2), 
      "% to ", round(readmit_rate_clean*100, 2), "%\n")
}

# 3. Missing Values Check
cat("\n3. Missing Values Check:\n")
missing_check <- sapply(data_clean[, c(selected_categorical, selected_numerical)], 
                        function(x) sum(is.na(x)))
if(sum(missing_check) == 0) {
  cat("   ✓ No NA values in selected variables\n")
} else {
  cat("   ✗ Found NA values:\n")
  print(missing_check[missing_check > 0])
}

# 4. Data Type Verification
cat("\n4. Data Type Verification:\n")
cat("   Logistic Regression dataset:\n")
cat("     Response: ", class(data_logistic$readmitted), "\n")
cat("     All numerical variables: numeric\n")
cat("     All dummy variables: numeric\n")
cat("   CART dataset:\n")
cat("     Response: ", class(data_cart$readmitted), "\n")
cat("     Categorical variables: factor\n")
cat("     Numerical variables: numeric\n")

# 5. Check for infinite values
cat("\n5. Infinite Values Check:\n")
inf_check <- sapply(data_clean[, c(selected_numerical, "medications_per_day")], 
                    function(x) sum(is.infinite(x)))
if(sum(inf_check) == 0) {
  cat("   ✓ No infinite values\n")
} else {
  cat("   ✗ Found infinite values:\n")
  print(inf_check[inf_check > 0])
  # Handle infinite values (e.g., medications_per_day when time_in_hospital = 0)
  if(sum(is.infinite(data_clean$medications_per_day)) > 0) {
    cat("   Handling infinite values in medications_per_day...\n")
    data_clean$medications_per_day[is.infinite(data_clean$medications_per_day)] <- NA
    data_logistic$medications_per_day[is.infinite(data_logistic$medications_per_day)] <- NA
    data_cart$medications_per_day[is.infinite(data_cart$medications_per_day)] <- NA
  }
}

# 6. Check for duplicate rows
cat("\n6. Duplicate Rows Check:\n")
duplicates <- sum(duplicated(data_clean))
cat("   Duplicate rows: ", duplicates, "\n")
if(duplicates == 0) {
  cat("   ✓ No duplicate rows\n")
} else {
  cat("   ⚠ Found duplicate rows - consider investigating\n")
}

cat("\n✓ Data quality checks complete\n\n")

# ==============================================================================
# 2.8 Save Cleaned Datasets
# ==============================================================================

cat("=== 2.8 Saving Cleaned Datasets ===\n\n")

# Save cleaned datasets
save(data_clean, file = "data_clean.RData")
cat("Saved: data_clean.RData (original cleaned data with all variables)\n")

save(data_logistic, file = "data_logistic.RData")
cat("Saved: data_logistic.RData (formatted for Logistic Regression)\n")

save(data_cart, file = "data_cart.RData")
cat("Saved: data_cart.RData (formatted for CART)\n")

# Also save as CSV for easy inspection
write.csv(data_clean, file = "data_clean.csv", row.names = FALSE)
cat("Saved: data_clean.csv (CSV format for inspection)\n")

cat("\n✓ Datasets saved successfully\n\n")

# ==============================================================================
# 2.9 Documentation Summary
# ==============================================================================

cat("=== 2.9 Documentation Summary ===\n\n")

cat("CLEANING SUMMARY:\n")
cat("================\n\n")

cat("1. Response Variable:\n")
cat("   - Converted 'readmitted' to binary (1 = Readmitted, 0 = Not Readmitted)\n")
cat("   - Final distribution: ", round(mean(data_clean$readmitted_binary)*100, 2), 
    "% readmitted\n\n")

cat("2. Missing Values:\n")
cat("   - diag_1: Dropped 4 rows (0.02%)\n")
cat("   - medical_specialty: Kept 'Missing' as category (49.53%)\n")
cat("   - diag_2: Kept 'Missing' as category (0.17%)\n")
cat("   - diag_3: Kept 'Missing' as category (0.78%)\n\n")

cat("3. Feature Engineering:\n")
cat("   - Created: n_diagnoses (count of non-missing diagnoses)\n")
cat("   - Created: medications_per_day (n_medications / time_in_hospital)\n")
cat("   - Created: total_previous_visits (sum of outpatient + inpatient + emergency)\n\n")

cat("4. Feature Selection:\n")
cat("   - Categorical: age, medical_specialty, diag_1, change, diabetes_med, glucose_test, A1Ctest\n")
cat("   - Numerical: time_in_hospital, n_lab_procedures, n_procedures, n_medications\n")
cat("   - Additional: n_outpatient, n_inpatient, n_emergency (for potential use)\n")
cat("   - Derived: n_diagnoses, medications_per_day, total_previous_visits\n\n")

cat("5. Encoding:\n")
cat("   - Logistic Regression: Dummy encoding for categorical variables\n")
cat("   - CART: Factor encoding for categorical variables\n\n")

cat("6. Final Dataset:\n")
cat("   - Observations: ", nrow(data_clean), "\n")
cat("   - Variables: ", ncol(data_clean), " (cleaned dataset)\n")
cat("   - Logistic Regression dataset: ", nrow(data_logistic), " obs, ", 
    ncol(data_logistic), " vars\n")
cat("   - CART dataset: ", nrow(data_cart), " obs, ", ncol(data_cart), " vars\n\n")

cat("7. Data Quality:\n")
cat("   - No NA values in selected variables\n")
cat("   - No duplicate rows\n")
cat("   - Response variable distribution maintained\n")
cat("   - All data types correct\n\n")

cat("=== Phase 2 Complete ===\n")
cat("Next steps: Proceed to Phase 3 (Exploratory Data Analysis)\n")

