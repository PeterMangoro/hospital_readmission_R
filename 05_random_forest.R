# ==============================================================================
# Phase 5b: Random Forest Model
# Project: Predicting 30-Day Hospital Readmissions
# ==============================================================================

# Load required libraries
library(ggplot2)
library(dplyr)

# Install and load randomForest if not available
if(!require(randomForest, quietly = TRUE)) {
  install.packages("randomForest", repos = "https://cran.r-project.org")
  library(randomForest)
}

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

cat("=== Phase 5b: Random Forest Model ===\n\n")

cat("Loading CART dataset (same as Phase 5)...\n")
load("data_cart.RData")
cat("Dataset: ", nrow(data_cart), " observations, ", ncol(data_cart), " variables\n")
cat("Response variable: readmitted (factor: Not_Readmitted/Readmitted)\n\n")

# ==============================================================================
# 5b.1 Prepare Data - Train/Test Split
# ==============================================================================

cat("=== 5b.1 Train/Test Split ===\n\n")

# Set seed for reproducibility (same as Phase 4 and 5)
set.seed(1)

# Split data: 70% training, 30% testing (same split as other models)
train_indices <- createDataPartition(data_cart$readmitted, 
                                     p = 0.7, 
                                     list = FALSE)

data_train_rf <- data_cart[train_indices, ]
data_test_rf <- data_cart[-train_indices, ]

cat("Training set: ", nrow(data_train_rf), " observations (", 
    round(nrow(data_train_rf)/nrow(data_cart)*100, 1), "%)\n")
cat("Testing set: ", nrow(data_test_rf), " observations (", 
    round(nrow(data_test_rf)/nrow(data_cart)*100, 1), "%)\n\n")

# Check distribution in both sets
cat("Readmission rate - Training: ", 
    round(sum(data_train_rf$readmitted == "Readmitted")/nrow(data_train_rf)*100, 2), "%\n")
cat("Readmission rate - Testing: ", 
    round(sum(data_test_rf$readmitted == "Readmitted")/nrow(data_test_rf)*100, 2), "%\n")
cat("Readmission rate - Original: ", 
    round(sum(data_cart$readmitted == "Readmitted")/nrow(data_cart)*100, 2), "%\n\n")

# ==============================================================================
# 5b.2 Build Random Forest Model
# ==============================================================================

cat("=== 5b.2 Building Random Forest Model ===\n\n")

# Build model formula
predictor_vars_rf <- setdiff(colnames(data_train_rf), "readmitted")
formula_rf <- as.formula(paste("readmitted ~", paste(predictor_vars_rf, collapse = " + ")))

# Calculate mtry (number of features to consider at each split)
# Common default: sqrt(p) for classification
mtry_value <- floor(sqrt(length(predictor_vars_rf)))

cat("Fitting Random Forest model...\n")
cat("Number of trees: 500\n")
cat("Features per split (mtry): ", mtry_value, "\n")
cat("Total features: ", length(predictor_vars_rf), "\n\n")

# Fit the Random Forest model
model_rf <- randomForest(
  formula_rf,
  data = data_train_rf,
  ntree = 500,              # Number of trees
  mtry = mtry_value,        # Number of features at each split
  importance = TRUE,        # Calculate variable importance
  proximity = FALSE,        # Don't calculate proximity matrix (saves memory)
  do.trace = 50            # Print progress every 50 trees
)

cat("Model fitted successfully!\n")
cat("Final number of trees: ", model_rf$ntree, "\n")
cat("Features per split (mtry): ", model_rf$mtry, "\n")
cat("Out-of-bag error rate: ", round(model_rf$err.rate[model_rf$ntree, "OOB"] * 100, 2), "%\n\n")

# ==============================================================================
# 5b.3 Variable Importance
# ==============================================================================

cat("=== 5b.3 Variable Importance ===\n\n")

# Extract variable importance
var_importance_rf <- importance(model_rf)

# Create importance data frame
var_importance_rf_df <- data.frame(
  Variable = rownames(var_importance_rf),
  MeanDecreaseGini = as.numeric(var_importance_rf[, "MeanDecreaseGini"]),
  MeanDecreaseAccuracy = as.numeric(var_importance_rf[, "MeanDecreaseAccuracy"])
) %>%
  arrange(desc(MeanDecreaseGini))

# Convert to percentage
var_importance_rf_df$Importance_Percent <- (var_importance_rf_df$MeanDecreaseGini / sum(var_importance_rf_df$MeanDecreaseGini)) * 100

cat("Variable Importance (Top 10):\n")
print(head(var_importance_rf_df, 10))

# Save importance table
write.csv(var_importance_rf_df, "plots/05b_variable_importance.csv", row.names = FALSE)

# Save model metadata (number of trees, mtry)
model_metadata_rf <- data.frame(
  Parameter = c("ntree", "mtry"),
  Value = c(model_rf$ntree, model_rf$mtry)
)
write.csv(model_metadata_rf, "plots/05b_model_metadata.csv", row.names = FALSE)

# Create importance plot
p_importance_rf <- ggplot(head(var_importance_rf_df, 15), 
                         aes(x = reorder(Variable, Importance_Percent), 
                             y = Importance_Percent)) +
  geom_bar(stat = "identity", fill = "darkgreen", alpha = 0.7) +
  coord_flip() +
  labs(title = "Random Forest: Variable Importance",
       subtitle = "Top 15 Most Important Variables",
       x = "Variable",
       y = "Importance (%)") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5, size = 12))

ggsave("plots/05b_variable_importance.png", p_importance_rf, width = 10, height = 8, dpi = 300)

cat("\nVariable importance plot saved to: plots/05b_variable_importance.png\n\n")

# ==============================================================================
# 5b.4 Model Evaluation
# ==============================================================================

cat("=== 5b.4 Model Evaluation ===\n\n")

# Make predictions on test set
cat("Making predictions on test set...\n")
predictions_class_rf <- predict(model_rf, newdata = data_test_rf, type = "class")
predictions_prob_rf <- predict(model_rf, newdata = data_test_rf, type = "prob")[, "Readmitted"]

# Confusion Matrix
cat("\n--- Confusion Matrix ---\n")
conf_matrix_rf <- table(Predicted = predictions_class_rf, Actual = data_test_rf$readmitted)
print(conf_matrix_rf)

# Calculate metrics
# Get indices for confusion matrix
actual_levels_rf <- levels(data_test_rf$readmitted)
predicted_levels_rf <- levels(predictions_class_rf)

# Find positions
not_readmitted_idx_rf <- which(actual_levels_rf == "Not_Readmitted")
readmitted_idx_rf <- which(actual_levels_rf == "Readmitted")

# Extract values from confusion matrix
TN_rf <- conf_matrix_rf[not_readmitted_idx_rf, not_readmitted_idx_rf]
FP_rf <- conf_matrix_rf[readmitted_idx_rf, not_readmitted_idx_rf]
FN_rf <- conf_matrix_rf[not_readmitted_idx_rf, readmitted_idx_rf]
TP_rf <- conf_matrix_rf[readmitted_idx_rf, readmitted_idx_rf]

accuracy_rf <- (TP_rf + TN_rf) / (TP_rf + TN_rf + FP_rf + FN_rf)
precision_rf <- TP_rf / (TP_rf + FP_rf)
recall_rf <- TP_rf / (TP_rf + FN_rf)  # Also called Sensitivity
specificity_rf <- TN_rf / (TN_rf + FP_rf)
f1_score_rf <- 2 * (precision_rf * recall_rf) / (precision_rf + recall_rf)

cat("\n--- Performance Metrics ---\n")
cat("Accuracy: ", round(accuracy_rf * 100, 2), "%\n")
cat("Precision: ", round(precision_rf * 100, 2), "%\n")
cat("Recall (Sensitivity): ", round(recall_rf * 100, 2), "%\n")
cat("Specificity: ", round(specificity_rf * 100, 2), "%\n")
cat("F1-Score: ", round(f1_score_rf, 4), "\n\n")

# Save metrics
metrics_table_rf <- data.frame(
  Metric = c("Accuracy", "Precision", "Recall (Sensitivity)", "Specificity", "F1-Score"),
  Value = c(accuracy_rf, precision_rf, recall_rf, specificity_rf, f1_score_rf),
  Percentage = c(accuracy_rf * 100, precision_rf * 100, recall_rf * 100, 
                 specificity_rf * 100, f1_score_rf * 100)
)
write.csv(metrics_table_rf, "plots/05b_performance_metrics.csv", row.names = FALSE)

# ==============================================================================
# 5b.5 ROC Curve and AUC
# ==============================================================================

cat("=== 5b.5 ROC Curve and AUC ===\n\n")

# Calculate ROC curve
roc_obj_rf <- roc(data_test_rf$readmitted, predictions_prob_rf)

# Extract AUC
auc_value_rf <- auc(roc_obj_rf)
cat("Area Under the Curve (AUC): ", round(as.numeric(auc_value_rf), 4), "\n\n")

cat("AUC Interpretation:\n")
if(auc_value_rf > 0.9) {
  cat("Excellent discrimination (AUC > 0.9)\n")
} else if(auc_value_rf > 0.8) {
  cat("Good discrimination (0.8 < AUC <= 0.9)\n")
} else if(auc_value_rf > 0.7) {
  cat("Fair discrimination (0.7 < AUC <= 0.8)\n")
} else {
  cat("Poor discrimination (AUC <= 0.7)\n")
}

# Create ROC curve plot
roc_data_rf <- data.frame(
  FPR = 1 - roc_obj_rf$specificities,
  TPR = roc_obj_rf$sensitivities
)

p_roc_rf <- ggplot(roc_data_rf, aes(x = FPR, y = TPR)) +
  geom_line(color = "darkgreen", linewidth = 1.2) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "red", linewidth = 1) +
  labs(title = "ROC Curve: Random Forest Model",
       subtitle = paste("AUC =", round(as.numeric(auc_value_rf), 4)),
       x = "False Positive Rate (1 - Specificity)",
       y = "True Positive Rate (Sensitivity)") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5, size = 12))

ggsave("plots/05b_roc_curve_ggplot.png", p_roc_rf, width = 8, height = 8, dpi = 300)

# Base R version
png("plots/05b_roc_curve.png", width = 800, height = 800)
plot(roc_obj_rf, 
     main = "ROC Curve: Random Forest Model",
     xlab = "False Positive Rate (1 - Specificity)",
     ylab = "True Positive Rate (Sensitivity)",
     col = "darkgreen",
     lwd = 2)
abline(a = 0, b = 1, lty = 2, col = "red", lwd = 2)
text(0.6, 0.2, paste("AUC =", round(as.numeric(auc_value_rf), 4)), cex = 1.2)
legend("bottomright", 
       legend = c("ROC Curve", "Random Classifier", paste("AUC =", round(as.numeric(auc_value_rf), 4))),
       col = c("darkgreen", "red", "black"),
       lty = c(1, 2, 0),
       lwd = c(2, 2, 0))
dev.off()

cat("\nROC curve saved to: plots/05b_roc_curve.png\n")
cat("ROC curve (ggplot) saved to: plots/05b_roc_curve_ggplot.png\n\n")

# Save AUC value
auc_table_rf <- data.frame(
  Metric = "Area Under the Curve (AUC)",
  Value = as.numeric(auc_value_rf)
)
write.csv(auc_table_rf, "plots/05b_auc.csv", row.names = FALSE)

# ==============================================================================
# 5b.6 Summary Report
# ==============================================================================

cat("=== Phase 5b Complete ===\n\n")

cat("SUMMARY:\n")
cat("========\n\n")
cat("Model Type: Random Forest (Ensemble of Decision Trees)\n")
cat("Training Observations: ", nrow(data_train_rf), "\n")
cat("Testing Observations: ", nrow(data_test_rf), "\n")
cat("Total Variables: ", length(predictor_vars_rf), "\n")
cat("Number of Trees: ", model_rf$ntree, "\n")
cat("Features per Split (mtry): ", model_rf$mtry, "\n\n")

cat("Model Performance:\n")
cat("  Accuracy: ", round(accuracy_rf * 100, 2), "%\n")
cat("  AUC: ", round(as.numeric(auc_value_rf), 4), "\n")
cat("  Precision: ", round(precision_rf * 100, 2), "%\n")
cat("  Recall: ", round(recall_rf * 100, 2), "%\n")
cat("  F1-Score: ", round(f1_score_rf, 4), "\n\n")

cat("Top 5 Most Important Variables:\n")
for(i in 1:min(5, nrow(var_importance_rf_df))) {
  cat(sprintf("  %d. %s (%.2f%%)\n", i, var_importance_rf_df$Variable[i], var_importance_rf_df$Importance_Percent[i]))
}

cat("\nAll outputs saved to 'plots/' directory:\n")
cat("  - 05b_variable_importance.png (importance plot)\n")
cat("  - 05b_variable_importance.csv (importance table)\n")
cat("  - 05b_performance_metrics.csv (accuracy, precision, recall, etc.)\n")
cat("  - 05b_auc.csv (AUC value)\n")
cat("  - 05b_roc_curve.png (ROC curve visualization)\n")
cat("  - 05b_roc_curve_ggplot.png (ROC curve - ggplot version)\n\n")

cat("Next steps: Proceed to Phase 6 (Model Comparison) - now includes Random Forest\n")

