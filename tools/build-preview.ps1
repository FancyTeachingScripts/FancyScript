# Compiles the same fixed PDF set that .github/workflows/pr-preview.yml
# builds on every PR, for local review before pushing. Run from a course
# repo's root (template mounted at ./template).
#
# Keep $files below in sync with the `texfile` matrix in
# .github/workflows/pr-preview.yml -- it is intentionally duplicated rather
# than shared, since GitHub Actions matrices can't source from a script
# without a separate job.
#
#   -Out DIR           output directory for the compiled PDFs (default: build)
#   -TemplateDir DIR    where the template payload lives: "template" for a
#                       course repo (default), "." for this repo itself
#
# Only these 4 driver files are generated (not the full 60-file option x
# theme matrix -- see gen-main.sh), built in parallel, and removed again
# once the build finishes, so this doesn't leave anything behind in main\.
param(
    [string]$Out = "build",
    [string]$TemplateDir = "template"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$files = @(
    "presentation_noaufraeumen.tex",
    "presentation_noaufraeumen-bright.tex",
    "print_students-cover.tex",
    "print_solution-cover.tex"
)

bash "$scriptDir/gen-main.sh" main @files

if (!(Test-Path $Out)) {
    New-Item -ItemType Directory -Path $Out -Force | Out-Null
}

$baseArgs = @("-Z", "search-path=.", "-Z", "search-path=$TemplateDir", "-Z", "search-path=$TemplateDir/sty/moloch", "-Z", "continue-on-errors")

$running = @()
foreach ($f in $files) {
    Write-Host "Starting $f..." -ForegroundColor Yellow
    $procArgs = $baseArgs + @("-o", $Out, "main/$f")
    $process = Start-Process -FilePath "tectonic" -ArgumentList $procArgs -PassThru -NoNewWindow
    $running += @{Process=$process; FileName=$f}
}

$failed = $false
foreach ($procInfo in $running) {
    $procInfo.Process.WaitForExit()
    if ($procInfo.Process.ExitCode -eq 0) {
        Write-Host "Successfully compiled $($procInfo.FileName)" -ForegroundColor Green
    } else {
        Write-Host "Failed compilation for $($procInfo.FileName)" -ForegroundColor Red
        $failed = $true
    }
}

foreach ($f in $files) {
    Remove-Item -Path "main/$f" -Force -ErrorAction SilentlyContinue
}
if ((Get-ChildItem -Path ".\main" -Force -ErrorAction SilentlyContinue).Count -eq 0) {
    Remove-Item -Path ".\main" -Force -ErrorAction SilentlyContinue
}

if ($failed) { exit 1 }
