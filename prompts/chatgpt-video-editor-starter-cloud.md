# ChatGPT/Codex prompt: local talking-head rough cut

Use this prompt in a Codex task with this repository checked out and the required local tools available. It describes the reusable workflow in `starters/talking-head-rough-cut/`; it does not depend on an editor connector or a particular drive letter.

---

Set up or operate the talking-head rough-cut workflow in `starters/talking-head-rough-cut/`. Read the workspace `AGENTS.md`, `shared/WORKSPACE_CORE.md`, `CREATIVE_DNA.md`, and the starter's `AGENTS.md` and `README.md`. Confirm `VPL-CORE-1`. Run `pwsh -File scripts/doctor.ps1` when PowerShell 7 is available and run `node starters/talking-head-rough-cut/scripts/preflight.mjs` before media work.

You are ChatGPT/Codex operating only through tools actually available in this task. If the repository or required local files are unavailable, say so and stop; do not pretend to access another device or local path. Do not assume any MCP, editor control, transcription package, or application is installed.

## Before editing

1. Check `starters/talking-head-rough-cut/source/` for a single user-supplied clip. Preserve it byte-for-byte. If no clip is available in the task, ask Mark to provide it through an approved file workflow; do not commit or send a private clip to an external service.
2. Ask which editing app Mark wants to finish in: Premiere, Resolve Studio, Resolve free, Final Cut, CapCut, or no app. If not yet chosen, continue with the editor-neutral MP4 route and record the choice as pending. Never claim live editor control unless a compatible connector is already present and verified.
3. Inspect the actual clip with FFprobe and available local preview tools. Report duration, frame rate, dimensions, orientation, audio streams, and any uncertainty. Do not infer visual/audio quality from metadata or a still frame.
4. Use an existing transcript if supplied. If no transcript exists, check whether a local transcription tool is already installed. Do not install or download models, upload footage, connect an account, or incur a charge without Mark's separate authorization. If no approved transcription route is available, ask for a transcript or permission for a specific route.

## Propose the cut

Create `starters/talking-head-rough-cut/work/transcript/cuts.json` with this shape:

```json
{"segments":[{"start":1.24,"end":4.60,"text":"the complete spoken line"}]}
```

The times are seconds from the source start. Cut filler, dead air, false starts, and repeated takes; keep the best complete take, usually the last. Preserve the speaker's personality. Leave about 0.08 seconds before the first kept word and 0.12 seconds after the last when safe; never cut into a word. Keep segments in order and non-overlapping. Snap times to whole source frames, preserving source dimensions and frame rate. Record uncertainty and any manual judgment.

Show Mark the full ordered cut list with times and text. Stop and wait for Mark's explicit approval. Do not create an approval record or render before that approval. After approval, hash the exact `cuts.json` file bytes and write `starters/talking-head-rough-cut/work/transcript/cut-approval.json` with `status: "APPROVED"`, `approvedBy: "Mark"`, an ISO-8601 `approvedAt`, and the matching lowercase SHA-256 in `cutsSha256`. Any cut-list edit invalidates the approval and requires another review.

## Render and verify

After the approval record matches, run from the repository root:

```sh
node starters/talking-head-rough-cut/scripts/render-cut.mjs --source starters/talking-head-rough-cut/source/<clip-name>
```

The script writes an H.264/AAC MP4 to `outputs/talking-head-rough-cut/cut.mp4` and a manifest beside it. It snaps video cuts to frames, preserves dimensions/frame rate, refuses probable VFR footage, requires an approval hash for the exact cuts, and verifies the output frame count. If the output already exists, choose a new path; use `--force` only if Mark explicitly requests replacement.

If Mark requested an editable timeline, first confirm the target app and installed version, then check current official documentation and verify an adapter/import route. Until that is proven, deliver only the verified MP4 and describe it as flattened. Do not install editor connectors or run third-party code as part of this starter.

Report separately: files created, tool availability, rendered technical checks, human watch/listen review, creative approval, and any publication state. Rendering is not human review or publication approval. Do not upload, publish, or change accounts/permissions.