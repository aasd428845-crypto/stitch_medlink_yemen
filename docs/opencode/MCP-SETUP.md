# MCP Setup

OpenCode V2 uses `mcp.servers` and `disabled: true` for configured-but-disabled servers.

## Context7
```bash
opencode mcp add context7 --url https://mcp.context7.com/mcp
opencode mcp list
```
Authenticate in OpenCode if requested.

## Figma
The V2 config already contains:
`https://mcp.figma.com/mcp`
Enable it after configuring Figma authentication.

## Playwright
The config enables:
`npx -y @playwright/mcp@latest`

Install Playwright browsers in the environment if required by your test setup.

## GitHub
Set:
`GITHUB_PERSONAL_ACCESS_TOKEN`
Then enable the `github` server. Do not commit the token.

## Important
Do not enable every MCP at once. MCP tools consume model context; keep only what the current task requires.
