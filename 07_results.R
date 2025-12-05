# ==============================================================================
# Phase 7: Results and Reporting
# Project: Predicting 30-Day Hospital Readmissions
# ==============================================================================

# Load required libraries
library(ggplot2)
library(dplyr)
library(knitr)

# Set working directory (adjust if needed)
# setwd("/home/themad/Documents/yeshiva/computationalMaths/projects")

cat("=== Phase 7: Results and Reporting ===\n\n")

# ==============================================================================
# 7.1 Load All Results
# ==============================================================================

cat("Loading all analysis results...\n")

# Load comparison results
model_comparison <- read.csv("plots/06_model_comparison.csv")
model_justification <- read.csv("plots/06_model_justification.csv")
metrics_logistic <- read.csv("plots/04_performance_metrics.csv")
metrics_cart <- read.csv("plots/05_performance_metrics.csv")
regression_output <- read.csv("plots/04_regression_output.csv")
var_importance <- read.csv("plots/05_variable_importance.csv")
r2_values <- read.csv("plots/04_rsquared.csv")
auc_logistic <- read.csv("plots/04_auc.csv")
auc_cart <- read.csv("plots/05_auc.csv")

cat("All results loaded successfully\n\n")

# ==============================================================================
# 7.2 Create Final Summary Report
# ==============================================================================

cat("=== 7.2 Creating Final Summary Report ===\n\n")

# Create comprehensive summary
summary_text <- paste0(
  "================================================================================\n",
  "FINAL PROJECT SUMMARY: Predicting 30-Day Hospital Readmissions\n",
  "================================================================================\n\n",
  
  "RESEARCH QUESTION:\n",
  "Can patient demographic, diagnostic, and treatment-related features effectively\n",
  "predict the likelihood of a patient being readmitted to the hospital within\n",
  "30 days of discharge?\n\n",
  
  "ANSWER: YES, with moderate accuracy (~61%)\n\n",
  
  "================================================================================\n",
  "DATASET SUMMARY\n",
  "================================================================================\n",
  "Source: Kaggle - Diabetes 130-US Hospitals for 10 years\n",
  "Time Period: 1999-2008\n",
  "Hospitals: 130 US hospitals\n",
  "Original Observations: 25,000\n",
  "Final Observations: 24,996 (after cleaning)\n",
  "Readmission Rate: 47.02%\n\n",
  
  "================================================================================\n",
  "MODEL PERFORMANCE SUMMARY\n",
  "================================================================================\n",
  "LOGISTIC REGRESSION:\n",
  "  Accuracy: ", round(metrics_logistic$Percentage[metrics_logistic$Metric == "Accuracy"], 2), "%\n",
  "  AUC: ", round(auc_logistic$Value, 4), "\n",
  "  Precision: ", round(metrics_logistic$Percentage[metrics_logistic$Metric == "Precision"], 2), "%\n",
  "  Recall: ", round(metrics_logistic$Percentage[metrics_logistic$Metric == "Recall (Sensitivity)"], 2), "%\n",
  "  F1-Score: ", round(metrics_logistic$Value[metrics_logistic$Metric == "F1-Score"], 4), "\n",
  "  Pseudo R²: ", round(r2_values$Value[r2_values$Metric == "McFadden's Pseudo R²"], 4), "\n",
  "  Significant Variables: ", sum(regression_output$P_Value < 0.05, na.rm = TRUE), "\n\n",
  
  "CART:\n",
  "  Accuracy: ", round(metrics_cart$Percentage[metrics_cart$Metric == "Accuracy"], 2), "%\n",
  "  AUC: ", round(auc_cart$Value, 4), "\n",
  "  Precision: ", round(metrics_cart$Percentage[metrics_cart$Metric == "Precision"], 2), "%\n",
  "  Recall: ", round(metrics_cart$Percentage[metrics_cart$Metric == "Recall (Sensitivity)"], 2), "%\n",
  "  F1-Score: ", round(metrics_cart$Value[metrics_cart$Metric == "F1-Score"], 4), "\n",
  "  Tree Complexity: 1 split, 2 nodes\n",
  "  Top Variable: ", var_importance$Variable[1], " (", 
  round(var_importance$Importance_Percent[1], 2), "% importance)\n\n",
  
  "WINNER: Logistic Regression (Higher AUC and Accuracy)\n\n",
  
  "================================================================================\n",
  "KEY FINDINGS\n",
  "================================================================================\n",
  "1. Previous hospital visits are the strongest predictor of readmission\n",
  "2. Age groups 70-80 and 80-90 show higher readmission risk\n",
  "3. Medical specialty (especially Cardiology) is associated with readmission\n",
  "4. Both models show moderate performance (AUC < 0.7)\n",
  "5. Logistic Regression provides more detailed statistical insights\n",
  "6. CART offers superior simplicity and interpretability\n\n",
  
  "================================================================================\n",
  "TOP PREDICTORS\n",
  "================================================================================\n",
  "Logistic Regression (by Odds Ratio):\n"
)

# Add top predictors
top_predictors <- head(regression_output[order(-regression_output$Odds_Ratio), ], 5)
for(i in 1:nrow(top_predictors)) {
  summary_text <- paste0(summary_text,
    sprintf("  %d. %s (OR: %.2f, p: %.4f)\n", 
            i, top_predictors$Variable[i], 
            top_predictors$Odds_Ratio[i],
            top_predictors$P_Value[i]))
}

summary_text <- paste0(summary_text,
  "\nCART (by Importance):\n")
top_cart <- head(var_importance, 5)
for(i in 1:nrow(top_cart)) {
  summary_text <- paste0(summary_text,
    sprintf("  %d. %s (%.2f%%)\n", 
            i, top_cart$Variable[i], 
            top_cart$Importance_Percent[i]))
}

summary_text <- paste0(summary_text,
  "\n================================================================================\n",
  "LIMITATIONS\n",
  "================================================================================\n",
  "1. Moderate predictive performance (AUC < 0.7)\n",
  "2. Missing important clinical variables (lab results, vital signs)\n",
  "3. Data from 1999-2008 may not reflect current practices\n",
  "4. High missing data in medical_specialty (49.53%)\n",
  "5. CART model may be underfitting (very simple tree)\n\n",
  
  "================================================================================\n",
  "RECOMMENDATIONS\n",
  "================================================================================\n",
  "1. Include additional clinical variables for better predictions\n",
  "2. Consider ensemble methods (Random Forest, Gradient Boosting)\n",
  "3. Collect more recent data if possible\n",
  "4. Use Logistic Regression for detailed risk assessment\n",
  "5. Use CART for simple screening tools\n",
  "6. Validate models on external datasets before clinical use\n\n",
  
  "================================================================================\n",
  "PROJECT COMPLETION STATUS\n",
  "================================================================================\n",
  "✓ Phase 1: Data Loading - COMPLETE\n",
  "✓ Phase 2: Data Cleaning - COMPLETE\n",
  "✓ Phase 3: Exploratory Data Analysis - COMPLETE\n",
  "✓ Phase 4: Logistic Regression - COMPLETE\n",
  "✓ Phase 5: CART - COMPLETE\n",
  "✓ Phase 6: Model Comparison - COMPLETE\n",
  "✓ Phase 7: Results and Reporting - COMPLETE\n\n",
  
  "All outputs saved in 'plots/' directory\n",
  "Ready for R Markdown report generation\n"
)

# Save summary
writeLines(summary_text, "plots/07_final_summary.txt")
cat(summary_text)

cat("\n=== Phase 7 Complete ===\n")
cat("Final summary saved to: plots/07_final_summary.txt\n")
cat("Next: Create master R Markdown report (PROJECT_REPORT.Rmd)\n")

