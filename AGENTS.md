# Claude Code Game Studios — running on Devin

Indie game development managed through 49 coordinated agent profiles and 78
slash-command skills. This fork runs on **Devin**, not Claude Code:

- `.devin/` is the authoritative runtime layer — **generated** by
  `python3 .devin/port-ccgs.py` from the `.claude/` sources. After
  `git pull upstream`, re-run the port script; do not edit `.devin/skills`,
  `.devin/agents`, or `.devin/rules` by hand.
- `.claude/` is kept upstream-pristine and acts as the content store:
  framework docs, templates, genres, engines, scripts, hooks scripts, and
  the original skill `references/` all still live there — paths in skills
  point at `.claude/...` on purpose.
- `.devin/config.json` disables the `claude` config import so `.claude/skills`
  does not double-load; `CLAUDE.md` is therefore not read — this file carries
  the always-on essentials instead.

## Runtime mapping (Claude Code → Devin)

| CCGS text says | You do |
|---|---|
| `spawn X via Agent` / subagent_type | `run_subagent` with profile `X` (profiles in `.devin/agents/`) |
| `AskUserQuestion` | `ask_user_question` tool |
| `TaskCreate` / `TaskList` / `TaskUpdate` | `todo_write` |
| `Skill` tool / slash name | `/name` or the `skill` tool |
| `` !`bash ... resolve_config ...` `` line | run that bash command via `exec`, use its stdout as the config block |
| `WebSearch` | `web_search` / `webfetch` |
| `SubagentStart`/`SubagentStop` hooks | `PreToolUse`/`PostToolUse` on `run_subagent` — payload translated by `ccgs-hook.sh xlate` |
| `Notification` (permission_prompt) | `PermissionRequest` event (idle_prompt has no equivalent) |
| `validate-agent-artifact.sh` | `.devin/hooks/check-artifact.sh` — same check against `tool_input.task` |
| `PreCompact` hook | no equivalent; covered by `session-stop.sh` on Stop + `active.md` reminder on PostCompaction |

## Technology Stack

- **Engine**: Godot 4.7 (`4.7.2.stable.official.ed1daf0bf`)
- **Language**: GDScript
- **Version Control**: Git, trunk-based
- **Build System**: SCons (engine), Godot Export Templates
- **Asset Pipeline**: Godot Import System + custom resource pipeline (`tools/assets/`: Qwen image → Hunyuan3D 3.0 LowPoly → Blender 5.2 `flatten_glb.py` → GLB)

Engine version reference: `docs/engine-reference/godot/VERSION.md`

`project.yaml` is the single source of truth for engine, rigor (`modes.rigor`),
automation, naming and performance budgets. Resolve config keys with
`bash .claude/hooks/yaml-helper.sh resolve_config --keys ...`.

## Coordination rules (from `.claude/docs/coordination-rules.md`, read it for detail)

- Vertical delegation only: directors → department leads → specialists.
- Peers may consult, never override another domain.
- Conflicts escalate to the shared parent (creative → creative-director,
  technical → technical-director); cross-domain changes go through producer.
- Never touch files outside your domain; design docs >40KB are read by
  section, never whole.
- When a skill spawns subagents, verify the named artifact paths exist on
  disk afterwards — a finished subagent is not proof the file was written.

## Collaboration protocol — user-driven, not autonomous

Every task: **Question → Options → Decision → Draft → Approval**

- Ask "May I write this to [filepath]?" before write/edit on existing or
  multi-file changes (bounded exceptions: `production/session-state/active.md`
  appends, agent memory, a subagent's new file at the path its orchestrating
  skill named — see `.devin/rules/agent-memory.md`).
- Show drafts or summaries before requesting approval.
- A skipped question is not an answer: re-ask in plain text and wait.
- No commits without explicit user instruction.

**`production/session-state/active.md` is the session checkpoint** — the file
is the memory, not the conversation. Read it first after any compaction,
crash, or restart.

Helpers in `.claude/scripts/` emit observations, never verdicts.

## Entry points

- New here? `/start` (guided onboarding) or `/prototype <idea>` ("make me a game").
- Lost? `/next-step` names the single next step from on-disk artifacts.
- Visual bar matters: fill `references/` with screenshots + `notes.md`,
  then `/art-bible` before `/map-systems`.

## Reference docs (read on demand)

`.claude/docs/` — workflow-catalog.yaml (authoritative phase ladder),
directory-structure.md, config-resolution.md, coordination-rules.md,
coding-standards.md, context-management.md, templates/ (62 files).
`.claude/genres/` — 67 genre chips driving questions/defaults.
`.claude/engines/` — engine table + web starter. `studio-tests/` — framework QA.
