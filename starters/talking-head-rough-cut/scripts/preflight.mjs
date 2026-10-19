import { spawnSync } from "node:child_process";

const supportedEditors = new Set(["premiere", "resolve-studio", "resolve-free", "final-cut", "capcut", "none"]);
const args = process.argv.slice(2);
let selectedEditor = "";
for (let i = 0; i < args.length; i += 1) {
  if (args[i] === "--editor" && args[i + 1]) selectedEditor = args[++i].toLowerCase();
  else if (args[i].startsWith("--editor=")) selectedEditor = args[i].slice("--editor=".length).toLowerCase();
  else throw new Error(`Unknown option: ${args[i]}`);
}
if (selectedEditor && !supportedEditors.has(selectedEditor)) {
  throw new Error(`Unknown editor '${selectedEditor}'. Use one of: ${[...supportedEditors].join(", ")}.`);
}

const checks = [
  ["node", ["--version"], true],
  ["ffmpeg", ["-version"], true],
  ["ffprobe", ["-version"], true],
  ["git", ["--version"], false],
  ["uv", ["--version"], false],
];

let failed = false;
let uvAvailable = false;
for (const [command, args, required] of checks) {
  const result = spawnSync(command, args, { encoding: "utf8", windowsHide: true });
  const available = !result.error && result.status === 0;
  if (command === "uv") uvAvailable = available;
  const label = required ? "required" : "optional";
  const detail = available
    ? (result.stdout || result.stderr || "").split(/\r?\n/, 1)[0].trim()
    : result.error?.message || `exit ${result.status}`;
  console.log(`${available ? "READY" : required ? "MISSING" : "OPTIONAL"} ${label.padEnd(8)} ${command}: ${detail}`);
  if (required && !available) failed = true;
}

const nodeMajor = Number(process.versions.node.split(".")[0]);
if (nodeMajor < 18) {
  console.error("MISSING required   Node.js 18 or newer is needed by these scripts.");
  failed = true;
}
if (selectedEditor === "premiere" && nodeMajor < 22) {
  console.error("MISSING required   Node.js 22 or newer is required for the Premiere adapter route.");
  failed = true;
}
if (selectedEditor === "premiere") console.log(`INFO  Premiere selected; Node.js ${process.versions.node} ${nodeMajor >= 22 ? "meets" : "does not meet"} the 22+ requirement.`);
if (uvAvailable) {
  const python = spawnSync("uv", ["python", "find", "3.11"], { encoding: "utf8", windowsHide: true });
  const found = !python.error && python.status === 0;
  console.log(`${found ? "READY optional" : "OPTIONAL"} Python 3.11 via uv: ${(python.stdout || python.stderr || "").split(/\r?\n/, 1)[0].trim() || "not available"}`);
}

console.log("INFO  No packages or software were installed. WhisperX and editor connectors are not required by the MP4 renderer.");
if (failed) process.exitCode = 1;
