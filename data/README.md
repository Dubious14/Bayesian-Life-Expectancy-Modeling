# Dataset

## Overview

This project uses the **Life Expectancy Dataset**, a country-level panel dataset containing demographic, health, economic, and educational indicators collected across multiple years.

The dataset was used to investigate factors associated with life expectancy through Bayesian statistical modeling.

## Dataset Summary

* **Observations:** 2,938
* **Variables:** 22
* **Unit of Analysis:** Country-Year
* **Coverage:** Multiple countries observed over multiple years
* **Target Variable:** Life Expectancy

## Key Variables

### Demographic Indicators

* Country
* Year
* Population
* Adult Mortality
* Infant Deaths
* Under-Five Deaths

### Health Indicators

* Hepatitis B Vaccination Coverage
* Polio Vaccination Coverage
* Diphtheria Vaccination Coverage
* HIV/AIDS Prevalence
* BMI
* Total Health Expenditure

### Economic Indicators

* GDP
* Percentage Health Expenditure
* Income Composition of Resources

### Social Indicators

* Schooling
* Development Status (Developed / Developing)

## Feature Engineering

Several additional variables were created during the analysis:

### Average Vaccination Coverage

A composite vaccination variable was constructed as the mean of:

* Hepatitis B
* Measles
* Polio
* Diphtheria

This feature was used in the health-focused Bayesian model.

### Distance from Baseline Year

A temporal feature was created:

```r
dist_to_2000 = Year - 2000
```

This variable captures long-term trends in life expectancy.

### Regional Indicators

Binary variables were generated for:

* Africa
* Asia
* South America
* Middle East

These indicators were used in the regional mortality analysis.

### Child Mortality Threshold Indicator

A binary outcome variable was created to identify observations where child mortality exceeded a predefined threshold.

This variable was used in the regional Bayesian probability model.

## Purpose in This Project

The dataset supports three main analyses:

1. Comparing education-based and vaccination-based life expectancy models.
2. Estimating life expectancy differences between developed and developing countries.
3. Evaluating regional differences in child mortality risk.

## Data Source

The dataset is publicly available through Kaggle and is commonly used for statistical modeling and predictive analytics tasks involving global health outcomes.
