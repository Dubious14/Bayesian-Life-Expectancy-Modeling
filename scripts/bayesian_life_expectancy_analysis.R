library(rstan)
library(rstanarm)
library(bridgesampling)
library(distributional)
library(easystats)
library(posterior)
library(loo)
library(dplyr)
library(tidyr)
library(bayesplot)
library(ggplot2)
library(ggdist)
library(gridExtra)
library(patchwork)


# We have left some of the graphs outside the word file due to lack of space. 
# In other cases, we used them to help us understand the results but we didn't think they
# should be presented.

file_path <- file.choose()
data <- read.csv(file_path) #choose Life-Expectancy-Data-Updated

# Checking if every country appears 16 times in the data (one for each year).
# if the number we get times 16 (16 years of data) equals to the sum of rows in the data,
# that means that each country has exactly 16 years of data.

unique_countries_count <- data %>%
  distinct(Country) %>%
  nrow()

# mean of several types of vaccinations 
data <- data %>%
  mutate(vaccine_1yo = rowMeans(select(., Hepatitis_B, Measles, Polio, Diphtheria), na.rm = TRUE))

# distance of each observation from the year 2000.
data$dist_to_2000 <- data$Year - 2000






# ***answer for Q1:***

# we have noticed high correlation among these variables with life_expectancy,
# so we wanted to examine this using linear regression.
# we added year because we believed that time also plays a role in increasing life expectancy.

corr <- summary(
correlation(data[, c("Life_expectancy", "Schooling", "vaccine_1yo", "Year")]),
redundant = FALSE)

plot(corr)

# Prior Predictive Check

prior_social <- list(
  N = nrow(data),
  schooling = data$Schooling,
  dist_to_2000 = data$dist_to_2000
)

prior_health <- list(
  N = nrow(data),
  vaccine_1yo = data$vaccine_1yo,
  dist_to_2000 = data$dist_to_2000
)

file_path_social_prior <- file.choose()
model_social_prior <- stan_model(file_path_social_prior) # choose social_prior stan model

file_path_health <- file.choose()
model_health_prior <- stan_model(file_path_health) # choose health_prior stan model


social_prior <- sampling(
  model_social_prior,
  data = prior_social,
  iter = 1000,
  warmup = 500,
  chains = 2)

health_prior <- sampling(
  model_health_prior,
  data = prior_health,
  iter = 1000,
  warmup = 500,
  chains = 2)


y_rep_M_SOCIAL_prior <- as.matrix(social_prior, pars = "y_rep")
y_rep_M_HEALTH_prior <- as.matrix(health_prior, pars = "y_rep")

color_scheme_set("mix-blue-red")

# Posterior predictive density overlay

plot_prior_social <- ppc_dens_overlay(
  y = data$Life_expectancy,
  yrep = y_rep_M_SOCIAL_prior
) +
  theme_minimal() +  
  ggtitle("prior Predictive Check for Model Social") +  
  xlab("Life Expectancy") +  
  ylab("Density")

plot_prior_health <- ppc_dens_overlay(
  y = data$Life_expectancy,
  yrep = y_rep_M_HEALTH_prior
) +
  theme_minimal() +  
  ggtitle("prior Predictive Check for Model Health") +  
  xlab("Life Expectancy") +  
  ylab("Density")

grid.arrange(plot_prior_social, plot_prior_health, ncol = 2)


# Compare the data$life expectancy mean to the sampled mean of Y 
plot_prior_social <- ppc_stat(
  y = data$Life_expectancy,
  yrep = y_rep_M_SOCIAL_prior,
  stat = "mean"
) +
  theme_minimal() +  
  ggtitle("prior Predictive Check for model social") +  
  xlab("Mean of Life Expectancy") +  
  ylab("Density")

plot_prior_health <- ppc_stat(
  y = data$Life_expectancy,
  yrep = y_rep_M_HEALTH_prior,
  stat = "mean"
) +
  theme_minimal() +  
  ggtitle("prior Predictive Check for model health") +  
  xlab("Mean of Life Expectancy") +  
  ylab("Density")

grid.arrange(plot_prior_social, plot_prior_health, ncol = 2)

# UPDATING

# Prepare data for Stan
stan_social <- list(
  N = nrow(data),
  Life_expectancy = data$Life_expectancy,
  Schooling = data$Schooling,
  dist_to_2000 = data$dist_to_2000
)

stan_health <- list(
  N = nrow(data),
  Life_expectancy = data$Life_expectancy,
  vaccine_1yo = data$vaccine_1yo,
  dist_to_2000 = data$dist_to_2000
)

# Set the model ------------------------------------------------

# Compile Stan models
file_path_social <- file.choose()
model_social <- stan_model(file_path_social) # choose social stan model

file_path_health <- file.choose()
model_health <- stan_model(file_path_health) # choose health stan model

# Fit model_social
M_social <- sampling(
  model_social, 
  data = stan_social, 
  chains = 4,  
  iter = 4000,  
  warmup = 2000,  
  thin = 1,
  seed = 1234
)

# Fit model_health
M_health <- sampling(
  model_health, 
  data = stan_health, 
  chains = 4,  
  iter = 4000,  
  warmup = 2000,  
  thin = 1,
  seed = 1234
)

social_summary <- summary(M_social)$summary
health_summary <- summary(M_health)$summary

parameters <- c("B0", "B1", "B2", "sigma")
print(social_summary[rownames(social_summary) %in% parameters,c("mean", "sd", "n_eff", "Rhat")])
print(health_summary[rownames(health_summary) %in% parameters,c("mean", "sd", "n_eff", "Rhat")])

social_result <- point_estimate(M_social, parameters = c("B0", "B1", "B2"))
print(social_result)
health_result <- point_estimate(M_health, parameters = c("B0", "B1", "B2"))
print(health_result)

# Model comparison ------------------------------------------------

# Compare models using WAIC
log_lik_M_social <- extract_log_lik(M_social)
log_lik_M_HEALTH <- extract_log_lik(M_health)

waic_M_social <- waic(log_lik_M_social)
waic_M_HEALTH <- waic(log_lik_M_HEALTH)

waic_comparison <- loo_compare(waic_M_social, waic_M_HEALTH)
print(waic_comparison, simplify = FALSE)


# Compare models using LOO
loo_M_social  <- loo(M_social)
loo_M_HEALTH <- loo(M_health)
loo_comparison <- loo_compare(loo_M_social, loo_M_HEALTH)
print(loo_comparison, simplify = FALSE)

# Compute Bayes Factors
bs_M_social <- bridge_sampler(M_social)
bs_M_HEALTH <- bridge_sampler(M_health)
bf <- bayes_factor(bs_M_social, bs_M_HEALTH)
print(bf)
print(bf$bf)

# Convergence
social_posterior <- as.array(M_social)
health_posterior <- as.array(M_health)

color_scheme_set("mix-blue-red")

p1 <- mcmc_trace(
  social_posterior, 
  pars = c("B0", "B1", "B2", "sigma"), 
  facet_args = list(ncol = 1, strip.position = "left"))

p2 <- mcmc_trace(
  health_posterior, 
  pars = c("B0", "B1", "B2", "sigma"), 
  facet_args = list(ncol = 1, strip.position = "left"))

grid.arrange(p1, p2, ncol = 2)

# now we recommend to click on "free unused R memory" which is next to the sweep symbol

# Posterior Predictive Check ------------------------------------------------

y_rep_M_social  <- as.matrix(M_social, pars = "y_rep")
y_rep_M_HEALTH <- as.matrix(M_health, pars = "y_rep")

# Posterior predictive density overlay for Model Social
p1 <- ppc_dens_overlay(
  y = stan_social$Life_expectancy,
  yrep = y_rep_M_social
) +
  theme_minimal() +  
  ggtitle("Posterior Predictive Check for Model Social") +  
  xlab("Life Expectancy") +  
  ylab("Density")

# Posterior predictive density overlay for Model Health
p2 <- ppc_dens_overlay(
  y = data$Life_expectancy,
  yrep = y_rep_M_HEALTH
) +
  theme_minimal() +  
  ggtitle("Posterior Predictive Check for Model Health") +  
  xlab("Life Expectancy") +  
  ylab("Density")


grid.arrange(p1, p2, ncol = 2)

# Compare the data's life expectancy mean to the sampled mean of life expectancy in Model Social
p1 <- ppc_stat(
  y = data$Life_expectancy,
  yrep = y_rep_M_social,
  stat = "mean"
) +
  theme_minimal() + 
  ggtitle("Posterior Predictive Check for Model Social") +  
  xlab("Mean of Life Expectancy") +  
  ylab("Density")

# Compare the data's life expectancy mean to the sampled mean of life expectancy in Model Health
p2 <- ppc_stat(
  y = data$Life_expectancy,
  yrep = y_rep_M_HEALTH,
  stat = "mean"
) +
  theme_minimal() +  
  ggtitle("Posterior Predictive Check for Model Health") +  
  xlab("Mean of Life Expectancy") +  
  ylab("Density")

# we have decided to keep it out of the word file, but we made it because
# we needed to see how our models predict life expectancy
# in terms of average to determine how well they are performing.
grid.arrange(p1, p2, ncol = 2)





# ******************Q2******************:


stan_developed <- list(
  N = nrow(data),
  Life_expectancy = data$Life_expectancy,
  Economy_status_Developed = data$Economy_status_Developed,
  dist_to_2000 = data$dist_to_2000
)


# Set the model ------------------------------------------------

# Compile Stan models
file_path_social <- file.choose()
model_developed <- stan_model(file_path_social) # choose developed stan model

M_developed <- sampling(
  model_developed, 
  data = stan_developed, 
  chains = 4,  
  iter = 4000,  
  warmup = 2000,  
  thin = 1,
  seed = 1234
)

# *** Convergence and centrality indices ***

parameters <- c("b0", "b1", "b2","b3", "sigma")
developed_summery <- summary(M_developed)$summary
print(developed_summery[rownames(developed_summery) %in% parameters,c("mean","sd", "n_eff", "Rhat")])


# ***PPD***

post_b0 <- rstan::extract(M_developed, "b0")$b0
post_b1 <- rstan::extract(M_developed, "b1")$b1
post_b2 <- rstan::extract(M_developed, "b2")$b2
post_b3 <- rstan::extract(M_developed, "b3")$b3


# Placing the variables we got in the prediction equation. 
# 0:15 is for the distance (in years) of each observation
# in the data from 2000 (which is the first year in the data).

developed_2015 = post_b0 + post_b1 * 1 + post_b2 * 0:15
developing_2015 = post_b0 + post_b1 * 0 + post_b3 * 0:15
diff = as.data.frame(developed_2015)
diff$developing_2015 = developing_2015
diff$life_expectancy = diff$developed_2015 - diff$developing_2015
diff$tech_advanement = post_b3 - post_b2


# *** 2030 prediction ***
# same as above but now we want to check out how the data would look like in 2030.


developed_2030 = post_b0 + post_b1 * 1 + post_b2 * 30
developing_2030 = post_b0 + post_b1 * 0 + post_b3 * 30
diff_2030 = as.data.frame(developed_2030)
diff_2030$developing_2030 = developing_2030
diff_2030$life_expectancy = diff_2030$developed_2030 - diff_2030$developing_2030

# *** 2030 prediction ***


## Plots -------------------------

color_scheme_set("red")

mcmc_trace(M_developed, pars = c("b0", "b1", "b2", "b3")) +
  ggtitle("Trace Plots for Model Parameters") +
  theme_minimal() +
  theme(legend.position = "top")


life_expectancy_summery = point_estimate(
  diff$life_expectancy,
  centrality  = c("median", "MAP", "mean")
)

tech_advanement_summery = point_estimate(
  diff$tech_advanement,
  centrality  = c("median", "MAP", "mean")
)


print(life_expectancy_summery)
print(tech_advanement_summery)

plot_life_expectancy = plot(life_expectancy_summery) +
  ggtitle("Life Expectancy Difference") +
  xlab("Difference")

plot_tech_advanement = plot(tech_advanement_summery) +
  ggtitle("Life Expectancy Increase Rate Difference") +
  xlab("Difference")


grid.arrange(plot_tech_advanement, plot_life_expectancy, nrow = 2)

p_direction_tech = p_direction(
  diff$tech_advanement,
  method = "direct",
  null = 0
)

print(p_direction_tech)

rope_tech_advanement <- rope(
  diff$tech_advanement,
  range = c(-0.1, 0.1),
  ci = c(0.5,0.8,0.95),
  ci_method = "ETI"
)


rope_life_expectancy <- rope(
  diff$life_expectancy,
  range = c(-10, 10),
  ci = c(0.5,0.8,0.95),
  ci_method = "ETI"
)


plot_tech_advanement <- plot(rope_tech_advanement, rope_color = "indianred1") +
  scale_fill_brewer(palette = "Spectral", direction = -1) +
  ggtitle("ROPE Analysis For Increase Rate Difference") +
  xlab("Difference") + 
  ylab("Density")

plot_life_expectancy <- plot(rope_life_expectancy, rope_color = "indianred1") +
  scale_fill_brewer(palette = "Spectral", direction = -1) +
  ggtitle("ROPE Analysis For Life Expectancy Difference") +
  xlab("Difference") + 
  ylab("Density")


grid.arrange(plot_tech_advanement, plot_life_expectancy, nrow = 2)


rope_life_expectancy <- rope(
  diff_2030$life_expectancy,
  range = c(-10, 10),
  ci = c(0.5,0.8,0.95),
  ci_method = "ETI"
)

life_expectancy_summery = point_estimate(
  diff_2030$life_expectancy,
  centrality  = c("median", "MAP", "mean")
)

# ***posterior predictive***
# for each type of country, sampling 1000 observations based on the posterior,
# for each year, to the years 2000-2030. 

set.seed(1234)
n = 1000

developed_posteriors <- tibble(
  .draw = 1:n,
  intercept = rnorm(n, mean(post_b0), sd(post_b0)),
  b1 = rnorm(n, mean(post_b1), sd(post_b1)),
  year_slope = rnorm(n, mean(post_b2), sd(post_b2)),
  x = list(2000:2030),
  y = Map(function(intercept, b1, year_slope) intercept + b1 * 1 + year_slope * 0:30, 
          intercept, b1, year_slope)
)%>%
  unnest(c(x, y))

developing_posteriors <- tibble(
  .draw = 1:n,
  intercept = rnorm(n, mean(post_b0), sd(post_b0)),
  b1 = rnorm(n, mean(post_b1), sd(post_b1)),
  year_slope = rnorm(n, mean(post_b3), sd(post_b3)),
  x = list(2000:2030),
  y = Map(function(intercept, b1, year_slope) intercept + b1 * 0 + year_slope * 0:30, 
          intercept, b1, year_slope)
)%>%
  unnest(c(x, y))

combined_model_posterior = rbind(
  mutate(developed_posteriors, country = "developed"),
  mutate(developing_posteriors, country = "developing")
)

plot <- combined_model_posterior %>%
  ggplot(aes(x = x, y = y, fill = country)) + 
  xlab("Year") +  
  ylab("Life Expectancy") + 
  stat_lineribbon(aes(fill_ramp = after_stat(level)))
plot + 
  scale_y_continuous(breaks = seq(55, 100, by = 5)) +
  theme_lucid()





# ******************Q3******************:

# creating binary variables indicating the region of the observed data.
# we did this in order to fit the data to the model.

data$is_africa <- ifelse(data$Region == "Africa", 1, 0)
data$is_south_america <- ifelse(data$Region == 	"South America", 1, 0)
data$is_asia <- ifelse(data$Region == "Asia", 1, 0)
data$is_Middle_East <- ifelse(data$Region == "Middle East", 1, 0)
data$youth_death_50_above <- ifelse(data$Under_five_deaths >= 50,1,0)
developing_data <- data %>% filter(Economy_status_Developing == 1)
developing_data <- data %>%
  filter(Region %in% c("South America", "Africa", "Asia", "Middle East") )



# Prepare the list for Stan
regions_data <- list(
  N = nrow(developing_data),                       
  is_africa = developing_data$is_africa,           
  is_south_america = developing_data$is_south_america,
  is_asia = developing_data$is_asia,
  is_Middle_East = developing_data$is_Middle_East,
  youth_death_50_above = developing_data$youth_death_50_above
)

# Compile Stan models
file_path_social <- file.choose()
model_regions <- stan_model(file_path_social) # choose regions stan model

# Compile and fit the model
model_regions <- sampling(
  model_regions, 
  data = regions_data,
  chains = 4,
  iter = 4000,
  warmup = 2000,
  seed = 1234)


theta <- as_draws_rvars(model_regions)$theta
rhat_basic(theta)
ess_bulk(theta)


color_scheme_set("mix-blue-red")
mcmc_trace(
  model_regions,
  pars = c("theta[1]", "theta[2]", "theta[3]", "theta[4]"),
  size = 0.5,
  facet_args = list(nrow = 4)
)

  
theta_matrix <- as_draws_matrix(theta)
colnames(theta_matrix) <- c("theta_africa", "theta_south_america", "theta_asia", "theta_middle_east")

describe_posterior(
  theta_matrix,
  centrality = "MAP",
  ci = 0.95,test = NULL,
  ci_method = "ETI",
  diagnostic = c("ESS", "Rhat")
  )


# calculating the true value of death over 5% in kids under 5 years old
# for each region. "true" value is how the variable distributes in the data.
# we then compare it to the posteriors.

mean_africa <- mean(data$youth_death_50_above[data$is_africa == 1])
mean_south_america <- mean(data$youth_death_50_above[data$is_south_america == 1])
mean_asia <- mean(data$youth_death_50_above[data$is_asia == 1])
mean_middle_east <- mean(data$youth_death_50_above[data$is_Middle_East == 1])

color_scheme_set("gray")
true <- c(mean_africa, mean_south_america, mean_asia, mean_middle_east)
mcmc_recover_intervals(sweep(theta_matrix, 2, true), rep(0, ncol(theta_matrix))) + 
  hline_0() +
  theme_minimal()


regions <- data.frame(
  region = c("Africa", "South America", "Asia", "Middle East"),
  dist = theta[1:4]
)
regions |> 
  ggplot(aes(y = region)) + 
  stat_slab(aes(xdist = theta, fill = after_stat(level)), 
            orientation = "y", alpha = 1,
            point_interval = "median_hdi",
            .width = c(0.5, 0.85, 0.9, 0.95, 1),
            color = "grey") + 
  labs(fill = "CI Level", title = "HDI / HDR For Each Region") + 
  coord_cartesian(ylim = c(1.5, 4.5))



#  PPD

set.seed(1234)
nsamples <- 8000
ps <- draws_of(theta)[1:nsamples,]
colnames(ps) <- c("Africa", "South America", "Asia", "Middle East")

grid2 <- data.frame(
  Group = sample(developing_data$Region,
  size = 1000,
  replace = TRUE))

probs_matrix <- t(ps[,grid2$Group])
obs_matrix <- matrix(
  rbinom(n = prod(dim(probs_matrix)), 
  size = 1,
  prob = as.vector(probs_matrix)),
  nrow = nrow(probs_matrix))

#Number of Times When A Country Had a Death Percentage Of Children Under 5 Year Old > 5%"
post_total <- rvar(apply(obs_matrix, 2, sum))

describe_posterior(
  post_total, 
  test = NULL, 
  centrality = "median", 
  ci_method = "eti"
  )

Pr(post_total > 500)







