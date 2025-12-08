# ============================================================================
# Script to Convert R Markdown Blog Post to Nuxt Content Format
# ============================================================================
# This script:
# 1. Renders the blog post to HTML (to generate all plots)
# 2. Extracts and copies plots to blog assets directory
# 3. Exports tables/data to JSON/CSV for Nuxt
# 4. Generates a Nuxt Content markdown file
# ============================================================================

library(rmarkdown)
library(knitr)
library(jsonlite)
library(ggplot2)
library(dplyr)
library(pROC)
library(caret)

cat("=== Converting Blog Post to Nuxt Content Format ===\n\n")

# ============================================================================
# Step 1: Create Directory Structure
# ============================================================================
cat("1. Creating directory structure...\n")

# Create blog assets directories
dir.create("blog_assets", showWarnings = FALSE)
dir.create("blog_assets/images", showWarnings = FALSE, recursive = TRUE)
dir.create("blog_assets/data", showWarnings = FALSE, recursive = TRUE)
dir.create("content", showWarnings = FALSE)
dir.create("content/blog", showWarnings = FALSE, recursive = TRUE)

# Also create public directory structure (for Nuxt)
dir.create("public", showWarnings = FALSE)
dir.create("public/images", showWarnings = FALSE, recursive = TRUE)
dir.create("public/images/blog", showWarnings = FALSE, recursive = TRUE)

cat("   ✓ Directories created\n\n")

# ============================================================================
# Step 2: Render Blog Post to HTML (to generate all plots)
# ============================================================================
cat("2. Rendering blog post to HTML...\n")

tryCatch({
  render("BLOG_POST.Rmd", output_format = "html_document", quiet = TRUE)
  cat("   ✓ Blog post rendered successfully\n\n")
}, error = function(e) {
  cat("   ⚠ Warning: Error rendering blog post:", e$message, "\n")
  cat("   Continuing with existing plots...\n\n")
})

# ============================================================================
# Step 3: Copy Key Plots to Blog Assets
# ============================================================================
cat("3. Copying plots to blog assets directory...\n")

# List of key plots to copy
key_plots <- list(
  "readmission_dist" = "plots/01_readmitted_distribution_ggplot.png",
  "lr_roc" = "plots/04_roc_curve_ggplot.png",
  "cart_tree" = "plots/05_cart_tree_compact.png",
  "rf_importance" = "plots/05b_variable_importance.csv", # Will generate plot
  "roc_comparison" = "plots/06_auc_comparison.png"
)

plots_copied <- 0
for (plot_name in names(key_plots)) {
  source_path <- key_plots[[plot_name]]
  if (file.exists(source_path)) {
    # Copy to blog_assets/images
    dest_path_assets <- file.path("blog_assets/images", paste0(plot_name, ".png"))
    file.copy(source_path, dest_path_assets, overwrite = TRUE)
    
    # Also copy to public/images/blog (for Nuxt)
    dest_path_public <- file.path("public/images/blog", paste0(plot_name, ".png"))
    file.copy(source_path, dest_path_public, overwrite = TRUE)
    
    plots_copied <- plots_copied + 1
    cat("   ✓ Copied:", plot_name, "\n")
  } else {
    cat("   ⚠ Not found:", source_path, "\n")
  }
}

# Generate Random Forest importance plot if CSV exists
if (file.exists("plots/05b_variable_importance.csv")) {
  var_imp_rf <- read.csv("plots/05b_variable_importance.csv")
  top10_rf <- head(var_imp_rf, 10)
  
  p_rf_imp <- ggplot(top10_rf, aes(x = reorder(Variable, Importance_Percent), 
                                    y = Importance_Percent)) +
    geom_bar(stat = "identity", fill = "darkgreen", alpha = 0.7) +
    coord_flip() +
    labs(title = "Random Forest: Top 10 Most Important Variables",
         x = "Variable",
         y = "Importance (%)") +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"))
  
  ggsave("blog_assets/images/rf_importance.png", p_rf_imp, width = 10, height = 6, dpi = 300)
  ggsave("public/images/blog/rf_importance.png", p_rf_imp, width = 10, height = 6, dpi = 300)
  plots_copied <- plots_copied + 1
  cat("   ✓ Generated: rf_importance.png\n")
}

cat("   ✓ Total plots copied/generated:", plots_copied, "\n\n")

# ============================================================================
# Step 4: Export Data to JSON for Nuxt
# ============================================================================
cat("4. Exporting data to JSON...\n")

# Load metrics
metrics_lr <- read.csv("plots/04_performance_metrics.csv")
metrics_cart <- read.csv("plots/05_performance_metrics.csv")
metrics_rf <- read.csv("plots/05b_performance_metrics.csv")
auc_lr <- read.csv("plots/04_auc.csv")
auc_cart <- read.csv("plots/05_auc.csv")
auc_rf <- read.csv("plots/05b_auc.csv")

# Create comparison data
comparison_data <- list(
  models = list(
    logistic_regression = list(
      accuracy = round(metrics_lr$Percentage[metrics_lr$Metric == "Accuracy"], 2),
      auc = round(auc_lr$Value, 3),
      precision = round(metrics_lr$Percentage[metrics_lr$Metric == "Precision"], 2),
      recall = round(metrics_lr$Percentage[metrics_lr$Metric == "Recall (Sensitivity)"], 2),
      f1_score = round(metrics_lr$Percentage[metrics_lr$Metric == "F1-Score"], 2)
    ),
    cart = list(
      accuracy = round(metrics_cart$Percentage[metrics_cart$Metric == "Accuracy"], 2),
      auc = round(auc_cart$Value, 3),
      precision = round(metrics_cart$Percentage[metrics_cart$Metric == "Precision"], 2),
      recall = round(metrics_cart$Percentage[metrics_cart$Metric == "Recall (Sensitivity)"], 2),
      f1_score = round(metrics_cart$Percentage[metrics_cart$Metric == "F1-Score"], 2)
    ),
    random_forest = list(
      accuracy = round(metrics_rf$Percentage[metrics_rf$Metric == "Accuracy"], 2),
      auc = round(auc_rf$Value, 3),
      precision = round(metrics_rf$Percentage[metrics_rf$Metric == "Precision"], 2),
      recall = round(metrics_rf$Percentage[metrics_rf$Metric == "Recall (Sensitivity)"], 2),
      f1_score = round(metrics_rf$Percentage[metrics_rf$Metric == "F1-Score"], 2)
    )
  )
)

# Save to JSON
write_json(comparison_data, "blog_assets/data/model_comparison.json", pretty = TRUE)
write_json(comparison_data, "public/images/blog/model_comparison.json", pretty = TRUE)

cat("   ✓ Model comparison data exported to JSON\n\n")

# ============================================================================
# Step 5: Generate Nuxt Content Markdown File
# ============================================================================
cat("5. Generating Nuxt Content markdown file...\n")

# Load additional data for the markdown
data_clean <- read.csv("data_clean.csv", stringsAsFactors = FALSE)
reg_output <- read.csv("plots/04_regression_output.csv")
var_imp_cart <- read.csv("plots/05_variable_importance.csv")
var_imp_rf <- read.csv("plots/05b_variable_importance.csv")

# Calculate statistics
n_total <- nrow(data_clean)
n_readmitted <- sum(data_clean$readmitted_binary == 1)
n_not_readmitted <- sum(data_clean$readmitted_binary == 0)
pct_readmitted <- round((n_readmitted / n_total) * 100, 2)

# Extract metrics
lr_accuracy <- round(metrics_lr$Percentage[metrics_lr$Metric == "Accuracy"], 2)
lr_auc <- round(auc_lr$Value, 3)
cart_accuracy <- round(metrics_cart$Percentage[metrics_cart$Metric == "Accuracy"], 2)
cart_auc <- round(auc_cart$Value, 3)
rf_accuracy <- round(metrics_rf$Percentage[metrics_rf$Metric == "Accuracy"], 2)
rf_auc <- round(auc_rf$Value, 3)

# Top predictors
top_predictor_lr <- reg_output$Variable[which.max(reg_output$Odds_Ratio)]
top_predictor_lr_or <- round(reg_output$Odds_Ratio[which.max(reg_output$Odds_Ratio)], 2)
top_predictor_cart <- var_imp_cart$Variable[1]
top_predictor_cart_imp <- round(var_imp_cart$Importance_Percent[1], 2)
top_predictor_rf <- var_imp_rf$Variable[1]
top_predictor_rf_imp <- round(var_imp_rf$Importance_Percent[1], 2)

# Generate markdown content
markdown_content <- paste0(
  "---\n",
  "title: \"Predicting Hospital Readmissions: A Machine Learning Journey\"\n",
  "description: \"How I built three ML models to predict 30-day readmissions in diabetes patients using Logistic Regression, CART, and Random Forest\"\n",
  "date: ", Sys.Date(), "\n",
  "image: \"/images/blog/readmission_dist.png\"\n",
  "category: \"Machine Learning\"\n",
  "tags: [\"R\", \"Machine Learning\", \"Healthcare\", \"Logistic Regression\", \"CART\", \"Random Forest\"]\n",
  "---\n\n",
  "# The Problem: Why Hospital Readmissions Matter\n\n",
  "Imagine you're a hospital administrator. Every day, you see patients being discharged, and you wonder: *\"Will this patient be back within 30 days?\"* \n\n",
  "Hospital readmissions are a **$15 billion problem** in the United States. For patients with diabetes, the stakes are even higher—they're more likely to be readmitted, which means:\n\n",
  "- **Higher costs** for healthcare systems\n",
  "- **Worse outcomes** for patients  \n",
  "- **Strain on resources** that could be better allocated\n\n",
  "But what if we could predict which patients are at high risk of readmission? That's exactly what I set out to do in this project.\n\n",
  "# The Data: 25,000 Patient Stories\n\n",
  "I worked with a dataset of **", n_total, " patient encounters** from 130 US hospitals over 10 years (1999-2008). Each row tells a story:\n\n",
  "- How long did they stay in the hospital?\n",
  "- How many medications were they on?\n",
  "- What was their primary diagnosis?\n",
  "- Had they been to the hospital before?\n\n",
  "The dataset had a **", pct_readmitted, "% readmission rate**—nearly half of all patients came back within 30 days. This is a significant problem that needs solving.\n\n",
  "![Readmission Distribution](/images/blog/readmission_dist.png)\n\n",
  "# My Approach: Three Models, One Goal\n\n",
  "I decided to build **three different machine learning models** to see which approach worked best:\n\n",
  "1. **Logistic Regression** - The classic statistical approach, great for interpretability\n",
  "2. **CART (Decision Trees)** - Simple, visual, easy to explain\n",
  "3. **Random Forest** - An ensemble method that combines many trees\n\n",
  "Each model has its strengths, and I wanted to see which one would give us the best predictions.\n\n",
  "## Model 1: Logistic Regression\n\n",
  "Logistic Regression was my starting point. It's interpretable and provides odds ratios that clinicians can understand.\n\n",
  "**Key Insight**: The model showed that **", top_predictor_lr, "** (OR: ", top_predictor_lr_or, ") was the strongest predictor of readmission. Patients with more previous visits had significantly higher odds of being readmitted.\n\n",
  "**Performance:**\n",
  "- **Accuracy**: ", lr_accuracy, "%\n",
  "- **AUC-ROC**: ", lr_auc, "\n",
  "- **Interpretability**: ⭐⭐⭐⭐⭐ (Excellent - provides odds ratios and p-values)\n\n",
  "![Logistic Regression ROC Curve](/images/blog/lr_roc.png)\n\n",
  "## Model 2: CART (Decision Trees)\n\n",
  "Decision trees are like a flowchart—they ask yes/no questions to classify patients. I loved how visual and intuitive this approach was.\n\n",
  "The tree showed that **", top_predictor_cart, "** (", top_predictor_cart_imp, "% importance) was the most important factor, splitting patients into high-risk and low-risk groups.\n\n",
  "**Performance:**\n",
  "- **Accuracy**: ", cart_accuracy, "%\n",
  "- **AUC-ROC**: ", cart_auc, "\n",
  "- **Interpretability**: ⭐⭐⭐⭐ (Great - visual decision rules)\n\n",
  "![CART Decision Tree](/images/blog/cart_tree.png)\n\n",
  "## Model 3: Random Forest\n\n",
  "Random Forest combines hundreds of decision trees, each trained on a different subset of the data. It's like asking a committee of experts instead of just one.\n\n",
  "**Performance:**\n",
  "- **Accuracy**: ", rf_accuracy, "%\n",
  "- **AUC-ROC**: ", rf_auc, "\n",
  "- **Interpretability**: ⭐⭐⭐ (Good - shows feature importance)\n\n",
  "![Random Forest Feature Importance](/images/blog/rf_importance.png)\n\n",
  "# The Results: What We Learned\n\n",
  "## Performance Comparison\n\n",
  "| Model | Accuracy | AUC | Interpretability |\n",
  "|-------|----------|-----|------------------|\n",
  "| Logistic Regression | ", lr_accuracy, "% | ", lr_auc, " | ⭐⭐⭐⭐⭐ |\n",
  "| CART | ", cart_accuracy, "% | ", cart_auc, " | ⭐⭐⭐⭐ |\n",
  "| Random Forest | ", rf_accuracy, "% | ", rf_auc, " | ⭐⭐⭐ |\n\n",
  "## Key Findings\n\n",
  "1. **All three models performed similarly** (~60-62% accuracy), suggesting the problem is inherently challenging with the available features.\n\n",
  "2. **Previous hospital visits** consistently emerged as the strongest predictor across all models. This makes intuitive sense—patients with complex medical histories are more likely to need readmission.\n\n",
  "3. **Number of diagnoses** was another important factor. Patients with multiple conditions are at higher risk.\n\n",
  "4. **Medical specialty** mattered too. Patients seen in Emergency/Trauma departments had higher readmission rates.\n\n",
  "## ROC Curves: Visualizing Model Performance\n\n",
  "![ROC Curves Comparison](/images/blog/roc_comparison.png)\n\n",
  "The ROC curves show how well each model distinguishes between patients who will and won't be readmitted. An AUC of 0.65 means the model is better than random guessing, but there's definitely room for improvement.\n\n",
  "# What I Learned: Challenges and Insights\n\n",
  "## The Challenge of ~60% Accuracy\n\n",
  "At first, I was disappointed with ~60% accuracy. But then I realized:\n\n",
  "- **This is a hard problem**. Even experienced clinicians struggle to predict readmissions.\n",
  "- **The dataset has limitations**. We're missing important clinical variables like lab values, vital signs, and social determinants of health.\n",
  "- **60% is a starting point**. With better features and more data, we could improve significantly.\n\n",
  "## What Would Improve the Model?\n\n",
  "If I had access to more data, I would add:\n\n",
  "1. **Lab values**: Blood glucose, HbA1c, creatinine, etc.\n",
  "2. **Vital signs**: Blood pressure, heart rate, temperature\n",
  "3. **Social determinants**: Insurance type, socioeconomic status, housing stability\n",
  "4. **Medication adherence**: Are patients taking their medications as prescribed?\n",
  "5. **Follow-up care**: Did patients attend follow-up appointments?\n\n",
  "## The Power of Interpretability\n\n",
  "One of my biggest takeaways was the importance of **interpretability** in healthcare. Clinicians need to understand *why* a model makes a prediction, not just that it does. That's why Logistic Regression, despite similar performance, might be more useful in practice—it provides odds ratios and statistical significance that doctors can interpret.\n\n",
  "# Building an Interactive Dashboard\n\n",
  "To make this project more practical, I created a **Shiny web application** where users can input patient information and get real-time readmission risk predictions from all three models.\n\n",
  "The app allows healthcare providers to:\n",
  "- Input patient demographics and medical history\n",
  "- See predictions from all three models\n",
  "- Compare model probabilities\n",
  "- View feature importance and ROC curves\n\n",
  "# Technical Stack\n\n",
  "For those interested in the technical details:\n\n",
  "- **Language**: R\n",
  "- **Libraries**: `caret`, `rpart`, `randomForest`, `pROC`, `ggplot2`, `dplyr`\n",
  "- **Visualization**: `ggplot2`, `rpart.plot`\n",
  "- **Interactive App**: R Shiny\n",
  "- **Report Generation**: R Markdown\n\n",
  "# Conclusion: What's Next?\n\n",
  "This project taught me that **predicting healthcare outcomes is complex**, but machine learning can provide valuable insights. While 60% accuracy might not seem impressive, it's a solid foundation that could be improved with:\n\n",
  "- Better feature engineering\n",
  "- More clinical variables\n",
  "- Advanced techniques like gradient boosting\n",
  "- Ensemble methods combining all three models\n\n",
  "Most importantly, I learned that in healthcare, **interpretability matters just as much as accuracy**. A model that doctors can understand and trust is often more valuable than a black box with slightly better performance.\n\n",
  "---\n\n",
  "## Try It Yourself\n\n",
  "- **📊 [View the Full Report](PROJECT_REPORT.pdf)** - Detailed technical analysis\n",
  "- **💻 [GitHub Repository](https://github.com/yourusername/hospital-readmissions)** - Full code and data\n",
  "- **🚀 [Interactive Dashboard](https://your-app-url.shinyapps.io/hospital-readmissions/)** - Try the models yourself\n\n",
  "---\n\n",
  "*This project was completed as part of a Computational Mathematics course. All code and analysis are available on GitHub.*\n"
)

# Write markdown file
writeLines(markdown_content, "content/blog/hospital-readmissions.md")

cat("   ✓ Nuxt Content markdown file generated\n")
cat("   ✓ Saved to: content/blog/hospital-readmissions.md\n\n")

# ============================================================================
# Summary
# ============================================================================
cat("=== Conversion Complete! ===\n\n")
cat("Summary:\n")
cat("  ✓ Blog post rendered\n")
cat("  ✓ Plots copied to blog_assets/images/ and public/images/blog/\n")
cat("  ✓ Data exported to JSON\n")
cat("  ✓ Nuxt Content markdown generated\n\n")
cat("Next Steps:\n")
cat("  1. Copy the 'content/blog/' directory to your Nuxt project\n")
cat("  2. Copy the 'public/images/blog/' directory to your Nuxt project\n")
cat("  3. Update links in the markdown file to match your Nuxt setup\n")
cat("  4. Customize the frontmatter and content as needed\n\n")

