# Guide v5.0 Roadmap

## Status

| Phase | Scope | Status | Shipped |
|---|---|---|---|
| Phase 1 | Backup repo + memory notes (private, ytrofr/claude-setup) | Done | 2026-04-19 |
| Phase 2 | install.sh v5.0 manifest-driven (Core/Recommended/Full) | Done | 2026-04-20 |
| Phase 3 | Scaffolding + redirects (6 Parts, jekyll-redirect-from) | Done | 2026-04-20 |
| **B2** | **Reference Part (Part VI)** — collapse 13 ship-logs into one CC version history page; CLI + hook + skill + MCP catalogs; security checklist | Done | 2026-04-20 |
| B3 | Advanced Part (Part V) — AI DNA, inter-agent, self-telemetry, Monitor, statusline, cross-project, defrag | Done | 2026-04-20 |
| B4 | Context Engineering Part (Part IV) — memory bank, rules, Basic Memory, budget, progressive disclosure, governance, skill lifecycle | Done | 2026-04-20 |
| B5 | Extension Part (Part III) — hooks, MCP, agents, skills authoring/maintenance, plugins, slash commands, Cloud Run deploy | Done | 2026-04-20 |
| B6 | Workflow Part (Part II) — plan mode, TDD, brainstorming, verify, session lifecycle, commit/PR | Done | 2026-04-20 |
| B7 | Foundation Part (Part I) + README + CHANGELOG + CITATION + release | Done | 2026-04-21 |

## Next workstreams

**`template/` repopulation** is the next priority. The v5.0 installer mechanically works but the `template/` directory at the repo root was not yet repopulated to match the new manifest tier contents. Recommended/Full installs will fetch 404s for most files until `template/` is refilled from `best-practices/` sources. This will be tracked as a separate sub-plan (target: B8).

Beyond template realignment:

- Opportunistic cleanup of any residual numbered chapter files under `docs/guide/` that are excluded from nav but still physically present.
- Post-release GH Pages verification after push (build clean, no broken redirects, Part index pages render).
- v5.0 release tag and GitHub release notes draft.

## Verification discipline per B-phase

Before each B-phase commit:
1. `bundle exec jekyll build` — builds clean
2. Hero metrics in touched chapters verified or removed (no unsourced claims)
3. CC version references match 2.1.111+ (or explicit "as of CC 2.1.X" for version-tied content)
4. No internal absolute paths (user home dirs, user emails) in committed chapter text
5. No project-specific references (`LimorAI`, `OGAS`, `AgentSmith`, `Sigma`) in committed chapter text
6. `redirect_from:` added to rewritten chapters per `docs/guide/_redirect-plan.md`

## Known gaps (v5.0 shipped state)

- **`template/` directory alignment** — at repo root, NOT yet repopulated to match manifest tier contents. Installer mechanically works but will fetch 404s for most Recommended/Full files until `template/` is filled. Separate sub-plan (next workstream).
- Pruned chapter files (05, 17, 20, 21, 24, 30, 30b, 31, 31b, 33, 41, 46, 47, 48, 49, 52, 55, 56, 59, 67, 68, 69) may still be present in `docs/guide/` as numbered files. They're excluded from nav via Jekyll front matter. Residual cleanup can happen opportunistically.
