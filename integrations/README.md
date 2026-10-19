# MCP integration registry

The portable agent configs are intentionally empty. A machine-level Codex MCP list may contain desktop, project-specific, or authenticated services that are unrelated to this workspace. Never copy those entries blindly, especially URLs with embedded secrets. For each new server, verify official transport and tool schema, check auth/scopes/cost, obtain Mark's authorization, then add nonsecret definitions separately to `.codex/config.toml` and `.mcp.json`. Record actual per-agent status and capabilities in `registry.json`. A login in one agent is not evidence of login in the other.

Codex app connectors and skills, such as ChatCut, Watch Skill, Canva, and Higgsfield, are session-level tools and are not represented by this workspace's local MCP files. Their presence in a tool list does not prove account authentication or make them available to Claude Code. Use the active agent's live tool surface and auth status; keep local MCP setup separate.
