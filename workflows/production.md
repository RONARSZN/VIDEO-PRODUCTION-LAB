# Production workflow

Use this as a phase checklist. Record decisions in project files, not provider-specific chat memory.

## Tool routing

| Need | Preferred tool | Boundary |
|---|---|---|
| Inspect media, extract frames, transcode, render, or check technical properties | Local `ffmpeg` / `ffprobe` | Keep source media unchanged; write derivatives to project `work/` or `outputs/`. |
| Review an unindexed video or ask about a previously reviewed one | Watch Skill (`watch_video` / `watch-skill watch` first, `ask_video` / `watch-skill ask` for follow-ups) | For visual judgments, inspect returned frames or the video itself. OCR, transcript, and index text alone are not visual evidence. |
| Transcribe source audio when captions are unavailable | Workspace launcher `scripts/transcribe.ps1` or ChatCut transcription | Whisper defaults to the local `base` model on CPU, writes VTT under the requested output directory, and auto-detects language unless `-Language` is set. Confirm language and coverage; transcripts do not establish visual evidence. |
| Edit or inspect a hosted timeline | ChatCut tools and the matching ChatCut workflow skill | Identify and target the intended project before any timeline mutation or export. |
| Build repeatable, code-driven motion graphics | Remotion skill | Use only when the brief benefits from code-driven motion; install dependencies inside that project. |
| Prepare or generate visual assets | Available Canva, Higgsfield, image-generation, or other connected tools | Confirm active-agent availability, account access, rights, privacy, and cost. Follow the approval gate in step 6 before paid or external generation. |

App connectors are session-level. A tool visible in the Codex app is not automatically configured for Codex CLI or Claude Code; use only the tools and authentication available to the active agent. Do not copy another workspace's machine-specific paths or credentials.

For private media, check where a tool processes or stores files before sending them to a hosted service. Prefer local FFmpeg and Whisper when they meet the need.

1. **Interpret brief:** extract goal, audience, channel, deliverables, deadline, budget, rights, privacy, and unknowns. Confirm material unknowns.
2. **Analyze references:** inspect actual picture and audio when accessible; use Watch Skill for first-pass indexing and timestamped follow-ups, then inspect frames for visual claims. Use source captions when reliable, otherwise run `pwsh -File scripts/transcribe.ps1 -InputFile <media> -OutputDirectory <project-work-folder>` and review the transcript. Separate observation from interpretation; log timestamped examples and rights.
3. **Develop treatment:** choose base direction, optional treatment, pacing, typography, grade, sound, and one sample check. Apply project > client > Creative DNA.
4. **Organize assets:** preserve originals, create media manifest, note source path, rights, checksum and missing media. Never rename or delete source files without approval.
5. **Select shots and plan sequence:** log selects with source/timecodes, narrative role, trim notes, and rough order. Do not imply selects were viewed if based on metadata only.
6. **Prompt AI generation:** use `prompts/ai-generation.md`; identify cost, privacy, and rights; obtain approval before paid or external generation.
7. **Prepare edit/timeline:** use verified installed tools. Use ChatCut for compatible hosted timelines, FFmpeg for local media operations, and Remotion for code-driven motion only after suitability review. Keep project edits reproducible.
8. **Sound design:** confirm music/SFX rights, intelligibility, dynamics, sync, and intended playback context. Human listen review remains required.
9. **Render/export:** lock version and specifications; render to outputs or project work, never source; capture command/preset and checksum.
10. **QC:** check duration, codec, dimensions, frame rate, loudness/clipping, black/silent frames, captions if required, and start/end boundaries. Use Watch Skill and inspect frames for visual review when available; human watch/listen review remains a separate claim.
11. **Manage revisions:** log feedback, decision, owner, version, approval source, and whether global learning is warranted.
12. **Deliver:** verify exact version and destination; obtain authorization for upload/publish; record receipt. Keep approved master and its manifest.
