# ClinicalDatabaseWorkflow

ClinicalDatabaseWorkflow is a clinical database research workflow for turning verified literature, reproducible database analyses, and conservative clinical interpretation into manuscript-ready outputs.

The public repository shows the product-facing workflow, output contracts, and example deliverables. Local research plans, private prompts, downloaded papers, third-party tool repositories, and manuscript drafts are intentionally ignored.

## What It Produces

- topic evidence brief
- literature coverage table
- database feasibility table
- claim-evidence map
- participant-selection flowchart specification
- manuscript outline
- conservative review checklist
- LaTeX-ready manuscript shell
- DOCX-ready manuscript shell

## Workflow

```text
Clinical question
  -> literature evidence brief
  -> database feasibility check
  -> analysis output contract
  -> figure and flowchart specification
  -> manuscript-ready structure
  -> conservative scientific review
```

## Local Toolchain

The workflow can use local figure and writing tools when they are available under `external_projects/`.

Expected local folders:

```text
external_projects/
  paper-framework-figure-studio-pro/
  Visiomaster/
  nature-skills/
```

These folders are not committed because they are third-party repositories and local working dependencies.

## Repository Layout

```text
docs/
  output_contract.md
  workflow.md
examples/
  product_result_brief.md
schemas/
  topic_matrix.csv
  workflow_manifest.yaml
templates/
  manuscript_shell.md
scripts/
  check_local_toolchain.ps1
```

## Boundary

The workflow is designed to support research organization and manuscript preparation. It does not invent data, citations, statistical results, or clinical conclusions. Every claim should remain linked to a verified source, database output, or explicit author-provided result.

