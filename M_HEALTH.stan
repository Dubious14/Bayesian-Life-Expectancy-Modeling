// M_HEALTH.stan

data {
  int<lower=0> N;  // number of observations
  vector[N] Life_expectancy;  // response variable
  vector[N] vaccine_1yo;  // predictor variable
  vector[N] dist_to_2000;  // predictor variable
}

parameters {
  real B0;  // intercept
  real B1;  // slope for vaccination % in 1 year olds in the country
  real B2;  // slope for years passed since 2000 (tech improvment etc..)
  real<lower=0> sigma;  // error standard deviation
}

model {
  B0 ~ normal(50, 10); // we belive that if vaccine_1yo is 0% and the year is 2000, the life expectancy is approximately 50 years.
  B1 ~ normal(0.2, 0.05); // we belive that for each 5% increase in vaccination, the life expectancy increases approximately by 1 year
  B2 ~ normal(0.5, 0.1); // we belive that for each year psasing by, the life expectancy increases approximately by 0.5 years 
  sigma ~ exponential(1); // we are somewhat sure in our priors.
  
  Life_expectancy ~ normal(B0 + B1 * vaccine_1yo + B2 * dist_to_2000 , sigma);
}

generated quantities {
  vector[N] log_lik;
  vector[N] y_rep;
  for (n in 1:N) {
    real mu = B0 + B1 * vaccine_1yo[n] + B2 * dist_to_2000[n];
    log_lik[n] = normal_lpdf(Life_expectancy[n] | mu, sigma);
    y_rep[n] = normal_rng(mu, sigma);
  }
}
