# Guide v5.0 Roadmap

## Status

| Phase | Scope | Status |
|---|---|---|
| Phase 1 | Backup repo + memory notes (private, ytrofr/claude-setup) | Done |
| Phase 2 | install.sh v5.0 manifest-driven (Core/Recommended/Full) | Done |
| Phase 3 | Scaffolding + redirects (6 Parts, jekyll-redirect-from) | Done |
| **B2** | **Reference Part (Part VI)** — collapse 13 ship-logs into one CC version history page; CLI + hook + skill + MCP catalogs; security checklist | PENDING |
| B3 | Advanced Part (Part V) — AI DNA, inter-agent, self-telemetry, Monitor, statusline, cross-project, defrag | PENDING |
| B4 | Context Engineering Part (Part IV) — memory bank, rules, Basic Memory, budget, progressive disclosure, governance, skill lifecycle | PENDING |
| B5 | Extension Part (Part III) — hooks, MCP, agents, skills authoring/maintenance, plugins, slash commands, Cloud Run deploy | PENDING |
| B6 | Workflow Part (Part II) — plan mode, TDD, brainstorming, verify, session lifecycle, commit/PR | PENDING |
| B7 | Foundation Part (Part I) + README + CHANGELOG + CITATION + release | PENDING |

## Next

When starting B2, request a dedicated implementation plan. Use `docs/guide/_redirect-plan.md` as the old→new URL map for adding `redirect_from:` arrays to rewritten chapters.

## Verification discipline per B-phase

Before each B-phase commit:
1. `bundle exec jekyll build` — builds clean
2. Hero metrics in touched chapters verified or removed (no unsourced claims)
3. CC version references match 2.1.111+ (or explicit "as of CC 2.1.X" for version-tied content)
4. No internal absolute paths (user home dirs, user emails) in committed chapter text
5. No project-specific references (`LimorAI`, `OGAS`, `AgentSmith`, `Sigma`) in committed chapter text
6. `redirect_from:` added to rewritten chapters per `docs/guide/_redirect-plan.md`

## Known gaps (v5.0 shipped state)

- `template/` directory (at repo root) is NOT yet repopulated to match manifest tier contents. Installer mechanically works but will fetch 404s for most Recommended/Full files until `template/` is filled. Separate sub-plan.
- Pruned chapter files (05, 17, 20, 21, 24, 30, 30b, 31, 31b, 33, 41, 46, 47, 48, 49, 52, 55, 56, 59, 67, 68, 69) are still present in `docs/guide/` as numbered files. They're pruned from nav via Jekyll front matter or outright deletion during the B-phase that covers their topic.
