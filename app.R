# Shiny App for Hospital Readmission Prediction
# Interactive dashboard for predicting 30-day hospital readmissions

library(shiny)
library(ggplot2)
library(dplyr)
library(pROC)
library(caret)
library(rpart)
library(randomForest)
library(DT)

# Source helper functions
source("app_helpers.R")

# Load models (do this once at startup)
cat("Loading models...\n")
load("model_logistic.RData")
load("model_cart_final.RData")
load("model_rf.RData")
cat("Models loaded successfully!\n")

# Load data to get factor levels for dropdowns
load("data_cart.RData")
factor_levels <- get_factor_levels()

# Load performance metrics for comparison tab
metrics_lr <- read.csv("plots/04_performance_metrics.csv", stringsAsFactors = FALSE)
metrics_cart <- read.csv("plots/05_performance_metrics.csv", stringsAsFactors = FALSE)
metrics_rf <- read.csv("plots/05b_performance_metrics.csv", stringsAsFactors = FALSE)
auc_lr <- read.csv("plots/04_auc.csv")
auc_cart <- read.csv("plots/05_auc.csv")
auc_rf <- read.csv("plots/05b_auc.csv")

# ============================================================================
# UI
# ============================================================================
ui <- fluidPage(
  titlePanel("Predicting 30-Day Hospital Readmissions"),
  tags$head(
    tags$style(HTML("
      .main-header { background-color: #2c3e50; color: white; padding: 20px; }
      .sidebar { background-color: #ecf0f1; }
      .prediction-box { border: 2px solid #3498db; padding: 15px; margin: 10px 0; 
                        border-radius: 5px; background-color: #ebf5fb; }
      .risk-high { color: #e74c3c; font-weight: bold; }
      .risk-moderate { color: #f39c12; font-weight: bold; }
      .risk-low { color: #27ae60; font-weight: bold; }
    "))
  ),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      h3("Patient Information"),
      
      # Numerical inputs
      h4("Hospital Stay"),
      numericInput("time_in_hospital", "Time in Hospital (days)", 
                   value = 3, min = 1, max = 14, step = 1),
      numericInput("n_lab_procedures", "Number of Lab Procedures", 
                   value = 43, min = 0, max = 132, step = 1),
      numericInput("n_procedures", "Number of Procedures", 
                   value = 0, min = 0, max = 6, step = 1),
      numericInput("n_medications", "Number of Medications", 
                   value = 16, min = 1, max = 81, step = 1),
      
      h4("Previous Visits"),
      numericInput("n_outpatient", "Previous Outpatient Visits", 
                   value = 0, min = 0, max = 42, step = 1),
      numericInput("n_inpatient", "Previous Inpatient Visits", 
                   value = 0, min = 0, max = 21, step = 1),
      numericInput("n_emergency", "Previous Emergency Visits", 
                   value = 0, min = 0, max = 76, step = 1),
      
      h4("Diagnoses"),
      numericInput("n_diagnoses", "Number of Diagnoses", 
                   value = 9, min = 1, max = 16, step = 1),
      
      # Categorical inputs
      h4("Demographics & Medical Info"),
      selectInput("age", "Age Group",
                  choices = factor_levels$age,
                  selected = factor_levels$age[3]),
      selectInput("medical_specialty", "Medical Specialty",
                  choices = factor_levels$medical_specialty,
                  selected = "Missing"),
      selectInput("diag_1", "Primary Diagnosis",
                  choices = factor_levels$diag_1,
                  selected = factor_levels$diag_1[1]),
      
      h4("Medications & Tests"),
      selectInput("change", "Change in Medication",
                  choices = factor_levels$change,
                  selected = factor_levels$change[1]),
      selectInput("diabetes_med", "Diabetes Medication",
                  choices = factor_levels$diabetes_med,
                  selected = factor_levels$diabetes_med[1]),
      selectInput("glucose_test", "Glucose Test",
                  choices = factor_levels$glucose_test,
                  selected = factor_levels$glucose_test[1]),
      selectInput("A1Ctest", "A1C Test",
                  choices = factor_levels$A1Ctest,
                  selected = factor_levels$A1Ctest[1]),
      
      br(),
      p("Predictions update automatically as you change inputs.", 
        style = "font-style: italic; color: #7f8c8d;")
    ),
    
    mainPanel(
      width = 9,
      tabsetPanel(
        # ====================================================================
        # Prediction Tab
        # ====================================================================
        tabPanel("Prediction",
                 h2("Readmission Risk Prediction"),
                 
                 # Main prediction display
                 div(class = "prediction-box",
                     h3("Predicted Readmission Probability"),
                     
                     # Average prediction
                     h4(textOutput("avg_prediction"), style = "color: #2c3e50;"),
                     
                     # Risk level
                     h4("Risk Level: ", 
                        span(textOutput("risk_level", inline = TRUE),
                             class = "risk-level")),
                     
                     br(),
                     
                     # Individual model predictions
                     h4("Individual Model Predictions:"),
                     tableOutput("predictions_table"),
                     
                     # Probability bars
                     plotOutput("probability_bars", height = "200px")
                 ),
                 
                 # Interpretation
                 h3("Interpretation"),
                 p("The models predict the probability of a 30-day hospital readmission based on the patient information provided."),
                 tags$ul(
                   tags$li("Low Risk (< 30%): Patient has low likelihood of readmission"),
                   tags$li("Moderate Risk (30-60%): Patient has moderate likelihood of readmission"),
                   tags$li("High Risk (> 60%): Patient has high likelihood of readmission")
                 )
        ),
        
        # ====================================================================
        # Visualizations Tab
        # ====================================================================
        tabPanel("Visualizations",
                 h2("Model Performance Visualizations"),
                 
                 h3("ROC Curves"),
                 p("Receiver Operating Characteristic (ROC) curves show the trade-off between sensitivity and specificity."),
                 plotOutput("roc_curves", height = "500px"),
                 
                 br(),
                 
                 h3("Feature Importance"),
                 
                 h4("Logistic Regression - Top Predictors (Odds Ratios)"),
                 DT::dataTableOutput("lr_importance"),
                 
                 h4("CART - Variable Importance"),
                 plotOutput("cart_importance", height = "400px"),
                 
                 h4("Random Forest - Variable Importance"),
                 plotOutput("rf_importance", height = "400px"),
                 
                 br(),
                 
                 h3("Model Performance Metrics"),
                 DT::dataTableOutput("metrics_table")
        ),
        
        # ====================================================================
        # Model Comparison Tab
        # ====================================================================
        tabPanel("Model Comparison",
                 h2("Model Performance Comparison"),
                 
                 h3("Side-by-Side Performance Metrics"),
                 DT::dataTableOutput("comparison_table"),
                 
                 br(),
                 
                 h3("AUC Comparison"),
                 plotOutput("auc_comparison", height = "400px"),
                 
                 br(),
                 
                 h3("Key Differences"),
                 tags$ul(
                   tags$li(tags$strong("Logistic Regression:"), 
                          "Provides interpretable coefficients, odds ratios, and statistical significance testing. Best for understanding which factors drive readmission risk."),
                   tags$li(tags$strong("CART:"), 
                          "Offers simple decision rules and high interpretability. Best for clinical decision support with clear if-then rules."),
                   tags$li(tags$strong("Random Forest:"), 
                          "Combines multiple trees for robust predictions. Best for maximizing predictive performance while maintaining variable importance insights.")
                 ),
                 
                 h3("Recommended Model"),
                 p("Based on the analysis, ", tags$strong("Logistic Regression"), 
                   " is recommended for clinical use due to its combination of good predictive performance and detailed statistical insights.")
        ),
        
        # ====================================================================
        # About Tab
        # ====================================================================
        tabPanel("About",
                 h2("About This Project"),
                 
                 h3("Project Overview"),
                 p("This application predicts 30-day hospital readmission risk using three machine learning models trained on data from 130 US hospitals (1999-2008)."),
                 
                 h3("Models"),
                 tags$ul(
                   tags$li(tags$strong("Logistic Regression:"), 
                          "A statistical model that provides interpretable coefficients and odds ratios."),
                   tags$li(tags$strong("CART (Classification and Regression Trees):"), 
                          "A decision tree model that creates simple, interpretable rules."),
                   tags$li(tags$strong("Random Forest:"), 
                          "An ensemble method that combines multiple decision trees for improved predictions.")
                 ),
                 
                 h3("Dataset"),
                 p("The models were trained on ", tags$strong("24,996 patient encounters"), 
                   " with a readmission rate of approximately 47%."),
                 
                 h3("Key Predictors"),
                 p("Previous hospital visits, number of diagnoses, medical specialty, and age are among the most important predictors of readmission."),
                 
                 h3("Authors"),
                 p("Masheia Dzimba and Peter Mangoro"),
                 
                 h3("Full Report"),
                 p("For detailed methodology, results, and analysis, please refer to the comprehensive project report (PROJECT_REPORT.pdf)."),
                 
                 h3("Source Code"),
                 p("The complete analysis code and data are available in the project repository.")
        )
      )
    )
  )
)

# ============================================================================
# Server
# ============================================================================
server <- function(input, output, session) {
  
  # Reactive function to collect all inputs
  get_inputs <- reactive({
    list(
      time_in_hospital = input$time_in_hospital,
      n_lab_procedures = input$n_lab_procedures,
      n_procedures = input$n_procedures,
      n_medications = input$n_medications,
      n_outpatient = input$n_outpatient,
      n_inpatient = input$n_inpatient,
      n_emergency = input$n_emergency,
      n_diagnoses = input$n_diagnoses,
      age = input$age,
      medical_specialty = input$medical_specialty,
      diag_1 = input$diag_1,
      change = input$change,
      diabetes_med = input$diabetes_med,
      glucose_test = input$glucose_test,
      A1Ctest = input$A1Ctest
    )
  })
  
  # Reactive function to make predictions
  make_predictions <- reactive({
    inputs <- get_inputs()
    
    tryCatch({
      # Encode inputs for each model
      data_lr <- encode_for_logistic(inputs)
      data_cart <- encode_for_cart(inputs)
      
      # Make predictions
      pred_lr <- predict(model_logistic, newdata = data_lr, type = "response")
      pred_cart <- predict(model_cart_final, newdata = data_cart, type = "prob")[, "Readmitted"]
      pred_rf <- predict(model_rf, newdata = data_cart, type = "prob")[, "Readmitted"]
      
      return(list(
        lr = as.numeric(pred_lr),
        cart = as.numeric(pred_cart),
        rf = as.numeric(pred_rf)
      ))
    }, error = function(e) {
      return(list(
        lr = NA,
        cart = NA,
        rf = NA,
        error = e$message
      ))
    })
  })
  
  # Average prediction (updates automatically when inputs change)
  output$avg_prediction <- renderText({
    # Trigger on any input change
    inputs <- get_inputs()
    preds <- make_predictions()
    if(any(is.na(preds))) {
      return("Error: Unable to make prediction. Please check inputs.")
    }
    avg_prob <- mean(c(preds$lr, preds$cart, preds$rf))
    paste0(round(avg_prob * 100, 2), "%")
  })
  
  # Risk level (updates automatically)
  output$risk_level <- renderText({
    inputs <- get_inputs()  # Trigger reactivity
    preds <- make_predictions()
    if(any(is.na(preds))) {
      return("Error")
    }
    avg_prob <- mean(c(preds$lr, preds$cart, preds$rf))
    
    risk_class <- if(avg_prob < 0.3) {
      "Low Risk"
    } else if(avg_prob < 0.6) {
      "Moderate Risk"
    } else {
      "High Risk"
    }
    
    return(risk_class)
  })
  
  # Add CSS class to risk level
  observe({
    preds <- make_predictions()
    if(!any(is.na(preds))) {
      avg_prob <- mean(c(preds$lr, preds$cart, preds$rf))
      class_name <- if(avg_prob < 0.3) {
        "risk-low"
      } else if(avg_prob < 0.6) {
        "risk-moderate"
      } else {
        "risk-high"
      }
      # Update the class dynamically (this is a simplified version)
    }
  })
  
  # Predictions table (updates automatically)
  output$predictions_table <- renderTable({
    inputs <- get_inputs()  # Trigger reactivity
    preds <- make_predictions()
    if(any(is.na(preds))) {
      return(data.frame(Model = "Error", Probability = "Unable to predict"))
    }
    
    data.frame(
      Model = c("Logistic Regression", "CART", "Random Forest"),
      Probability = paste0(round(c(preds$lr, preds$cart, preds$rf) * 100, 2), "%"),
      stringsAsFactors = FALSE
    )
  }, digits = 2)
  
  # Probability bars (updates automatically)
  output$probability_bars <- renderPlot({
    inputs <- get_inputs()  # Trigger reactivity
    preds <- make_predictions()
    if(any(is.na(preds))) {
      return(NULL)
    }
    
    prob_df <- data.frame(
      Model = c("Logistic\nRegression", "CART", "Random\nForest"),
      Probability = c(preds$lr, preds$cart, preds$rf)
    )
    
    ggplot(prob_df, aes(x = Model, y = Probability, fill = Model)) +
      geom_bar(stat = "identity", alpha = 0.7) +
      scale_fill_manual(values = c("steelblue", "orange", "darkgreen")) +
      scale_y_continuous(labels = scales::percent_format(), limits = c(0, 1)) +
      labs(title = "Readmission Probability by Model",
           y = "Probability",
           x = "") +
      theme_minimal() +
      theme(legend.position = "none",
            plot.title = element_text(hjust = 0.5, face = "bold"))
  })
  
  # ROC Curves - Recreate from test data
  output$roc_curves <- renderPlot({
    tryCatch({
      # Load test data
      load("data_logistic.RData")
      load("data_cart.RData")
      
      # Create train/test split (same as model training)
      set.seed(1)
      train_indices_lr <- createDataPartition(data_logistic$readmitted, p = 0.7, list = FALSE)
      data_test_lr <- data_logistic[-train_indices_lr, ]
      
      train_indices_cart <- createDataPartition(data_cart$readmitted, p = 0.7, list = FALSE)
      data_test_cart <- data_cart[-train_indices_cart, ]
      
      # Make predictions on test data
      # Logistic Regression
      pred_lr <- predict(model_logistic, newdata = data_test_lr, type = "response")
      roc_lr <- roc(data_test_lr$readmitted, pred_lr)
      auc_lr_val <- as.numeric(auc(roc_lr))
      
      # CART
      pred_cart <- predict(model_cart_final, newdata = data_test_cart, type = "prob")[, "Readmitted"]
      actual_cart <- ifelse(data_test_cart$readmitted == "Readmitted", 1, 0)
      roc_cart <- roc(actual_cart, pred_cart)
      auc_cart_val <- as.numeric(auc(roc_cart))
      
      # Random Forest
      pred_rf <- predict(model_rf, newdata = data_test_cart, type = "prob")[, "Readmitted"]
      roc_rf <- roc(actual_cart, pred_rf)
      auc_rf_val <- as.numeric(auc(roc_rf))
      
      # Create combined ROC data
      roc_data <- rbind(
        data.frame(
          FPR = 1 - roc_lr$specificities,
          TPR = roc_lr$sensitivities,
          Model = "Logistic Regression",
          AUC = auc_lr_val
        ),
        data.frame(
          FPR = 1 - roc_cart$specificities,
          TPR = roc_cart$sensitivities,
          Model = "CART",
          AUC = auc_cart_val
        ),
        data.frame(
          FPR = 1 - roc_rf$specificities,
          TPR = roc_rf$sensitivities,
          Model = "Random Forest",
          AUC = auc_rf_val
        )
      )
      
      # Create plot
      p <- ggplot(roc_data, aes(x = FPR, y = TPR, color = Model)) +
        geom_line(linewidth = 1.2, alpha = 0.8) +
        geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray", linewidth = 1) +
        scale_color_manual(values = c("Logistic Regression" = "steelblue",
                                      "CART" = "orange",
                                      "Random Forest" = "darkgreen")) +
        labs(title = "ROC Curves: Model Comparison",
             subtitle = paste0("AUC: LR = ", round(auc_lr_val, 3), 
                              ", CART = ", round(auc_cart_val, 3),
                              ", RF = ", round(auc_rf_val, 3)),
             x = "False Positive Rate (1 - Specificity)",
             y = "True Positive Rate (Sensitivity)",
             color = "Model") +
        theme_minimal() +
        theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
              plot.subtitle = element_text(hjust = 0.5, size = 12),
              legend.position = "right")
      
      return(p)
    }, error = function(e) {
      # Fallback: try to load saved images
      if(file.exists("plots/04_roc_curve_ggplot.png") && 
         file.exists("plots/05_roc_curve_ggplot.png")) {
        # Could display saved images, but for now return error message
        return(ggplot() + 
               annotate("text", x = 0.5, y = 0.5, 
                       label = paste("Error loading ROC curves:", e$message),
                       size = 4) +
               theme_void())
      }
      return(NULL)
    })
  })
  
  # Feature importance tables and plots
  output$lr_importance <- DT::renderDataTable({
    # Load logistic regression output
    tryCatch({
      reg_output <- read.csv("plots/04_regression_output.csv", stringsAsFactors = FALSE)
      sig_vars <- reg_output[reg_output$P_Value < 0.05, ]
      top_vars <- head(sig_vars[order(-sig_vars$Odds_Ratio), ], 10)
      DT::datatable(top_vars[, c("Variable", "Coefficient", "Odds_Ratio", "P_Value")],
                    options = list(pageLength = 10))
    }, error = function(e) {
      return(data.frame(Error = "Unable to load data"))
    })
  })
  
  output$cart_importance <- renderPlot({
    tryCatch({
      var_imp <- read.csv("plots/05_variable_importance.csv", stringsAsFactors = FALSE)
      top10 <- head(var_imp, 10)
      
      ggplot(top10, aes(x = reorder(Variable, Importance_Percent), 
                       y = Importance_Percent)) +
        geom_bar(stat = "identity", fill = "steelblue", alpha = 0.7) +
        coord_flip() +
        labs(title = "CART: Top 10 Most Important Variables",
             x = "Variable",
             y = "Importance (%)") +
        theme_minimal()
    }, error = function(e) {
      return(NULL)
    })
  })
  
  output$rf_importance <- renderPlot({
    tryCatch({
      var_imp <- read.csv("plots/05b_variable_importance.csv", stringsAsFactors = FALSE)
      top10 <- head(var_imp, 10)
      
      ggplot(top10, aes(x = reorder(Variable, Importance_Percent), 
                       y = Importance_Percent)) +
        geom_bar(stat = "identity", fill = "darkgreen", alpha = 0.7) +
        coord_flip() +
        labs(title = "Random Forest: Top 10 Most Important Variables",
             x = "Variable",
             y = "Importance (%)") +
        theme_minimal()
    }, error = function(e) {
      return(NULL)
    })
  })
  
  # Metrics table
  output$metrics_table <- DT::renderDataTable({
    all_metrics <- rbind(
      cbind(Model = "Logistic Regression", metrics_lr),
      cbind(Model = "CART", metrics_cart),
      cbind(Model = "Random Forest", metrics_rf)
    )
    DT::datatable(all_metrics, options = list(pageLength = 15))
  })
  
  # Comparison table
  output$comparison_table <- DT::renderDataTable({
    comparison_df <- data.frame(
      Metric = metrics_lr$Metric,
      Logistic_Regression = paste0(round(metrics_lr$Percentage, 2), "%"),
      CART = paste0(round(metrics_cart$Percentage, 2), "%"),
      Random_Forest = paste0(round(metrics_rf$Percentage, 2), "%")
    )
    
    # Add AUC row
    comparison_df <- rbind(comparison_df,
      data.frame(
        Metric = "AUC",
        Logistic_Regression = as.character(round(auc_lr$Value, 3)),
        CART = as.character(round(auc_cart$Value, 3)),
        Random_Forest = as.character(round(auc_rf$Value, 3))
      )
    )
    
    DT::datatable(comparison_df, options = list(pageLength = 10))
  })
  
  # AUC comparison plot
  output$auc_comparison <- renderPlot({
    auc_df <- data.frame(
      Model = c("Logistic Regression", "CART", "Random Forest"),
      AUC = c(auc_lr$Value, auc_cart$Value, auc_rf$Value)
    )
    
    ggplot(auc_df, aes(x = Model, y = AUC, fill = Model)) +
      geom_bar(stat = "identity", alpha = 0.7) +
      scale_fill_manual(values = c("steelblue", "orange", "darkgreen")) +
      scale_y_continuous(limits = c(0, 1)) +
      labs(title = "AUC Comparison Across Models",
           y = "Area Under the Curve (AUC)",
           x = "") +
      theme_minimal() +
      theme(legend.position = "none",
            plot.title = element_text(hjust = 0.5, face = "bold"))
  })
}

# Run the app
shinyApp(ui = ui, server = server)

