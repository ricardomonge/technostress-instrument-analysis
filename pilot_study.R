# -------------------------------------------------------------------------
# Data Import, Preprocessing, and Ordinal Reliability Analysis (Pilot Sample)
# -------------------------------------------------------------------------


# Install required packages (if not already installed)
if (!require("readxl")) install.packages("readxl")
if (!require("dplyr")) install.packages("dplyr")
if (!require("gtsummary")) install.packages("gtsummary")
if (!require("huxtable")) install.packages("huxtable")
if (!require("psych")) install.packages("psych")

# Load necessary libraries
library(readxl)     # To import Excel files
library(dplyr)      # For data manipulation (filter, mutate, select, etc.)
library(gtsummary)  # To create publication-ready summary tables
library(huxtable)   # To format tables for LaTeX, HTML, or Word output
library(psych)      # For psychometric analysis, including reliability and EFA


# Define file path and worksheet name (update with actual values)
file_path <- "data/pilot_sample.xlsx"
sheet_name <- "Sheet1"  # Replace with actual sheet name

# Import dataset from Excel file
dataset <- read_excel(file_path, sheet = sheet_name)

# Recode 'regimen' variable into broader categorical groups
dataset <- dataset %>%
  mutate(categoria_regimen = case_when(
    regimen == "A DISTANCIA" ~ "Distance",
    regimen %in% c("DIURNO", "VESPERTINO", "EXECUTIVE") ~ "Face-to-face",
    regimen == "SEMIPRESENCIAL EXECUTIVE" ~ "Blended",
    TRUE ~ NA_character_  # Handles unexpected values
  ))

# Compute total score across item responses and assign variable labels
dataset <- dataset %>% 
  mutate(
    total = rowSums(.[14:47])  # Adjust index if item columns differ
  ) %>% 
  labelled::set_variable_labels(
    edad = "Age",
    campus = "Campus",
    sede = "Location",
    sexo = "Sex",
    carrera = "Program",
    escuela = "School",
    facultad = "Faculty",
    categoria_regimen = "Modality",
    aceptacion = "What was the level of understanding and acceptance of this instrument?",
    comprension = "What was the level of understanding of the questions?",
    satisfaccion = "What was the level of satisfaction with this instrument?"
  )

# Filter dataset to include only active participants with informed consent
dataset <- dataset %>%
  filter(vigente == "SI", consentimiento == 1)

# Display number of rows after filtering
cat("Number of rows in the dataset:", nrow(dataset), "\n")

# Display first few rows of the filtered dataset
print(head(dataset))

# Select sociodemographic variables for descriptive analysis
dataset_demo <- dataset %>%
  dplyr::select(edad, sede, categoria_regimen, facultad, sexo)

# Generate summary table for sociodemographic characteristics
theme_gtsummary_eda(set_theme = TRUE)
tbl_summary(dataset_demo) %>%
  modify_header(label = "Variable") %>%
  modify_caption("Table 1. Sociodemographic characteristics of participants (pilot sample)") %>%
  as_hux_table()

# Select satisfaction-related variables
dataset_satisfaccion <- dataset %>%
  dplyr::select(aceptacion, comprension, satisfaccion)

# Generate summary table for satisfaction indicators
theme_gtsummary_eda(set_theme = TRUE)
tbl_summary(dataset_satisfaccion) %>%
  modify_header(label = "Variable") %>%
  modify_caption("Table 2. Frequency distribution of satisfaction with the STAS instrument (pilot sample)") %>%
  as_hux_table()

# Remove non-item columns to isolate only instrument items
items <- dataset[ , !(names(dataset) %in% 
                        c("semestre", "ID", "nacimiento", "edad", "campus", "sede", "regimen",
                          "categoria_regimen", "carrera", "escuela", "facultad", "sexo",
                          "vigente", "consentimiento", "comprension", "satisfaccion", "aceptacion",
                          "comentarios", "total"))]

# Estimate internal consistency (ordinal reliability) using polychoric correlation matrix

# Suppress warnings related to smoothing of non-positive definite matrices
matriz_poly <- suppressWarnings(
  psych::polychoric(items, smooth = TRUE, correct = 0)
)

# Compute ordinal Cronbach's alpha
alpha_ordinal <- psych::alpha(matriz_poly$rho, check.keys = TRUE)

# Calculate 95% confidence interval for ordinal alpha
intervalo_alpha_ordinal <- alpha.ci(
  alpha_ordinal$total$raw_alpha,
  n.obs = 100,     # Replace with actual number of respondents
  n.var = 34,      # Replace with actual number of items
  p.val = 0.05,
  digits = 4
)

# Output formatted result for manuscript/reporting
cat(sprintf(
  "Ordinal Cronbach's alpha = %.4f and 95%% confidence interval = CI : ]%.4f, %.4f[\n",
  alpha_ordinal$total$raw_alpha,
  intervalo_alpha_ordinal[1],
  intervalo_alpha_ordinal[2]
))
