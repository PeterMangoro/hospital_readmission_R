# Helper functions for Shiny app encoding
# These functions convert user inputs to the format expected by each model

# ============================================================================
# Calculate Derived Features
# ============================================================================
calculate_derived_features <- function(time_in_hospital, n_medications, 
                                       n_outpatient, n_inpatient, n_emergency) {
  # Calculate medications_per_day
  medications_per_day <- ifelse(time_in_hospital > 0,
                                n_medications / time_in_hospital,
                                n_medications)
  
  # Calculate total_previous_visits
  total_previous_visits <- n_outpatient + n_inpatient + n_emergency
  
  # Note: n_diagnoses is not calculated here as we only have diag_1 in the app
  # We'll use a default value or let user input it directly
  
  return(list(
    medications_per_day = medications_per_day,
    total_previous_visits = total_previous_visits
  ))
}

# ============================================================================
# Encode for Logistic Regression (Dummy Encoding)
# ============================================================================
encode_for_logistic <- function(inputs) {
  # inputs should be a list with:
  # - time_in_hospital, n_lab_procedures, n_procedures, n_medications
  # - n_outpatient, n_inpatient, n_emergency, n_diagnoses
  # - age, medical_specialty, diag_1, change, diabetes_med, glucose_test, A1Ctest
  
  # Load training data to get column structure
  load("data_logistic.RData")
  training_cols <- colnames(data_logistic)
  training_cols <- training_cols[training_cols != "readmitted"]
  
  # Calculate derived features
  derived <- calculate_derived_features(
    inputs$time_in_hospital,
    inputs$n_medications,
    inputs$n_outpatient,
    inputs$n_inpatient,
    inputs$n_emergency
  )
  
  # Create a temporary data frame for model.matrix
  # Use same factor levels as training data
  load("data_cart.RData")
  temp_df <- data.frame(
    age = factor(inputs$age, levels = levels(data_cart$age), ordered = TRUE),
    medical_specialty = factor(inputs$medical_specialty, levels = levels(data_cart$medical_specialty)),
    diag_1 = factor(inputs$diag_1, levels = levels(data_cart$diag_1)),
    glucose_test = factor(inputs$glucose_test, levels = levels(data_cart$glucose_test)),
    A1Ctest = factor(inputs$A1Ctest, levels = levels(data_cart$A1Ctest)),
    stringsAsFactors = FALSE
  )
  
  # Create dummy variables using model.matrix (same as in data cleaning)
  # Age
  age_dummies <- model.matrix(~ age - 1, data = temp_df)
  colnames(age_dummies) <- paste0("age_", gsub("\\[|\\]|\\)|\\(", "", colnames(age_dummies)))
  colnames(age_dummies) <- gsub(" ", "_", colnames(age_dummies))
  
  # Medical specialty
  medspec_dummies <- model.matrix(~ medical_specialty - 1, data = temp_df)
  # Match training data format: "medspec_medical_specialtyEmergency.Trauma"
  # Training data has dots (.) not slashes (/), so we need to convert "/" to "."
  # Original code: paste0("medspec_", gsub(" ", "_", colnames(medspec_dummies)))
  # But we also need to convert "/" to "." to match training data
  colnames(medspec_dummies) <- paste0("medspec_", gsub(" ", "_", gsub("/", ".", colnames(medspec_dummies))))
  
  # Primary diagnosis
  diag1_dummies <- model.matrix(~ diag_1 - 1, data = temp_df)
  colnames(diag1_dummies) <- paste0("diag1_", tolower(colnames(diag1_dummies)))
  
  # Glucose test
  glucose_dummies <- model.matrix(~ glucose_test - 1, data = temp_df)
  colnames(glucose_dummies) <- paste0("glucose_", tolower(colnames(glucose_dummies)))
  
  # A1C test
  a1c_dummies <- model.matrix(~ A1Ctest - 1, data = temp_df)
  colnames(a1c_dummies) <- paste0("a1c_", tolower(colnames(a1c_dummies)))
  
  # Binary variables (must match training data encoding exactly)
  change_binary <- as.numeric(inputs$change == "yes")
  diabetes_med_binary <- as.numeric(inputs$diabetes_med == "yes")
  
  # Combine all features into data frame
  data_logistic_format <- data.frame(
    # Numerical variables
    time_in_hospital = inputs$time_in_hospital,
    n_lab_procedures = inputs$n_lab_procedures,
    n_procedures = inputs$n_procedures,
    n_medications = inputs$n_medications,
    n_outpatient = inputs$n_outpatient,
    n_inpatient = inputs$n_inpatient,
    n_emergency = inputs$n_emergency,
    # Derived numerical features
    n_diagnoses = inputs$n_diagnoses,
    medications_per_day = derived$medications_per_day,
    total_previous_visits = derived$total_previous_visits,
    # Binary variables
    change_binary = change_binary,
    diabetes_med_binary = diabetes_med_binary,
    # Dummy-encoded categorical variables
    age_dummies,
    medspec_dummies,
    diag1_dummies,
    glucose_dummies,
    a1c_dummies,
    stringsAsFactors = FALSE
  )
  
  # Ensure all columns from training data exist (set missing to 0)
  missing_cols <- setdiff(training_cols, colnames(data_logistic_format))
  if(length(missing_cols) > 0) {
    for(col in missing_cols) {
      data_logistic_format[[col]] <- 0
    }
  }
  
  # Reorder columns to match training data
  data_logistic_format <- data_logistic_format[, training_cols, drop = FALSE]
  
  return(data_logistic_format)
}

# ============================================================================
# Encode for CART/Random Forest (Factor Encoding)
# ============================================================================
encode_for_cart <- function(inputs) {
  # inputs should be a list with the same fields as above
  
  # Load training data to get factor levels
  load("data_cart.RData")
  
  # Calculate derived features
  derived <- calculate_derived_features(
    inputs$time_in_hospital,
    inputs$n_medications,
    inputs$n_outpatient,
    inputs$n_inpatient,
    inputs$n_emergency
  )
  
  # Create data frame with factors (matching data_cart structure)
  # Use exact same factor levels as training data
  data_cart_format <- data.frame(
    # Numerical variables
    time_in_hospital = inputs$time_in_hospital,
    n_lab_procedures = inputs$n_lab_procedures,
    n_procedures = inputs$n_procedures,
    n_medications = inputs$n_medications,
    n_outpatient = inputs$n_outpatient,
    n_inpatient = inputs$n_inpatient,
    n_emergency = inputs$n_emergency,
    # Derived numerical features
    n_diagnoses = inputs$n_diagnoses,
    medications_per_day = derived$medications_per_day,
    total_previous_visits = derived$total_previous_visits,
    # Factor categorical variables (use same levels as training data)
    age = factor(inputs$age, 
                levels = levels(data_cart$age),
                ordered = is.ordered(data_cart$age)),
    medical_specialty = factor(inputs$medical_specialty, 
                               levels = levels(data_cart$medical_specialty)),
    diag_1 = factor(inputs$diag_1, 
                   levels = levels(data_cart$diag_1)),
    change = factor(inputs$change, 
                   levels = levels(data_cart$change)),
    diabetes_med = factor(inputs$diabetes_med, 
                         levels = levels(data_cart$diabetes_med)),
    glucose_test = factor(inputs$glucose_test, 
                          levels = levels(data_cart$glucose_test)),
    A1Ctest = factor(inputs$A1Ctest, 
                    levels = levels(data_cart$A1Ctest)),
    stringsAsFactors = FALSE
  )
  
  return(data_cart_format)
}

# ============================================================================
# Get Available Levels for Dropdowns
# ============================================================================
get_factor_levels <- function() {
  # Load data to get actual factor levels
  load("data_cart.RData")
  
  return(list(
    age = levels(data_cart$age),
    medical_specialty = levels(data_cart$medical_specialty),
    diag_1 = levels(data_cart$diag_1),
    change = levels(data_cart$change),
    diabetes_med = levels(data_cart$diabetes_med),
    glucose_test = levels(data_cart$glucose_test),
    A1Ctest = levels(data_cart$A1Ctest)
  ))
}

