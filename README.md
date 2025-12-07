# Predicting 30-Day Hospital Readmissions

A computational math project comparing Logistic Regression, CART, and Random Forest models for predicting 30-day hospital readmissions in diabetes patients.

## Project Overview

This project analyzes patient demographic, diagnostic, and treatment-related features to predict the likelihood of 30-day hospital readmissions. Three statistical modeling approaches are compared: Logistic Regression, Classification and Regression Trees (CART), and Random Forest.

**Research Question**: Can patient demographic, diagnostic, and treatment-related features effectively predict the likelihood of a patient being readmitted to the hospital within 30 days of discharge?

## Dataset

- **Source**: Kaggle - "Diabetes 130-US Hospitals for 10 years"
- **Time Period**: 1999-2008
- **Hospitals**: 130 US hospitals
- **Observations**: 24,996 patient encounters (after cleaning)
- **Readmission Rate**: 47.02%

## Project Structure

```
projects/
├── hospital_readmissions.csv          # Original dataset
├── 01_data_loading.Rmd               # Phase 1: Data loading and initial exploration
├── 02_data_cleaning.Rmd              # Phase 2: Data cleaning and preprocessing
├── 03_eda.Rmd                         # Phase 3: Exploratory data analysis
├── 04_logistic_regression.Rmd        # Phase 4: Logistic Regression model
├── 05_cart.Rmd                        # Phase 5: CART model
├── 05_random_forest.Rmd               # Phase 5b: Random Forest model
├── 06_model_comparison.Rmd           # Phase 6: Model comparison
├── PROJECT_REPORT.Rmd                # Master R Markdown report (comprehensive)
├── PROJECT_PLAN.md                    # Project plan and timeline
├── README.md                          # This file
├── plots/                             # All visualizations and outputs
│   ├── 01_*                           # Phase 1 outputs
│   ├── 02_*                           # Phase 2 outputs
│   ├── 03_*                           # Phase 3 outputs
│   ├── 04_*                           # Phase 4 outputs (Logistic Regression)
│   ├── 05_*                           # Phase 5 outputs (CART)
│   ├── 05b_*                          # Phase 5b outputs (Random Forest)
│   └── 06_*                           # Phase 6 outputs (Model comparison)
├── data_clean.csv                     # Cleaned dataset (CSV format)
├── data_logistic.RData                # Dataset formatted for Logistic Regression
└── data_cart.RData                    # Dataset formatted for CART/Random Forest
```

## How to Run

### Prerequisites

Required R packages:
- `ggplot2` - Data visualization
- `dplyr` - Data manipulation
- `tidyr` - Data tidying
- `pROC` - ROC curve analysis
- `caret` - Model training and evaluation
- `rpart` - CART models
- `rpart.plot` - Tree visualization
- `randomForest` - Random Forest models
- `kableExtra` - Enhanced table formatting
- `knitr` - Dynamic report generation
- `rmarkdown` - R Markdown compilation

Install packages if needed:
```r
install.packages(c("ggplot2", "dplyr", "tidyr", "pROC", "caret", 
                   "rpart", "rpart.plot", "randomForest", "kableExtra",
                   "knitr", "rmarkdown"))
```

### Running the Analysis

**Option 1: Run all phases sequentially (R Markdown files)**
```r
# In R or RStudio, render each R Markdown file in order:
rmarkdown::render("01_data_loading.Rmd")
rmarkdown::render("02_data_cleaning.Rmd")
rmarkdown::render("03_eda.Rmd")
rmarkdown::render("04_logistic_regression.Rmd")
rmarkdown::render("05_cart.Rmd")
rmarkdown::render("05_random_forest.Rmd")
rmarkdown::render("06_model_comparison.Rmd")
```

**Option 2: Generate the comprehensive report directly**
```r
# The PROJECT_REPORT.Rmd loads all saved outputs and generates a complete report:
rmarkdown::render("PROJECT_REPORT.Rmd")
```

**Note**: Each R Markdown file generates its own PDF report and saves outputs (CSV files, plots) to the `plots/` directory. The `PROJECT_REPORT.Rmd` file dynamically loads these outputs to create a comprehensive final report.

### Generating the Final Report

To create PDF/HTML report:
```r
rmarkdown::render("PROJECT_REPORT.Rmd")
```

This will generate:
- `PROJECT_REPORT.pdf` (PDF document)
- `PROJECT_REPORT.html` (HTML document)

**Note**: For PDF generation, you may need `xelatex`. Install with:
```r
tinytex::install_tinytex()
```

## Phase Descriptions

### Phase 1: Data Loading
- Loads the dataset
- Checks structure and data types
- Identifies missing values
- Creates initial visualizations

### Phase 2: Data Cleaning
- Converts response variable to binary format
- Handles missing values
- Feature engineering
- Encodes variables for both models
- Saves cleaned datasets

### Phase 3: Exploratory Data Analysis
- Univariate and bivariate analysis
- Statistical tests (t-tests, chi-square)
- Comprehensive visualizations
- Key insights documentation

### Phase 4: Logistic Regression
- Mathematical formulation and theory
- Model summary and fitted equation
- Regression output with coefficients, p-values, odds ratios, confidence intervals
- Hypothesis testing
- Coefficient and odds ratio interpretation
- R-squared interpretation
- Gradient (rate of change) explanation
- Example calculation
- Model evaluation (confusion matrix, accuracy, precision, recall, F1-score)
- ROC curve analysis

### Phase 5: CART
- Decision tree model building
- Tree pruning and complexity selection
- Tree visualization
- Variable importance analysis
- Model evaluation (confusion matrix, performance metrics)
- ROC curve analysis

### Phase 5b: Random Forest
- Ensemble model with multiple decision trees
- Bootstrap aggregating (bagging)
- Feature randomization
- Variable importance analysis
- Model evaluation (confusion matrix, performance metrics)
- ROC curve analysis

### Phase 6: Model Comparison
- Side-by-side performance comparison (all three models)
- Feature importance comparison across models
- ROC curve comparison
- Interpretability and complexity analysis
- Model selection justification
- Recommended model with rationale

## Key Results

### Model Performance

| Metric | Logistic Regression | CART | Random Forest |
|--------|---------------------|------|---------------|
| Accuracy | ~62% | ~61% | ~62% |
| AUC | ~0.65 | ~0.61 | ~0.64 |
| Precision | ~64% | ~59% | ~63% |
| Recall | ~42% | ~56% | ~45% |
| F1-Score | ~51% | ~58% | ~52% |

*Note: Exact values are dynamically calculated in the report based on the current model fits.*

### Top Predictors

**Logistic Regression:**
- Previous inpatient visits (highest odds ratio)
- Number of diagnoses
- Medical specialty (Emergency/Trauma)
- Age groups (70-80)

**CART:**
- Total previous visits (highest importance)
- Previous inpatient visits
- Number of diagnoses

**Random Forest:**
- Previous visits (inpatient, outpatient, emergency)
- Number of diagnoses
- Medical specialty

### Recommended Model

**Logistic Regression** - Typically achieves the highest AUC and accuracy, with detailed statistical insights including odds ratios, p-values, confidence intervals, and hypothesis testing. Provides the best balance of predictive performance and statistical rigor for clinical decision support.

## Output Files

All outputs are saved in the `plots/` directory:

- **Visualizations**: PNG files for all charts and graphs (distribution plots, boxplots, ROC curves, decision trees)
- **Data Tables**: CSV files with summary statistics, comparison tables, and results
- **Model Outputs**: 
  - Regression tables (coefficients, odds ratios, confidence intervals)
  - Performance metrics (accuracy, precision, recall, F1-score, AUC)
  - Variable importance tables
  - Confusion matrices
- **Comparison Tables**: Side-by-side model comparisons across all three models
- **Model Metadata**: Model parameters and configuration details

## Reproducibility

To ensure reproducibility:
1. Set seed values are used in all R Markdown files (seed = 123)
2. All data cleaning steps are documented with explanations
3. All outputs are saved to CSV files for reference and dynamic loading
4. Code is well-commented with inline explanations
5. All model results are saved and can be reloaded
6. The PROJECT_REPORT.Rmd file is fully dynamic, loading all results from saved files

## Authors

- Masheia Dzimba
- Peter Mangoro

## References

Kaggle. "Diabetes 130-US Hospitals for 10 years." Accessed November 14, 2025. https://www.kaggle.com/datasets/brandao/diabetes

## License

This project is for educational purposes as part of a Computational Math course.

## Key Features

- **Dynamic Reporting**: The `PROJECT_REPORT.Rmd` file dynamically loads all results from CSV files, ensuring the report is always up-to-date
- **Comprehensive Analysis**: Includes mathematical formulations, statistical interpretations, and clinical implications
- **Three Model Comparison**: Compares Logistic Regression, CART, and Random Forest with detailed justification
- **Feature Engineering**: Includes derived features (n_diagnoses, medications_per_day, total_previous_visits)
- **Professional Formatting**: Uses `kableExtra` for publication-quality tables in PDF output
- **Complete Documentation**: Each phase is documented in its own R Markdown file with explanations

## Technical Details

- **PDF Engine**: Uses `xelatex` for better Unicode support and LaTeX compilation
- **Table Formatting**: Tables are split and formatted to fit PDF margins
- **Figure Placement**: Uses LaTeX float controls to ensure figures appear in correct locations
- **Confusion Matrices**: Displayed with clear "Predicted Yes/No" and "Actual Yes/No" labels for easy interpretation

---

**Last Updated**: December 2025

