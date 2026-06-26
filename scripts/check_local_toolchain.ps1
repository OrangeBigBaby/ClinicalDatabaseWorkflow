$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$external = Join-Path $root "external_projects"

$tools = @(
  "paper-framework-figure-studio-pro",
  "Visiomaster",
  "nature-skills"
)

foreach ($tool in $tools) {
  $path = Join-Path $external $tool
  if (Test-Path -LiteralPath $path) {
    Write-Output "FOUND  $tool"
  } else {
    Write-Output "MISSING $tool"
  }
}

