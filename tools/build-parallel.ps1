# Parallel LaTeX Build Script (template version)
#
# Regenerates main/*.tex from the template's option matrix, then builds them
# with concurrency bounded to the CPU count. Launching all 39 at once (the
# previous behaviour) oversubscribes the machine and measured ~12% slower
# end-to-end on a 16-core box, with a much larger memory spike.
#
#   -Jobs N   concurrency (default: number of logical processors)
#   -Out DIR  output directory for the compiled PDFs (default: main\pdfs)
#   -Draft    single TeX pass: ~3x faster, but cross-references, the table of
#             contents and beamer navigation are NOT converged. For a quick
#             look only, never for anything published.
param(
    [int]$Jobs = 0,
    [string]$Out = ".\main\pdfs",
    [switch]$Draft
)

Write-Host "=== Parallel LaTeX Build Script ===" -ForegroundColor Magenta

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# main/*.tex are generated, not checked in.
bash "$scriptDir/gen-main.sh" main

if ($Jobs -le 0) { $Jobs = [Environment]::ProcessorCount }
Write-Host "Concurrency: $Jobs" -ForegroundColor Cyan

$texFiles = Get-ChildItem -Path ".\main\*.tex"
Write-Host "Found $($texFiles.Count) TeX files to compile..." -ForegroundColor Cyan

if (!(Test-Path $Out)) {
    New-Item -ItemType Directory -Path $Out -Force | Out-Null
    Write-Host "Created $Out directory" -ForegroundColor Yellow
}

$baseArgs = @("-Z", "search-path=.", "-Z", "search-path=template", "-Z", "search-path=template/sty/moloch", "-Z", "continue-on-errors")
if ($Draft) { $baseArgs += @("-r", "0") }

$running = @()
$results = @()

foreach ($file in $texFiles) {
    # Throttle: wait until a slot frees up.
    while (@($running | Where-Object { -not $_.Process.HasExited }).Count -ge $Jobs) {
        Start-Sleep -Milliseconds 200
    }
    $running = @($running | Where-Object { -not $_.Process.HasExited }) + @($running | Where-Object { $_.Process.HasExited } | ForEach-Object { $results += $_; $null })
    $running = @($running | Where-Object { $_ -ne $null })

    Write-Host "Starting $($file.Name)..." -ForegroundColor Yellow
    $procArgs = $baseArgs + @("-o", $Out, $file.FullName)
    $process = Start-Process -FilePath "tectonic" -ArgumentList $procArgs -PassThru -NoNewWindow
    $running += @{Process=$process; FileName=$file.Name}
}

Write-Host "Waiting for compilation to complete..." -ForegroundColor Cyan
foreach ($procInfo in ($running + $results)) {
    if ($null -eq $procInfo) { continue }
    $procInfo.Process.WaitForExit()
    if ($procInfo.Process.ExitCode -eq 0) {
        Write-Host "Successfully compiled $($procInfo.FileName)" -ForegroundColor Green
    } else {
        Write-Host "Failed compilation for $($procInfo.FileName)" -ForegroundColor Red
    }
}

Write-Host "Cleaning up temporary files..." -ForegroundColor Cyan
Get-ChildItem -Path "." -Include "*.aux","*.log","*.nav","*.out","*.snm","*.toc","*.atfi","*.fls","*.fdb_latexmk","*.synctex.gz","*.bbl","*.blg" -Recurse | Remove-Item -Force

# main\*.tex are pure build inputs, regenerated fresh from options.conf on
# every run (see gen-main.sh) -- remove them so they don't clutter the repo
# once the PDFs (in $Out) exist. Leaves e.g. main\pdfs\ (the default $Out)
# untouched.
Remove-Item -Path ".\main\*.tex" -Force -ErrorAction SilentlyContinue
if ((Get-ChildItem -Path ".\main" -Force -ErrorAction SilentlyContinue).Count -eq 0) {
    Remove-Item -Path ".\main" -Force -ErrorAction SilentlyContinue
}

Write-Host "Cleanup completed!" -ForegroundColor Green
Write-Host "=== Build process finished ===" -ForegroundColor Magenta
