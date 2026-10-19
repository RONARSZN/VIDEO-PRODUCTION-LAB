param([string]$Root = (Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)
if (-not (Test-Path -LiteralPath (Join-Path $Root 'shared/WORKSPACE_CORE.md'))) { throw 'Run bootstrap from a restored VIDEO-PRODUCTION-LAB package.' }
foreach ($name in @('clients','projects','assets','references','workflows','prompts','integrations','memory','scripts','templates','outputs')) {
  New-Item -ItemType Directory -Path (Join-Path $Root $name) -Force | Out-Null
}
Write-Output "Workspace ready at $Root"
Write-Output 'No software or account was installed or connected. Run scripts/doctor.ps1 next.'
