# ClinicalDatabaseWorkflow

ClinicalDatabaseWorkflow is a structured clinical database research workflow for converting a clinical question into manuscript-ready evidence, analysis specifications, figures, and conservative scientific writing outputs.

The public repository presents the workflow product and its visible deliverables. Local research plans, private prompts, downloaded full texts, third-party tool repositories, private data, generated manuscripts, and draft figures are intentionally ignored.

## Product Value

ClinicalDatabaseWorkflow is built for high-throughput public-database manuscript production.

- **Public-database first**: converts NHANES, CHARLS, GBD, MIMIC/eICU, SEER, and similar public datasets into a repeatable manuscript workflow.
- **Topic-to-output chain**: connects literature mapping, database feasibility, statistical analysis, figure planning, manuscript structure, and review gates.
- **Reusable analysis templates**: provides prebuilt NHANES templates for cohort construction, sample-selection flow, weighted Table 1, survey-weighted regression, RCS, sensitivity analysis, subgroup analysis, machine learning, and SHAP interpretation.
- **Reviewer-aware outputs**: keeps every manuscript claim tied to evidence, model output, or a visible placeholder.
- **Private strategy separation**: keeps local plans, downloaded papers, private datasets, third-party repositories, and draft manuscripts outside the public repository.

## Public Database Module

The first reusable module is the NHANES public-database module. It packages a repeatable analysis path for cross-sectional association and optional prediction-model studies:

```text
raw XPT files
  -> merged analytic cohort
  -> sample-selection flow
  -> weighted Table 1
  -> weighted logistic models
  -> RCS nonlinear analysis
  -> sensitivity and subgroup analyses
  -> optional ML and SHAP outputs
  -> manuscript shell and review gate
```

Template entry point:

```text
templates/public_database/nhanes/
```

## Output Package

Each workflow run is organized around a compact result package:

```text
outputs/<project_slug>/
  evidence_brief.md
  topic_matrix.csv
  database_feasibility.md
  analysis_contract.md
  figure_specs/
    participant_selection_flowchart.yaml
    manuscript_framework.yaml
  manuscript_shell.md
  review_gate.md
```

## Structured Workflow

| Stage | Purpose | Tool Action | Public Output |
|---|---|---|---|
| 1. Question intake | Convert a clinical idea into a searchable question | Normalize disease, exposure, outcome, population, database, and study type | project brief |
| 2. Evidence mapping | Identify what has already been studied | Search literature, extract disease-indicator-database-method combinations, and flag missing full texts | evidence brief, topic matrix |
| 3. Database feasibility | Check whether the question can be answered with available variables | Map exposure, outcome, covariates, cohort rules, missingness, and bias risks | database feasibility report |
| 4. Analysis contract | Define what analysis outputs must exist before writing | Specify baseline tables, primary models, sensitivity analyses, subgroup analyses, and optional prediction outputs | analysis contract |
| 5. Figure planning | Turn the analysis story into editable visual specifications | Draft framework figures, participant-selection flowcharts, and analysis pipeline diagrams as structured specs | figure specification files |
| 6. Manuscript shell | Build a writing-ready structure without inventing results | Generate title options, one-sentence argument, section outline, and claim-evidence map | manuscript shell |
| 7. Review gate | Prevent overclaiming before manuscript expansion | Check unsupported claims, causal language, citation status, reporting guideline fit, and model-leakage risk | review gate report |

## Tool Use

The workflow treats tools as local execution helpers rather than public-facing content.

### Literature and Evidence Tools

Used to:

- run literature searches from the clinical question
- classify prior studies by disease, indicator, database, method, and outcome
- mark whether full text is available
- produce a topic matrix for novelty and feasibility review

### Figure and Flowchart Tools

Used to:

- sketch manuscript framework figures from the analysis story
- rebuild those figures into editable diagram specifications
- generate participant-selection flowchart specifications for public clinical databases
- preserve figure structure so later edits remain reproducible

### Writing and Review Tools

Used to:

- build a one-sentence argument before drafting
- maintain a claim-evidence map
- keep terminology consistent
- polish wording while keeping clinical claims conservative
- check whether the manuscript shell matches the selected reporting guideline

## Repository Layout

```text
docs/
  output_contract.md
  public_database_product.md
  workflow.md
examples/
  product_result_brief.md
schemas/
  topic_matrix.csv
  workflow_manifest.yaml
templates/
  manuscript_shell.md
  public_database/
    nhanes/
scripts/
  check_local_toolchain.ps1
```

## Local-Only Files

These folders are intentionally excluded from Git:

```text
external_projects/
local_private_plan/
input_papers/
private_data/
outputs/
manuscripts/
figures/generated/
```

## Scientific Boundary

ClinicalDatabaseWorkflow supports research organization and manuscript preparation. It does not invent data, citations, statistical results, or clinical conclusions. Every major claim should remain linked to a verified source, a database output, or an explicit author-provided result.

## References And Local Dependencies

When available locally, the workflow can interoperate with the following external projects:

- `paper-framework-figure-studio-pro`: framework figure ideation
- `Visiomaster`: editable figure reconstruction and flowchart rendering
- `nature-skills`: scientific writing, polishing, citation, and figure-style references

Expected local folder layout:

```text
external_projects/
  paper-framework-figure-studio-pro/
  Visiomaster/
  nature-skills/
```
