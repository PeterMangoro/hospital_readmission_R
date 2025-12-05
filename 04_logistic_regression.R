# ==============================================================================
# Phase 4: Logistic Regression Model
# Project: Predicting 30-Day Hospital Readmissions
# ==============================================================================

# Load required libraries
library(ggplot2)
library(dplyr)

# Install and load pROC if not available
if(!require(pROC, quietly = TRUE)) {
  install.packages("pROC", repos = "https://cran.r-project.org")
  library(pROC)
}

# Install and load caret if not available
if(!require(caret, quietly = TRUE)) {
  install.packages("caret", repos = "https://cran.r-project.org")
  library(caret)
}

# Set working directory (adjust if needed)
# setwd("/home/themad/Documents/yeshiva/computationalMaths/projects")

# ==============================================================================
# Load Data
# ==============================================================================

cat("=== Phase 4: Logistic Regression Model ===\n\n")

cat("Loading Logistic Regression dataset...\n")
load("data_logistic.RData")
cat("Dataset: ", nrow(data_logistic), " observations, ", ncol(data_logistic), " variables\n")
cat("Response variable: readmitted (binary 0/1)\n\n")

# ==============================================================================
# 4.1 Prepare Data - Train/Test Split
# ==============================================================================

cat("=== 4.1 Train/Test Split ===\n\n")

# Set seed for reproducibility
set.seed(123)

# Split data: 70% training, 30% testing
train_indices <- createDataPartition(data_logistic$readmitted, 
                                     p = 0.7, 
                                     list = FALSE)

data_train <- data_logistic[train_indices, ]
data_test <- data_logistic[-train_indices, ]

cat("Training set: ", nrow(data_train), " observations (", 
    round(nrow(data_train)/nrow(data_logistic)*100, 1), "%)\n")
cat("Testing set: ", nrow(data_test), " observations (", 
    round(nrow(data_test)/nrow(data_logistic)*100, 1), "%)\n\n")

# Check distribution in both sets
cat("Readmission rate - Training: ", round(mean(data_train$readmitted)*100, 2), "%\n")
cat("Readmission rate - Testing: ", round(mean(data_test$readmitted)*100, 2), "%\n")
cat("Readmission rate - Original: ", round(mean(data_logistic$readmitted)*100, 2), "%\n\n")

# ==============================================================================
# 4.2 Build Logistic Regression Model
# ==============================================================================

cat("=== 4.2 Building Logistic Regression Model ===\n\n")

# Fit logistic regression model
# Note: model.matrix created all dummy variables, so we need to drop one reference category
# R's glm() will automatically handle this, but we'll be explicit

cat("Fitting logistic regression model...\n")
cat("Using all variables from the dataset...\n\n")

# Build model formula (exclude response variable)
predictor_vars <- setdiff(colnames(data_train), "readmitted")
formula_str <- paste("readmitted ~", paste(predictor_vars, collapse = " + "))
formula_obj <- as.formula(formula_str)

# Fit the model
model_logistic <- glm(formula_obj, 
                     data = data_train, 
                     family = binomial(link = "logit"))

cat("Model fitted successfully!\n\n")

# ==============================================================================
# 4.3 Model Summary and Interpretation
# ==============================================================================

cat("=== 4.3 Model Summary ===\n\n")

# Display model summary
model_summary <- summary(model_logistic)
print(model_summary)

# Extract key statistics
cat("\n--- Model Statistics ---\n")
cat("Null Deviance: ", model_summary$null.deviance, "\n")
cat("Residual Deviance: ", model_summary$deviance, "\n")
cat("AIC: ", model_summary$aic, "\n")
cat("Number of observations: ", model_summary$df.null + 1, "\n\n")

# ==============================================================================
# 4.4 Regression Output Table
# ==============================================================================

cat("=== 4.4 Regression Output Table ===\n\n")

# Extract coefficients
coefficients_table <- model_summary$coefficients

# Create comprehensive output table
output_table <- data.frame(
  Variable = rownames(coefficients_table),
  Coefficient = round(coefficients_table[, "Estimate"], 4),
  Std_Error = round(coefficients_table[, "Std. Error"], 4),
  Z_Value = round(coefficients_table[, "z value"], 4),
  P_Value = round(coefficients_table[, "Pr(>|z|)"], 6),
  Significance = ifelse(coefficients_table[, "Pr(>|z|)"] < 0.001, "***",
                ifelse(coefficients_table[, "Pr(>|z|)"] < 0.01, "**",
                ifelse(coefficients_table[, "Pr(>|z|)"] < 0.05, "*",
                ifelse(coefficients_table[, "Pr(>|z|)"] < 0.1, ".", "")))),
  Odds_Ratio = round(exp(coefficients_table[, "Estimate"]), 4),
  CI_Lower = round(exp(coefficients_table[, "Estimate"] - 1.96 * coefficients_table[, "Std. Error"]), 4),
  CI_Upper = round(exp(coefficients_table[, "Estimate"] + 1.96 * coefficients_table[, "Std. Error"]), 4)
)

# Significance codes
cat("Significance codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1\n\n")

# Display significant variables
cat("Significant Variables (p < 0.05):\n")
significant_vars <- output_table[output_table$P_Value < 0.05, ]
print(significant_vars[, c("Variable", "Coefficient", "P_Value", "Odds_Ratio")])

# Save full output table
write.csv(output_table, "plots/04_regression_output.csv", row.names = FALSE)
cat("\nFull regression output saved to: plots/04_regression_output.csv\n\n")

# ==============================================================================
# 4.5 Hypothesis Testing
# ==============================================================================

cat("=== 4.5 Hypothesis Testing ===\n\n")

cat("For each variable in the model:\n")
cat("H₀: β_variable = 0 (variable has no effect on readmission)\n")
cat("H₁: β_variable ≠ 0 (variable affects readmission)\n\n")

# Show hypotheses for top significant variables
top_significant <- head(significant_vars[order(significant_vars$P_Value), ], 10)

cat("Top 10 Most Significant Variables:\n\n")
for(i in 1:nrow(top_significant)) {
  var <- top_significant$Variable[i]
  pval <- top_significant$P_Value[i]
  coef <- top_significant$Coefficient[i]
  
  cat(sprintf("%d. %s\n", i, var))
  cat(sprintf("   H₀: β_%s = 0\n", var))
  cat(sprintf("   H₁: β_%s ≠ 0\n", var))
  cat(sprintf("   Coefficient: %.4f\n", coef))
  cat(sprintf("   P-value: %.6f\n", pval))
  
  if(pval < 0.05) {
    cat(sprintf("   Conclusion: Reject H₀ - Variable is significant (p < 0.05)\n"))
  } else {
    cat(sprintf("   Conclusion: Fail to reject H₀ - Variable is not significant\n"))
  }
  cat("\n")
}

# ==============================================================================
# 4.6 R-squared (Pseudo R-squared)
# ==============================================================================

cat("=== 4.6 R-squared (Pseudo R-squared) ===\n\n")

# Calculate pseudo R-squared (McFadden's)
null_deviance <- model_summary$null.deviance
residual_deviance <- model_summary$deviance

mcfadden_r2 <- 1 - (residual_deviance / null_deviance)

# Calculate Nagelkerke's R-squared (adjusted)
n <- nrow(data_train)
nagelkerke_r2 <- (1 - exp((model_summary$deviance - model_summary$null.deviance) / n)) / 
                 (1 - exp(-model_summary$null.deviance / n))

cat("McFadden's Pseudo R²: ", round(mcfadden_r2, 4), "\n")
cat("Nagelkerke's R²: ", round(nagelkerke_r2, 4), "\n\n")

cat("Interpretation:\n")
cat(sprintf("The model explains approximately %.2f%% of the variance in readmission status.\n", 
            mcfadden_r2 * 100))
cat("Note: Pseudo R² values are typically lower than R² in linear regression.\n")
cat("Values above 0.2-0.4 are considered good for logistic regression.\n\n")

# Save R-squared values
r2_table <- data.frame(
  Metric = c("McFadden's Pseudo R²", "Nagelkerke's R²"),
  Value = c(mcfadden_r2, nagelkerke_r2)
)
write.csv(r2_table, "plots/04_rsquared.csv", row.names = FALSE)

# ==============================================================================
# 4.7 Model Evaluation
# ==============================================================================

cat("=== 4.7 Model Evaluation ===\n\n")

# Make predictions on test set
cat("Making predictions on test set...\n")
predictions_prob <- predict(model_logistic, newdata = data_test, type = "response")
predictions_class <- ifelse(predictions_prob > 0.5, 1, 0)

# Confusion Matrix
cat("\n--- Confusion Matrix ---\n")
conf_matrix <- table(Predicted = predictions_class, Actual = data_test$readmitted)
print(conf_matrix)

# Calculate metrics
TN <- conf_matrix[1, 1]  # True Negatives
FP <- conf_matrix[2, 1]  # False Positives
FN <- conf_matrix[1, 2]  # False Negatives
TP <- conf_matrix[2, 2]  # True Positives

accuracy <- (TP + TN) / (TP + TN + FP + FN)
precision <- TP / (TP + FP)
recall <- TP / (TP + FN)  # Also called Sensitivity
specificity <- TN / (TN + FP)
f1_score <- 2 * (precision * recall) / (precision + recall)

cat("\n--- Performance Metrics ---\n")
cat("Accuracy: ", round(accuracy * 100, 2), "%\n")
cat("Precision: ", round(precision * 100, 2), "%\n")
cat("Recall (Sensitivity): ", round(recall * 100, 2), "%\n")
cat("Specificity: ", round(specificity * 100, 2), "%\n")
cat("F1-Score: ", round(f1_score, 4), "\n\n")

# Save metrics
metrics_table <- data.frame(
  Metric = c("Accuracy", "Precision", "Recall (Sensitivity)", "Specificity", "F1-Score"),
  Value = c(accuracy, precision, recall, specificity, f1_score),
  Percentage = c(accuracy * 100, precision * 100, recall * 100, specificity * 100, f1_score * 100)
)
write.csv(metrics_table, "plots/04_performance_metrics.csv", row.names = FALSE)

# ==============================================================================
# 4.8 ROC Curve and AUC
# ==============================================================================

cat("=== 4.8 ROC Curve and AUC ===\n\n")

# Calculate ROC curve
roc_obj <- roc(data_test$readmitted, predictions_prob)

# Extract AUC
auc_value <- auc(roc_obj)
cat("Area Under the Curve (AUC): ", round(as.numeric(auc_value), 4), "\n\n")

cat("AUC Interpretation:\n")
if(auc_value > 0.9) {
  cat("Excellent discrimination (AUC > 0.9)\n")
} else if(auc_value > 0.8) {
  cat("Good discrimination (0.8 < AUC <= 0.9)\n")
} else if(auc_value > 0.7) {
  cat("Fair discrimination (0.7 < AUC <= 0.8)\n")
} else {
  cat("Poor discrimination (AUC <= 0.7)\n")
}

# Create ROC curve plot
png("plots/04_roc_curve.png", width = 800, height = 800)
plot(roc_obj, 
     main = "ROC Curve: Logistic Regression Model",
     xlab = "False Positive Rate (1 - Specificity)",
     ylab = "True Positive Rate (Sensitivity)",
     col = "steelblue",
     lwd = 2)
abline(a = 0, b = 1, lty = 2, col = "red", lwd = 2)
text(0.6, 0.2, paste("AUC =", round(as.numeric(auc_value), 4)), cex = 1.2)
legend("bottomright", 
       legend = c("ROC Curve", "Random Classifier", paste("AUC =", round(as.numeric(auc_value), 4))),
       col = c("steelblue", "red", "black"),
       lty = c(1, 2, 0),
       lwd = c(2, 2, 0))
dev.off()

# ggplot version
roc_data <- data.frame(
  FPR = 1 - roc_obj$specificities,
  TPR = roc_obj$sensitivities
)

p_roc <- ggplot(roc_data, aes(x = FPR, y = TPR)) +
  geom_line(color = "steelblue", size = 1.2) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "red", size = 1) +
  labs(title = "ROC Curve: Logistic Regression Model",
       subtitle = paste("AUC =", round(as.numeric(auc_value), 4)),
       x = "False Positive Rate (1 - Specificity)",
       y = "True Positive Rate (Sensitivity)") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5, size = 12))

ggsave("plots/04_roc_curve_ggplot.png", p_roc, width = 8, height = 8, dpi = 300)

cat("\nROC curve saved to: plots/04_roc_curve.png\n")
cat("ROC curve (ggplot) saved to: plots/04_roc_curve_ggplot.png\n\n")

# Save AUC value
auc_table <- data.frame(
  Metric = "Area Under the Curve (AUC)",
  Value = as.numeric(auc_value)
)
write.csv(auc_table, "plots/04_auc.csv", row.names = FALSE)

# ==============================================================================
# 4.9 Odds Ratios Interpretation
# ==============================================================================

cat("=== 4.9 Odds Ratios Interpretation ===\n\n")

cat("Top 10 Variables with Highest Odds Ratios (Risk Factors):\n\n")
top_odds <- head(output_table[order(-output_table$Odds_Ratio), ], 10)
print(top_odds[, c("Variable", "Odds_Ratio", "CI_Lower", "CI_Upper", "P_Value")])

cat("\nTop 10 Variables with Lowest Odds Ratios (Protective Factors):\n\n")
bottom_odds <- head(output_table[order(output_table$Odds_Ratio), ], 10)
print(bottom_odds[, c("Variable", "Odds_Ratio", "CI_Lower", "CI_Upper", "P_Value")])

cat("\nOdds Ratio Interpretation:\n")
cat("- Odds Ratio > 1: Variable increases odds of readmission\n")
cat("- Odds Ratio < 1: Variable decreases odds of readmission\n")
cat("- Odds Ratio = 1: Variable has no effect\n\n")

# ==============================================================================
# 4.10 Model Diagnostics
# ==============================================================================

cat("=== 4.10 Model Diagnostics ===\n\n")

# Check for multicollinearity (VIF - Variance Inflation Factor)
if(require(car, quietly = TRUE)) {
  cat("Checking for multicollinearity (VIF)...\n")
  
  # Try to calculate VIF, but handle aliased coefficients
  tryCatch({
    vif_values <- vif(model_logistic)
    
    cat("\nVariance Inflation Factors (VIF):\n")
    cat("VIF > 10 indicates potential multicollinearity\n\n")
    
    high_vif <- vif_values[vif_values > 10]
    if(length(high_vif) > 0) {
      cat("Variables with VIF > 10:\n")
      print(high_vif)
    } else {
      cat("No variables with VIF > 10 - multicollinearity not a major concern\n")
    }
    
    # Save VIF values
    vif_table <- data.frame(
      Variable = names(vif_values),
      VIF = as.numeric(vif_values)
    )
    write.csv(vif_table, "plots/04_vif.csv", row.names = FALSE)
  }, error = function(e) {
    cat("Note: VIF calculation skipped due to aliased coefficients (perfect multicollinearity)\n")
    cat("This is expected when using all dummy variables from one-hot encoding.\n")
    cat("The model automatically handles this by dropping redundant variables.\n\n")
  })
} else {
  cat("Package 'car' not available - skipping VIF calculation\n")
  cat("Install with: install.packages('car')\n")
}

# ==============================================================================
# 4.11 Summary Report
# ==============================================================================

cat("\n=== Phase 4 Complete ===\n\n")

cat("SUMMARY:\n")
cat("========\n\n")
cat("Model Type: Logistic Regression\n")
cat("Training Observations: ", nrow(data_train), "\n")
cat("Testing Observations: ", nrow(data_test), "\n")
cat("Total Variables: ", length(predictor_vars), "\n")
cat("Significant Variables (p < 0.05): ", nrow(significant_vars), "\n\n")

cat("Model Performance:\n")
cat("  Accuracy: ", round(accuracy * 100, 2), "%\n")
cat("  AUC: ", round(as.numeric(auc_value), 4), "\n")
cat("  Pseudo R² (McFadden): ", round(mcfadden_r2, 4), "\n\n")

cat("All outputs saved to 'plots/' directory:\n")
cat("  - 04_regression_output.csv (complete regression table)\n")
cat("  - 04_performance_metrics.csv (accuracy, precision, recall, etc.)\n")
cat("  - 04_rsquared.csv (pseudo R-squared values)\n")
cat("  - 04_auc.csv (AUC value)\n")
cat("  - 04_roc_curve.png (ROC curve visualization)\n")
cat("  - 04_roc_curve_ggplot.png (ROC curve - ggplot version)\n\n")

cat("Next steps: Proceed to Phase 5 (CART Model)\n")

