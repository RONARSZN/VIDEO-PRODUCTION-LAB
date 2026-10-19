# Recreate the lab on another machine or in Codex Cloud

## Portable configuration package

From the repository root, create a package with `pwsh -NoProfile -File scripts/export-workspace.ps1 -Destination <new-zip-path>`. The exporter uses an explicit file list for reusable instructions, workflows, templates, and scripts. It excludes client/project records, media, local production data, local history, authentication state, and machine-specific implementation notes. The secret-pattern check is defense in depth; inspect the archive entries and contents before transferring it.

Restore to a new, empty directory with `pwsh -NoProfile -File scripts/restore-workspace.ps1 -Package <zip-path> -Destination <new-empty-directory>`. Restore checks archive paths and excluded data, then runs `scripts/bootstrap.ps1`. It refuses to overwrite an existing destination. PowerShell 7 is required for these scripts.

## Codex Cloud

In Codex desktop or web, create a Cloud environment and select the private GitHub repository. Review the environment's repository, installation commands, tools, network settings, and access before publishing. The Cloud task uses its existing agent process; do not start a second CLI agent from `scripts/start.ps1`.

PowerShell 7 is required for `.ps1` scripts. Node.js 18+, FFmpeg, and FFprobe are needed only for the talking-head rough-cut workflow. Whisper and yt-dlp executables/models are optional and are not included. The repository contains no account credentials or third-party MCP configuration.

## Supply separately when a workflow needs it

- Original source media and project-specific transcripts/cut lists remain outside Git. A Cloud task needs its media made available through an approved task file workflow; this repository does not transfer media.
- Tool binaries and model caches are not in the repository. Install only the tools needed for the task in the Cloud environment, or use a verified available tool.
- Codex, Claude, and GitHub authentication are separate provider sessions. Reauthenticate through each provider's official flow when needed; do not copy local auth files, cookies, browser profiles, or tokens.

Keep client briefs and handoffs local unless a specific private migration is approved. Technical checks do not replace human review or publication approval.