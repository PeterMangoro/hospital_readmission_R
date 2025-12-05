# ==============================================================================
# Phase 6: Model Comparison - Logistic Regression vs. CART
# Project: Predicting 30-Day Hospital Readmissions
# ==============================================================================

# Load required libraries
library(ggplot2)
library(dplyr)
library(tidyr)
library(pROC)
library(gridExtra)
library(caret)

# Set working directory (adjust if needed)
# setwd("/home/themad/Documents/yeshiva/computationalMaths/projects")

# ==============================================================================
# Load Model Results
# ==============================================================================

cat("=== Phase 6: Model Comparison ===\n\n")

# Load performance metrics from all models
metrics_logistic <- read.csv("plots/04_performance_metrics.csv")
metrics_cart <- read.csv("plots/05_performance_metrics.csv")
metrics_rf <- read.csv("plots/05b_performance_metrics.csv")

auc_logistic <- read.csv("plots/04_auc.csv")
auc_cart <- read.csv("plots/05_auc.csv")
auc_rf <- read.csv("plots/05b_auc.csv")

# Load regression output for logistic regression
regression_output <- read.csv("plots/04_regression_output.csv")

# Load variable importance for CART and Random Forest
var_importance_cart <- read.csv("plots/05_variable_importance.csv")
var_importance_rf <- read.csv("plots/05b_variable_importance.csv")

# Load Random Forest model metadata (if available)
if(file.exists("plots/05b_model_metadata.csv")) {
  model_metadata_rf <- read.csv("plots/05b_model_metadata.csv")
  n_trees_rf <- model_metadata_rf$Value[model_metadata_rf$Parameter == "ntree"]
} else {
  n_trees_rf <- 500  # Default value
}

cat("Loaded results from all three models\n\n")

# ==============================================================================
# 6.1 Performance Metrics Comparison
# ==============================================================================

cat("=== 6.1 Performance Metrics Comparison ===\n\n")

# Create comparison table with all three models
comparison_table <- data.frame(
  Metric = metrics_logistic$Metric,
  Logistic_Regression = round(metrics_logistic$Percentage, 2),
  CART = round(metrics_cart$Percentage, 2),
  Random_Forest = round(metrics_rf$Percentage, 2)
)

# Add AUC row
comparison_table <- rbind(comparison_table,
  data.frame(
    Metric = "AUC",
    Logistic_Regression = round(auc_logistic$Value * 100, 2),
    CART = round(auc_cart$Value * 100, 2),
    Random_Forest = round(auc_rf$Value * 100, 2)
  )
)

cat("Side-by-Side Performance Comparison:\n")
print(comparison_table)

# Save comparison table
write.csv(comparison_table, "plots/06_model_comparison.csv", row.names = FALSE)

# Determine winner for each metric
cat("\n--- Model Performance Summary ---\n")
for(i in 1:nrow(comparison_table)) {
  metric <- comparison_table$Metric[i]
  lr_val <- comparison_table$Logistic_Regression[i]
  cart_val <- comparison_table$CART[i]
  rf_val <- comparison_table$Random_Forest[i]
  
  # Find the best value
  values <- c(lr_val, cart_val, rf_val)
  names(values) <- c("Logistic Regression", "CART", "Random Forest")
  best_idx <- which.max(values)
  winner <- names(values)[best_idx]
  best_val <- values[best_idx]
  
  # Calculate difference from second best
  second_best <- sort(values, decreasing = TRUE)[2]
  diff <- best_val - second_best
  
  cat(sprintf("%s: %s wins (%.2f%%, %.2f%% above second best)\n", 
              metric, winner, best_val, diff))
}

# ==============================================================================
# 6.2 ROC Curve Comparison
# ==============================================================================

cat("\n=== 6.2 ROC Curve Comparison ===\n\n")

cat("AUC Comparison:\n")
cat("  Logistic Regression: ", round(auc_logistic$Value, 4), "\n")
cat("  CART: ", round(auc_cart$Value, 4), "\n")
cat("  Random Forest: ", round(auc_rf$Value, 4), "\n")
cat("  Best: ", c("Logistic Regression", "CART", "Random Forest")[which.max(c(auc_logistic$Value, auc_cart$Value, auc_rf$Value))], 
    " (", round(max(auc_logistic$Value, auc_cart$Value, auc_rf$Value), 4), ")\n\n")

# Create comparison visualization
comparison_data <- data.frame(
  Model = c("Logistic Regression", "CART", "Random Forest"),
  AUC = c(auc_logistic$Value, auc_cart$Value, auc_rf$Value),
  Accuracy = c(metrics_logistic$Percentage[metrics_logistic$Metric == "Accuracy"] / 100,
               metrics_cart$Percentage[metrics_cart$Metric == "Accuracy"] / 100,
               metrics_rf$Percentage[metrics_rf$Metric == "Accuracy"] / 100),
  Precision = c(metrics_logistic$Percentage[metrics_logistic$Metric == "Precision"] / 100,
                metrics_cart$Percentage[metrics_cart$Metric == "Precision"] / 100,
                metrics_rf$Percentage[metrics_rf$Metric == "Precision"] / 100),
  Recall = c(metrics_logistic$Percentage[metrics_logistic$Metric == "Recall (Sensitivity)"] / 100,
             metrics_cart$Percentage[metrics_cart$Metric == "Recall (Sensitivity)"] / 100,
             metrics_rf$Percentage[metrics_rf$Metric == "Recall (Sensitivity)"] / 100),
  F1_Score = c(metrics_logistic$Value[metrics_logistic$Metric == "F1-Score"],
               metrics_cart$Value[metrics_cart$Metric == "F1-Score"],
               metrics_rf$Value[metrics_rf$Metric == "F1-Score"])
)

# Reshape for grouped bar chart
comparison_long <- comparison_data %>%
  select(Model, Accuracy, Precision, Recall, F1_Score) %>%
  pivot_longer(cols = c(Accuracy, Precision, Recall, F1_Score),
               names_to = "Metric",
               values_to = "Value")

# Bar chart comparison
p_metrics <- ggplot(comparison_long, aes(x = Metric, y = Value, fill = Model)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
  scale_fill_manual(values = c("Logistic Regression" = "steelblue", 
                               "CART" = "lightcoral",
                               "Random Forest" = "darkgreen")) +
  labs(title = "Model Performance Comparison",
       subtitle = "Accuracy, Precision, Recall, and F1-Score",
       y = "Score",
       x = "Metric",
       fill = "Model") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5, size = 12))

ggsave("plots/06_metrics_comparison.png", p_metrics, width = 10, height = 6, dpi = 300)

# AUC comparison bar chart
p_auc <- ggplot(comparison_data, aes(x = Model, y = AUC, fill = Model)) +
  geom_bar(stat = "identity", alpha = 0.7) +
  scale_fill_manual(values = c("Logistic Regression" = "steelblue", 
                               "CART" = "lightcoral",
                               "Random Forest" = "darkgreen")) +
  labs(title = "AUC Comparison: All Three Models",
       y = "Area Under the Curve (AUC)",
       x = "Model") +
  geom_text(aes(label = round(AUC, 4)), vjust = -0.5, size = 5) +
  ylim(0, max(comparison_data$AUC) * 1.2) +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
        legend.position = "none")

ggsave("plots/06_auc_comparison.png", p_auc, width = 8, height = 6, dpi = 300)

cat("Comparison visualizations saved\n\n")

# ==============================================================================
# 6.3 Interpretability Comparison
# ==============================================================================

cat("=== 6.3 Interpretability Comparison ===\n\n")

cat("Logistic Regression:\n")
cat("  - Provides coefficients and odds ratios for each variable\n")
cat("  - Statistical significance testing (p-values)\n")
cat("  - Linear relationships assumed\n")
cat("  - ", nrow(regression_output), " parameters in the model\n")
cat("  - ", sum(regression_output$P_Value < 0.05, na.rm = TRUE), " significant variables (p < 0.05)\n\n")

cat("CART:\n")
cat("  - Simple decision tree with ", nrow(var_importance_cart), " variables considered\n")
cat("  - Very interpretable: simple decision rule(s)\n")
cat("  - Non-linear relationships captured\n")
cat("  - Top variable: ", var_importance_cart$Variable[1], " (", 
    round(var_importance_cart$Importance_Percent[1], 2), "% importance)\n\n")

cat("Random Forest:\n")
cat("  - Ensemble of 500 decision trees\n")
cat("  - Uses bootstrap sampling and feature randomization\n")
cat("  - ", nrow(var_importance_rf), " variables considered\n")
cat("  - Lower interpretability (ensemble effect)\n")
cat("  - Non-linear relationships captured\n")
cat("  - Top variable: ", var_importance_rf$Variable[1], " (", 
    round(var_importance_rf$Importance_Percent[1], 2), "% importance)\n\n")

# ==============================================================================
# 6.4 Model Selection and Justification
# ==============================================================================

cat("=== 6.4 Model Selection and Justification ===\n\n")

# Determine best model based on multiple criteria
lr_wins <- sum(comparison_table$Logistic_Regression > comparison_table$CART & 
               comparison_table$Logistic_Regression > comparison_table$Random_Forest, na.rm = TRUE)
cart_wins <- sum(comparison_table$CART > comparison_table$Logistic_Regression & 
                 comparison_table$CART > comparison_table$Random_Forest, na.rm = TRUE)
rf_wins <- sum(comparison_table$Random_Forest > comparison_table$Logistic_Regression & 
               comparison_table$Random_Forest > comparison_table$CART, na.rm = TRUE)

cat("Performance Metrics Won:\n")
cat("  Logistic Regression: ", lr_wins, " metrics\n")
cat("  CART: ", cart_wins, " metrics\n")
cat("  Random Forest: ", rf_wins, " metrics\n\n")

# Overall assessment - find best AUC and accuracy
auc_values <- c(auc_logistic$Value, auc_cart$Value, auc_rf$Value)
names(auc_values) <- c("Logistic Regression", "CART", "Random Forest")
best_auc_model <- names(auc_values)[which.max(auc_values)]

acc_values <- c(metrics_logistic$Value[metrics_logistic$Metric == "Accuracy"],
                metrics_cart$Value[metrics_cart$Metric == "Accuracy"],
                metrics_rf$Value[metrics_rf$Metric == "Accuracy"])
names(acc_values) <- c("Logistic Regression", "CART", "Random Forest")
best_acc_model <- names(acc_values)[which.max(acc_values)]

if(best_auc_model == best_acc_model) {
  best_model <- best_auc_model
  reason <- paste("Highest AUC and accuracy")
} else if(max(auc_values) > 0.7 && max(acc_values) > 0.6) {
  best_model <- best_auc_model
  reason <- paste("Highest AUC (", round(max(auc_values), 3), ")", sep = "")
} else {
  best_model <- "Logistic Regression"
  reason <- "Best overall performance and statistical rigor"
}

cat("Recommended Model: ", best_model, "\n")
cat("Reason: ", reason, "\n\n")

# Create justification table
justification <- data.frame(
  Criterion = c("Accuracy", "AUC", "Precision", "Recall", "F1-Score", 
                "Interpretability", "Complexity", "Statistical Rigor"),
  Logistic_Regression = c(
    paste0(round(metrics_logistic$Percentage[metrics_logistic$Metric == "Accuracy"], 2), "%"),
    paste0(round(auc_logistic$Value * 100, 2), "%"),
    paste0(round(metrics_logistic$Percentage[metrics_logistic$Metric == "Precision"], 2), "%"),
    paste0(round(metrics_logistic$Percentage[metrics_logistic$Metric == "Recall (Sensitivity)"], 2), "%"),
    round(metrics_logistic$Value[metrics_logistic$Metric == "F1-Score"], 4),
    "High (coefficients, odds ratios)",
    paste0("High (", nrow(regression_output), " parameters)"),
    "High (p-values, hypothesis tests)"
  ),
  CART = c(
    paste0(round(metrics_cart$Percentage[metrics_cart$Metric == "Accuracy"], 2), "%"),
    paste0(round(auc_cart$Value * 100, 2), "%"),
    paste0(round(metrics_cart$Percentage[metrics_cart$Metric == "Precision"], 2), "%"),
    paste0(round(metrics_cart$Percentage[metrics_cart$Metric == "Recall (Sensitivity)"], 2), "%"),
    round(metrics_cart$Value[metrics_cart$Metric == "F1-Score"], 4),
    "Very High (simple tree, easy rules)",
    "Very Low (simple tree)",
    "Medium (no p-values, variable importance)"
  ),
  Random_Forest = c(
    paste0(round(metrics_rf$Percentage[metrics_rf$Metric == "Accuracy"], 2), "%"),
    paste0(round(auc_rf$Value * 100, 2), "%"),
    paste0(round(metrics_rf$Percentage[metrics_rf$Metric == "Precision"], 2), "%"),
    paste0(round(metrics_rf$Percentage[metrics_rf$Metric == "Recall (Sensitivity)"], 2), "%"),
    round(metrics_rf$Value[metrics_rf$Metric == "F1-Score"], 4),
    paste0("Low (ensemble of ", n_trees_rf, " trees)"),
    paste0("High (", n_trees_rf, " trees, complex ensemble)"),
    "Medium (variable importance, no p-values)"
  )
)

print(justification)
write.csv(justification, "plots/06_model_justification.csv", row.names = FALSE)

# ==============================================================================
# 6.5 Key Findings Summary
# ==============================================================================

cat("\n=== 6.5 Key Findings Summary ===\n\n")

cat("1. Performance:\n")
avg_accuracy <- mean(c(metrics_logistic$Percentage[metrics_logistic$Metric == "Accuracy"],
                       metrics_cart$Percentage[metrics_cart$Metric == "Accuracy"],
                       metrics_rf$Percentage[metrics_rf$Metric == "Accuracy"]))
cat("   - All three models show similar performance (accuracy ~", round(avg_accuracy, 0), "%)\n", sep = "")
cat("   - Best AUC: ", best_auc_model, " (", round(max(auc_logistic$Value, auc_cart$Value, auc_rf$Value), 3), ")\n", sep = "")
cat("   - Logistic Regression: ", round(auc_logistic$Value, 3), 
    ", CART: ", round(auc_cart$Value, 3), 
    ", Random Forest: ", round(auc_rf$Value, 3), "\n", sep = "")
max_auc <- max(auc_logistic$Value, auc_cart$Value, auc_rf$Value)
cat("   - All models have ", 
    ifelse(max_auc < 0.7, "fair to poor", "good"), 
    " discrimination (AUC < 0.7)\n\n")

cat("2. Interpretability:\n")
n_cart_vars <- nrow(var_importance_cart)
n_lr_params <- nrow(regression_output)
n_rf_vars <- nrow(var_importance_rf)
cat("   - CART: Simplest (", n_cart_vars, " variables, single tree)\n", sep = "")
cat("   - Logistic Regression: ", n_lr_params, " parameters, detailed statistical insights\n", sep = "")
cat("   - Random Forest: Most complex (", n_trees_rf, " trees, ", n_rf_vars, " variables)\n", sep = "")
cat("   - All models identify similar key predictors\n\n")

cat("3. Key Predictors:\n")
# Get top predictor from logistic regression
top_lr_predictor <- regression_output[order(-regression_output$Odds_Ratio), ][1, ]
cat("   - Logistic Regression: ", top_lr_predictor$Variable, " (OR: ", round(top_lr_predictor$Odds_Ratio, 2), "), age groups, medical specialty\n", sep = "")
top_odds <- regression_output[order(-regression_output$Odds_Ratio), ][1:min(3, nrow(regression_output)), ]
cat("   - Top 3 predictors by OR: ", paste(top_odds$Variable, collapse = ", "), "\n", sep = "")
cat("   - CART: ", var_importance_cart$Variable[1], " (", 
    round(var_importance_cart$Importance_Percent[1], 2), "% importance)\n", sep = "")
cat("   - Random Forest: ", var_importance_rf$Variable[1], " (", 
    round(var_importance_rf$Importance_Percent[1], 2), "% importance)\n\n", sep = "")

cat("4. Model Selection:\n")
cat("   - For prediction: ", best_model, " (", reason, ")\n", sep = "")
cat("   - For simplicity: CART (very interpretable)\n")
cat("   - For statistical rigor: Logistic Regression (p-values, confidence intervals)\n\n")

# ==============================================================================
# 6.6 Limitations and Recommendations
# ==============================================================================

cat("=== 6.6 Limitations and Recommendations ===\n\n")

cat("Limitations:\n")
cat("1. Both models show moderate performance (AUC < 0.7)\n")
cat("2. Limited predictive power suggests missing important variables\n")
cat("3. CART model is very simple (may be underfitting)\n")
cat("4. Logistic Regression assumes linear relationships\n")
cat("5. Data from 1999-2008 may not reflect current healthcare practices\n")
cat("6. Missing data in medical_specialty (49.53%) may affect results\n\n")

cat("Recommendations:\n")
cat("1. Consider additional features (e.g., lab results, vital signs, comorbidities)\n")
cat("2. Try ensemble methods (Random Forest, Gradient Boosting)\n")
cat("3. Collect more recent data if possible\n")
cat("4. For clinical use: Logistic Regression provides more detailed risk factors\n")
cat("5. For quick screening: CART provides simple decision rules\n")
cat("6. Consider feature engineering to improve model performance\n\n")

# ==============================================================================
# 6.7 Final Summary
# ==============================================================================

cat("=== Phase 6 Complete ===\n\n")

cat("SUMMARY:\n")
cat("========\n\n")
cat("Model Comparison Completed:\n")
cat("  - Performance metrics compared\n")
cat("  - ROC curves analyzed\n")
cat("  - Interpretability assessed\n")
cat("  - Best model identified: ", best_model, "\n\n")

cat("All outputs saved to 'plots/' directory:\n")
cat("  - 06_model_comparison.csv (performance comparison table)\n")
cat("  - 06_model_justification.csv (detailed justification)\n")
cat("  - 06_metrics_comparison.png (metrics visualization)\n")
cat("  - 06_auc_comparison.png (AUC comparison)\n\n")

cat("Next steps: Create master R Markdown report (PROJECT_REPORT.Rmd)\n")

