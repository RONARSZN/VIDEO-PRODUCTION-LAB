# VIDEO-PRODUCTION-LAB

A portable production workspace for ChatGPT/Codex and Claude Code. Shared instructions live in `shared/WORKSPACE_CORE.md`; both agents use the same Creative DNA, client/project templates, workflows, prompts, and handoff rules. Agent authentication stays separate. A plain chat without this repository available cannot read local files or run local commands.

## Local CLI setup

From the repository root, run `pwsh -NoProfile -File scripts/bootstrap.ps1`, then `pwsh -NoProfile -File scripts/doctor.ps1`. Start a local agent CLI only when needed: `pwsh -NoProfile -File scripts/start.ps1 -Agent codex` or `-Agent claude`. The launcher scopes Git trust to this checkout and routes its temporary files into ignored workspace storage. Use `pwsh -NoProfile -File scripts/new-project.ps1 -Name sample-edit -Client sample-client` to create a project from the blank templates. Fill its brief and claim ownership in `STATE.md` before production work.

`doctor.ps1` reports workspace-file readiness separately from optional tools and account authentication. `Overall: READY` does not mean an agent, service, or media tool is installed or connected.

## Codex Cloud

Create a Cloud environment from the Codex desktop or web interface and select this private GitHub repository. Let the environment setup inspect the repository and test the commands you need before publishing that environment. The Cloud agent is already running there; `scripts/start.ps1` is for local CLI sessions.

PowerShell 7 is required to run the workspace `.ps1` scripts. Node.js 18+ and FFmpeg/FFprobe are needed only for the talking-head rough-cut starter. Whisper, yt-dlp, editor connectors, and other integrations are optional. Do not add credentials to the repository or configure a service just to prepare the environment. Codex Cloud setup is described in the [official environment guide](https://developers.openai.com/codex/environments/cloud-environments).

No source media, client/project records, rendered exports, or local tool binaries are part of this source set. Media work in Cloud requires the source clip to be made available to that task through an approved file workflow; it remains outside Git.

## Production workflow

Read the relevant client and project files. Follow `workflows/production.md`, preserve original media, and write handoffs when ownership changes. `FFmpeg` and `FFprobe` are optional local tools for media operations. Remotion is optional and should be installed per project only if the edit benefits from code-driven motion. No third-party integration or heavyweight editor is configured by this workspace.

See `AUTHENTICATION.md` for provider login boundaries and `MIGRATION.md` for portable packages. Never put secrets or original client footage in Git.

The reusable talking-head workflow is under `starters/talking-head-rough-cut/`, indexed by `prompts/chatgpt-video-editor-starter-cloud.md`.