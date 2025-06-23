start_time <- Sys.time()

# -------------------------------------------------------------------------
# Exploratory and Confirmatory Factor Analysis of the ITAT Instrument
# ------------------------------------------------------------------------- 

# Load required libraries
library(openxlsx)        # For reading/writing Excel files
library(dplyr)           # For data manipulation (filter, mutate, select, etc.)
library(readxl)          # For importing Excel data
library(gtsummary)       # For creating summary tables for publication
library(huxtable)        # For formatting tables as LaTeX/HTML/Markdown
library(psych)           # For reliability analysis, EFA, polychoric correlations
library(QuantPsyc)       # For Mardia's test of multivariate normality
library(nortest)         # For univariate normality tests like Anderson-Darling
library(mvtnorm)         # For multivariate distributions used in tests
library(corrplot)        # To visualize correlation matrices
library(parameters)      # For computing number of factors
library(performance)     # For checking factor structure assumptions
library(nFactors)        # For determining factor count via scree plots
library(lavaan)          # For structural equation modeling (CFA)
library(pheatmap)        # For heatmaps with clustering
library(gplots)          # Additional plotting tools
library(see)             # Visual tools for modeling and stats
library(semTools)        # For AVE, CR, and additional SEM utilities
library(GPArotation)     # For performing oblique and orthogonal factor rotations in EFA
library(benchmarkme)     # Load benchmarkme to retrieve system information (CPU, RAM, OS) and performance metrics


options(digits = 4)

# Load and prepare dataset
data_itat <- read_excel("data/stas_anonymized_data.xlsx", sheet = 1)

# Recode categorical variables to English labels
data_itat <- data_itat %>%
  mutate(
    categoria_regimen = case_when(
      regimen == "A DISTANCIA" ~ "Distance",
      regimen %in% c("DIURNO", "VESPERTINO", "EXECUTIVE") ~ "Face-to-face",
      regimen == "SEMIPRESENCIAL EXECUTIVE" ~ "Blended",
      TRUE ~ NA_character_
    ),
    categoria_sexo = case_when(
      sexo == "Femenino" ~ "Female",
      sexo == "Masculino" ~ "Male",
      TRUE ~ NA_character_
    )
  )

# Compute total score and set variable labels
data_itat <- data_itat %>%
  mutate(total = rowSums(.[14:47])) %>%
  labelled::set_variable_labels(
    edad = "Age",
    campus = "Campus",
    sede = "Location",
    sexo = "Sex",
    carrera = "Program",
    escuela = "School",
    facultad = "Faculty",
    categoria_regimen = "Regime",
    categoria_sexo = "Sex",
    aceptacion = "Perceived acceptability of the instrument",
    comprension = "Perceived comprehension of the items",
    satisfaccion = "Overall satisfaction with the instrument"
  )

# Reverse-score negatively worded items in Technostress dimension
items_to_reverse <- c("i14", "i15", "i16", "i17", "i18", "i19", "i20", "i21")
data_itat[ , items_to_reverse] <- 7 - data_itat[ , items_to_reverse]

# Filter respondents with valid consent
data_itat_so <- data_itat %>%
  filter(vigente == "SI", consentimiento == 1)

# Descriptive statistics for sociodemographic variables
data_itat_so_demo <- data_itat_so %>%
  dplyr::select("edad", "sede", "categoria_regimen", "facultad", "categoria_sexo")
theme_gtsummary_eda(set_theme = TRUE)
tbl_summary(data_itat_so_demo) %>%
  modify_header(label = "Variable") %>%
  modify_caption("Table 4. Sociodemographic characteristics of participants") %>%
  as_hux_table()

# Descriptive statistics for satisfaction-related variables
data_itat_so_satisfaccion <- data_itat_so %>%
  dplyr::select("aceptacion", "comprension", "satisfaccion")
tbl_summary(data_itat_so_satisfaccion) %>%
  modify_header(label = "Variable") %>%
  modify_caption("Table 12: Frequency distribution of satisfaction with the STAS instrument") %>%
  as_hux_table()

# Select only item response variables for psychometric analysis
items <- data_itat_so[ , !(names(data_itat_so) %in% 
                             c("semestre", "ID", "nacimiento", "edad", "campus", "sede", "regimen",
                               "categoria_regimen", "carrera", "escuela", "facultad", "sexo", "categoria_sexo",
                               "vigente", "consentimiento", "comprension", "satisfaccion", "aceptacion",
                               "comentarios", "total"))]

# Compute polychoric correlation matrix and ordinal alpha
matriz_poly <- suppressWarnings(psych::polychoric(items, smooth = TRUE, correct = 0))
alpha_ordinal <- psych::alpha(matriz_poly$rho, check.keys = TRUE)
intervalo_alpha_ordinal <- alpha.ci(
  alpha_ordinal$total$raw_alpha,
  n.obs = 6102,
  n.var = 34,
  p.val = 0.05,
  digits = 4
)
cat(sprintf(
  "Ordinal Cronbach's alpha = %.4f and 95%% confidence interval = CI : ]%.4f, %.4f[\n",
  alpha_ordinal$total$raw_alpha,
  intervalo_alpha_ordinal[1],
  intervalo_alpha_ordinal[2]
))

# Displays ordinal alpha results rounded to three decimals, including overall reliability and item-drop effects.
print(alpha_ordinal, digits = 3)


# Visualize correlation matrix
corrplot(matriz_poly$rho, type = "upper", tl.pos = "tp")
corrplot(matriz_poly$rho, add = TRUE, type = "lower", method = "number", col = "black", diag = FALSE, tl.pos = "n", cl.pos = "n", number.cex = 0.9)

# Heatmap with clustering
pheatmap(
  matriz_poly$rho,
  clustering_method = "ward.D2",
  color = colorRampPalette(c("blue", "white", "red"))(50),
  display_numbers = FALSE,
  border_color = NA,
  fontsize = 10,
  treeheight_row = 50,
  treeheight_col = 50,
  main = "Polychoric Correlation Matrix with Clustering"
)

# -------------------------------------------------------------------------
# Split data into EFA and CFA samples
# -------------------------------------------------------------------------

set.seed(123)  # Set seed for reproducibility
N <- nrow(data_itat_so)  # Total number of cases
indices <- seq_len(N)
indices_EFA <- sample(indices, floor(0.5 * N))  # Randomly select 50% for EFA
indices_CFA <- setdiff(indices, indices_EFA)    # Remaining 50% for CFA
itat_EFA <- data_itat_so[indices_EFA, 14:47]    # Select Likert-scale items
itat_CFA <- data_itat_so[indices_CFA, 14:47]

# Inspect data and basic descriptives
knitr::kable(head(itat_EFA), booktabs = TRUE, format = "markdown")
knitr::kable(describe(itat_EFA, type = 3, fast = FALSE), booktabs = TRUE, format = "markdown")
knitr::kable(response.frequencies(itat_EFA), booktabs = TRUE, format = "markdown")

# Assess multivariate normality using Mardia’s test
mardia_result <- QuantPsyc::mult.norm(itat_EFA)
print(mardia_result$mult.test)

# Assess univariate normality using Anderson-Darling test
univar_ad <- apply(itat_EFA, 2, ad.test)
resultado_uni <- data.frame(
  Variable = names(univar_ad),
  AD_statistic = sapply(univar_ad, function(x) round(x$statistic, 4)),
  p_value = sapply(univar_ad, function(x) round(x$p.value, 4))
)
knitr::kable(resultado_uni, booktabs = TRUE, format = "markdown",
             caption = "Univariate normality tests using Anderson-Darling")

# -------------------------------------------------------------------------
# Exploratory Factor Analysis (EFA)
# -------------------------------------------------------------------------

# Check factor structure assumptions
performance::check_factorstructure(itat_EFA)

# Compute polychoric correlation matrix
salida <- polychoric(itat_EFA)
salida_matriz <- salida$rho

# Estimate optimal number of factors while suppressing warnings
resultado_nfactors <- suppressWarnings(
  parameters::n_factors(
    itat_EFA,
    cor = salida_matriz,
    rotation = "oblimin",
    algorithm = "ml",
    n = nrow(itat_EFA),
    n_simulations = 100,
    parallel = FALSE
  )
)


plot(resultado_nfactors)+ 
  ggplot2::theme_bw()

summary(resultado_nfactors)

# Run EFA with 4 factors and oblimin rotation
RDAfactor <- fa(itat_EFA, nfactors = 4, fm = "wls", rotate = "oblimin", cor = "poly")
print(RDAfactor, digits = 3, cut = 0.50, sort = TRUE)

# -------------------------------------------------------------------------
# Confirmatory Factor Analysis (CFA)
# -------------------------------------------------------------------------

# Specify 4-factor model based on theoretical structure
model_spec <- 'Technological_self_efficacy =~ i01+i02+i03+i04+i05+i06+i07+i08+i09+i10+i11+i12+i13
Technostress =~ i14+i15+i16+i17+i18+i19+i20+i21
Academic_performance =~ i22+i23+i24
Security_and_privacy =~ i25+i26+i27+i28+i29+i30+i31+i32+i33+i34'

# Fit model using DWLS estimator (suitable for ordinal data)
CFAcuatro <- lavaan::cfa(model = model_spec, data = itat_CFA, ordered = names(itat_CFA),
                         estimator = "DWLS", representation = "LISREL")

# Retrieve and inspect model fit indices
fitMeasures(CFAcuatro, c("chisq", "df", "pvalue", "gfi", "rmsea", "srmr", "cfi", "tli", "agfi", "pnfi", "ifi","nfi"))
summary(CFAcuatro, fit.measures = TRUE, standardized = TRUE)

# Get standardized covariances between latent factors
parameterEstimates(CFAcuatro, standardized = TRUE) %>%
  subset(op == "~~" & lhs != rhs)  # Extracts factor-factor relationships

# Get standardized factor loadings
parameterEstimates(CFAcuatro, standardized = TRUE) %>%
  subset(op == "=~")  # Extracts loadings from latent variables to items

# Get standardized residual variances for observed items
parameterEstimates(CFAcuatro, standardized = TRUE) %>%
  subset(op == "~~" & lhs == rhs & grepl("^i\\d+", lhs))  # Extracts item error variances

# -------------------------------------------------------------------------
# Reliability and Convergent Validity (AVE & CR)
# -------------------------------------------------------------------------

# # Extract composite reliability (CR)
cr_results <- semTools::compRelSEM(CFAcuatro)

# # Extract AVE
ave_results <- semTools::AVE(CFAcuatro)

# # Extract standardized covariances between factors (equivalent to Std.lv)
cov_std_lv <- standardizedSolution(CFAcuatro) %>%
  dplyr::filter(op == "~~", lhs != rhs) %>%
  dplyr::select(Factor1 = lhs, Factor2 = rhs, Std_LV_Covariance = est.std)

#  Helper function to retrieve values between pairs of factors
get_std_lv <- function(f1, f2) {
  val <- cov_std_lv %>%
    dplyr::filter((Factor1 == f1 & Factor2 == f2) | (Factor1 == f2 & Factor2 == f1)) %>%
    dplyr::pull(Std_LV_Covariance)
  if (length(val) == 0) return("-") else return(val)
}

# Build matrix of AVE and shared covariances
Dimensions <- c("Technological_self_efficacy", "Technostress", "Academic_performance", "Security_and_privacy")

Technological_self_efficacy <- c(
  as.numeric(ave_results["Technological_self_efficacy"]),
  get_std_lv("Technological_self_efficacy", "Technostress")^2,
  get_std_lv("Technological_self_efficacy", "Academic_performance")^2,
  get_std_lv("Technological_self_efficacy", "Security_and_privacy")^2
)

Technostress <- c(
  "-", 
  as.numeric(ave_results["Technostress"]), 
  get_std_lv("Technostress", "Academic_performance")^2,
  get_std_lv("Technostress", "Security_and_privacy")^2
)

Academic_performance <- c(
  "-", "-", 
  as.numeric(ave_results["Academic_performance"]), 
  get_std_lv("Academic_performance", "Security_and_privacy")^2
)

Security_and_privacy <- c(
  "-", "-", "-", 
  as.numeric(ave_results["Security_and_privacy"])
)

matrix_VD <- data.frame(
  Dimensions,
  Technological_self_efficacy,
  Technostress,
  Academic_performance,
  Security_and_privacy,
  stringsAsFactors = FALSE
)

# Format numeric values to 4 decimal places
matrix_VD[ , 2:5] <- lapply(matrix_VD[ , 2:5], function(col) {
  if (is.numeric(col)) {
    sprintf("%.4f", col)
  } else {
    sapply(col, function(x) {
      if (suppressWarnings(!is.na(as.numeric(x)))) {
        sprintf("%.4f", as.numeric(x))
      } else {
        x
      }
    })
  }
})

# Print table
print(matrix_VD, right = FALSE, row.names = FALSE)


# -------------------------------------------------------------------------
# Composite Reliability (CR)
# -------------------------------------------------------------------------

# Calculate composite reliability manually from standardized loadings
sl <- standardizedSolution(CFAcuatro) %>%
  filter(op == "=~") %>%
  dplyr::select(lhs, rhs, est.std) %>%
  mutate(re = 1 - est.std^2)
names(sl) <- c("dimensions", "item", "CFE", "Error")

# Compute CR per factor
tl <- sl %>%
  arrange(dimensions) %>%
  group_by(dimensions) %>%
  mutate(fc = sum(CFE)^2 / (sum(CFE)^2 + sum(Error)))
tabla_fc <- aggregate(tl[, 5], list(tl$dimensions), mean)
names(tabla_fc) <- c("Factor", "CR")
tabla_fc

# -------------------------------------------------------------------------
# Discriminant Validity: HTMT
# -------------------------------------------------------------------------

# Custom HTMT function to compute Heterotrait-Monotrait ratio
htmt_manual <- function(cor_matrix, grupos) {
  n <- length(grupos)
  htmt_values <- matrix(NA, n, n)
  rownames(htmt_values) <- colnames(htmt_values) <- names(grupos)
  
  for (i in 1:(n - 1)) {
    for (j in (i + 1):n) {
      cor_cross <- cor_matrix[grupos[[i]], grupos[[j]]]
      cor_within_i <- cor_matrix[grupos[[i]], grupos[[i]]]
      cor_within_j <- cor_matrix[grupos[[j]], grupos[[j]]]
      htmt_ij <- mean(abs(cor_cross)) / sqrt(mean(abs(cor_within_i)) * mean(abs(cor_within_j)))
      htmt_values[i, j] <- htmt_ij
      htmt_values[j, i] <- htmt_ij
    }
  }
  return(htmt_values)
}

# Define item groups per factor
grupos <- list(
  Technological_self_efficacy = c("i01", "i02", "i03", "i04", "i05", "i06",
                                  "i07", "i08", "i09", "i10", "i11", "i12", "i13"),
  Technostress = c("i14", "i15", "i16", "i17", "i18", "i19", "i20", "i21"),
  Academic_performance = c("i22", "i23", "i24"),
  Security_and_privacy = c("i25", "i26", "i27", "i28", "i29", "i30", "i31", "i32", "i33", "i34")
)

# Compute and display HTMT matrix
htmt_matrix <- htmt_manual(salida_matriz, grupos)
print(htmt_matrix)


end_time <- Sys.time()
elapsed_time <- end_time - start_time

cat("\n--- Execution Summary ---\n")
cat("Start Time:", start_time, "\n")
cat("End Time:", end_time, "\n")
cat("Elapsed Time:", elapsed_time, "\n")

cat("\n--- System Info ---\n")
print(get_platform_info())

cat("\nCPU:\n")
print(get_cpu())

cat("\nRAM (in GB):\n")
print(round(get_ram() / (1024^3), 2))


