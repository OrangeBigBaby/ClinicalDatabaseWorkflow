# Clinical Database Workflow

This document defines the structured workflow and the visible outputs produced at each stage.

## Stage 1: Question Intake

Purpose:

- convert a broad clinical idea into a searchable, analyzable research question

Inputs:

- disease or clinical population
- exposure, indicator, biomarker, risk score, or model target
- candidate outcome
- candidate database
- preferred study design

Tool actions:

- standardize terms
- define population, exposure, comparator, outcome, and database scope
- create a project slug

Outputs:

- project brief
- terminology list

Gate:

- the question must be specific enough for literature search and database feasibility review

## Stage 2: Evidence Mapping

Purpose:

- determine what has already been studied and where evidence gaps remain

Tool actions:

- search literature sources
- extract disease, indicator, outcome, database, method, and study design
- mark full-text availability
- create a topic matrix

Outputs:

- `evidence_brief.md`
- `topic_matrix.csv`
- missing full-text list

Gate:

- no novelty claim is allowed unless the search strategy and topic matrix support it

## Stage 3: Database Feasibility

Purpose:

- determine whether the candidate database can support the clinical question

Tool actions:

- map cohort fields
- map exposure and outcome variables
- map covariates
- identify missingness, temporal-order, and selection-bias risks

Outputs:

- `database_feasibility.md`

Gate:

- the workflow must flag infeasible variables before analysis or writing begins

## Stage 4: Analysis Contract

Purpose:

- define exactly which analysis outputs are required before manuscript writing

Tool actions:

- specify baseline table requirements
- specify primary model outputs
- specify sensitivity and subgroup analyses
- specify optional machine-learning evaluation only when justified

Outputs:

- `analysis_contract.md`

Gate:

- each planned result must map to a future manuscript claim or figure/table

## Stage 5: Figure And Flowchart Specification

Purpose:

- turn the study logic into editable visual specifications

Tool actions:

- sketch the manuscript framework figure
- define participant-selection flowchart nodes and exclusion counts
- define analysis pipeline figure panels
- preserve editability through structured figure specifications

Outputs:

- `figure_specs/participant_selection_flowchart.yaml`
- `figure_specs/manuscript_framework.yaml`

Gate:

- figure specifications must be editable and traceable to the study design

## Stage 6: Manuscript Shell

Purpose:

- build a writing-ready manuscript structure without inventing results

Tool actions:

- generate title options
- write the one-sentence argument
- build section-level outline
- build claim-evidence map
- place placeholders where evidence is missing

Outputs:

- `manuscript_shell.md`

Gate:

- every major claim must be supported, inferred with caution, or marked as needing evidence

## Stage 7: Review Gate

Purpose:

- prevent overclaiming and reviewer-visible scientific weaknesses

Tool actions:

- check unsupported claims
- verify citation status
- check causal language
- check model-leakage risk
- check reporting-guideline fit
- check conservative limitation wording

Outputs:

- `review_gate.md`

Gate:

- unresolved red flags must remain visible in the output rather than being hidden in polished prose

## References And Local Dependencies

The workflow can use local copies of external projects for figure ideation, editable diagram generation, and scientific writing support. These dependencies live under `external_projects/` and are not committed to the public repository.

