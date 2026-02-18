---
layout: default
title: Enable Claude Code Sandbox on WSL2
description: Set up Claude Code's built-in sandbox on WSL2 for filesystem and network isolation. Reduces permission prompts by 84%.
---

# Enable Claude Code Sandbox on WSL2

**Time to set up**: 2 minutes
**Requires**: WSL2, Claude Code installed

---

## What is Sandbox?

Claude Code includes a built-in sandbox that isolates bash commands in a restricted environment. Instead of prompting you to approve every shell command, the sandbox auto-approves commands that operate within safe boundaries.

According to Anthropic's engineering blog, sandbox mode reduces permission prompts by **84%**, making sessions significantly more fluid.

The sandbox enforces two key constraints:

- **Filesystem isolation** -- prevents accidental reads or writes outside your project directory.
- **Network isolation** -- restricts outbound network access from sandboxed commands.

Commands that stay within these boundaries run without approval. Commands that would break isolation still trigger a prompt, so you remain in control.

---

## Install Dependencies

The sandbox relies on two Linux packages:

- **bubblewrap** (`bwrap`) -- lightweight unprivileged sandboxing tool used by Flatpak and other projects.
- **socat** -- multipurpose relay for bidirectional data transfer, used for sandbox communication.

Install both on your WSL2 instance:

```bash
sudo apt-get update && sudo apt-get install -y bubblewrap socat
```

These are small packages with no heavy dependencies.

---

## Enable in Claude Code

Once the dependencies are installed, activate sandbox mode from within a Claude Code session:

```
/sandbox
```

This toggles sandbox on for the current session. Claude Code detects `bwrap` and `socat` on your PATH and configures the isolation layer automatically.

---

## What Changes When Sandbox is Active

| Aspect | Without Sandbox | With Sandbox |
|--------|----------------|--------------|
| Bash commands | Each prompts for approval | Safe commands auto-approved |
| File access | Unrestricted | Scoped to project directory |
| Network access | Unrestricted | Restricted within sandbox |
| Permission prompts | Frequent | ~84% fewer |

Sandbox does **not** affect tool calls like Read, Write, Edit, or Grep. It only applies to commands executed via the Bash tool.

---

## Verify Sandbox is Active

After running `/sandbox`, confirm it is working:

1. **Check the session indicator** -- Claude Code displays a sandbox status in the session header when isolation is enabled.

2. **Run a scoped command** -- execute a simple bash command (e.g., `ls`) and confirm it runs without a permission prompt.

3. **Test isolation** -- attempt to read a file outside your project directory. The sandbox should block or prompt for the operation:

```bash
cat /etc/hostname
```

If sandbox is active, this triggers a permission prompt instead of executing silently.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `/sandbox` reports missing dependencies | Run `sudo apt-get install -y bubblewrap socat` and retry |
| `bwrap` not found after install | Ensure `/usr/bin` is on your PATH: `which bwrap` |
| Sandbox not persisting across sessions | `/sandbox` is per-session; run it at the start of each session or configure it in your Claude Code settings |
| Commands that should be safe still prompt | Some commands require network or out-of-scope file access by nature; the prompt is expected |

---

## Summary

1. Install `bubblewrap` and `socat` on WSL2.
2. Run `/sandbox` inside Claude Code.
3. Enjoy 84% fewer permission prompts with filesystem and network isolation.

---

**License**: MIT
