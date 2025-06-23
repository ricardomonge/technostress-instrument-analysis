# -------------------------------------------------------------------------
# Content Validity Analysis of Expert Judgments Using Aiken's V and Summary Tables
# -------------------------------------------------------------------------

# Load required packages
library(tidyverse)   # Collection of packages for data manipulation and visualization
library(readxl)      # To read Excel (.xlsx) files
library(gtsummary)   # To create clean summary tables for reporting
library(flextable)   # To format tables for Word and PowerPoint documents
library(ftExtra)     # Extensions for customizing flextable outputs
library(labelled)    # To manage and apply variable labels in datasets


# Load datasets
file_path1 <- "data/expert_judges_data.xlsx"  # Adjust path as needed
df <- read_excel(file_path1)

file_path2 <- "data/data_Aiken_STATS.xlsx" 
df2 <- read_excel(file_path2)


# -------------------------------------------------------------------------
# Characterization of expert judges
# -------------------------------------------------------------------------

# Assign variable labels for a clearer summary table
df <- df |> 
  labelled::set_variable_labels(
    sex = "Sex",
    academic_degree = "Highest level of educational attainment",
    specialization = "Specialization",
    years_of_experience = "Years of experience",
    instrument_validation_experience = "Has had experience in the design and evaluation of assessment instruments"
  )

# Apply gtsummary theme for exploratory data analysis
suppressMessages(theme_gtsummary_eda(set_theme = TRUE))

# Generate summary table with median, mean, and range statistics
table1 <- tbl_summary(
  df,
  type = list(instrument_validation_experience ~ "categorical"),
  statistic = list(
    all_continuous() ~ c("{median} ({p25}, {p75})", "{mean} ({sd})", "{min}, {max}")
  ),
  digits = all_continuous() ~ 1  # Round continuous statistics to 1 decimal place
) |>
  modify_header(label = "Variable") |>  # Rename label column
  modify_caption("Table 5. Characterization of the expert judges") |>  # Set table caption
  as_flex_table() |>  # Convert to flextable for Word-compatible output
  autofit()  # Automatically adjust column widths

# Display summary table
table1


# -------------------------------------------------------------------------
# Results of content validity analysis based on Aiken’s V
# -------------------------------------------------------------------------

# Define function to compute Aiken's V coefficient
compute_aiken_v <- function(valores, k) {
  N <- length(valores)  # Number of expert raters
  V <- sum(valores - 1) / (N * (k - 1))
  return(V)
}

# Define function to compute the confidence interval for Aiken’s V
compute_aiken_ci <- function(V, n, k, confianza = 0.95) {
  z <- qnorm(1 - (1 - confianza) / 2)  # Z-score for the desired confidence level
  
  # Calculate the square root component of the interval
  sqrt_term <- sqrt(4 * n * k * V * (1 - V) + z^2)
  
  # Compute lower and upper bounds of the CI
  L <- (2 * n * k * V + z^2 - z * sqrt_term) / (2 * (n * k + z^2))
  U <- (2 * n * k * V + z^2 + z * sqrt_term) / (2 * (n * k + z^2))
  
  return(c(L, U))
}

# Reshape data to long format for item-level analysis
lf2 <- df2 %>%
  pivot_longer(cols = -dimension, names_to = "item", values_to = "valor")

# Define number of response categories on the scale (e.g., 4-point Likert scale)
k <- 4

# Set desired confidence level (default = 95%)
confianza <- 0.95

# Calculate Aiken's V, mean scores, and confidence intervals for each item and dimension
resultados <- lf2 %>%
  group_by(dimension, item) %>%
  summarise(
    promedio = mean(valor),               # Mean rating per item
    V = compute_aiken_v(valor, k),        # Aiken’s V coefficient
    n = length(valor),                    # Number of raters per item
    .groups = "drop"
  ) %>%
  rowwise() %>%
  mutate(
    lim_inf = compute_aiken_ci(V, n, k, confianza)[1],  # Lower bound of CI
    lim_sup = compute_aiken_ci(V, n, k, confianza)[2]   # Upper bound of CI
  ) %>%
  ungroup()

# Calculate frequency counts for each score (1 to 4) per item
frecuencias <- lf2 %>%
  group_by(dimension, item, valor) %>%
  summarise(frecuencia = n(), .groups = "drop") %>%
  pivot_wider(names_from = valor, values_from = frecuencia, values_fill = list(frecuencia = 0))

# Merge frequencies with results to build a complete output table
resultados_final <- resultados %>%
  left_join(frecuencias, by = c("dimension", "item")) %>%
  mutate(across(`1`:`4`, ~replace_na(.x, 0)))  # Replace NA with 0 in frequency columns

# Reorder columns for clarity: frequencies, mean, V, CI
resultados_final <- resultados_final %>%
  dplyr::select(dimension, item, `1`, `2`, `3`, `4`, promedio, V, lim_inf, lim_sup)

# Round selected numeric columns to 3 decimal places
resultados_final <- resultados_final %>%
  mutate(across(c(promedio, V, lim_inf, lim_sup), ~ round(.x, 3)))

# Optional: display results as markdown or pipe table
# kable(resultados_final, format = "pipe", caption = "Final Results Table")

# -------------------------------------------------------------------------
# Separate and format tables by dimension
# -------------------------------------------------------------------------

# Extract items related to the "relevance" dimension
tabla_pertinencia <- resultados_final %>%
  filter(dimension == "relevante") %>%
  dplyr::select(-dimension)

# Extract items related to the "wording" dimension
tabla_redaccion <- resultados_final %>%
  filter(dimension == "wording") %>%
  dplyr::select(-dimension)

# Create a formatted flextable for the relevance dimension
tabla_pertinencia_ft <- tabla_pertinencia %>%
  flextable() %>%
  set_caption(as_paragraph("Table 6.1 Results of the content validity analysis of relevance using Aiken’s V")) %>%
  add_header_row(values = c("", "Score frequency", "", "", "Confidence interval (95%)"), colwidths = c(1, 4, 1, 1, 2)) %>%
  bold(j = 1) %>%
  autofit()

# Create a formatted flextable for the wording dimension
tabla_redaccion_ft <- tabla_redaccion %>%
  flextable() %>%
  set_caption(as_paragraph("Table 6.2 Results of the content validity analysis of wording using Aiken’s V")) %>%
  add_header_row(values = c("", "Score frequency", "", "", "Confidence interval (95%)"), colwidths = c(1, 4, 1, 1, 2)) %>%
  bold(j = 1) %>%
  autofit()

# Print final formatted tables
tabla_pertinencia_ft
tabla_redaccion_ft
