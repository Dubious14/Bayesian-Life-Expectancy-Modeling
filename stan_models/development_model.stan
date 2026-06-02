// M_DEVELOPED.stan

data {
  int<lower=0> N;          // Number of observations
  vector[N] Life_expectancy;             // Response variable
  vector[N] Economy_status_Developed; // predictor variable
  vector[N] dist_to_2000;  // predictor variable
}

parameters {
  real b0;                 // Intercept
  real b1;                 // Slope for developed countries
  real b2;                 // Slope for developed countries
  real b3;                 // Slope for developing countries
  real<lower=0> sigma;     // error standard deviation
}

model {
  // Priors
  b0 ~ normal(55, 5);      // we belive that in a developing country, the life expectancy is approximately 55 years.
  b1 ~ normal(20, 1);      // life expectancy is greater compared to developing country by around 20 years.
  b2 ~ normal(0.3, 0.05);
  b3 ~ normal(0.15, 0.05);
  sigma ~ exponential(0.1);    // Prior for sigma

  // Likelihood
  for (i in 1:N) {
    Life_expectancy[i] ~ normal(b0 
      + b1 * Economy_status_Developed[i]
      + b2 * dist_to_2000[i] * Economy_status_Developed[i] 
      + b3 * dist_to_2000[i] * (1 - Economy_status_Developed[i]), sigma);
  }
}

