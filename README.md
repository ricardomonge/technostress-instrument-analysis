# Data and R Scripts for the Validation of a Technostress, Technological Self-Efficacy, Academic Performance, and Digital Safety Scale

This repository contains the R scripts and anonymized datasets used in the development and psychometric validation of a multi-dimensional instrument designed to assess **technostress**, **technological self-efficacy**, **academic performance**, and **digital safety** among first-year undergraduate students.

---

## 📁 Repository Structure

```
├── data/                        # Contains anonymized datasets used in the analyses
│   ├── expert_judges_data.xlsx         # Data from expert raters for content validation
│   ├── data_Aiken_STATS.xlsx           # Formatted ratings used to compute Aiken’s V
│   ├── pilot_sample.xlsx               # Dataset used in the pilot phase
│   └── stas_anonymized_data.xlsx       # Full dataset for factor and reliability analysis
├── content_validation.R        # Content validity analysis using Aiken's V
├── factor_analysis.R           # Exploratory and confirmatory factor analysis (EFA & CFA)
├── pilot_study.R               # Preprocessing, descriptive analysis, and reliability (pilot sample)
└── README.md                   # This file
```

---

## 📊 Description of Scripts

- `content_validation.R`: Computes Aiken's V and confidence intervals for expert ratings on item relevance and wording.
- `factor_analysis.R`: Performs dimensionality analysis, exploratory factor analysis (EFA), confirmatory factor analysis (CFA), and computes reliability and validity metrics.
- `pilot_study.R`: Handles data cleaning, recoding, descriptive statistics, and estimation of ordinal reliability (Cronbach’s alpha) for the pilot dataset.

---

## 📂 Data Overview

| File                         | Description                                                                 |
|------------------------------|-----------------------------------------------------------------------------|
| `expert_judges_data.xlsx`    | Expert reviewers’ responses regarding item relevance and wording for initial content validation. |
| `data_Aiken_STATS.xlsx`      | Cleaned and reshaped data for Aiken’s V coefficient and CI estimation.     |
| `pilot_sample.xlsx`          | Dataset from the pilot application of the instrument used for initial reliability and item analysis. |
| `stas_anonymized_data.xlsx`  | Final full sample used for factor structure modeling and validation (EFA/CFA). |

All datasets are fully anonymized and comply with institutional and ethical research standards.

---

## 📦 Requirements

To reproduce the analyses, please ensure you have the following R packages installed:

```r
install.packages(c(
  "tidyverse", "readxl", "gtsummary", "flextable", "ftExtra", "labelled",
  "huxtable", "psych", "lavaan", "nFactors", "semTools", "corrplot"
))
```

---

## ▶️ How to Reproduce the Analyses

1. Clone or download this repository.
2. Open each script (`.R` files) in RStudio or your preferred R environment.
3. Run the scripts in the following order for full reproducibility:
   1. `pilot_study.R`
   2. `content_validation.R`
   3. `factor_analysis.R`
4. Ensure the `/data` folder is in the working directory.

---

## 👥 Authors and Affiliations

- **Ricardo Monge-Rogel**¹²  
- **Guillermo Durán-González**¹² *  
- **Mónica Panes-Martínez**¹²  
- **Rodrigo Cáceres-Chomalí**⁴  
- **Jesús Rojas-Cabello**³  

¹ Instituto de Matemática, Física y Estadística, Universidad de Las Américas, Manuel Montt 948, Providencia, Región Metropolitana, Chile  
² Grupo de Investigación en Educación STEM (GIE-STEM), Universidad de Las Américas  
³ Facultad de Educación, Universidad de Las Américas, República 71, Santiago Centro, Región Metropolitana, Chile  
⁴ Vicerrectoría Académica, Universidad de Las Américas

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 📚 Citation

If you use this repository or its materials in your work, please cite it as follows:

**APA:**

> Monge-Rogel, R., Durán-González, G., Panes-Martínez, M., Cáceres-Chomalí, R., & Rojas-Cabello, J. (2025). *technostress-instrument-analysis* [Data and R scripts]. GitHub. https://github.com/ricardomonge/technostress-instrument-analysis

**BibTeX:**

```bibtex
@misc{monge2025technostress,
  author       = {Ricardo Monge-Rogel and Guillermo Durán-González and Mónica Panes-Martínez and Rodrigo Cáceres-Chomalí and Jesús Rojas-Cabello},
  title        = {technostress-instrument-analysis: Data and R scripts for the development and validation of a multidimensional instrument},
  year         = {2025},
  url          = {https://github.com/ricardomonge/technostress-instrument-analysis},
  note         = {GitHub repository}
}
```
