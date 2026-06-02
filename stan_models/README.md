# Stan Models

This directory contains the probabilistic models used throughout the Bayesian Life Expectancy Modeling project.

## Models

### social_model.stan

Bayesian linear regression predicting life expectancy using:

- Education level
- Year

Used to evaluate the relationship between social factors and life expectancy.

---

### health_model.stan

Bayesian linear regression predicting life expectancy using:

- Vaccination coverage
- Year

Used to evaluate the predictive power of health-related factors.

---

### development_model.stan

Bayesian regression model comparing:

- Developed countries
- Developing countries

Used to estimate differences in life expectancy and long-term trends between economic groups.

---

### regional_mortality_model.stan

Bayesian model estimating the probability that child mortality exceeds a critical threshold across geographic regions.

Regions analyzed:

- Africa
- Asia
- South America
- Middle East

---

## Prior Predictive Models

### social_prior.stan

Prior predictive simulation for the social model.

Used to evaluate whether prior assumptions generate realistic life expectancy distributions before observing data.

---

### health_prior.stan

Prior predictive simulation for the health model.

Used to assess prior assumptions before model fitting.

---

## Inference

All models were estimated using:

- Stan
- Markov Chain Monte Carlo (MCMC)
- Multiple chains
- Convergence diagnostics (R-hat, ESS)

Model performance was evaluated using:

- Prior Predictive Checks
- Posterior Predictive Checks
- WAIC
- LOO-CV
- Bayes Factors
