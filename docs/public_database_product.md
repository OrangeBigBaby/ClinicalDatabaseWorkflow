# Public Database Product Module

ClinicalDatabaseWorkflow is designed around public clinical databases where the same manuscript pipeline can be reused across different diseases, indicators, and outcomes.

## Selling Points

| Product Capability | What It Solves | Visible Output |
|---|---|---|
| Literature-to-database matching | Avoids choosing topics already saturated in the same database | evidence brief, topic matrix |
| Database feasibility gate | Prevents writing topics whose exposure, outcome, or covariates cannot be measured | database feasibility report |
| Public-database cohort builder | Standardizes inclusion/exclusion and sample-selection flow | participant flow table |
| Weighted epidemiology templates | Handles complex survey designs and common public-database statistics | Table 1, weighted regression tables |
| Nonlinear and robustness layer | Adds reviewer-facing depth beyond a simple association table | RCS, sensitivity, subgroup outputs |
| Prediction-model extension | Adds machine-learning outputs only when useful | AUC, calibration, DCA, feature importance |
| Explainability layer | Converts ML outputs into interpretable manuscript material | SHAP summary and figures |
| Conservative review gate | Reduces overclaiming before manuscript drafting | claim-evidence and review-gate files |

## Distilled NHANES Workflow Pattern

Two completed NHANES analysis workflows were distilled into the reusable pattern below.

1. Define a public-database clinical question.
2. Create a variable dictionary for demographics, outcome, exposures, covariates, weights, strata, and PSU.
3. Download or stage XPT files by cycle.
4. Merge modules by participant identifier.
5. Derive indicators using transparent formulas and unit conversions.
6. Apply inclusion/exclusion rules and export a sample-selection flow table.
7. Build the complex survey design object.
8. Generate weighted Table 1 by outcome status.
9. Run survey-weighted logistic models for continuous and quantile exposure forms.
10. Run RCS nonlinear analysis.
11. Run sensitivity models with staged covariate adjustment.
12. Run subgroup and interaction analyses.
13. Run ROC and optional machine-learning evaluation.
14. Run SHAP or feature-importance analysis when ML is justified.
15. Export manuscript shells, figure specifications, and review-gate files.

## Template Location

Reusable templates are available under:

```text
templates/public_database/nhanes/
```

These templates are intentionally generic. Users should replace placeholder variables and formulas with database-verified definitions before analysis.

