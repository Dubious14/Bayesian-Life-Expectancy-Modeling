// M_HEALTH_prior.stan
data {
  int<lower=0> N;  
  vector[N] vaccine_1yo;  
  vector[N] dist_to_2000;  
}

parameters {
  real B0; 
  real B1;  
  real B2;  
  real<lower=0> sigma;  
}

model {
  // Priors
  B0 ~ normal(50, 10); 
  B1 ~ normal(0.2, 0.05); 
  B2 ~ normal(0.5, 0.1); 
  sigma ~ exponential(1); 
}

generated quantities {
  vector[N] y_rep;
  for (n in 1:N) {
    real mu = B0 + B1 * vaccine_1yo[n] + B2 * dist_to_2000[n];
    y_rep[n] = normal_rng(mu, sigma);
  }
}
