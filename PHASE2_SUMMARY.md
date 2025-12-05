# Phase 2: Data Cleaning and Preprocessing - Summary

## ✅ Completion Status: COMPLETE

Date: Phase 2 completed successfully

---

## Results Summary

### Dataset Statistics
- **Original dataset**: 25,000 observations, 17 variables
- **Cleaned dataset**: 24,996 observations (99.98% retention)
- **Rows dropped**: 4 (0.02%) - missing primary diagnosis (`diag_1`)

### Response Variable
- **Binary conversion**: Successfully converted to 0/1 format
  - 1 = Readmitted (47.02%)
  - 0 = Not Readmitted (52.98%)
- **Distribution maintained**: No significant change after cleaning

---

## Missing Data Handling

| Variable | Missing % | Strategy | Result |
|----------|-----------|----------|--------|
| `diag_1` | 0.02% (4 cases) | **Dropped rows** | Removed 4 rows |
| `medical_specialty` | 49.53% | **Kept as category** | "Missing" is valid category |
| `diag_2` | 0.17% | **Kept as category** | "Missing" is valid category |
| `diag_3` | 0.78% | **Kept as category** | "Missing" is valid category |

**Rationale:**
- Primary diagnosis is critical - cannot impute reliably
- Medical specialty missing rate too high (49.53%) - represents meaningful group
- Secondary/tertiary diagnoses less critical - preserve data

---

## Feature Engineering

### Created Features:
1. **`n_diagnoses`**: Count of non-missing diagnoses (1-3)
   - Distribution: 1 (21 cases), 2 (196 cases), 3 (24,779 cases)

2. **`medications_per_day`**: Medication intensity metric
   - Formula: `n_medications / time_in_hospital`
   - Range: 0.14 - 40.0 medications/day
   - Mean: 5.13 medications/day

3. **`total_previous_visits`**: Combined visit history
   - Formula: `n_outpatient + n_inpatient + n_emergency`
   - Range: 0 - 68 visits
   - Mean: 1.17 visits

---

## Feature Selection

### Selected Variables (Per Proposal):

**Categorical (5):**
- `age` - Age group (6 categories)
- `medical_specialty` - Medical specialty (7 categories including "Missing")
- `diag_1` - Primary diagnosis (8 categories)
- `change` - Medication change (yes/no)
- `diabetes_med` - Diabetes medication (yes/no)

**Numerical (4):**
- `time_in_hospital` - Length of stay (days)
- `n_lab_procedures` - Number of lab tests
- `n_procedures` - Number of procedures
- `n_medications` - Number of medications

**Additional Variables (Available for Testing):**
- Visit history: `n_outpatient`, `n_inpatient`, `n_emergency`
- Derived features: `n_diagnoses`, `medications_per_day`, `total_previous_visits`

---

## Encoding Strategy

### For Logistic Regression:
- **Response**: Binary numeric (0/1)
- **Categorical variables**: Dummy/one-hot encoding
  - Age: 6 categories → 6 dummy variables
  - Medical specialty: 7 categories → 7 dummy variables
  - Primary diagnosis: 8 categories → 8 dummy variables
- **Binary variables**: 0/1 encoding (`change`, `diabetes_med`)
- **Numerical variables**: Original scale (no standardization)

**Final Logistic Regression dataset:**
- Observations: 24,996
- Variables: 33 (including all dummy variables)

### For CART:
- **Response**: Factor with labels ("Not_Readmitted"/"Readmitted")
- **Categorical variables**: Factors (ordered for age)
- **Numerical variables**: Original scale

**Final CART dataset:**
- Observations: 24,996
- Variables: 16

---

## Data Quality Checks

All checks passed ✓:

1. ✅ **Sample Size**: Consistent across all datasets (24,996)
2. ✅ **Response Distribution**: Stable (47.02% readmitted)
3. ✅ **Missing Values**: No NA values in selected variables
4. ✅ **Data Types**: All correct (numeric for Logistic Regression, factors for CART)
5. ✅ **Infinite Values**: None found
6. ✅ **Duplicate Rows**: None found

---

## Saved Outputs

### R Data Files:
1. **`data_clean.RData`** (342 KB)
   - Complete cleaned dataset with all variables
   - Includes original variables + derived features

2. **`data_logistic.RData`** (333 KB)
   - Formatted for Logistic Regression
   - Dummy-encoded categorical variables
   - Ready for model fitting

3. **`data_cart.RData`** (222 KB)
   - Formatted for CART/Decision Trees
   - Factor-encoded categorical variables
   - Ready for model fitting

### CSV File:
4. **`data_clean.csv`** (2.8 MB)
   - Human-readable format
   - For inspection and external use

---

## Key Decisions Made

1. **Minimal Data Loss**: Dropped only 4 rows (0.02%) with missing primary diagnosis
2. **Preserved "Missing" Categories**: Kept as valid categories where appropriate
3. **No Standardization**: Variables kept on original scale for interpretability
4. **Comprehensive Feature Engineering**: Created 3 derived features for testing
5. **Separate Datasets**: Created model-specific datasets for clarity

---

## Next Steps: Phase 3

Proceed to **Exploratory Data Analysis (EDA)**:
- Univariate analysis of all selected variables
- Bivariate analysis: relationships with readmission
- Visualizations and summary statistics
- Identify patterns and potential predictors

---

## Script Location

All cleaning code saved in: `02_data_cleaning.R`

This script can be re-run anytime to reproduce the cleaned datasets.

