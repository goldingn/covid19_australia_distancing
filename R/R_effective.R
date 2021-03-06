# fit a Bayesian model-based estimate of R_effective over time, quantifying the
# impacts of both quarantine and physical distancing measures.

set.seed(2020-04-29)
source("R/functions.R")

# sync up the case data
sync_nndss()

# prepare data for Reff modelling
data <- reff_model_data()

data$dates$linelist

# save the key dates for Freya and David to read in, and tabulated local cases
# data for the Robs
write_reff_key_dates(data)
write_local_cases(data)

# format and write out any new linelists to the past_cases folder for Rob H
update_past_cases()

# define the model (and greta arrays) for Reff, and sample until convergence
fitted_model <- fit_reff_model(data)

# save the fitted model object
saveRDS(fitted_model, "outputs/fitted_reff_model.RDS")
# fitted_model <- readRDS("outputs/fitted_reff_model.RDS")

# output Reff trajectory draws for Rob M
write_reff_sims(fitted_model, dir = "outputs/projection")
  
# visual checks of model fit
plot_reff_checks(fitted_model)

# do plots for main period
reff_plotting(fitted_model, dir = "outputs")

# and for projected part
reff_plotting(fitted_model,
              dir = "outputs/projection",
              max_date = fitted_model$data$dates$latest_project,
              mobility_extrapolation_rectangle = FALSE,
              projection_date = fitted_model$data$dates$latest_mobility)

# model C1 under UK strain, under two modelled estimates of relative transmissability

# Imperial estimate with a long GI (6.5 days); 50-75%. Assuming centred at 62.5%.
imperial_fitted_model <- multiply_reff(fitted_model, 1.625, c(1.5, 1.75))
imperial_dir <- "outputs/projection/b117_imperial_long"
dir.create(imperial_dir, showWarnings = FALSE)
write_reff_sims(imperial_fitted_model, imperial_dir)

# LSHTM estimate with a short GI (mean 3.6); 31% (27%-34%)
lshtm_fitted_model <- multiply_reff(fitted_model, 1.31, c(1.27, 1.34))
lshtm_dir <- "outputs/projection/b117_lshtm_short"
dir.create(lshtm_dir, showWarnings = FALSE)
write_reff_sims(lshtm_fitted_model, lshtm_dir)

read_csv("outputs/projection/b117_lshtm_short/r_eff_1_local_samples.csv") %>%
  filter(date == as.Date("2020-04-11")) %>%
  pivot_longer(
    cols = starts_with("sim"),
    names_to = "sim"
  ) %>%
  group_by(state, date) %>%
  summarise(
    mean = mean(value),
    lower = quantile(value, 0.05),
    upper = quantile(value, 0.95)
  )

  
