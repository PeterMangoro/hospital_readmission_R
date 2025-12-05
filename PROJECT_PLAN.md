# Project Plan: Predicting 30-Day Hospital Readmissions

## Overview
This plan outlines the step-by-step approach to complete the Computational Math project on predicting 30-day hospital readmissions using Logistic Regression and CART models.

---

## Phase 1: Data Loading and Initial Exploration (Days 1-2)

### 1.1 Load the Dataset
- Read `hospital_readmissions.csv` into R
- Check dimensions, structure, and data types
- Identify missing values and data quality issues

### 1.2 Initial Exploration
- Generate summary statistics for all variables
- Examine distribution of response variable (`readmitted`)
- Create initial visualizations:
  - Bar chart for readmitted (already completed)
  - Histograms for numerical variables
  - Frequency tables for categorical variables

---

## Phase 2: Data Cleaning and Preprocessing (Days 2-3)

### 2.1 Clean Response Variable
- Remove header row if present in data
- Convert `readmitted` to binary format:
  - 1 = Readmitted within 30 days
  - 0 = Not readmitted within 30 days
- Handle any ">30" or other non-standard values if present

### 2.2 Handle Missing Values
- Identify missing data patterns
- Decide on imputation or exclusion strategy
- Document decisions made

### 2.3 Feature Engineering
- Encode categorical variables (one-hot encoding or label encoding)
- Standardize/normalize numerical variables if needed
- Create derived features if relevant (e.g., medication-to-procedure ratio)

### 2.4 Feature Selection
- Select variables as specified in proposal:
  - **Categorical**: age, medical_specialty, diag_1, change, diabetes_med
  - **Numerical**: time_in_hospital, n_lab_procedures, n_procedures, n_medications
- Consider correlation analysis and feature importance

---

## Phase 3: Exploratory Data Analysis (EDA) (Days 3-4)

### 3.1 Univariate Analysis
- Distribution plots for all selected variables
- Summary statistics tables

### 3.2 Bivariate Analysis
- Relationship between each predictor and readmission
- Visualizations:
  - Boxplots for numerical vs. categorical
  - Grouped bar charts for categorical vs. categorical
  - Correlation matrices

### 3.3 Key Insights
- Document patterns and potential predictors
- Note any data quality concerns

---

## Phase 4: Model Building - Logistic Regression (Days 4-6)

### 4.1 Prepare Data
- Split data into training (70-80%) and testing (20-30%) sets
- Ensure balanced representation of readmitted cases

### 4.2 Build Logistic Regression Model
- Fit model with selected features
- Check assumptions (linearity, multicollinearity)
- Handle categorical variables appropriately

### 4.3 Model Interpretation
- Extract coefficients and odds ratios
- Identify significant predictors
- Interpret practical meaning of results

### 4.4 Model Evaluation
- Make predictions on test set
- Calculate metrics:
  - Accuracy
  - Precision
  - Recall
  - F1-score
  - AUC-ROC
- Create confusion matrix
- Visualize ROC curve

---

## Phase 5: Model Building - CART (Days 6-7)

### 5.1 Build CART Model
- Fit decision tree on same training data
- Tune hyperparameters:
  - Max depth
  - Min samples split
  - Min samples leaf
- Use cross-validation for parameter selection

### 5.2 Model Visualization
- Visualize the decision tree
- Identify important splits and rules

### 5.3 Model Evaluation
- Make predictions on test set
- Calculate same metrics as Logistic Regression:
  - Accuracy, Precision, Recall, F1-score, AUC-ROC
- Create confusion matrix
- Visualize ROC curve

---

## Phase 6: Model Comparison and Analysis (Days 7-8)

### 6.1 Performance Comparison
- Side-by-side comparison of metrics:
  - Accuracy
  - AUC
  - Precision
  - Recall
- Visual comparison: ROC curves on same plot
- Statistical significance tests if appropriate

### 6.2 Interpretability Comparison
- **Logistic Regression**: Odds ratios and coefficients
- **CART**: Decision rules and feature importance
- Discuss trade-offs between models

### 6.3 Identify Best Model
- Choose based on performance and interpretability
- Justify selection with evidence

---

## Phase 7: Results and Reporting (Days 8-9)

### 7.1 Create Visualizations
- Model performance comparison charts
- Feature importance plots
- ROC curves
- Key findings visualizations

### 7.2 Document Findings
- Key predictors of readmission
- Model performance summary
- Limitations and assumptions
- Recommendations

### 7.3 Prepare Final Report/Presentation
- Executive summary
- Methodology section
- Results and interpretation
- Conclusions

---

## Phase 8: Code Organization and Documentation (Day 9-10)

### 8.1 Organize Code
- Separate scripts for each phase
- Clear comments and documentation
- Reproducible workflow

### 8.2 Final Review
- Ensure all proposal requirements are met
- Verify code runs without errors
- Check all visualizations are clear and professional

---

## Recommended File Structure

```
projects/
├── hospital_readmissions.csv
├── 01_data_loading.R          # Load and initial exploration
├── 02_data_cleaning.R          # Data preprocessing
├── 03_eda.R                    # Exploratory data analysis
├── 04_logistic_regression.R    # Logistic Regression model
├── 05_cart.R                   # CART model
├── 06_model_comparison.R       # Compare models
├── 07_results.R                # Final visualizations and summary
├── PROJECT_PLAN.md             # This file
└── README.md                   # Project documentation
```

---

## Key Deliverables Checklist

- [ ] Cleaned dataset with binary response variable
- [ ] EDA report with visualizations
- [ ] Logistic Regression model with interpretation
- [ ] CART model with visualization
- [ ] Model comparison analysis
- [ ] Final report with findings and recommendations
- [ ] All code files organized and documented

---

## Tips for Success

1. **Start Simple**: Begin with basic models before adding complexity
2. **Document Everything**: Note why you made certain decisions
3. **Visualize Often**: Use plots to understand data and communicate results
4. **Validate Models**: Use train/test splits and cross-validation
5. **Interpret Results**: Focus on what models mean, not just metrics

---

## Timeline Summary

| Phase | Duration | Key Activities |
|-------|----------|----------------|
| Phase 1 | Days 1-2 | Data loading and initial exploration |
| Phase 2 | Days 2-3 | Data cleaning and preprocessing |
| Phase 3 | Days 3-4 | Exploratory data analysis |
| Phase 4 | Days 4-6 | Logistic Regression model |
| Phase 5 | Days 6-7 | CART model |
| Phase 6 | Days 7-8 | Model comparison |
| Phase 7 | Days 8-9 | Results and reporting |
| Phase 8 | Days 9-10 | Code organization and final review |

**Total Estimated Time: 9-10 days**

