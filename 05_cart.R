# ==============================================================================
# Phase 5: CART (Classification and Regression Trees) Model
# Project: Predicting 30-Day Hospital Readmissions
# ==============================================================================

# Load required libraries
library(ggplot2)
library(dplyr)
library(rpart)

# Install and load rpart.plot if not available
if(!require(rpart.plot, quietly = TRUE)) {
  install.packages("rpart.plot", repos = "https://cran.r-project.org")
  library(rpart.plot)
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

cat("=== Phase 5: CART (Classification and Regression Trees) Model ===\n\n")

cat("Loading CART dataset...\n")
load("data_cart.RData")
cat("Dataset: ", nrow(data_cart), " observations, ", ncol(data_cart), " variables\n")
cat("Response variable: readmitted (factor: Not_Readmitted/Readmitted)\n\n")

# ==============================================================================
# 5.1 Prepare Data - Train/Test Split
# ==============================================================================

cat("=== 5.1 Train/Test Split ===\n\n")

# Set seed for reproducibility (same as Phase 4)
set.seed(123)

# Split data: 70% training, 30% testing (same split as logistic regression)
train_indices <- createDataPartition(data_cart$readmitted, 
                                     p = 0.7, 
                                     list = FALSE)

data_train_cart <- data_cart[train_indices, ]
data_test_cart <- data_cart[-train_indices, ]

cat("Training set: ", nrow(data_train_cart), " observations (", 
    round(nrow(data_train_cart)/nrow(data_cart)*100, 1), "%)\n")
cat("Testing set: ", nrow(data_test_cart), " observations (", 
    round(nrow(data_test_cart)/nrow(data_cart)*100, 1), "%)\n\n")

# Check distribution in both sets
cat("Readmission rate - Training: ", 
    round(sum(data_train_cart$readmitted == "Readmitted")/nrow(data_train_cart)*100, 2), "%\n")
cat("Readmission rate - Testing: ", 
    round(sum(data_test_cart$readmitted == "Readmitted")/nrow(data_test_cart)*100, 2), "%\n")
cat("Readmission rate - Original: ", 
    round(sum(data_cart$readmitted == "Readmitted")/nrow(data_cart)*100, 2), "%\n\n")

# ==============================================================================
# 5.2 Build CART Model
# ==============================================================================

cat("=== 5.2 Building CART Model ===\n\n")

# Build model formula
predictor_vars_cart <- setdiff(colnames(data_train_cart), "readmitted")
formula_cart <- as.formula(paste("readmitted ~", paste(predictor_vars_cart, collapse = " + ")))

cat("Fitting CART model...\n")
cat("Using all variables from the dataset...\n\n")

# Fit the CART model
# Using default parameters initially
model_cart <- rpart(formula_cart,
                   data = data_train_cart,
                   method = "class",  # For classification
                   parms = list(split = "gini"),  # Gini impurity for splitting
                   control = rpart.control(
                     minsplit = 20,      # Minimum observations in node to split
                     minbucket = 7,      # Minimum observations in terminal node
                     cp = 0.01,          # Complexity parameter
                     maxdepth = 10,      # Maximum depth of tree
                     xval = 10           # 10-fold cross-validation
                   ))

cat("Model fitted successfully!\n\n")

# Print model summary
cat("--- Model Summary ---\n")
print(model_cart)
cat("\n")

# Print complexity parameter table
cat("--- Complexity Parameter Table ---\n")
print(model_cart$cptable)
cat("\n")

# ==============================================================================
# 5.3 Prune Tree (Optional - Find Optimal Complexity)
# ==============================================================================

cat("=== 5.3 Tree Pruning (Finding Optimal Complexity) ===\n\n")

# Find the optimal CP value using 1-SE rule
cp_table <- model_cart$cptable
optimal_cp_index <- which.min(cp_table[, "xerror"])
optimal_cp <- cp_table[optimal_cp_index, "CP"]

# Get 1-SE rule CP (more conservative)
xerror_min <- cp_table[optimal_cp_index, "xerror"]
xerror_se <- cp_table[optimal_cp_index, "xstd"]
xerror_1se <- xerror_min + xerror_se

# Find largest tree within 1-SE
cp_1se_index <- which(cp_table[, "xerror"] <= xerror_1se)[1]
cp_1se <- cp_table[cp_1se_index, "CP"]

cat("Optimal CP (minimum xerror): ", optimal_cp, "\n")
cat("1-SE Rule CP: ", cp_1se, "\n")
cat("Using 1-SE rule for pruning (more conservative)...\n\n")

# Prune the tree
model_cart_pruned <- prune(model_cart, cp = cp_1se)

cat("Tree pruned successfully!\n")
cat("Original tree size: ", length(unique(model_cart$where)), " nodes\n")
cat("Pruned tree size: ", length(unique(model_cart_pruned$where)), " nodes\n\n")

# Use pruned model for further analysis
model_cart_final <- model_cart_pruned

# ==============================================================================
# 5.4 Visualize Decision Tree
# ==============================================================================

cat("=== 5.4 Visualizing Decision Tree ===\n\n")

# Create output directory for plots
if(!dir.exists("plots")) {
  dir.create("plots")
}

# Basic tree plot
png("plots/05_cart_tree_basic.png", width = 2000, height = 1500, res = 300)
rpart.plot(model_cart_final, 
           type = 2,           # Type 2: split labels, node labels
           extra = 104,        # Show probability of class and percent of observations
           fallen.leaves = TRUE,
           branch = 0.3,
           under = TRUE,
           cex = 0.6,
           main = "CART Decision Tree: Predicting Hospital Readmissions")
dev.off()

# Detailed tree plot
png("plots/05_cart_tree_detailed.png", width = 2400, height = 1800, res = 300)
rpart.plot(model_cart_final, 
           type = 4,           # Type 4: probability of second class
           extra = 101,        # Show number of observations and percent
           fallen.leaves = TRUE,
           branch = 0.3,
           under = TRUE,
           cex = 0.5,
           main = "CART Decision Tree: Detailed View")
dev.off()

# Compact tree plot
png("plots/05_cart_tree_compact.png", width = 1600, height = 1200, res = 300)
rpart.plot(model_cart_final, 
           type = 0,           # Type 0: compact
           extra = 2,          # Show number of correct classifications
           fallen.leaves = TRUE,
           branch = 0.3,
           cex = 0.7,
           main = "CART Decision Tree: Compact View")
dev.off()

cat("Tree visualizations saved:\n")
cat("  - plots/05_cart_tree_basic.png\n")
cat("  - plots/05_cart_tree_detailed.png\n")
cat("  - plots/05_cart_tree_compact.png\n\n")

# ==============================================================================
# 5.5 Variable Importance
# ==============================================================================

cat("=== 5.5 Variable Importance ===\n\n")

# Extract variable importance
var_importance <- model_cart_final$variable.importance

# Normalize to percentages
var_importance_pct <- (var_importance / sum(var_importance)) * 100

# Create importance data frame
importance_df <- data.frame(
  Variable = names(var_importance),
  Importance = as.numeric(var_importance),
  Importance_Percent = as.numeric(var_importance_pct)
) %>%
  arrange(desc(Importance))

cat("Variable Importance (Top 10):\n")
print(head(importance_df, 10))

# Save importance table
write.csv(importance_df, "plots/05_variable_importance.csv", row.names = FALSE)

# Create importance plot
p_importance <- ggplot(head(importance_df, 15), 
                      aes(x = reorder(Variable, Importance_Percent), 
                          y = Importance_Percent)) +
  geom_bar(stat = "identity", fill = "steelblue", alpha = 0.7) +
  coord_flip() +
  labs(title = "CART Model: Variable Importance",
       subtitle = "Top 15 Most Important Variables",
       x = "Variable",
       y = "Importance (%)") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5, size = 12))

ggsave("plots/05_variable_importance.png", p_importance, width = 10, height = 8, dpi = 300)

cat("\nVariable importance plot saved to: plots/05_variable_importance.png\n\n")

# ==============================================================================
# 5.6 Model Evaluation
# ==============================================================================

cat("=== 5.6 Model Evaluation ===\n\n")

# Make predictions on test set
cat("Making predictions on test set...\n")
predictions_class_cart <- predict(model_cart_final, newdata = data_test_cart, type = "class")
predictions_prob_cart <- predict(model_cart_final, newdata = data_test_cart, type = "prob")[, "Readmitted"]

# Confusion Matrix
cat("\n--- Confusion Matrix ---\n")
conf_matrix_cart <- table(Predicted = predictions_class_cart, Actual = data_test_cart$readmitted)
print(conf_matrix_cart)

# Calculate metrics
# Get indices for confusion matrix
actual_levels <- levels(data_test_cart$readmitted)
predicted_levels <- levels(predictions_class_cart)

# Find positions
not_readmitted_idx <- which(actual_levels == "Not_Readmitted")
readmitted_idx <- which(actual_levels == "Readmitted")

# Extract values from confusion matrix
TN <- conf_matrix_cart[not_readmitted_idx, not_readmitted_idx]
FP <- conf_matrix_cart[readmitted_idx, not_readmitted_idx]
FN <- conf_matrix_cart[not_readmitted_idx, readmitted_idx]
TP <- conf_matrix_cart[readmitted_idx, readmitted_idx]

accuracy_cart <- (TP + TN) / (TP + TN + FP + FN)
precision_cart <- TP / (TP + FP)
recall_cart <- TP / (TP + FN)  # Also called Sensitivity
specificity_cart <- TN / (TN + FP)
f1_score_cart <- 2 * (precision_cart * recall_cart) / (precision_cart + recall_cart)

cat("\n--- Performance Metrics ---\n")
cat("Accuracy: ", round(accuracy_cart * 100, 2), "%\n")
cat("Precision: ", round(precision_cart * 100, 2), "%\n")
cat("Recall (Sensitivity): ", round(recall_cart * 100, 2), "%\n")
cat("Specificity: ", round(specificity_cart * 100, 2), "%\n")
cat("F1-Score: ", round(f1_score_cart, 4), "\n\n")

# Save metrics
metrics_table_cart <- data.frame(
  Metric = c("Accuracy", "Precision", "Recall (Sensitivity)", "Specificity", "F1-Score"),
  Value = c(accuracy_cart, precision_cart, recall_cart, specificity_cart, f1_score_cart),
  Percentage = c(accuracy_cart * 100, precision_cart * 100, recall_cart * 100, 
                 specificity_cart * 100, f1_score_cart * 100)
)
write.csv(metrics_table_cart, "plots/05_performance_metrics.csv", row.names = FALSE)

# ==============================================================================
# 5.7 ROC Curve and AUC
# ==============================================================================

cat("=== 5.7 ROC Curve and AUC ===\n\n")

# Calculate ROC curve
roc_obj_cart <- roc(data_test_cart$readmitted, predictions_prob_cart)

# Extract AUC
auc_value_cart <- auc(roc_obj_cart)
cat("Area Under the Curve (AUC): ", round(as.numeric(auc_value_cart), 4), "\n\n")

cat("AUC Interpretation:\n")
if(auc_value_cart > 0.9) {
  cat("Excellent discrimination (AUC > 0.9)\n")
} else if(auc_value_cart > 0.8) {
  cat("Good discrimination (0.8 < AUC <= 0.9)\n")
} else if(auc_value_cart > 0.7) {
  cat("Fair discrimination (0.7 < AUC <= 0.8)\n")
} else {
  cat("Poor discrimination (AUC <= 0.7)\n")
}

# Create ROC curve plot
roc_data_cart <- data.frame(
  FPR = 1 - roc_obj_cart$specificities,
  TPR = roc_obj_cart$sensitivities
)

p_roc_cart <- ggplot(roc_data_cart, aes(x = FPR, y = TPR)) +
  geom_line(color = "steelblue", linewidth = 1.2) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "red", linewidth = 1) +
  labs(title = "ROC Curve: CART Model",
       subtitle = paste("AUC =", round(as.numeric(auc_value_cart), 4)),
       x = "False Positive Rate (1 - Specificity)",
       y = "True Positive Rate (Sensitivity)") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5, size = 12))

ggsave("plots/05_roc_curve_ggplot.png", p_roc_cart, width = 8, height = 8, dpi = 300)

# Base R version
png("plots/05_roc_curve.png", width = 800, height = 800)
plot(roc_obj_cart, 
     main = "ROC Curve: CART Model",
     xlab = "False Positive Rate (1 - Specificity)",
     ylab = "True Positive Rate (Sensitivity)",
     col = "steelblue",
     lwd = 2)
abline(a = 0, b = 1, lty = 2, col = "red", lwd = 2)
text(0.6, 0.2, paste("AUC =", round(as.numeric(auc_value_cart), 4)), cex = 1.2)
legend("bottomright", 
       legend = c("ROC Curve", "Random Classifier", paste("AUC =", round(as.numeric(auc_value_cart), 4))),
       col = c("steelblue", "red", "black"),
       lty = c(1, 2, 0),
       lwd = c(2, 2, 0))
dev.off()

cat("\nROC curve saved to: plots/05_roc_curve.png\n")
cat("ROC curve (ggplot) saved to: plots/05_roc_curve_ggplot.png\n\n")

# Save AUC value
auc_table_cart <- data.frame(
  Metric = "Area Under the Curve (AUC)",
  Value = as.numeric(auc_value_cart)
)
write.csv(auc_table_cart, "plots/05_auc.csv", row.names = FALSE)

# ==============================================================================
# 5.8 Tree Rules and Interpretation
# ==============================================================================

cat("=== 5.8 Tree Rules and Interpretation ===\n\n")

# Extract rules from the tree
cat("Decision Rules (from root to leaves):\n\n")

# Function to extract rules (simplified)
tree_rules <- capture.output(print(model_cart_final))
cat("Tree structure:\n")
cat(paste(tree_rules[1:min(50, length(tree_rules))], collapse = "\n"))
cat("\n\n")

# Count terminal nodes
terminal_nodes <- sum(model_cart_final$frame$var == "<leaf>")
cat("Number of terminal nodes (leaves): ", terminal_nodes, "\n")
cat("Number of splits: ", nrow(model_cart_final$frame) - terminal_nodes, "\n\n")

# ==============================================================================
# 5.9 Summary Report
# ==============================================================================

cat("=== Phase 5 Complete ===\n\n")

cat("SUMMARY:\n")
cat("========\n\n")
cat("Model Type: CART (Classification and Regression Trees)\n")
cat("Training Observations: ", nrow(data_train_cart), "\n")
cat("Testing Observations: ", nrow(data_test_cart), "\n")
cat("Total Variables: ", length(predictor_vars_cart), "\n")
cat("Tree Complexity: ", length(unique(model_cart_final$where)), " nodes\n")
cat("Terminal Nodes: ", terminal_nodes, "\n\n")

cat("Model Performance:\n")
cat("  Accuracy: ", round(accuracy_cart * 100, 2), "%\n")
cat("  AUC: ", round(as.numeric(auc_value_cart), 4), "\n")
cat("  Precision: ", round(precision_cart * 100, 2), "%\n")
cat("  Recall: ", round(recall_cart * 100, 2), "%\n")
cat("  F1-Score: ", round(f1_score_cart, 4), "\n\n")

cat("Top 5 Most Important Variables:\n")
for(i in 1:min(5, nrow(importance_df))) {
  cat(sprintf("  %d. %s (%.2f%%)\n", i, importance_df$Variable[i], importance_df$Importance_Percent[i]))
}

cat("\nAll outputs saved to 'plots/' directory:\n")
cat("  - 05_cart_tree_basic.png (tree visualization)\n")
cat("  - 05_cart_tree_detailed.png (detailed tree)\n")
cat("  - 05_cart_tree_compact.png (compact tree)\n")
cat("  - 05_variable_importance.png (importance plot)\n")
cat("  - 05_variable_importance.csv (importance table)\n")
cat("  - 05_performance_metrics.csv (accuracy, precision, recall, etc.)\n")
cat("  - 05_auc.csv (AUC value)\n")
cat("  - 05_roc_curve.png (ROC curve visualization)\n")
cat("  - 05_roc_curve_ggplot.png (ROC curve - ggplot version)\n\n")

cat("Next steps: Proceed to Phase 6 (Model Comparison)\n")

