// M_regions.stan

data {
  int<lower=0> N;               
  vector[N]is_africa;             
  vector[N] is_south_america;       
  vector[N] is_asia;
  vector[N] is_Middle_East;              
  int youth_death_50_above[N];          
}

parameters {
  vector<lower=0, upper=1>[4] theta;  
}

model {
  // Priors on theta
  target += beta_lpdf(theta[1] | 7.5, 2.5); // Prior for Africa
  target += beta_lpdf(theta[2] | 4, 6); // Prior for South America
  target += beta_lpdf(theta[3] | 3, 7); // Prior for Asia
  target += beta_lpdf(theta[4] | 2, 8); // Prior for Middle East

  // Likelihood
  vector[N] p = theta[1] * is_africa + theta[2] * is_south_america + theta[3] * is_asia +
  theta[4] * is_Middle_East;
  target += bernoulli_lpmf(youth_death_50_above | p);
}

generated quantities {
  vector[N] log_lik;
  for (i in 1:N) {
    real prob = theta[1] * is_africa[i] + theta[2] * is_south_america[i] + 
    theta[3] * is_asia[i] + theta[4] * is_Middle_East[i];
    log_lik[i] = bernoulli_lpmf(youth_death_50_above[i] | prob);
  }
}
