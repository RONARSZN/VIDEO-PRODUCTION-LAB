# Authentication and connection management

Use `pwsh -File scripts/doctor.ps1` for local readiness. Its CLI checks are local status signals, not a guarantee that every MCP tool call will work. Use provider-native login and OAuth; repeat on a new device when required. Codex and Claude Code have independent sessions and may require separate authorization for the same account. Existing ChatGPT app connections do not automatically transfer.

Codex: `codex login status`; if needed, `codex login`. Claude Code: `claude auth status`; if needed, `claude login`. GitHub: `gh auth status`; if needed, `gh auth login`. Keep credentials in each provider's supported user-level store or the platform's credential manager. Do not copy auth files, cookies, browser profiles, or tokens into this workspace or migration archive. Do not print credential files while diagnosing.

`integrations/accounts.json` tracks service, method, status, capabilities, health, and next action without secrets. `integrations/registry.json` tracks MCP compatibility. The checked-in `.codex/config.toml` and `.mcp.json` contain no active third-party connections. Add an integration only after verifying official endpoint, transport, scopes, auth method, tool compatibility, cost, and Mark's authorization. Test Codex and Claude independently. If a token expires, use the provider's reauthentication flow; never bypass MFA or CAPTCHA.

Persistent browser sessions may be used only in provider-supported user profiles with Mark's authorization; profile directories remain outside this workspace and never migrate. Disconnected optional services must not block local production.
