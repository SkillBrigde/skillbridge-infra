param([switch]$Optional)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$environmentFile = Join-Path $repositoryRoot ".env"
$environmentExample = Join-Path $repositoryRoot ".env.example"

if (-not (Test-Path -LiteralPath $environmentFile)) {
    Copy-Item -LiteralPath $environmentExample -Destination $environmentFile
    Write-Host "Created .env from .env.example (development values only)."
}

$composeArgs = @("compose", "--project-directory", $repositoryRoot, "--env-file", $environmentFile)
if ($Optional) {
    $composeArgs += @("--profile", "optional")
}

& docker @composeArgs up -d
if ($LASTEXITCODE -ne 0) { throw "Docker Compose could not start the services." }
& docker @composeArgs ps
if ($LASTEXITCODE -ne 0) { throw "Docker Compose could not show service status." }
