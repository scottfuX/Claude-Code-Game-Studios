# Test Infrastructure

**Engine**: Godot 4.7.2
**Test Framework**: gdUnit4 6.2.2
**CI**: `.github/workflows/tests.yml`
**Setup date**: 2026-11-18

## Directory Layout

```
tests/
  unit/           # Isolated unit tests (formulas, state machines, logic)
  integration/    # Cross-system and save/load tests
  smoke/          # Critical path test list for /smoke-check gate
```

```
production/qa/
  evidence/       # Screenshot logs and manual test sign-off records
```

> **Manual evidence lives under `production/qa/evidence/`, not `tests/`** — that
> is where every consumer reads it.

## Running Tests

From the repository root, with Godot 4.7.2 on your PATH (or substitute the
path to its executable):

```bash
godot --headless --path . --import
godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode
```

Import first to refresh the script class cache. Lonefire has no main scene yet;
the test runner does not need one. The loopback remote-debug setting prevents
Godot from waiting at an interactive debugger prompt on script errors.
Diagnostics about connecting to port 0 are expected; use the test summary and
process exit code to determine the result.

Check that at least one test ran: gdUnit4 can exit 0 after finding no tests.
Exit 100 means a test failed, 101 means a test leaked nodes, and 105 means a
test script failed to parse. Reports are written to `reports/`.

## gdUnit4 dependency

The [gdUnit4 6.2.2 release](https://github.com/godot-gdunit-labs/gdUnit4/releases/tag/v6.2.2)
is vendored in `addons/gdUnit4/` from upstream commit
`0127a55f4543dfc24746f6e5c7ba6f94105d51f2`. The addon comes with its MIT license
and excludes upstream's own tests. No addon install or editor plugin activation
is needed for headless tests.

## Test Naming

Names follow the engine's language (`.claude/rules/test-standards.md`):
- **Godot**: file `[system]_[feature]_test.gd`, function `test_[scenario]_[expected]`
  — `combat_damage_test.gd` → `test_base_attack_returns_expected_damage()`

## Story Type → Test Evidence

| Story Type | Required Evidence | Location |
|---|---|---|
| Logic | Automated unit test — must pass | `tests/unit/[system]/` |
| Integration | Integration test OR playtest doc | `tests/integration/[system]/` |
| Visual/Feel | Screenshot + lead sign-off | `production/qa/evidence/` |
| UI | Retained screenshot of each screen touched | `production/qa/evidence/` |
| Config/Data | Smoke check pass | `production/qa/smoke-*.md` |

## CI

CI runs all suites under `tests/` headlessly on pushes to `main` and pull
requests targeting it. The workflow uploads gdUnit4's report as `test-results`
and fails if no report is produced.
The `Run GdUnit4 Tests` job is the check to require if branch protection is enabled.
