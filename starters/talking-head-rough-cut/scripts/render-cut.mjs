import { createHash } from "node:crypto";
import { createReadStream } from "node:fs";
import { access, mkdir, readFile, stat, writeFile } from "node:fs/promises";
import { spawn } from "node:child_process";
import { basename, dirname, extname, isAbsolute, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const projectDir = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const workspaceRoot = resolve(projectDir, "..", "..");
const defaultCuts = resolve(projectDir, "work", "transcript", "cuts.json");
const defaultApproval = resolve(projectDir, "work", "transcript", "cut-approval.json");
const defaultOutput = resolve(workspaceRoot, "outputs", basename(projectDir), "cut.mp4");

function parseArgs(args) {
  const options = { cuts: defaultCuts, approval: defaultApproval, output: defaultOutput, force: false, help: false };
  for (let i = 0; i < args.length; i += 1) {
    const arg = args[i];
    if (arg === "--force") options.force = true;
    else if (arg === "--help" || arg === "-h") options.help = true;
    else if (["--source", "--cuts", "--approval", "--output"].includes(arg)) {
      const value = args[i + 1];
      if (!value || value.startsWith("--")) throw new Error(`Missing value for ${arg}`);
      options[arg.slice(2)] = value;
      i += 1;
    } else throw new Error(`Unknown option: ${arg}`);
  }
  return options;
}

function printHelp() {
  console.log("Usage: node scripts/render-cut.mjs --source <video> [--cuts <json>] [--approval <json>] [--output <mp4>] [--force]");
  console.log("Default output: workspace outputs/talking-head-rough-cut/cut.mp4");
}

function run(command, args, { capture = false } = {}) {
  return new Promise((resolvePromise, reject) => {
    const child = spawn(command, args, { windowsHide: true, stdio: capture ? ["ignore", "pipe", "pipe"] : "inherit" });
    let stdout = "";
    let stderr = "";
    if (capture) {
      child.stdout.setEncoding("utf8").on("data", (chunk) => { stdout += chunk; });
      child.stderr.setEncoding("utf8").on("data", (chunk) => { stderr += chunk; });
    }
    child.once("error", reject);
    child.once("close", (code) => {
      if (code !== 0) reject(new Error(`${command} exited with code ${code}${stderr ? `: ${stderr.trim()}` : ""}`));
      else resolvePromise(capture ? { stdout, stderr } : undefined);
    });
  });
}

function parseRate(value, label) {
  const match = String(value || "").match(/^(\d+)\/(\d+)$/);
  if (!match || Number(match[2]) === 0) throw new Error(`Could not read ${label} from FFprobe: ${value}`);
  return Number(match[1]) / Number(match[2]);
}

function sha256(buffer) {
  return createHash("sha256").update(buffer).digest("hex");
}

function isWithin(parent, target) {
  const path = relative(parent, target);
  return path === "" || (!path.startsWith(`..${sep}`) && path !== ".." && !isAbsolute(path));
}

async function hashFile(path) {
  return new Promise((resolvePromise, reject) => {
    const hash = createHash("sha256");
    const stream = createReadStream(path);
    stream.on("data", (chunk) => hash.update(chunk));
    stream.once("error", reject);
    stream.once("end", () => resolvePromise(hash.digest("hex")));
  });
}

async function probe(path, countFrames = false) {
  const args = ["-v", "error", "-show_streams", "-show_format"];
  if (countFrames) args.push("-count_frames");
  args.push("-of", "json", path);
  const { stdout } = await run("ffprobe", args, { capture: true });
  return JSON.parse(stdout);
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) return printHelp();
  if (!options.source) throw new Error("Pass a source clip with --source.");

  const sourcePath = resolve(options.source);
  const cutsPath = resolve(options.cuts);
  const approvalPath = resolve(options.approval);
  const outputPath = resolve(options.output);
  const allowedOutputs = [resolve(workspaceRoot, "outputs"), resolve(projectDir, "work")];
  if (!allowedOutputs.some((folder) => isWithin(folder, outputPath))) {
    throw new Error("Output must be inside this workspace's outputs/ or this project's work/ directory.");
  }
  if (sourcePath === outputPath || extname(outputPath).toLowerCase() !== ".mp4") {
    throw new Error("Output must be a different .mp4 path from the source.");
  }

  await Promise.all([access(sourcePath), access(cutsPath), access(approvalPath)]);
  const [sourceStat, existingOutput, existingManifest] = await Promise.all([
    stat(sourcePath),
    stat(outputPath).then(() => true, () => false),
    stat(`${outputPath}.manifest.json`).then(() => true, () => false),
  ]);
  if (sourceStat.size === 0) throw new Error("Source clip is empty.");
  if ((existingOutput || existingManifest) && !options.force) {
    throw new Error("Output or manifest already exists. Choose another path or use --force after Mark requests replacement.");
  }

  const cutsBytes = await readFile(cutsPath);
  const cutsSha256 = sha256(cutsBytes);
  const approval = JSON.parse((await readFile(approvalPath, "utf8")).replace(/^\uFEFF/, ""));
  if (approval.status !== "APPROVED" || approval.approvedBy !== "Mark" || !Number.isFinite(Date.parse(approval.approvedAt))) {
    throw new Error("The approval record is not approved by Mark. Show the cut list and wait for his explicit approval first.");
  }
  if (approval.cutsSha256 !== cutsSha256) {
    throw new Error("Cut-list approval is stale: its SHA-256 does not match the current cuts.json bytes.");
  }

  const cuts = JSON.parse(cutsBytes.toString("utf8").replace(/^\uFEFF/, ""));
  if (!Array.isArray(cuts.segments) || cuts.segments.length === 0) throw new Error("cuts.json must contain at least one segment.");
  const sourceInfo = await probe(sourcePath);
  const video = sourceInfo.streams?.find((stream) => stream.codec_type === "video");
  const audio = sourceInfo.streams?.find((stream) => stream.codec_type === "audio");
  if (!video) throw new Error("FFprobe found no video stream in the source.");
  const fps = parseRate(video.avg_frame_rate, "average frame rate");
  const nominalFps = parseRate(video.r_frame_rate, "nominal frame rate");
  if (Math.abs(fps - nominalFps) > 0.1) {
    throw new Error(`The source may be variable-frame-rate (${fps.toFixed(3)} average vs ${nominalFps.toFixed(3)} nominal). Use an editor workflow or create an approved constant-frame-rate working copy first.`);
  }
  const duration = Number(sourceInfo.format?.duration);
  if (!Number.isFinite(duration) || duration <= 0) throw new Error("FFprobe did not return a valid source duration.");

  let lastEndFrame = -1;
  const segments = cuts.segments.map((segment, index) => {
    const start = Number(segment.start);
    const end = Number(segment.end);
    if (!Number.isFinite(start) || !Number.isFinite(end) || start < 0 || end <= start) {
      throw new Error(`Segment ${index + 1} needs numeric start/end seconds with end > start.`);
    }
    const startFrame = Math.round(start * fps);
    const endFrame = Math.round(end * fps);
    if (endFrame <= startFrame) throw new Error(`Segment ${index + 1} is shorter than one source frame after snapping.`);
    if (startFrame < lastEndFrame) throw new Error(`Segment ${index + 1} overlaps the previous segment after frame snapping.`);
    const startSeconds = startFrame / fps;
    const endSeconds = endFrame / fps;
    if (endSeconds > duration + (1 / fps)) throw new Error(`Segment ${index + 1} ends beyond the source duration.`);
    lastEndFrame = endFrame;
    return { index: index + 1, text: String(segment.text || ""), requestedStart: start, requestedEnd: end, startFrame, endFrame, startSeconds, endSeconds };
  });

  const filters = [];
  const inputs = [];
  for (const segment of segments) {
    const suffix = segment.index - 1;
    filters.push(`[0:v:0]trim=start_frame=${segment.startFrame}:end_frame=${segment.endFrame},setpts=PTS-STARTPTS,format=yuv420p[v${suffix}]`);
    inputs.push(`[v${suffix}]`);
    if (audio) {
      const start = segment.startSeconds.toFixed(9);
      const end = segment.endSeconds.toFixed(9);
      filters.push(`[0:a:0]atrim=start=${start}:end=${end},asetpts=PTS-STARTPTS[a${suffix}]`);
      inputs.push(`[a${suffix}]`);
    }
  }
  filters.push(`${inputs.join("")}concat=n=${segments.length}:v=1:a=${audio ? 1 : 0}[vout]${audio ? "[aout]" : ""}`);

  await mkdir(dirname(outputPath), { recursive: true });
  const ffmpegArgs = ["-hide_banner", "-nostdin", options.force ? "-y" : "-n", "-i", sourcePath, "-filter_complex", filters.join(";"), "-map", "[vout]"];
  if (audio) ffmpegArgs.push("-map", "[aout]");
  ffmpegArgs.push("-c:v", "libx264", "-preset", "medium", "-crf", "18", "-pix_fmt", "yuv420p");
  if (audio) ffmpegArgs.push("-c:a", "aac", "-b:a", Number(audio.channels) === 1 ? "192k" : "320k");
  ffmpegArgs.push("-fps_mode", "passthrough", "-movflags", "+faststart", outputPath);

  console.log(`Rendering ${segments.length} approved segment(s) to ${outputPath}`);
  await run("ffmpeg", ffmpegArgs);

  const renderedInfo = await probe(outputPath, true);
  const renderedVideo = renderedInfo.streams?.find((stream) => stream.codec_type === "video");
  const expectedFrames = segments.reduce((sum, segment) => sum + segment.endFrame - segment.startFrame, 0);
  const actualFrames = Number(renderedVideo?.nb_read_frames);
  if (!Number.isFinite(actualFrames) || actualFrames !== expectedFrames) {
    throw new Error(`Rendered frame count mismatch: expected ${expectedFrames}, got ${renderedVideo?.nb_read_frames ?? "unknown"}. Keep the output for inspection; do not treat it as verified.`);
  }
  if (renderedVideo.width !== video.width || renderedVideo.height !== video.height) {
    throw new Error("Rendered dimensions do not match the source.");
  }

  const manifestPath = `${outputPath}.manifest.json`;
  const manifest = {
    schemaVersion: 1,
    status: "rendered_pending_human_review",
    project: basename(projectDir),
    renderedAt: new Date().toISOString(),
    source: { path: sourcePath, sha256: await hashFile(sourcePath), durationSeconds: duration, width: video.width, height: video.height, frameRate: video.avg_frame_rate, audioPresent: Boolean(audio), audioChannels: audio?.channels ?? 0 },
    cutList: { path: cutsPath, sha256: cutsSha256, approvedBy: approval.approvedBy, approvedAt: approval.approvedAt },
    output: { path: outputPath, sha256: await hashFile(outputPath), bytes: (await stat(outputPath)).size, width: renderedVideo.width, height: renderedVideo.height, frameRate: renderedVideo.avg_frame_rate, frameCount: actualFrames, codec: renderedVideo.codec_name, durationSeconds: Number(renderedInfo.format?.duration) },
    segments,
  };
  await writeFile(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, "utf8");
  console.log(`Verified ${actualFrames} frames at ${renderedVideo.avg_frame_rate}; manifest: ${manifestPath}`);
  console.log("Human watch/listen review is still required. Rendered does not mean approved for publication.");
}

main().catch((error) => {
  console.error(`ERROR ${error.message}`);
  process.exitCode = 1;
});
