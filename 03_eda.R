# ==============================================================================
# Phase 3: Exploratory Data Analysis (EDA)
# Project: Predicting 30-Day Hospital Readmissions
# ==============================================================================

# Load required libraries
library(ggplot2)
library(dplyr)
library(tidyr)
library(gridExtra)

# Try to load corrplot, install if not available
if(!require(corrplot, quietly = TRUE)) {
  install.packages("corrplot", repos = "https://cran.r-project.org")
  library(corrplot)
}

# Set working directory (adjust if needed)
# setwd("/home/themad/Documents/yeshiva/computationalMaths/projects")

# ==============================================================================
# Load Cleaned Data
# ==============================================================================

cat("=== Phase 3: Exploratory Data Analysis ===\n\n")

cat("Loading cleaned datasets...\n")
load("data_clean.RData")
cat("Loaded: data_clean.RData\n")
cat("Dataset: ", nrow(data_clean), " observations, ", ncol(data_clean), " variables\n\n")

# ==============================================================================
# 3.1 Univariate Analysis
# ==============================================================================

cat("=== 3.1 Univariate Analysis ===\n\n")

# Selected variables from proposal
selected_categorical <- c("age", "medical_specialty", "diag_1", "change", "diabetes_med", 
                          "glucose_test", "A1Ctest")
selected_numerical <- c("time_in_hospital", "n_lab_procedures", "n_procedures", "n_medications")

# Create output directory for plots
if(!dir.exists("plots")) {
  dir.create("plots")
}

# 3.1.1 Summary Statistics for Numerical Variables
cat("--- Summary Statistics: Numerical Variables ---\n\n")

numerical_summary <- data_clean %>%
  select(all_of(selected_numerical)) %>%
  summary()

print(numerical_summary)

# Save summary table
write.csv(numerical_summary, "plots/03_numerical_summary.csv", row.names = TRUE)

# 3.1.2 Frequency Tables for Categorical Variables
cat("\n--- Frequency Tables: Categorical Variables ---\n\n")

for(var in selected_categorical) {
  cat(sprintf("\n%s:\n", var))
  freq_table <- table(data_clean[[var]])
  print(freq_table)
  print(prop.table(freq_table))
}

# ==============================================================================
# 3.2 Bivariate Analysis: Predictors vs. Readmission
# ==============================================================================

cat("\n=== 3.2 Bivariate Analysis: Predictors vs. Readmission ===\n\n")

# 3.2.1 Summary Statistics by Readmission Status
cat("--- Summary Statistics by Readmission Status ---\n\n")

# Numerical variables by readmission status
cat("Numerical Variables - Comparison by Readmission Status:\n\n")

comparison_stats <- data_clean %>%
  group_by(readmitted_binary) %>%
  summarise(
    across(all_of(selected_numerical), 
           list(mean = mean, median = median, sd = sd, min = min, max = max),
           .names = "{.col}_{.fn}")
  )

print(comparison_stats)

# Create formatted comparison table
comparison_table <- data_clean %>%
  group_by(readmitted = ifelse(readmitted_binary == 1, "Readmitted", "Not Readmitted")) %>%
  summarise(
    time_in_hospital_mean = round(mean(time_in_hospital), 2),
    time_in_hospital_sd = round(sd(time_in_hospital), 2),
    n_lab_procedures_mean = round(mean(n_lab_procedures), 2),
    n_lab_procedures_sd = round(sd(n_lab_procedures), 2),
    n_procedures_mean = round(mean(n_procedures), 2),
    n_procedures_sd = round(sd(n_procedures), 2),
    n_medications_mean = round(mean(n_medications), 2),
    n_medications_sd = round(sd(n_medications), 2)
  )

print(comparison_table)
write.csv(comparison_table, "plots/03_comparison_by_readmission.csv", row.names = FALSE)

# 3.2.2 Categorical Variables by Readmission Status
cat("\n--- Categorical Variables - Frequency by Readmission Status ---\n\n")

for(var in selected_categorical) {
  cat(sprintf("\n%s by Readmission Status:\n", var))
  crosstab <- table(data_clean[[var]], data_clean$readmitted_binary)
  colnames(crosstab) <- c("Not Readmitted", "Readmitted")
  print(crosstab)
  
  # Proportions
  prop_crosstab <- prop.table(crosstab, margin = 1)  # Row proportions
  print("Row Proportions:")
  print(round(prop_crosstab, 3))
  
  # Save crosstab
  write.csv(crosstab, sprintf("plots/03_crosstab_%s.csv", var), row.names = TRUE)
}

# ==============================================================================
# 3.3 Visualizations
# ==============================================================================

cat("\n=== 3.3 Creating Visualizations ===\n\n")

# 3.3.1 Boxplots: Numerical Variables by Readmission Status
cat("1. Creating boxplots for numerical variables...\n")

for(var in selected_numerical) {
  p <- ggplot(data_clean, aes(x = factor(readmitted_binary, 
                                         labels = c("Not Readmitted", "Readmitted")),
                              y = .data[[var]],
                              fill = factor(readmitted_binary))) +
    geom_boxplot(alpha = 0.7) +
    scale_fill_manual(values = c("lightcoral", "lightblue"),
                     guide = "none") +
    labs(title = sprintf("Distribution of %s by Readmission Status", var),
         x = "Readmission Status",
         y = var) +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5, size = 12, face = "bold"))
  
  ggsave(sprintf("plots/03_boxplot_%s.png", var), p, width = 8, height = 6, dpi = 300)
}

# Combined boxplot
cat("   Creating combined boxplot...\n")
data_long_numerical <- data_clean %>%
  select(all_of(selected_numerical), readmitted_binary) %>%
  pivot_longer(cols = all_of(selected_numerical),
               names_to = "variable",
               values_to = "value")

p_combined <- ggplot(data_long_numerical, 
                    aes(x = factor(readmitted_binary, 
                                  labels = c("Not Readmitted", "Readmitted")),
                       y = value,
                       fill = factor(readmitted_binary))) +
  geom_boxplot(alpha = 0.7) +
  facet_wrap(~ variable, scales = "free_y", ncol = 2) +
  scale_fill_manual(values = c("lightcoral", "lightblue"),
                   guide = "none") +
  labs(title = "Distribution of Numerical Variables by Readmission Status",
       x = "Readmission Status",
       y = "Value") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
        strip.text = element_text(size = 10))

ggsave("plots/03_boxplots_combined.png", p_combined, width = 12, height = 10, dpi = 300)

# 3.3.2 Grouped Bar Charts: Categorical Variables by Readmission Status
cat("2. Creating grouped bar charts for categorical variables...\n")

for(var in selected_categorical) {
  # Count data
  plot_data <- data_clean %>%
    group_by(.data[[var]], readmitted = ifelse(readmitted_binary == 1, "Readmitted", "Not Readmitted")) %>%
    summarise(count = n(), .groups = "drop")
  
  p <- ggplot(plot_data, aes(x = .data[[var]], y = count, fill = readmitted)) +
    geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
    scale_fill_manual(values = c("Not Readmitted" = "lightcoral", 
                                 "Readmitted" = "lightblue")) +
    labs(title = sprintf("%s by Readmission Status", var),
         x = var,
         y = "Count",
         fill = "Readmission Status") +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5, size = 12, face = "bold"),
          axis.text.x = element_text(angle = 45, hjust = 1))
  
  ggsave(sprintf("plots/03_bar_%s.png", var), p, width = 10, height = 6, dpi = 300)
}

# 3.3.3 Stacked Bar Charts (Proportions)
cat("3. Creating stacked bar charts (proportions)...\n")

for(var in selected_categorical) {
  plot_data <- data_clean %>%
    group_by(.data[[var]], readmitted = ifelse(readmitted_binary == 1, "Readmitted", "Not Readmitted")) %>%
    summarise(count = n(), .groups = "drop") %>%
    group_by(.data[[var]]) %>%
    mutate(proportion = count / sum(count))
  
  p <- ggplot(plot_data, aes(x = .data[[var]], y = proportion, fill = readmitted)) +
    geom_bar(stat = "identity", alpha = 0.8) +
    scale_fill_manual(values = c("Not Readmitted" = "lightcoral", 
                                 "Readmitted" = "lightblue")) +
    scale_y_continuous(labels = scales::percent) +
    labs(title = sprintf("Readmission Rate by %s", var),
         x = var,
         y = "Proportion",
         fill = "Readmission Status") +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5, size = 12, face = "bold"),
          axis.text.x = element_text(angle = 45, hjust = 1))
  
  ggsave(sprintf("plots/03_stacked_%s.png", var), p, width = 10, height = 6, dpi = 300)
}

# 3.3.4 Correlation Matrix (Numerical Variables)
cat("4. Creating correlation matrix...\n")

# Calculate correlation matrix
cor_matrix <- cor(data_clean[, selected_numerical], use = "complete.obs")

# Save correlation matrix
write.csv(cor_matrix, "plots/03_correlation_matrix.csv", row.names = TRUE)

# Create correlation plot
png("plots/03_correlation_heatmap.png", width = 800, height = 800)
corrplot(cor_matrix, method = "color", type = "upper", 
         order = "hclust", tl.cex = 0.8, tl.col = "black",
         addCoef.col = "black", number.cex = 0.7)
dev.off()

# ggplot version
cor_df <- as.data.frame(cor_matrix)
cor_df$var1 <- rownames(cor_df)
cor_df_long <- cor_df %>%
  pivot_longer(cols = -var1, names_to = "var2", values_to = "correlation")

p_corr <- ggplot(cor_df_long, aes(x = var1, y = var2, fill = correlation)) +
  geom_tile(color = "white") +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                       midpoint = 0, limit = c(-1,1), space = "Lab",
                       name = "Correlation") +
  geom_text(aes(label = round(correlation, 2)), color = "black", size = 3) +
  labs(title = "Correlation Matrix: Numerical Variables",
       x = "", y = "") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
        axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("plots/03_correlation_heatmap_ggplot.png", p_corr, width = 8, height = 8, dpi = 300)

# 3.3.5 Readmission Rate by Category
cat("5. Creating readmission rate comparison charts...\n")

# Calculate readmission rates for each categorical variable
readmission_rates <- list()

for(var in selected_categorical) {
  rates <- data_clean %>%
    group_by(.data[[var]]) %>%
    summarise(
      total = n(),
      readmitted = sum(readmitted_binary),
      readmission_rate = round(mean(readmitted_binary) * 100, 2)
    ) %>%
    arrange(desc(readmission_rate))
  
  readmission_rates[[var]] <- rates
  
  # Create bar chart of readmission rates
  p <- ggplot(rates, aes(x = reorder(.data[[var]], readmission_rate), 
                        y = readmission_rate)) +
    geom_bar(stat = "identity", fill = "steelblue", alpha = 0.7) +
    geom_text(aes(label = paste0(readmission_rate, "%")), 
              hjust = -0.1, size = 3) +
    coord_flip() +
    labs(title = sprintf("Readmission Rate by %s", var),
         x = var,
         y = "Readmission Rate (%)") +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5, size = 12, face = "bold"))
  
  ggsave(sprintf("plots/03_readmission_rate_%s.png", var), p, width = 10, height = 6, dpi = 300)
  
  # Save rates table
  write.csv(rates, sprintf("plots/03_readmission_rates_%s.csv", var), row.names = FALSE)
}

# ==============================================================================
# 3.4 Key Insights and Patterns
# ==============================================================================

cat("\n=== 3.4 Key Insights and Patterns ===\n\n")

# 3.4.1 Statistical Tests for Differences
cat("--- Statistical Tests: Readmitted vs. Not Readmitted ---\n\n")

# T-tests for numerical variables
cat("T-tests for numerical variables:\n")
test_results <- list()

for(var in selected_numerical) {
  readmitted_group <- data_clean[data_clean$readmitted_binary == 1, var]
  not_readmitted_group <- data_clean[data_clean$readmitted_binary == 0, var]
  
  test_result <- t.test(readmitted_group, not_readmitted_group)
  test_results[[var]] <- test_result
  
  cat(sprintf("\n%s:\n", var))
  cat(sprintf("  Mean (Readmitted): %.2f\n", mean(readmitted_group)))
  cat(sprintf("  Mean (Not Readmitted): %.2f\n", mean(not_readmitted_group)))
  cat(sprintf("  Difference: %.2f\n", mean(readmitted_group) - mean(not_readmitted_group)))
  cat(sprintf("  T-statistic: %.3f\n", test_result$statistic))
  cat(sprintf("  P-value: %.4f\n", test_result$p.value))
  cat(sprintf("  95%% CI: [%.3f, %.3f]\n", test_result$conf.int[1], test_result$conf.int[2]))
  
  if(test_result$p.value < 0.05) {
    cat("  ✓ Significant difference (p < 0.05)\n")
  } else {
    cat("  ✗ No significant difference (p >= 0.05)\n")
  }
}

# Chi-square tests for categorical variables
cat("\n\nChi-square tests for categorical variables:\n")
chi_results <- list()

for(var in selected_categorical) {
  crosstab <- table(data_clean[[var]], data_clean$readmitted_binary)
  test_result <- chisq.test(crosstab)
  chi_results[[var]] <- test_result
  
  cat(sprintf("\n%s:\n", var))
  cat(sprintf("  Chi-square statistic: %.3f\n", test_result$statistic))
  cat(sprintf("  P-value: %.4f\n", test_result$p.value))
  cat(sprintf("  Degrees of freedom: %d\n", test_result$parameter))
  
  if(test_result$p.value < 0.05) {
    cat("  ✓ Significant association (p < 0.05)\n")
  } else {
    cat("  ✗ No significant association (p >= 0.05)\n")
  }
}

# 3.4.2 Summary of Key Findings
cat("\n\n=== Summary of Key Findings ===\n\n")

cat("1. Overall Readmission Rate: ", 
    round(mean(data_clean$readmitted_binary) * 100, 2), "%\n\n")

cat("2. Numerical Variables - Mean Differences:\n")
for(var in selected_numerical) {
  readmitted_mean <- mean(data_clean[data_clean$readmitted_binary == 1, var])
  not_readmitted_mean <- mean(data_clean[data_clean$readmitted_binary == 0, var])
  diff <- readmitted_mean - not_readmitted_mean
  cat(sprintf("   %s: Readmitted (%.2f) vs. Not Readmitted (%.2f), Difference: %.2f\n",
              var, readmitted_mean, not_readmitted_mean, diff))
}

cat("\n3. Categorical Variables - Readmission Rates:\n")
for(var in selected_categorical) {
  rates <- data_clean %>%
    group_by(.data[[var]]) %>%
    summarise(rate = round(mean(readmitted_binary) * 100, 2)) %>%
    arrange(desc(rate))
  
  cat(sprintf("\n   %s:\n", var))
  cat(sprintf("      Highest rate: %s (%.2f%%)\n", 
              rates[[var]][1], rates$rate[1]))
  cat(sprintf("      Lowest rate: %s (%.2f%%)\n", 
              rates[[var]][nrow(rates)], rates$rate[nrow(rates)]))
}

# ==============================================================================
# Save Summary Report
# ==============================================================================

cat("\n=== Phase 3 Complete ===\n")
cat("All outputs saved to 'plots/' directory\n")
cat("Next steps: Proceed to Phase 4 (Logistic Regression Model)\n")

# Create summary document
summary_text <- paste0(
  "Phase 3: Exploratory Data Analysis Summary\n",
  "==========================================\n\n",
  "Dataset: ", nrow(data_clean), " observations\n",
  "Readmission Rate: ", round(mean(data_clean$readmitted_binary) * 100, 2), "%\n\n",
  "Visualizations Created:\n",
  "- Boxplots for numerical variables\n",
  "- Grouped and stacked bar charts for categorical variables\n",
  "- Correlation heatmap\n",
  "- Readmission rate comparisons\n\n",
  "Statistical Tests:\n",
  "- T-tests for numerical variables\n",
  "- Chi-square tests for categorical variables\n\n",
  "All outputs saved in 'plots/' directory\n"
)

cat(summary_text)
writeLines(summary_text, "plots/03_EDA_summary.txt")

