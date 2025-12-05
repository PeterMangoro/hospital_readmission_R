# Predicting 30-Day Hospital Readmissions

A computational math project comparing Logistic Regression and CART models for predicting 30-day hospital readmissions in diabetes patients.

## Project Overview

This project analyzes patient demographic, diagnostic, and treatment-related features to predict the likelihood of 30-day hospital readmissions. Two statistical modeling approaches are compared: Logistic Regression and Classification and Regression Trees (CART).

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
├── 01_data_loading.R                  # Phase 1: Data loading and initial exploration
├── 02_data_cleaning.R                 # Phase 2: Data cleaning and preprocessing
├── 03_eda.R                           # Phase 3: Exploratory data analysis
├── 04_logistic_regression.R           # Phase 4: Logistic Regression model
├── 05_cart.R                          # Phase 5: CART model
├── 06_model_comparison.R              # Phase 6: Model comparison
├── 07_results.R                       # Phase 7: Results and reporting
├── PROJECT_REPORT.Rmd                 # Master R Markdown report
├── PROJECT_PLAN.md                    # Project plan and timeline
├── README.md                          # This file
├── plots/                             # All visualizations and outputs
│   ├── 01_*                           # Phase 1 outputs
│   ├── 02_*                           # Phase 2 outputs
│   ├── 03_*                           # Phase 3 outputs
│   ├── 04_*                           # Phase 4 outputs
│   ├── 05_*                           # Phase 5 outputs
│   ├── 06_*                           # Phase 6 outputs
│   └── 07_*                           # Phase 7 outputs
├── data_clean.RData                   # Cleaned dataset
├── data_logistic.RData                # Dataset formatted for Logistic Regression
└── data_cart.RData                    # Dataset formatted for CART
```

## How to Run

### Prerequisites

Required R packages:
- `ggplot2`
- `dplyr`
- `tidyr`
- `pROC`
- `caret`
- `rpart`
- `rpart.plot`
- `knitr`
- `rmarkdown`

Install packages if needed:
```r
install.packages(c("ggplot2", "dplyr", "tidyr", "pROC", "caret", 
                   "rpart", "rpart.plot", "knitr", "rmarkdown"))
```

### Running the Analysis

**Option 1: Run all phases sequentially**
```r
# In R or RStudio, run each script in order:
source("01_data_loading.R")
source("02_data_cleaning.R")
source("03_eda.R")
source("04_logistic_regression.R")
source("05_cart.R")
source("06_model_comparison.R")
source("07_results.R")
```

**Option 2: Generate the report directly**
```r
# If all outputs already exist, just render the report:
rmarkdown::render("PROJECT_REPORT.Rmd")
```

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
- Train/test split
- Model fitting
- Regression output with coefficients, p-values, odds ratios
- Hypothesis testing
- R-squared interpretation
- Model evaluation (AUC, accuracy, etc.)

### Phase 5: CART
- Decision tree model
- Tree visualization
- Variable importance
- Model evaluation

### Phase 6: Model Comparison
- Side-by-side performance comparison
- ROC curve comparison
- Interpretability analysis
- Model selection justification

### Phase 7: Results and Reporting
- Final summary
- Comprehensive results documentation

## Key Results

### Model Performance

| Metric | Logistic Regression | CART |
|--------|---------------------|------|
| Accuracy | 61.84% | 60.78% |
| AUC | 0.648 | 0.605 |
| Precision | 64.09% | 58.71% |
| Recall | 42.05% | 55.83% |

### Top Predictors

**Logistic Regression:**
1. Previous inpatient visits (OR: 1.47)
2. Number of diagnoses (OR: 1.33)
3. Cardiology specialty (OR: 1.31)

**CART:**
1. Total previous visits (42.32% importance)
2. Previous inpatient visits (31.86% importance)

### Recommended Model

**Logistic Regression** - Higher AUC and accuracy, with detailed statistical insights including odds ratios, p-values, and confidence intervals.

## Output Files

All outputs are saved in the `plots/` directory:

- **Visualizations**: PNG files for all charts and graphs
- **Data Tables**: CSV files with summary statistics and results
- **Model Outputs**: Regression tables, performance metrics, variable importance
- **Comparison Tables**: Side-by-side model comparisons

## Reproducibility

To ensure reproducibility:
1. Set seed values are used in all scripts (seed = 123)
2. All data cleaning steps are documented
3. All outputs are saved for reference
4. Code is well-commented

## Authors

- Masheia Dzimba
- Peter Mangoro

## References

Kaggle. "Diabetes 130-US Hospitals for 10 years." Accessed November 14, 2025. https://www.kaggle.com/datasets/brandao/diabetes

## License

This project is for educational purposes as part of a Computational Math course.

---

**Last Updated**: November 2024

