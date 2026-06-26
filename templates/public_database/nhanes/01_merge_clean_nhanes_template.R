# Template: merge and clean multi-cycle NHANES data.

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(haven)
  library(readr)
})

project_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
raw_dir <- file.path(project_dir, "02_data_raw")
processed_dir <- file.path(project_dir, "03_data_processed")
table_dir <- file.path(project_dir, "05_results", "tables")
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)

cycles <- tibble::tribble(
  ~cycle,      ~suffix,
  "2003-2004", "C",
  "2005-2006", "D",
  "2007-2008", "E",
  "2009-2010", "F",
  "2011-2012", "G",
  "2013-2014", "H",
  "2015-2016", "I",
  "2017-2018", "J"
)

read_xpt_select <- function(module, suffix, vars) {
  path <- file.path(raw_dir, paste0(module, "_", suffix, ".XPT"))
  if (!file.exists(path)) {
    stop("Missing XPT file: ", path, call. = FALSE)
  }
  dat <- haven::read_xpt(path)
  missing_vars <- setdiff(vars, names(dat))
  for (var in missing_vars) dat[[var]] <- NA_real_
  dat %>%
    select(all_of(vars)) %>%
    mutate(across(where(is.numeric), ~ ifelse(abs(.x) < 1e-12, NA_real_, .x)))
}

yes_no <- function(x) {
  case_when(
    x == 1 ~ 1L,
    x == 2 ~ 0L,
    TRUE ~ NA_integer_
  )
}

race_group <- function(x) {
  case_when(
    x == 1 ~ "Mexican American",
    x == 2 ~ "Other Hispanic",
    x == 3 ~ "Non-Hispanic White",
    x == 4 ~ "Non-Hispanic Black",
    x == 5 ~ "Other Race",
    TRUE ~ NA_character_
  )
}

education_group <- function(x) {
  case_when(
    x %in% c(1, 2) ~ "Low",
    x == 3 ~ "Medium",
    x %in% c(4, 5) ~ "High",
    TRUE ~ NA_character_
  )
}

pir_group <- function(x) {
  case_when(
    is.na(x) ~ NA_character_,
    x < 1.4 ~ "<1.4",
    x < 3.5 ~ "1.4-3.5",
    TRUE ~ ">=3.5"
  )
}

bp_mean <- function(df, prefix) {
  cols <- intersect(paste0(prefix, 1:4), names(df))
  vals <- df[, cols, drop = FALSE]
  vals[abs(vals) < 1e-12] <- NA
  out <- rowMeans(vals, na.rm = TRUE)
  ifelse(is.nan(out), NA_real_, out)
}

derive_exposures <- function(df) {
  df %>%
    mutate(
      # Replace formulas after verifying units and source variables.
      triglyceride_mmol_l = triglyceride_mg_dl * 0.01129,
      hdl_mmol_l = hdl_mg_dl * 0.02586,
      exposure_1 = if_else(
        triglyceride_mmol_l > 0 & hdl_mmol_l > 0,
        log10(triglyceride_mmol_l / hdl_mmol_l),
        NA_real_
      ),
      exposure_2 = if_else(
        hdl_mg_dl > 0 & height_cm > 0,
        (triglyceride_mg_dl / hdl_mg_dl) * (waist_cm / height_cm),
        NA_real_
      )
    )
}

merge_one_cycle <- function(cycle, suffix) {
  demo <- read_xpt_select(
    "DEMO", suffix,
    c("SEQN", "SDDSRVYR", "WTMEC2YR", "SDMVSTRA", "SDMVPSU",
      "RIDAGEYR", "RIAGENDR", "RIDRETH1", "DMDEDUC2", "INDFMPIR")
  )
  mcq <- read_xpt_select("MCQ", suffix, c("SEQN", "MCQ160F"))
  bmx <- read_xpt_select("BMX", suffix, c("SEQN", "BMXBMI", "BMXWAIST", "BMXHT"))
  bpx_raw <- read_xpt_select("BPX", suffix, c("SEQN", paste0("BPXSY", 1:4), paste0("BPXDI", 1:4)))
  bpx <- bpx_raw %>%
    mutate(sbp = bp_mean(bpx_raw, "BPXSY"), dbp = bp_mean(bpx_raw, "BPXDI")) %>%
    select(SEQN, sbp, dbp)
  bpq <- read_xpt_select("BPQ", suffix, c("SEQN", "BPQ020"))
  diq <- read_xpt_select("DIQ", suffix, c("SEQN", "DIQ010"))
  smq <- read_xpt_select("SMQ", suffix, c("SEQN", "SMQ020"))
  alq <- read_xpt_select("ALQ", suffix, c("SEQN", "ALQ101", "ALQ111"))
  glu <- read_xpt_select("GLU", suffix, c("SEQN", "WTSAF2YR", "LBXGLU"))
  trigly <- read_xpt_select("TRIGLY", suffix, c("SEQN", "WTSAF2YR", "LBXTR"))
  hdl <- read_xpt_select("HDL", suffix, c("SEQN", "LBDHDD", "LBXHDD")) %>%
    mutate(hdl_mg_dl = coalesce(LBDHDD, LBXHDD)) %>%
    select(SEQN, hdl_mg_dl)

  list(demo, mcq, bmx, bpx, bpq, diq, smq, alq, glu, trigly, hdl) %>%
    reduce(full_join, by = "SEQN") %>%
    mutate(
      cycle = cycle,
      fasting_weight_2yr = coalesce(WTSAF2YR.x, WTSAF2YR.y),
      analysis_weight = fasting_weight_2yr / nrow(cycles)
    ) %>%
    transmute(
      seqn = SEQN,
      cycle = cycle,
      age = RIDAGEYR,
      sex = factor(RIAGENDR, levels = c(1, 2), labels = c("Male", "Female")),
      race = race_group(RIDRETH1),
      education = education_group(DMDEDUC2),
      pir = INDFMPIR,
      pir_group = pir_group(INDFMPIR),
      sdmvstra = SDMVSTRA,
      sdmvpsu = SDMVPSU,
      analysis_weight = analysis_weight,
      outcome = yes_no(MCQ160F),
      bmi = BMXBMI,
      waist_cm = BMXWAIST,
      height_cm = BMXHT,
      sbp = sbp,
      dbp = dbp,
      hypertension = yes_no(BPQ020),
      diabetes = case_when(DIQ010 == 1 ~ 1L, DIQ010 %in% c(2, 3) ~ 0L, TRUE ~ NA_integer_),
      smoking = yes_no(SMQ020),
      alcohol = yes_no(coalesce(ALQ101, ALQ111)),
      glucose_mg_dl = LBXGLU,
      triglyceride_mg_dl = LBXTR,
      hdl_mg_dl = hdl_mg_dl
    ) %>%
    derive_exposures()
}

nhanes_all <- pmap_dfr(cycles, merge_one_cycle)

key_vars <- c(
  "age", "outcome", "exposure_1", "exposure_2", "analysis_weight",
  "sdmvstra", "sdmvpsu", "sex", "race", "education", "pir_group",
  "smoking", "alcohol", "hypertension", "diabetes", "bmi", "sbp", "dbp"
)

eligible <- nhanes_all %>% filter(age >= 45)
analysis_minimal <- eligible %>%
  filter(!is.na(outcome), !is.na(exposure_1), !is.na(exposure_2), analysis_weight > 0)
complete_case <- analysis_minimal %>% filter(if_all(all_of(key_vars), ~ !is.na(.x)))

flow <- tibble::tibble(
  step = c(
    "Merged NHANES participants",
    "Age criterion",
    "Non-missing outcome, exposures, and weight",
    "Complete key covariates"
  ),
  n = c(nrow(nhanes_all), nrow(eligible), nrow(analysis_minimal), nrow(complete_case))
) %>%
  mutate(excluded_from_previous = lag(n, default = first(n)) - n)

saveRDS(complete_case, file.path(processed_dir, "nhanes_clean.rds"))
write_csv(complete_case, file.path(processed_dir, "nhanes_clean.csv"))
write_csv(flow, file.path(table_dir, "sample_selection_flow.csv"))

