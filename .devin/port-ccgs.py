#!/usr/bin/env python3
"""Regenerate the Devin runtime layer (.devin/) from the CCGS .claude/ sources.

Run from the repo root:  python3 .devin/port-ccgs.py
Idempotent — re-run after `git pull upstream` to re-port upstream changes.

What it does:
  .claude/skills/<n>/SKILL.md  -> .devin/skills/<n>/SKILL.md   (frontmatter + `!` lines + reference paths)
  .claude/agents/<n>.md        -> .devin/agents/<n>.md         (tool-name map, drop Claude-only fields)
  .claude/rules/<n>.md         -> .devin/rules/<n>.md          (paths: -> trigger: glob + globs:)
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CLAUDE = ROOT / ".claude"
DEVIN = ROOT / ".devin"

# Devin tool names usable in skill allowed-tools / permissions.
DEVIN_TOOLS = {"read", "write", "edit", "grep", "glob", "exec"}
# Subagent profile allowed-tools can also name these.
SUBAGENT_EXTRA = {
    "WebSearch": "webfetch",
    "Agent": "run_subagent",
    "TaskCreate": "todo_write",
    "TaskGet": "todo_write",
    "TaskList": "todo_write",
    "TaskUpdate": "todo_write",
    "Skill": "skill",
}
VALID_MODELS = {
    "opus", "sonnet", "swe", "codex", "gemini", "gpt", "gpt-5",
    "swe-1-6", "swe-1-6-fast", "o3", "o4-mini",
}
# CCGS model values Devin doesn't have — drop the field (inherit session model).
DROP_MODELS = {"haiku"}


# ---------------------------------------------------------------- frontmatter

def parse_frontmatter(text):
    """Return (list_of_(key,value), body). Values keep raw YAML scalar text;
    `paths:`-style dash lists come back as python lists."""
    if not text.startswith("---"):
        return [], text
    end = text.find("\n---", 3)
    if end == -1:
        return [], text
    fm_text = text[3:end].strip("\n")
    body = text[end + 1:]
    if body.startswith("---"):
        body = body[3:].lstrip("\n")
    items = []
    for line in fm_text.split("\n"):
        if not line.strip():
            continue
        m = re.match(r"^(\S[^:]*):\s*(.*)$", line)
        if m:
            items.append([m.group(1).strip(), m.group(2).strip()])
        elif line.strip().startswith("- ") and items:
            if not isinstance(items[-1][1], list):
                items[-1][1] = [items[-1][1]] if items[-1][1] else []
            items[-1][1].append(line.strip()[2:].strip())
        elif line.startswith(" ") and items:  # continuation of a long scalar
            items[-1][1] = (items[-1][1] or "") + " " + line.strip()
    return items, body


def fm_get(items, key):
    for k, v in items:
        if k == key:
            return v
    return None


def unquote(v):
    if isinstance(v, str) and len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'":
        return v[1:-1]
    return v


# ---------------------------------------------------------------- tool parsing

def split_allowed_tools(raw):
    """Split a Claude 'allowed-tools' comma list, respecting Bash(...) parens."""
    raw = unquote(raw or "")
    parts, depth, cur = [], 0, ""
    for ch in raw:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth = max(0, depth - 1)
        if ch == "," and depth == 0:
            parts.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        parts.append(cur.strip())
    return parts


def bash_pattern_to_exec(pattern):
    """Claude Bash(<glob>) -> Devin Exec(<prefix>). Prefix match only."""
    p = pattern.strip().strip('"')
    if "yaml-helper.sh" in p:
        return "Exec(bash .claude/hooks/yaml-helper.sh)"
    p = p.replace("*/", "").replace("*", " ")
    p = re.sub(r"\s+", " ", p).strip()
    return f"Exec({p})"


def tools_to_devin(entries, is_subagent):
    """-> (allowed-tools list, Exec permission entries)."""
    tools, execs = [], []
    for e in entries:
        m = re.match(r"^Bash\((.*)\)$", e)
        if m:
            execs.append(bash_pattern_to_exec(m.group(1)))
            if "exec" not in tools:
                tools.append("exec")
            continue
        low = e.lower()
        if low in DEVIN_TOOLS:
            if low not in tools:
                tools.append(low)
        elif is_subagent and e in SUBAGENT_EXTRA:
            t = SUBAGENT_EXTRA[e]
            if t not in tools:
                tools.append(t)
        # anything else (AskUserQuestion, Skill, WebSearch in skills, Agent,
        # Task*) — not grantable / harmless to omit; still usable via prompts.
    return tools, execs


# ---------------------------------------------------------------- transforms

def emit_fm(d):
    out = ["---"]
    for k, v in d:
        if isinstance(v, list):
            out.append(f"{k}:")
            out += [f"  - {x}" for x in v]
        elif v is not None:
            out.append(f"{k}: {v}")
    out.append("---")
    return "\n".join(out) + "\n\n"


def port_skill(src_dir, dst_dir):
    src = src_dir / "SKILL.md"
    if not src.exists():
        return None
    items, body = parse_frontmatter(src.read_text())
    name = fm_get(items, "name") or src_dir.name

    keep = {}
    for k in ("name", "description", "argument-hint"):
        v = fm_get(items, k)
        if v:
            keep[k] = v
    out = list(keep.items())

    model = fm_get(items, "model")
    if model and unquote(model).lower() not in DROP_MODELS and unquote(model) in VALID_MODELS:
        out.append(("model", model))
    if fm_get(items, "disable-model-invocation") == "true":
        out.append(("triggers", ["user"]))

    raw_tools = fm_get(items, "allowed-tools")
    tools, execs = tools_to_devin(split_allowed_tools(raw_tools), is_subagent=False)
    if tools:
        out.append(("allowed-tools", tools))
    fm_head = emit_fm(out)
    if execs:
        perm = "permissions:\n  allow:\n" + "".join(f'    - "{e}"\n' for e in execs)
        fm_head = fm_head[:-5] + perm + "---\n\n"

    # body: `!` resolve_config lines -> run-the-bash instruction
    def cfg_repl(m):
        keys = m.group(1).strip()
        return (
            "> **Devin port — resolve config first:** `!` preprocessing is not "
            "supported here. Run the following via the shell and treat its "
            "output as the resolved config block:\n"
            f"> `bash .claude/hooks/yaml-helper.sh resolve_config --keys {keys}`"
        )
    body = re.sub(r"!`bash[^`\n]*resolve_config\s+--keys\s+([^`\n]+)`", cfg_repl, body)
    # any other leftover `!` lines -> drop the bang so they read as comments
    body = re.sub(r"^!`", "`", body, flags=re.M)

    # skill-local references -> real path under .claude/skills/<name>/references/
    ref_dir = src_dir / "references"
    if ref_dir.is_dir():
        def subref(m):
            rel = m.group(2)
            if (ref_dir / rel).exists():
                return f"{m.group(1)}.claude/skills/{name}/references/{rel}"
            return m.group(0)
        body = re.sub(r"([`(]\s*)references/([\w./-]+\.\w+)", subref, body)

        # Bare `references/` folder mentions meaning THIS skill's own dir —
        # skip possessive forms that mean another skill's (e.g. "its references/").
        def ownref(m):
            before = body[max(0, m.start() - 30):m.start()].lower()
            if re.search(r"(its|a skill|that skill|phase's|their|the target)\W*$", before):
                return m.group(0)
            return f"{m.group(1)}.claude/skills/{name}/references/"
        body = re.sub(r"([`(]\s*)references/(?=[\s`'\",;.)])", ownref, body)
    body = body.replace("${CLAUDE_SKILL_DIR}", f".claude/skills/{name}")
    body = body.replace("${CLAUDE_PROJECT_DIR}", ".")

    dst_dir.mkdir(parents=True, exist_ok=True)
    (dst_dir / "SKILL.md").write_text(fm_head + body)
    return name


def port_agent(src, dst_dir):
    items, body = parse_frontmatter(src.read_text())
    out = []
    for k in ("name", "description"):
        v = fm_get(items, k)
        if v:
            out.append((k, v))
    model = fm_get(items, "model")
    if model and unquote(model).lower() not in DROP_MODELS and unquote(model) in VALID_MODELS:
        out.append(("model", model))
    raw = fm_get(items, "tools") or fm_get(items, "allowed-tools")
    if raw:
        entries = raw if isinstance(raw, list) else split_allowed_tools(raw)
        tools, _ = tools_to_devin(entries, is_subagent=True)
        if tools:
            out.append(("allowed-tools", tools))
    dst_dir.mkdir(parents=True, exist_ok=True)
    (dst_dir / src.name).write_text(emit_fm(out) + body)


def port_rule(src, dst_dir):
    items, body = parse_frontmatter(src.read_text())
    paths = fm_get(items, "paths")
    desc = fm_get(items, "description")
    out = []
    if desc:
        out.append(("description", desc))
    if paths:
        globs = paths if isinstance(paths, list) else [paths]
        out.append(("trigger", "glob"))
        out.append(("globs", globs))
    else:
        out.append(("trigger", "model_decision"))
    dst_dir.mkdir(parents=True, exist_ok=True)
    (dst_dir / src.name).write_text(emit_fm(out) + body)


def main():
    n = {"skills": 0, "agents": 0, "rules": 0}
    for d in sorted((CLAUDE / "skills").iterdir()):
        if d.is_dir() and port_skill(d, DEVIN / "skills" / d.name):
            n["skills"] += 1
    for f in sorted((CLAUDE / "agents").glob("*.md")):
        port_agent(f, DEVIN / "agents")
        n["agents"] += 1
    for f in sorted((CLAUDE / "rules").glob("*.md")):
        port_rule(f, DEVIN / "rules")
        n["rules"] += 1
    print(f"ported: {n['skills']} skills, {n['agents']} agents, {n['rules']} rules")


if __name__ == "__main__":
    sys.exit(main())
