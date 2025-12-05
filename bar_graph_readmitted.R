# Load required libraries
library(ggplot2)

# Read the CSV file
data <- read.csv("hospital_readmissions.csv", stringsAsFactors = FALSE)

# Check the structure of the readmitted column
print("Readmitted column values:")
print(table(data$readmitted))

# Create a bar graph
barplot(table(data$readmitted),
        main = "Distribution of Readmitted Patients",
        xlab = "Readmitted",
        ylab = "Count",
        col = c("lightcoral", "lightblue"),
        names.arg = c("No", "Yes"))

# Alternative using ggplot2 (more customizable)
ggplot(data, aes(x = readmitted, fill = readmitted)) +
  geom_bar() +
  scale_fill_manual(values = c("no" = "lightcoral", "yes" = "lightblue"),
                    labels = c("no" = "No", "yes" = "Yes")) +
  labs(title = "Distribution of Readmitted Patients",
       x = "Readmitted",
       y = "Count",
       fill = "Readmitted") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"))

# Save the ggplot
ggsave("readmitted_bar_graph.png", width = 8, height = 6, dpi = 300)

