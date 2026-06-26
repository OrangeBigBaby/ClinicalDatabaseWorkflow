# Template: sensitivity, subgroup, and interaction analyses.

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
    age_group = cut(age, c(45, 60, 75, Inf), right = FALSE, labels = c("45-59", "60-74", ">=75")),
    across(c(sex, race, education, pir_group, age_group), factor),
    across(c(smoking, alcohol, hypertension, diabetes), ~ factor(.x, levels = c(0, 1), labels = c("No", "Yes"))),
    exposure_1_z = as.numeric(scale(exposure_1)),
    exposure_2_z = as.numeric(scale(exposure_2))
  )

design <- svydesign(id = ~sdmvpsu, strata = ~sdmvstra, weights = ~analysis_weight, nest = TRUE, data = dat)

fmt_p <- function(p) ifelse(is.na(p), "", ifelse(p < 0.001, "<0.001", sprintf("%.3f", p)))
tidy_or <- function(model, exposure, label, model_name) {
  broom::tidy(model, conf.int = TRUE) %>%
    filter(term == exposure) %>%
    transmute(exposure = label, model = model_name, OR = exp(estimate), CI_lower = exp(conf.low), CI_upper = exp(conf.high), p_value = p.value, OR_95CI = sprintf("%.3f (%.3f, %.3f)", OR, CI_lower, CI_upper), p_value_fmt = fmt_p(p_value))
}

model_sets <- list(
  "S1 demographic" = "age + sex + race",
  "S2 demographic + socioeconomic + lifestyle" = "age + sex + race + education + pir_group + smoking + alcohol",
  "S3 S2 + comorbidities" = "age + sex + race + education + pir_group + smoking + alcohol + hypertension + diabetes",
  "S4 full clinical" = "age + sex + race + education + pir_group + smoking + alcohol + hypertension + diabetes + bmi + sbp + dbp"
)

run_sensitivity <- function(exposure, label) {
  bind_rows(lapply(names(model_sets), function(model_name) {
    fit <- svyglm(as.formula(paste("outcome ~", exposure, "+", model_sets[[model_name]])), design = design, family = quasibinomial())
    tidy_or(fit, exposure, label, model_name)
  }))
}

sensitivity <- bind_rows(
  run_sensitivity("exposure_1_z", "Exposure 1 per SD"),
  run_sensitivity("exposure_2_z", "Exposure 2 per SD")
)
write_csv(sensitivity, file.path(out_dir, "sensitivity_models.csv"))

subgroup_vars <- c("sex", "age_group", "race", "hypertension", "diabetes", "smoking")
base_covars <- c("age", "sex", "race", "education", "pir_group", "smoking", "alcohol", "hypertension", "diabetes", "bmi", "sbp", "dbp")
exclude_map <- list(sex = "sex", age_group = "age", race = "race", hypertension = "hypertension", diabetes = "diabetes", smoking = "smoking")

run_subgroup <- function(exposure, label, subgroup_var) {
  bind_rows(lapply(levels(dat[[subgroup_var]]), function(lv) {
    sub <- dat %>% filter(.data[[subgroup_var]] == lv)
    if (nrow(sub) < 100 || sum(sub$outcome == 1, na.rm = TRUE) < 10) {
      return(tibble(exposure = label, subgroup = subgroup_var, level = lv, n = nrow(sub), events = sum(sub$outcome == 1, na.rm = TRUE), OR = NA_real_, CI_lower = NA_real_, CI_upper = NA_real_, p_value = NA_real_, note = "Skipped: low n or events"))
    }
    sub_design <- subset(design, dat[[subgroup_var]] == lv)
    covars <- setdiff(base_covars, exclude_map[[subgroup_var]])
    fit <- svyglm(as.formula(paste("outcome ~", exposure, "+", paste(covars, collapse = " + "))), design = sub_design, family = quasibinomial())
    tidy_or(fit, exposure, label, subgroup_var) %>% mutate(subgroup = subgroup_var, level = lv, n = nrow(sub), events = sum(sub$outcome == 1, na.rm = TRUE), note = "")
  }))
}

subgroups <- bind_rows(lapply(subgroup_vars, function(sg) {
  bind_rows(
    run_subgroup("exposure_1_z", "Exposure 1 per SD", sg),
    run_subgroup("exposure_2_z", "Exposure 2 per SD", sg)
  )
}))
write_csv(subgroups, file.path(out_dir, "subgroup_models.csv"))

