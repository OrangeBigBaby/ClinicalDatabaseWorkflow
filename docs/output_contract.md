# Output Contract

Each workflow run should produce a compact result package.

## Required Files

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

## Claim-Evidence Rule

Every major claim must be represented as:

```text
Claim: ...
Evidence: ...
Status: supported | needs evidence | inferred
Source: PMID/DOI/database output/user-provided result
```

## Conservative Language Rule

Use:

- `is associated with` for observational associations
- `suggests` or `indicates` for indirect evidence
- `may` or `could` for plausible explanations

Avoid:

- `proves`
- `causes`
- `first ever`
- `comprehensive`
- `unprecedented`

