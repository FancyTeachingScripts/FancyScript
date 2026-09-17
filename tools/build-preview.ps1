# Compiles the same fixed PDF set that .github/workflows/pr-preview.yml
# builds on every PR, for local review before pushing. Run from a course
# repo's root (template mounted at ./template).
#
# Keep $files below in sync with the `texfile` matrix in
# .github/workflows/pr-preview.yml -- it is intentionally duplicated rather
# than shared, since GitHub Actions matrices can't source from a script
# without a separate job.
#
#   -Out DIR          output directory for the compiled PDFs (default: build)
#   -TemplateDir DIR   where the template payload lives: "template" for a
#                       course repo (default), "." for this repo itself
param(
    [string]$Out = "build",
    [string]$TemplateDir = "template"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

bash "$scriptDir/gen-main.sh" main

if (!(Test-Path $Out)) {
    New-Item -ItemType Directory -Path $Out -Force | Out-Null
}

$files = @(
    "presentation_noaufraeumen.tex",
    "presentation_noaufraeumen-bright.tex",
    "print_students-cover.tex",
    "print_solution-cover.tex"
)

$baseArgs = @("-Z", "search-path=.", "-Z", "search-path=$TemplateDir", "-Z", "search-path=$TemplateDir/sty/moloch", "-Z", "continue-on-errors")

foreach ($f in $files) {
    Write-Host "==> $f" -ForegroundColor Cyan
    & tectonic @baseArgs -o $Out "main/$f"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed compilation for $f" -ForegroundColor Red
        exit $LASTEXITCODE
    }
}
