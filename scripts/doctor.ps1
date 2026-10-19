param([string]$Root = (Split-Path $PSScriptRoot -Parent), [switch]$Json)
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)
$items = [Collections.Generic.List[object]]::new()
function Add-Check($name,$status,$detail) { $items.Add([pscustomobject]@{name=$name;status=$status;detail=$detail}) }
foreach ($file in @('AGENTS.md','CLAUDE.md','shared/WORKSPACE_CORE.md','CREATIVE_DNA.md','.codex/config.toml','.mcp.json','integrations/registry.json','integrations/accounts.json')) {
  $path = Join-Path $Root $file
  Add-Check $file $(if(Test-Path -LiteralPath $path){'READY'}else{'ACTION REQUIRED'}) 'Required workspace file'
}
foreach ($tool in @('codex','claude','git','ffmpeg','ffprobe','node')) {
  $cmd = Get-Command $tool -ErrorAction SilentlyContinue
  Add-Check $tool $(if($cmd){'READY'}else{'OPTIONAL INTEGRATION UNAVAILABLE'}) $(if($cmd){$cmd.Source}else{'Install or add to PATH if this workflow needs it'})
}
$watchSkill = Get-Command 'watch-skill' -ErrorAction SilentlyContinue
Add-Check 'Watch Skill CLI' $(if($watchSkill){'READY'}else{'OPTIONAL INTEGRATION UNAVAILABLE'}) $(if($watchSkill){$watchSkill.Source}else{'Use the connected Codex app tool or install the CLI if needed'})
$ytDlpLocalCandidates = @((Join-Path $Root '.local-tools/yt-dlp/yt-dlp'),(Join-Path $Root '.local-tools/yt-dlp/yt-dlp.exe'))
$ytDlpLocal = $ytDlpLocalCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
$ytDlpCommand = if($ytDlpLocal){$null}else{Get-Command -Name @('yt-dlp','yt-dlp.exe') -ErrorAction SilentlyContinue | Select-Object -First 1}
$ytDlpPath = if($ytDlpLocal){$ytDlpLocal}elseif($ytDlpCommand){$ytDlpCommand.Source}else{$null}
Add-Check 'yt-dlp' $(if($ytDlpPath){'READY'}else{'OPTIONAL INTEGRATION UNAVAILABLE'}) $(if($ytDlpPath){$ytDlpPath}else{'Install only when a video source needs downloading'})
$whisperExe = $env:VPL_WHISPER_EXE
if (-not $whisperExe) {
  $whisperCommand = Get-Command -Name @('whisper','whisper.exe') -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($whisperCommand) { $whisperExe = $whisperCommand.Source }

}
$whisperReady = $whisperExe -and (Test-Path -LiteralPath $whisperExe)
Add-Check 'Whisper CLI' $(if($whisperReady){'READY'}else{'OPTIONAL INTEGRATION UNAVAILABLE'}) $(if($whisperReady){$whisperExe}else{'Set VPL_WHISPER_EXE or use scripts/transcribe.ps1 after installation'})
$whisperModels = $env:VPL_WHISPER_MODEL_DIR
if (-not $whisperModels) { $whisperModels = Join-Path $Root '.local-tools/whisper/models' }
$whisperBase = Join-Path $whisperModels 'base.pt'
Add-Check 'Whisper base model' $(if(Test-Path -LiteralPath $whisperBase){'READY'}else{'OPTIONAL INTEGRATION UNAVAILABLE'}) $(if(Test-Path -LiteralPath $whisperBase){$whisperBase}else{'It will download the base model on first transcription'})
try { $null = Get-Content -LiteralPath (Join-Path $Root '.mcp.json') -Raw | ConvertFrom-Json; Add-Check 'Claude MCP config' 'READY' 'Valid JSON; each server still requires independent health verification' } catch { Add-Check 'Claude MCP config' 'ACTION REQUIRED' 'Invalid JSON' }
try { $null = Get-Content -LiteralPath (Join-Path $Root 'integrations/registry.json') -Raw | ConvertFrom-Json; Add-Check 'MCP registry' 'READY' 'Valid JSON' } catch { Add-Check 'MCP registry' 'ACTION REQUIRED' 'Invalid JSON' }
if (Get-Command codex -ErrorAction SilentlyContinue) {
  $result = & codex login status 2>&1 | Out-String
  Add-Check 'Codex authentication' $(if($LASTEXITCODE -eq 0){'READY'}else{'ACTION REQUIRED'}) $(if($LASTEXITCODE -eq 0){'CLI reports login available'}else{'Run codex login'})
}
if (Get-Command claude -ErrorAction SilentlyContinue) {
  $result = & claude auth status 2>&1 | Out-String
  $ok = $LASTEXITCODE -eq 0 -and $result -match '"loggedIn"\s*:\s*true'
  Add-Check 'Claude authentication' $(if($ok){'READY'}else{'ACTION REQUIRED'}) $(if($ok){'CLI reports login available'}else{'Run claude login or check claude auth status'})
}
if (Get-Command gh -ErrorAction SilentlyContinue) {
  $null = & gh auth status 2>&1 | Out-String
  Add-Check 'GitHub authentication' $(if($LASTEXITCODE -eq 0){'READY'}else{'OPTIONAL INTEGRATION UNAVAILABLE'}) $(if($LASTEXITCODE -eq 0){'gh reports account available'}else{'Run gh auth login if GitHub is needed'})
}
Add-Check 'Higgsfield' 'OPTIONAL INTEGRATION UNAVAILABLE' 'PENDING_SETUP for both agents'
foreach ($project in @(Get-ChildItem -LiteralPath (Join-Path $Root 'projects') -Directory -ErrorAction SilentlyContinue)) {
  foreach ($required in @('BRIEF.md','STATE.md','HANDOFF.md','media-manifest.json')) {
    Add-Check "$($project.Name)/$required" $(if(Test-Path -LiteralPath (Join-Path $project.FullName $required)){'READY'}else{'ACTION REQUIRED'}) 'Project file integrity'
  }
  $manifest = Join-Path $project.FullName 'media-manifest.json'
  if(Test-Path -LiteralPath $manifest) {
    try {
      $data = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
      foreach($asset in @($data.assets)) {
        if(-not $asset.required){continue}
        $exists = $asset.path -and (Test-Path -LiteralPath $asset.path)
        Add-Check "media:$($project.Name):$($asset.id)" $(if($exists){'READY'}else{'ACTION REQUIRED'}) $(if($exists){'Required media found'}else{'Reconnect media or update manifest path'})
      }
    } catch { Add-Check "media:$($project.Name)" 'ACTION REQUIRED' 'Invalid media manifest' }
  }
}
$coreBad = @($items | Where-Object { $_.status -eq 'ACTION REQUIRED' -and $_.name -notin @('Codex authentication','Claude authentication') })
$codexReady = @($items | Where-Object { $_.name -eq 'codex' -and $_.status -eq 'READY' }).Count -gt 0 -and @($items | Where-Object { $_.name -eq 'Codex authentication' -and $_.status -eq 'READY' }).Count -gt 0
$claudeReady = @($items | Where-Object { $_.name -eq 'claude' -and $_.status -eq 'READY' }).Count -gt 0 -and @($items | Where-Object { $_.name -eq 'Claude authentication' -and $_.status -eq 'READY' }).Count -gt 0
$overall = if($coreBad.Count -gt 0){'ACTION REQUIRED'}else{'READY'}
$report = [pscustomobject]@{overall=$overall;agents=[pscustomobject]@{codex=$(if($codexReady){'READY'}else{'ACTION REQUIRED'});claude=$(if($claudeReady){'READY'}else{'ACTION REQUIRED'})};checks=$items}
if($Json){$report | ConvertTo-Json -Depth 6}else{$report.checks | Format-Table -AutoSize; Write-Output "Overall: $overall"}
