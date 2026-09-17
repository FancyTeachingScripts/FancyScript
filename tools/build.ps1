# Build a single .tex file (default: main.tex) with the shared template
# mounted as a submodule at ./template. Run from a course repo's root.
# PowerShell counterpart to build.sh -- see that file for the rationale
# behind --draft and the per-page build-time note.
#
#   -Draft   single TeX pass: cross-references, TOC and beamer navigation
#            are NOT converged (page count can be off by one). Use for a
#            quick look while iterating, not for anything you publish.
param(
    [string]$File = "main.tex",
    [string]$Out = "build",
    [switch]$Draft
)

$ErrorActionPreference = "Stop"

if (!(Test-Path $Out)) {
    New-Item -ItemType Directory -Path $Out -Force | Out-Null
}

$baseArgs = @("-Z", "search-path=.", "-Z", "search-path=template", "-Z", "search-path=template/sty/moloch", "-Z", "continue-on-errors")
if ($Draft) { $baseArgs += @("-r", "0") }

& tectonic @baseArgs -o $Out $File
