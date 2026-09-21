$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$environmentFile = Join-Path $repositoryRoot ".env"
$environmentExample = Join-Path $repositoryRoot ".env.example"

if (-not (Test-Path -LiteralPath $environmentFile)) {
    Copy-Item -LiteralPath $environmentExample -Destination $environmentFile
    Write-Host "Created .env from .env.example (development values only)."
}

docker compose --project-directory $repositoryRoot --env-file $environmentFile up -d
docker compose --project-directory $repositoryRoot --env-file $environmentFile ps
