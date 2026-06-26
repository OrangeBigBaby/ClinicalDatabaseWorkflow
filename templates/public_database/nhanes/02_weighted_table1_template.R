# Template: survey-weighted Table 1 by outcome status.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(survey)
})

options(survey.lonely.psu = "adjust")

project_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
data_path <- file.path(project_dir, "03_data_processed", "nhanes_clean.rds")
out_dir <- file.path(project_dir, "05_results", "tables")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

dat <- readRDS(data_path) %>%
  mutate(
    outcome_f = factor(outcome, levels = c(0, 1), labels = c("No", "Yes")),
    across(c(sex, race, education, pir_group), factor),
    across(c(smoking, alcohol, hypertension, diabetes), ~ factor(.x, levels = c(0, 1), labels = c("No", "Yes"))),
    exposure_1_q = cut(exposure_1, quantile(exposure_1, seq(0, 1, 0.25), na.rm = TRUE), include.lowest = TRUE, labels = paste0("Q", 1:4)),
    exposure_2_q = cut(exposure_2, quantile(exposure_2, seq(0, 1, 0.25), na.rm = TRUE), include.lowest = TRUE, labels = paste0("Q", 1:4))
  )

design <- svydesign(
  id = ~sdmvpsu,
  strata = ~sdmvstra,
  weights = ~analysis_weight,
  nest = TRUE,
  data = dat
)

fmt_p <- function(p) ifelse(is.na(p), "", ifelse(p < 0.001, "<0.001", sprintf("%.3f", p)))
fmt_mean_sd <- function(m, s) sprintf("%.2f (%.2f)", m, s)

weighted_mean_sd <- function(var, group = NULL) {
  d <- if (is.null(group)) design else subset(design, outcome_f == group)
  f <- as.formula(paste0("~", var))
  m <- as.numeric(coef(svymean(f, d, na.rm = TRUE)))
  s <- sqrt(as.numeric(coef(svyvar(f, d, na.rm = TRUE))))
  fmt_mean_sd(m, s)
}

continuous_p <- function(var) {
  out <- tryCatch(svyttest(as.formula(paste0(var, " ~ outcome_f")), design), error = function(e) NULL)
  if (is.null(out)) NA_real_ else out$p.value
}

weighted_level <- function(var, level, group = NULL) {
  d <- if (is.null(group)) design else subset(design, outcome_f == group)
  f <- as.formula(paste0("~I(", var, " == '", level, "')"))
  pct_vec <- coef(svymean(f, d, na.rm = TRUE)) * 100
  true_idx <- grep("TRUE$", names(pct_vec))
  pct <- ifelse(length(true_idx) > 0, as.numeric(pct_vec[true_idx[1]]), 0)
  n <- if (is.null(group)) {
    sum(dat[[var]] == level, na.rm = TRUE)
  } else {
    sum(dat[[var]] == level & dat$outcome_f == group, na.rm = TRUE)
  }
  sprintf("%d (%.1f)", n, pct)
}

categorical_p <- function(var) {
  out <- tryCatch(svychisq(as.formula(paste0("~", var, " + outcome_f")), design, statistic = "F"), error = function(e) NULL)
  if (is.null(out)) NA_real_ else out$p.value
}

continuous_vars <- c("age", "exposure_1", "exposure_2", "bmi", "waist_cm", "sbp", "dbp", "glucose_mg_dl", "triglyceride_mg_dl", "hdl_mg_dl")
categorical_vars <- c("exposure_1_q", "exposure_2_q", "sex", "race", "education", "pir_group", "smoking", "alcohol", "hypertension", "diabetes")

rows <- list()
rows[[1]] <- tibble(variable = "Unweighted n", level = "", overall = as.character(nrow(dat)), no = as.character(sum(dat$outcome_f == "No")), yes = as.character(sum(dat$outcome_f == "Yes")), p_value = "")

for (var in continuous_vars) {
  rows[[length(rows) + 1]] <- tibble(
    variable = var,
    level = "",
    overall = weighted_mean_sd(var),
    no = weighted_mean_sd(var, "No"),
    yes = weighted_mean_sd(var, "Yes"),
    p_value = fmt_p(continuous_p(var))
  )
}

for (var in categorical_vars) {
  p <- fmt_p(categorical_p(var))
  for (i in seq_along(levels(dat[[var]]))) {
    lv <- levels(dat[[var]])[i]
    rows[[length(rows) + 1]] <- tibble(
      variable = ifelse(i == 1, var, ""),
      level = lv,
      overall = weighted_level(var, lv),
      no = weighted_level(var, lv, "No"),
      yes = weighted_level(var, lv, "Yes"),
      p_value = ifelse(i == 1, p, "")
    )
  }
}

write_csv(bind_rows(rows), file.path(out_dir, "table1_weighted_by_outcome.csv"))

