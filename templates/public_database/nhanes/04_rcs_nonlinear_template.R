# Template: restricted cubic spline analysis for survey-weighted logistic models.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(survey)
  library(splines)
  library(ggplot2)
})

options(survey.lonely.psu = "adjust")

project_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
data_path <- file.path(project_dir, "03_data_processed", "nhanes_clean.rds")
table_dir <- file.path(project_dir, "05_results", "tables")
figure_dir <- file.path(project_dir, "05_results", "figures")
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

dat <- readRDS(data_path) %>%
  mutate(
    outcome = as.integer(outcome),
    across(c(sex, race, education, pir_group), factor),
    across(c(smoking, alcohol, hypertension, diabetes), ~ factor(.x, levels = c(0, 1), labels = c("No", "Yes")))
  )

design <- svydesign(id = ~sdmvpsu, strata = ~sdmvstra, weights = ~analysis_weight, nest = TRUE, data = dat)
covariates <- c("age", "sex", "race", "education", "pir_group", "smoking", "alcohol", "hypertension", "diabetes", "bmi", "sbp", "dbp")

weighted_mode <- function(x, w) {
  ok <- !is.na(x) & !is.na(w)
  tab <- tapply(w[ok], x[ok], sum)
  names(tab)[which.max(tab)]
}

make_reference_data <- function(exposure, grid_values) {
  ref <- data.frame(matrix(nrow = length(grid_values), ncol = 0))
  ref[[exposure]] <- grid_values
  w <- dat$analysis_weight
  for (v in covariates) {
    if (is.factor(dat[[v]])) {
      ref[[v]] <- factor(weighted_mode(dat[[v]], w), levels = levels(dat[[v]]))
    } else {
      ref[[v]] <- weighted.mean(dat[[v]], w, na.rm = TRUE)
    }
  }
  ref
}

predict_or_curve <- function(model, exposure, grid_values, ref_value) {
  newdata <- make_reference_data(exposure, grid_values)
  refdata <- make_reference_data(exposure, ref_value)
  tt <- delete.response(terms(model))
  x_grid <- model.matrix(tt, newdata)
  x_ref <- model.matrix(tt, refdata)
  beta <- coef(model)
  vc <- vcov(model)
  common <- intersect(colnames(x_grid), names(beta))
  diff_x <- sweep(x_grid[, common, drop = FALSE], 2, as.numeric(x_ref[1, common]), "-")
  beta <- beta[common]
  vc <- vc[common, common, drop = FALSE]
  eta <- as.numeric(diff_x %*% beta)
  se <- sqrt(rowSums((diff_x %*% vc) * diff_x))
  tibble(value = grid_values, OR = exp(eta), CI_lower = exp(eta - 1.96 * se), CI_upper = exp(eta + 1.96 * se))
}

run_rcs <- function(exposure, label) {
  knots <- as.numeric(quantile(dat[[exposure]], c(0.05, 0.35, 0.65, 0.95), na.rm = TRUE))
  boundary <- range(dat[[exposure]], na.rm = TRUE)
  grid <- seq(quantile(dat[[exposure]], 0.01, na.rm = TRUE), quantile(dat[[exposure]], 0.99, na.rm = TRUE), length.out = 200)
  ref_value <- as.numeric(quantile(dat[[exposure]], 0.50, na.rm = TRUE))
  spline_expr <- paste0("ns(", exposure, ", knots = c(", paste(knots[2:3], collapse = ","), "), Boundary.knots = c(", paste(boundary, collapse = ","), "))")
  formula <- as.formula(paste("outcome ~", spline_expr, "+", paste(covariates, collapse = " + ")))
  fit <- svyglm(formula, design = design, family = quasibinomial())
  curve <- predict_or_curve(fit, exposure, grid, ref_value) %>% mutate(exposure = label, reference_value = ref_value)

  write_csv(curve, file.path(table_dir, paste0("rcs_curve_", exposure, ".csv")))
  p <- ggplot(curve, aes(value, OR)) +
    geom_ribbon(aes(ymin = CI_lower, ymax = CI_upper), alpha = 0.25) +
    geom_line(linewidth = 0.9) +
    geom_hline(yintercept = 1, linetype = "dashed") +
    geom_vline(xintercept = ref_value, linetype = "dotted") +
    labs(x = label, y = "Odds ratio", title = paste("Restricted cubic spline:", label)) +
    theme_classic(base_size = 12)
  ggsave(file.path(figure_dir, paste0("rcs_", exposure, ".png")), p, width = 7, height = 5, dpi = 300)
}

run_rcs("exposure_1", "Exposure 1")
run_rcs("exposure_2", "Exposure 2")

