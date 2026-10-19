# Talking-head rough-cut starter

A provider-neutral, no-dependency Node.js and FFmpeg workflow for proposing and rendering an approved rough cut. The scripts are cross-platform; source media and intermediate files remain local and are ignored by Git.

## Requirements

- Node.js 18 or newer
- `ffmpeg` and `ffprobe` on `PATH` for preflight and rendering

No npm packages are required. Whisper, editor integrations, and cloud services are optional and are not installed or configured here.

## Start

Run commands from the repository root:

1. Put one source clip in `starters/talking-head-rough-cut/source/`.
2. Check the local tools:

   ```sh
   node starters/talking-head-rough-cut/scripts/preflight.mjs
   ```

3. Create a transcript if one is already available, then prepare `cuts.json` from `templates/cuts.json` under `starters/talking-head-rough-cut/work/transcript/`.
4. Show Mark the complete ordered cut list and wait for explicit approval. Copy `templates/cut-approval.json` beside it, record the approval time, and set `cutsSha256` to the SHA-256 of the exact `cuts.json` bytes.
5. Render only after the approval hash matches:

   ```sh
   node starters/talking-head-rough-cut/scripts/render-cut.mjs --source starters/talking-head-rough-cut/source/clip.mp4
   ```

The default render is `outputs/talking-head-rough-cut/cut.mp4`, with a JSON manifest beside it. Both `source/` and `work/` are ignored; workspace `outputs/` is ignored. The renderer refuses an unapproved or changed cut list and will not overwrite an existing output unless `--force` is supplied after Mark requests replacement.

The default deliverable is a flattened MP4. Native editor control requires selecting an editor and verifying a supported import/control route first. Technical render checks do not replace human watch/listen review, and rendering does not mean the edit was approved for publication.