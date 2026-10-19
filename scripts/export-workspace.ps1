param([string]$Root=(Split-Path $PSScriptRoot -Parent),[Parameter(Mandatory)][string]$Destination)
$ErrorActionPreference='Stop'
$Root=[IO.Path]::GetFullPath($Root); $Destination=[IO.Path]::GetFullPath($Destination)
if(Test-Path -LiteralPath $Destination){throw 'Destination already exists; choose a new package filename.'}
$allowedFiles=@(
  'AGENTS.md','CLAUDE.md','CREATIVE_DNA.md','README.md','AUTHENTICATION.md','MIGRATION.md','.gitignore','.mcp.json','.codex/config.toml',
  'assets/README.md','outputs/README.md','references/README.md',
  'integrations/README.md','integrations/accounts.json','integrations/registry.json',
  'memory/approved-learnings.md','prompts/ai-generation.md','prompts/chatgpt-video-editor-starter-cloud.md',
  'shared/WORKSPACE_CORE.md','templates/CLIENT.md','templates/project/BRIEF.md','templates/project/HANDOFF.md','templates/project/STATE.md','templates/project/media-manifest.json','workflows/production.md',
  'scripts/bootstrap.ps1','scripts/doctor.ps1','scripts/export-workspace.ps1','scripts/new-project.ps1','scripts/restore-workspace.ps1','scripts/start.ps1','scripts/transcribe.ps1','scripts/yt-dlp.ps1',
  'starters/talking-head-rough-cut/AGENTS.md','starters/talking-head-rough-cut/README.md','starters/talking-head-rough-cut/scripts/preflight.mjs','starters/talking-head-rough-cut/scripts/render-cut.mjs','starters/talking-head-rough-cut/templates/cuts.json','starters/talking-head-rough-cut/templates/cut-approval.json'
)
$files=[Collections.Generic.List[string]]::new()
foreach($relative in $allowedFiles){$path=Join-Path $Root $relative;if(Test-Path -LiteralPath $path -PathType Leaf){$files.Add($path)}}
$blockedPath='(?i)(^|[\\/])(source|work|renders|private|node_modules|browser-profiles|\.cache|\.git|\.playwright-cli|\.local-tools|\.migration-tmp)([\\/]|$)|(^|[\\/])\.env(\.|$)|settings\.local\.json$|\.(mp4|mov|mxf|wav|aif|aiff|mp3|psd|aep|prproj|pem|p12|pfx|key|cookie|token)$'
$secretPattern='(?i)(-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|(?:api[_-]?key|access[_-]?token|refresh[_-]?token|client[_-]?secret|password)\s*[=:]\s*["'']?[^\s"'']{8,}|https?://[^\s"'']+[?&](?:secret|token|key)=|\b(?:ghp_|gho_|ghu_|ghs_|github_pat_|sk-[A-Za-z0-9_-]{16,})[A-Za-z0-9_-]{12,})'
$stage=Join-Path (Join-Path $Root '.migration-tmp') ('vpl-export-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage -Force | Out-Null
try {
  foreach($file in $files){
    $relative=[IO.Path]::GetRelativePath($Root,$file)
    if($relative -match $blockedPath){continue}
    if([IO.Path]::GetExtension($file) -notin @('.md','.json','.toml','.ps1','.mjs','.example') -and [IO.Path]::GetFileName($file) -ne '.gitignore'){continue}
    if((Get-Item -LiteralPath $file).Attributes -band [IO.FileAttributes]::ReparsePoint){throw "Refusing link: $relative"}
    $content=Get-Content -LiteralPath $file -Raw
    if($content -match $secretPattern){throw "Potential secret in $relative; review and sanitize before export"}
    $out=Join-Path $stage $relative; New-Item -ItemType Directory -Path (Split-Path $out -Parent) -Force | Out-Null; Copy-Item -LiteralPath $file -Destination $out
  }
  Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $Destination -CompressionLevel Optimal
  Write-Output "Sanitized configuration package: $Destination"
} finally {Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue}