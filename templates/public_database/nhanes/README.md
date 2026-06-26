# NHANES Public Database Templates

These templates distill a reusable NHANES manuscript-analysis workflow from completed public-database projects.

## Run Order

1. `config_example.yaml`: define project metadata, modules, variables, formulas, and output names.
2. `01_merge_clean_nhanes_template.R`: merge XPT files, derive indicators, apply inclusion criteria, and export sample flow.
3. `02_weighted_table1_template.R`: build survey-weighted baseline characteristics by outcome.
4. `03_weighted_logistic_template.R`: run survey-weighted logistic regression for continuous and quartile exposure forms.
5. `04_rcs_nonlinear_template.R`: evaluate nonlinear exposure-outcome associations.
6. `05_sensitivity_subgroup_template.R`: run staged adjustment, subgroup, and interaction analyses.
7. `06_ml_prediction_template.py`: train optional prediction models and export AUC, calibration, DCA, and importance outputs.
8. `07_shap_xgboost_template.py`: run XGBoost SHAP interpretation when ML extension is justified.

## Expected Project Structure

```text
project/
  01_protocol/
  02_data_raw/
  03_data_processed/
  04_code/
  05_results/
    tables/
    figures/
  06_manuscript/
  07_logs/
```

## Template Philosophy

- Keep raw data unchanged.
- Save every derived dataset and table.
- Preserve sample-selection counts.
- Use survey design variables when NHANES weighting is required.
- Model exposures in both continuous and quantile forms.
- Treat machine learning as an optional extension, not a replacement for epidemiologic analysis.
- Keep all claims conservative and linked to outputs.

