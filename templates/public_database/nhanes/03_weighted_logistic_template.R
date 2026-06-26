# Template: survey-weighted logistic regression for continuous and quantile exposures.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(survey)
  library(broom)
})

options(survey.lonely.psu = "adjust")

project_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
data_path <- file.path(project_dir, "03_data_processed", "nhanes_clean.rds")
out_dir <- file.path(project_dir, "05_results", "tables")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

dat <- readRDS(data_path) %>%
  mutate(
    outcome = as.integer(outcome),
    across(c(sex, race, education, pir_group), factor),
    across(c(smoking, alcohol, hypertension, diabetes), ~ factor(.x, levels = c(0, 1), labels = c("No", "Yes"))),
    exposure_1_z = as.numeric(scale(exposure_1)),
    exposure_2_z = as.numeric(scale(exposure_2)),
    exposure_1_q = cut(exposure_1, quantile(exposure_1, seq(0, 1, 0.25), na.rm = TRUE), include.lowest = TRUE, labels = paste0("Q", 1:4)),
    exposure_2_q = cut(exposure_2, quantile(exposure_2, seq(0, 1, 0.25), na.rm = TRUE), include.lowest = TRUE, labels = paste0("Q", 1:4))
  )

design <- svydesign(id = ~sdmvpsu, strata = ~sdmvstra, weights = ~analysis_weight, nest = TRUE, data = dat)

fmt_p <- function(p) ifelse(is.na(p), "", ifelse(p < 0.001, "<0.001", sprintf("%.3f", p)))

tidy_or <- function(model, exposure_label, exposure_pattern, model_label) {
  broom::tidy(model, conf.int = TRUE) %>%
    filter(grepl(exposure_pattern, term)) %>%
    transmute(
      exposure = exposure_label,
      model = model_label,
      term = term,
      OR = exp(estimate),
      CI_lower = exp(conf.low),
      CI_upper = exp(conf.high),
      p_value = p.value,
      OR_95CI = sprintf("%.3f (%.3f, %.3f)", OR, CI_lower, CI_upper),
      p_value_fmt = fmt_p(p_value)
    )
}

run_models <- function(exposure, exposure_label, exposure_pattern) {
  model_sets <- list(
    "Model 1: crude" = "",
    "Model 2: demographic" = "age + sex + race",
    "Model 3: fully adjusted" = "age + sex + race + education + pir_group + smoking + alcohol + hypertension + diabetes + bmi + sbp + dbp"
  )

  bind_rows(lapply(names(model_sets), function(model_name) {
    covars <- model_sets[[model_name]]
    rhs <- paste(c(exposure, covars[covars != ""]), collapse = " + ")
    fit <- svyglm(as.formula(paste("outcome ~", rhs)), design = design, family = quasibinomial())
    tidy_or(fit, exposure_label, exposure_pattern, model_name)
  }))
}

continuous_results <- bind_rows(
  run_models("exposure_1_z", "Exposure 1 per SD", "^exposure_1_z$"),
  run_models("exposure_2_z", "Exposure 2 per SD", "^exposure_2_z$")
)

quartile_results <- bind_rows(
  run_models("exposure_1_q", "Exposure 1 quartiles", "^exposure_1_q"),
  run_models("exposure_2_q", "Exposure 2 quartiles", "^exposure_2_q")
)

write_csv(continuous_results, file.path(out_dir, "weighted_logistic_continuous.csv"))
write_csv(quartile_results, file.path(out_dir, "weighted_logistic_quartiles.csv"))
write_csv(bind_rows(continuous_results, quartile_results), file.path(out_dir, "weighted_logistic_all.csv"))

