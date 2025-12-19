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
  # Need to ensure we have at least one row - duplicate temp_df if needed
  temp_df_for_matrix <- temp_df
  if(nrow(temp_df_for_matrix) == 0) {
    # This shouldn't happen, but handle it
    temp_df_for_matrix <- rbind(temp_df_for_matrix, temp_df_for_matrix)
  }
  
  # Age
  age_dummies <- model.matrix(~ age - 1, data = temp_df_for_matrix)
  if(nrow(age_dummies) == 0) {
    # Create a single-row matrix with zeros for all age levels
    age_levels <- levels(temp_df$age)
    age_dummies <- matrix(0, nrow = 1, ncol = length(age_levels))
    colnames(age_dummies) <- paste0("age_", gsub("\\[|\\]|\\)|\\(", "", age_levels))
    colnames(age_dummies) <- gsub(" ", "_", colnames(age_dummies))
    # Set the matching level to 1
    age_match <- which(age_levels == inputs$age)
    if(length(age_match) > 0) age_dummies[1, age_match] <- 1
  } else {
    colnames(age_dummies) <- paste0("age_", gsub("\\[|\\]|\\)|\\(", "", colnames(age_dummies)))
    colnames(age_dummies) <- gsub(" ", "_", colnames(age_dummies))
    # Take only first row if multiple rows
    if(nrow(age_dummies) > 1) age_dummies <- age_dummies[1, , drop = FALSE]
  }
  
  # Medical specialty
  medspec_dummies <- model.matrix(~ medical_specialty - 1, data = temp_df_for_matrix)
  if(nrow(medspec_dummies) == 0) {
    medspec_levels <- levels(temp_df$medical_specialty)
    medspec_dummies <- matrix(0, nrow = 1, ncol = length(medspec_levels))
    colnames(medspec_dummies) <- paste0("medspec_", gsub(" ", "_", gsub("/", ".", medspec_levels)))
    medspec_match <- which(medspec_levels == inputs$medical_specialty)
    if(length(medspec_match) > 0) medspec_dummies[1, medspec_match] <- 1
  } else {
    colnames(medspec_dummies) <- paste0("medspec_", gsub(" ", "_", gsub("/", ".", colnames(medspec_dummies))))
    if(nrow(medspec_dummies) > 1) medspec_dummies <- medspec_dummies[1, , drop = FALSE]
  }
  
  # Primary diagnosis
  diag1_dummies <- model.matrix(~ diag_1 - 1, data = temp_df_for_matrix)
  if(nrow(diag1_dummies) == 0) {
    diag1_levels <- levels(temp_df$diag_1)
    diag1_dummies <- matrix(0, nrow = 1, ncol = length(diag1_levels))
    colnames(diag1_dummies) <- paste0("diag1_", tolower(diag1_levels))
    diag1_match <- which(diag1_levels == inputs$diag_1)
    if(length(diag1_match) > 0) diag1_dummies[1, diag1_match] <- 1
  } else {
    colnames(diag1_dummies) <- paste0("diag1_", tolower(colnames(diag1_dummies)))
    if(nrow(diag1_dummies) > 1) diag1_dummies <- diag1_dummies[1, , drop = FALSE]
  }
  
  # Glucose test
  glucose_dummies <- model.matrix(~ glucose_test - 1, data = temp_df_for_matrix)
  if(nrow(glucose_dummies) == 0) {
    glucose_levels <- levels(temp_df$glucose_test)
    glucose_dummies <- matrix(0, nrow = 1, ncol = length(glucose_levels))
    colnames(glucose_dummies) <- paste0("glucose_", tolower(glucose_levels))
    glucose_match <- which(glucose_levels == inputs$glucose_test)
    if(length(glucose_match) > 0) glucose_dummies[1, glucose_match] <- 1
  } else {
    colnames(glucose_dummies) <- paste0("glucose_", tolower(colnames(glucose_dummies)))
    if(nrow(glucose_dummies) > 1) glucose_dummies <- glucose_dummies[1, , drop = FALSE]
  }
  
  # A1C test
  a1c_dummies <- model.matrix(~ A1Ctest - 1, data = temp_df_for_matrix)
  if(nrow(a1c_dummies) == 0) {
    a1c_levels <- levels(temp_df$A1Ctest)
    a1c_dummies <- matrix(0, nrow = 1, ncol = length(a1c_levels))
    colnames(a1c_dummies) <- paste0("a1c_", tolower(a1c_levels))
    a1c_match <- which(a1c_levels == inputs$A1Ctest)
    if(length(a1c_match) > 0) a1c_dummies[1, a1c_match] <- 1
  } else {
    colnames(a1c_dummies) <- paste0("a1c_", tolower(colnames(a1c_dummies)))
    if(nrow(a1c_dummies) > 1) a1c_dummies <- a1c_dummies[1, , drop = FALSE]
  }
  
  # Binary variables (must match training data encoding exactly)
  change_binary <- as.numeric(inputs$change == "yes")
  diabetes_med_binary <- as.numeric(inputs$diabetes_med == "yes")
  
  # Combine all features into data frame
  # Start with numerical and binary variables
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
    stringsAsFactors = FALSE
  )
  
  # Add dummy variables one at a time (handle empty matrices)
  if(ncol(age_dummies) > 0) {
    data_logistic_format <- cbind(data_logistic_format, age_dummies)
  }
  if(ncol(medspec_dummies) > 0) {
    data_logistic_format <- cbind(data_logistic_format, medspec_dummies)
  }
  if(ncol(diag1_dummies) > 0) {
    data_logistic_format <- cbind(data_logistic_format, diag1_dummies)
  }
  if(ncol(glucose_dummies) > 0) {
    data_logistic_format <- cbind(data_logistic_format, glucose_dummies)
  }
  if(ncol(a1c_dummies) > 0) {
    data_logistic_format <- cbind(data_logistic_format, a1c_dummies)
  }
  
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
  
  # Add readmitted column for Random Forest (formula interface requirement)
  # Use a dummy value - it won't be used for prediction
  data_cart_format$readmitted <- factor("Not Readmitted", 
                                       levels = c("Not Readmitted", "Readmitted"))
  
  # Reorder columns to match training data exactly (Random Forest can be sensitive to column order)
  data_cart_format <- data_cart_format[, colnames(data_cart), drop = FALSE]
  
  return(data_cart_format)
}

# ============================================================================
# Encode for XGBoost (Numeric Encoding)
# ============================================================================
encode_for_xgb <- function(inputs) {
  # Load training data to get structure
  load("data_cart.RData")
  
  # Calculate derived features
  derived <- calculate_derived_features(
    inputs$time_in_hospital,
    inputs$n_medications,
    inputs$n_outpatient,
    inputs$n_inpatient,
    inputs$n_emergency
  )
  
  # Create data frame matching data_cart structure
  data_xgb_format <- data.frame(
    time_in_hospital = inputs$time_in_hospital,
    n_lab_procedures = inputs$n_lab_procedures,
    n_procedures = inputs$n_procedures,
    n_medications = inputs$n_medications,
    n_outpatient = inputs$n_outpatient,
    n_inpatient = inputs$n_inpatient,
    n_emergency = inputs$n_emergency,
    n_diagnoses = inputs$n_diagnoses,
    medications_per_day = derived$medications_per_day,
    total_previous_visits = derived$total_previous_visits,
    age = factor(inputs$age, levels = levels(data_cart$age), ordered = is.ordered(data_cart$age)),
    medical_specialty = factor(inputs$medical_specialty, levels = levels(data_cart$medical_specialty)),
    diag_1 = factor(inputs$diag_1, levels = levels(data_cart$diag_1)),
    change = factor(inputs$change, levels = levels(data_cart$change)),
    diabetes_med = factor(inputs$diabetes_med, levels = levels(data_cart$diabetes_med)),
    glucose_test = factor(inputs$glucose_test, levels = levels(data_cart$glucose_test)),
    A1Ctest = factor(inputs$A1Ctest, levels = levels(data_cart$A1Ctest)),
    stringsAsFactors = FALSE
  )
  
  # Convert factors to numeric codes (same as training)
  for(col in colnames(data_xgb_format)) {
    if(is.factor(data_xgb_format[[col]])) {
      data_xgb_format[[col]] <- as.numeric(data_xgb_format[[col]]) - 1
    }
  }
  
  # Convert to matrix
  X_matrix <- as.matrix(data_xgb_format)
  return(X_matrix)
}

# ============================================================================
# Encode for Neural Network (Dummy Encoding + Scaling)
# ============================================================================
encode_for_nn <- function(inputs) {
  # Load training data and scaling parameters
  load("data_cart.RData")
  load("scaling_params_nn.RData")  # This loads scaling_params
  
  # Calculate derived features
  derived <- calculate_derived_features(
    inputs$time_in_hospital,
    inputs$n_medications,
    inputs$n_outpatient,
    inputs$n_inpatient,
    inputs$n_emergency
  )
  
  # Create data frame matching data_cart structure
  data_nn_format <- data.frame(
    time_in_hospital = inputs$time_in_hospital,
    n_lab_procedures = inputs$n_lab_procedures,
    n_procedures = inputs$n_procedures,
    n_medications = inputs$n_medications,
    n_outpatient = inputs$n_outpatient,
    n_inpatient = inputs$n_inpatient,
    n_emergency = inputs$n_emergency,
    n_diagnoses = inputs$n_diagnoses,
    medications_per_day = derived$medications_per_day,
    total_previous_visits = derived$total_previous_visits,
    age = factor(inputs$age, levels = levels(data_cart$age), ordered = is.ordered(data_cart$age)),
    medical_specialty = factor(inputs$medical_specialty, levels = levels(data_cart$medical_specialty)),
    diag_1 = factor(inputs$diag_1, levels = levels(data_cart$diag_1)),
    change = factor(inputs$change, levels = levels(data_cart$change)),
    diabetes_med = factor(inputs$diabetes_med, levels = levels(data_cart$diabetes_med)),
    glucose_test = factor(inputs$glucose_test, levels = levels(data_cart$glucose_test)),
    A1Ctest = factor(inputs$A1Ctest, levels = levels(data_cart$A1Ctest)),
    stringsAsFactors = FALSE
  )
  
  # Add dummy readmitted column for model.matrix (will be removed)
  data_nn_format$readmitted <- factor("Not Readmitted", levels = c("Not Readmitted", "Readmitted"))
  
  # Create model matrix (dummy encoding)
  # Ensure we have at least one row
  if(nrow(data_nn_format) == 0) {
    stop("data_nn_format has 0 rows")
  }
  
  # Try to create model matrix - handle ordered factors carefully
  tryCatch({
    X_matrix <- model.matrix(~ . - readmitted, data = data_nn_format)[, -1]
  }, error = function(e) {
    # If model.matrix fails, create manually
    X_matrix <<- NULL
  })
  
  # Handle case where model.matrix fails or returns 0 rows
  if(is.null(X_matrix) || length(X_matrix) == 0 || (is.matrix(X_matrix) && nrow(X_matrix) == 0)) {
    # Create a single-row matrix with zeros matching scaling params
    X_matrix <- matrix(0, nrow = 1, ncol = length(scaling_params$center))
    colnames(X_matrix) <- names(scaling_params$center)
    
    # Set values for known numerical columns
    known_cols <- c("time_in_hospital", "n_lab_procedures", "n_procedures", "n_medications",
                    "n_outpatient", "n_inpatient", "n_emergency", "n_diagnoses",
                    "medications_per_day", "total_previous_visits")
    for(col in known_cols) {
      if(col %in% colnames(X_matrix)) {
        if(col == "time_in_hospital") X_matrix[1, col] <- inputs$time_in_hospital
        else if(col == "n_lab_procedures") X_matrix[1, col] <- inputs$n_lab_procedures
        else if(col == "n_procedures") X_matrix[1, col] <- inputs$n_procedures
        else if(col == "n_medications") X_matrix[1, col] <- inputs$n_medications
        else if(col == "n_outpatient") X_matrix[1, col] <- inputs$n_outpatient
        else if(col == "n_inpatient") X_matrix[1, col] <- inputs$n_inpatient
        else if(col == "n_emergency") X_matrix[1, col] <- inputs$n_emergency
        else if(col == "n_diagnoses") X_matrix[1, col] <- inputs$n_diagnoses
        else if(col == "medications_per_day") X_matrix[1, col] <- derived$medications_per_day
        else if(col == "total_previous_visits") X_matrix[1, col] <- derived$total_previous_visits
      }
    }
    
    # Set dummy variables for categoricals manually
    # Age dummies
    age_cols <- grep("^age", colnames(X_matrix), value = TRUE)
    if(length(age_cols) > 0 && inputs$age %in% levels(data_cart$age)) {
      age_match <- paste0("age", gsub("\\[|\\]|\\)|\\(", "", gsub(" ", "_", inputs$age)))
      if(age_match %in% colnames(X_matrix)) {
        X_matrix[1, age_match] <- 1
      }
    }
    
    # Medical specialty dummies
    medspec_cols <- grep("^medical_specialty", colnames(X_matrix), value = TRUE)
    if(length(medspec_cols) > 0) {
      medspec_match <- paste0("medical_specialty", gsub(" ", "_", gsub("/", ".", inputs$medical_specialty)))
      if(medspec_match %in% colnames(X_matrix)) {
        X_matrix[1, medspec_match] <- 1
      }
    }
    
    # Other categorical dummies similarly...
  } else {
    # Ensure we only take first row if multiple rows
    if(is.matrix(X_matrix) && nrow(X_matrix) > 1) {
      X_matrix <- X_matrix[1, , drop = FALSE]
    } else if(!is.matrix(X_matrix)) {
      # Convert to matrix if it's a vector
      X_matrix <- matrix(X_matrix, nrow = 1)
      colnames(X_matrix) <- names(scaling_params$center)
    }
  }
  
  # Scale using training parameters
  X_scaled <- scale(X_matrix, 
                    center = scaling_params$center,
                    scale = scaling_params$scale)
  
  return(X_scaled)
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

