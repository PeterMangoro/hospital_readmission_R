---
title: "Predicting Hospital Readmissions: A Machine Learning Journey"
description: "How I built three ML models to predict 30-day readmissions in diabetes patients using Logistic Regression, CART, and Random Forest"
date: 2025-12-07
image: "/images/blog/readmission_dist.png"
category: "Machine Learning"
tags: ["R", "Machine Learning", "Healthcare", "Logistic Regression", "CART", "Random Forest"]
---

# The Problem: Why Hospital Readmissions Matter

Imagine you're a hospital administrator. Every day, you see patients being discharged, and you wonder: *"Will this patient be back within 30 days?"* 

Hospital readmissions are a **$15 billion problem** in the United States. For patients with diabetes, the stakes are even higher—they're more likely to be readmitted, which means:

- **Higher costs** for healthcare systems
- **Worse outcomes** for patients  
- **Strain on resources** that could be better allocated

But what if we could predict which patients are at high risk of readmission? That's exactly what I set out to do in this project.

# The Data: 25,000 Patient Stories

I worked with a dataset of **24996 patient encounters** from 130 US hospitals over 10 years (1999-2008). Each row tells a story:

- How long did they stay in the hospital?
- How many medications were they on?
- What was their primary diagnosis?
- Had they been to the hospital before?

The dataset had a **47.02% readmission rate**—nearly half of all patients came back within 30 days. This is a significant problem that needs solving.

![Readmission Distribution](/images/blog/readmission_dist.png)

# My Approach: Three Models, One Goal

I decided to build **three different machine learning models** to see which approach worked best:

1. **Logistic Regression** - The classic statistical approach, great for interpretability
2. **CART (Decision Trees)** - Simple, visual, easy to explain
3. **Random Forest** - An ensemble method that combines many trees

Each model has its strengths, and I wanted to see which one would give us the best predictions.

## Model 1: Logistic Regression

Logistic Regression was my starting point. It's interpretable and provides odds ratios that clinicians can understand.

**Key Insight**: The model showed that **n_inpatient** (OR: 1.47) was the strongest predictor of readmission. Patients with more previous visits had significantly higher odds of being readmitted.

**Performance:**
- **Accuracy**: 61.84%
- **AUC-ROC**: 0.648
- **Interpretability**: ⭐⭐⭐⭐⭐ (Excellent - provides odds ratios and p-values)

![Logistic Regression ROC Curve](/images/blog/lr_roc.png)

## Model 2: CART (Decision Trees)

Decision trees are like a flowchart—they ask yes/no questions to classify patients. I loved how visual and intuitive this approach was.

The tree showed that **total_previous_visits** (42.32% importance) was the most important factor, splitting patients into high-risk and low-risk groups.

**Performance:**
- **Accuracy**: 60.78%
- **AUC-ROC**: 0.605
- **Interpretability**: ⭐⭐⭐⭐ (Great - visual decision rules)

![CART Decision Tree](/images/blog/cart_tree.png)

## Model 3: Random Forest

Random Forest combines hundreds of decision trees, each trained on a different subset of the data. It's like asking a committee of experts instead of just one.

**Performance:**
- **Accuracy**: 61.46%
- **AUC-ROC**: 0.648
- **Interpretability**: ⭐⭐⭐ (Good - shows feature importance)

![Random Forest Feature Importance](/images/blog/rf_importance.png)

# The Results: What We Learned

## Performance Comparison

| Model | Accuracy | AUC | Interpretability |
|-------|----------|-----|------------------|
| Logistic Regression | 61.84% | 0.648 | ⭐⭐⭐⭐⭐ |
| CART | 60.78% | 0.605 | ⭐⭐⭐⭐ |
| Random Forest | 61.46% | 0.648 | ⭐⭐⭐ |

## Key Findings

1. **All three models performed similarly** (~60-62% accuracy), suggesting the problem is inherently challenging with the available features.

2. **Previous hospital visits** consistently emerged as the strongest predictor across all models. This makes intuitive sense—patients with complex medical histories are more likely to need readmission.

3. **Number of diagnoses** was another important factor. Patients with multiple conditions are at higher risk.

4. **Medical specialty** mattered too. Patients seen in Emergency/Trauma departments had higher readmission rates.

## ROC Curves: Visualizing Model Performance

![ROC Curves Comparison](/images/blog/roc_comparison.png)

The ROC curves show how well each model distinguishes between patients who will and won't be readmitted. An AUC of 0.65 means the model is better than random guessing, but there's definitely room for improvement.

# What I Learned: Challenges and Insights

## The Challenge of ~60% Accuracy

At first, I was disappointed with ~60% accuracy. But then I realized:

- **This is a hard problem**. Even experienced clinicians struggle to predict readmissions.
- **The dataset has limitations**. We're missing important clinical variables like lab values, vital signs, and social determinants of health.
- **60% is a starting point**. With better features and more data, we could improve significantly.

## What Would Improve the Model?

If I had access to more data, I would add:

1. **Lab values**: Blood glucose, HbA1c, creatinine, etc.
2. **Vital signs**: Blood pressure, heart rate, temperature
3. **Social determinants**: Insurance type, socioeconomic status, housing stability
4. **Medication adherence**: Are patients taking their medications as prescribed?
5. **Follow-up care**: Did patients attend follow-up appointments?

## The Power of Interpretability

One of my biggest takeaways was the importance of **interpretability** in healthcare. Clinicians need to understand *why* a model makes a prediction, not just that it does. That's why Logistic Regression, despite similar performance, might be more useful in practice—it provides odds ratios and statistical significance that doctors can interpret.

# Building an Interactive Dashboard

To make this project more practical, I created a **Shiny web application** where users can input patient information and get real-time readmission risk predictions from all three models.

The app allows healthcare providers to:
- Input patient demographics and medical history
- See predictions from all three models
- Compare model probabilities
- View feature importance and ROC curves

# Technical Stack

For those interested in the technical details:

- **Language**: R
- **Libraries**: `caret`, `rpart`, `randomForest`, `pROC`, `ggplot2`, `dplyr`
- **Visualization**: `ggplot2`, `rpart.plot`
- **Interactive App**: R Shiny
- **Report Generation**: R Markdown

# Conclusion: What's Next?

This project taught me that **predicting healthcare outcomes is complex**, but machine learning can provide valuable insights. While 60% accuracy might not seem impressive, it's a solid foundation that could be improved with:

- Better feature engineering
- More clinical variables
- Advanced techniques like gradient boosting
- Ensemble methods combining all three models

Most importantly, I learned that in healthcare, **interpretability matters just as much as accuracy**. A model that doctors can understand and trust is often more valuable than a black box with slightly better performance.

---

## Try It Yourself

- **📊 [View the Full Report](PROJECT_REPORT.pdf)** - Detailed technical analysis
- **💻 [GitHub Repository](https://github.com/yourusername/hospital-readmissions)** - Full code and data
- **🚀 [Interactive Dashboard](https://your-app-url.shinyapps.io/hospital-readmissions/)** - Try the models yourself

---

*This project was completed as part of a Computational Mathematics course. All code and analysis are available on GitHub.*

