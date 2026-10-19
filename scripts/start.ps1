param([ValidateSet('codex','claude')][string]$Agent='codex')
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent))
$temp=Join-Path $root '.local-temp'
New-Item -ItemType Directory -Path $temp -Force | Out-Null
$env:TEMP=$temp
$env:TMP=$temp
# This F: filesystem does not record ownership. Trust only this checkout for child Git processes.
$count=0
if($env:GIT_CONFIG_COUNT -match '^\d+$'){$count=[int]$env:GIT_CONFIG_COUNT}
[Environment]::SetEnvironmentVariable("GIT_CONFIG_KEY_$count",'safe.directory','Process')
[Environment]::SetEnvironmentVariable("GIT_CONFIG_VALUE_$count",$root.Replace('\','/'),'Process')
$env:GIT_CONFIG_COUNT=[string]($count+1)
Set-Location -LiteralPath $root
& $Agent
