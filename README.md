# spec-tdd bridge

A two-tier OpenSpec schema that uses Superpowers for TDD and heavy-change
execution while keeping OpenSpec as the user-facing workflow. All portable
bridge files are written in English.

## Core idea

OpenSpec owns proposal, behavioral specs, and archive. Superpowers owns TDD and,
for heavy changes, detailed planning and subagent execution.

The OpenSpec apply gate is `[specs]`, so the Propose surface stops after the two
light-tier artifacts instead of creating every possible artifact.

| Tier | Planning artifacts | Executor |
|---|---|---|
| Light | `proposal.md` + delta specs | `superpowers:test-driven-development` in the current session |
| Heavy | Light artifacts + optional `design.md` + `tasks.md` + `<change-name>-plan.md` | `superpowers:subagent-driven-development` |

`tasks.md` is the persisted tier marker. A change without it is a light
candidate; a change with it is heavy.

## Naming

The schema is named `spec-tdd`. This repository is named `sdd-tdd` because it
contains the broader SDD/TDD integration research. The distinction avoids a
collision with Superpowers' `.superpowers/sdd/`, where SDD means
subagent-driven development.

## Prerequisites

1. The target project is a Git repository with at least one commit.
2. Node.js 20.19.0 or newer and npm are available.
3. Superpowers 6.2.0 is installed separately for every target agent. Newer
   versions are not assumed compatible; complete the upgrade checks below
   before adopting one.
4. OpenSpec CLI 1.6.0 is available.
5. Heavy tier requires a Bash-compatible shell available to the agent because
   `subagent-driven-development` runs Bash helper scripts. Git Bash, WSL, Linux,
   and macOS are suitable; having Git Bash installed but absent from the agent's
   `PATH` is not sufficient.

Shell snippets use POSIX syntax by default. PowerShell equivalents are included
for filesystem and configuration-verification steps so Light-tier installation
does not require Bash.

Install the CLI globally:

```bash
npm install -g @fission-ai/openspec@1.6.0
```

Alternatively, replace each `openspec` command below with
`npx @fission-ai/openspec@1.6.0`.

## Installation

Define these paths before installing:

- `<bridge>`: the absolute path to this `sdd-tdd` checkout.
- `<target>`: the absolute path to the project receiving the bridge.

Replace the placeholders in every command below. Commands that operate on
OpenSpec state explicitly run against or from `<target>`; copy commands read
assets from `<bridge>`. Keep substituted paths quoted. In Git Bash, write
Windows paths as `D:/Projects/...` or `/d/Projects/...`; in PowerShell, use the
native `D:\Projects\...` form.

### 1. Install Superpowers for each agent

Installation is harness-specific. Follow the upstream
[Superpowers installation guide](https://github.com/obra/superpowers#installation)
for every agent you use:

| Agent | Installation entry point |
|---|---|
| Claude Code | `/plugin install superpowers@claude-plugins-official` |
| Codex App | Open **Plugins**, find **Superpowers** in **Coding**, then install it |
| Codex CLI | Open `/plugins`, search for `superpowers`, then select **Install Plugin** |
| Cursor | Run `/add-plugin superpowers` or install it from the plugin marketplace |

Restart the agent after installation. In its plugin manager, confirm the
installed version is 6.2.0. Then confirm the available skill list includes at
least `superpowers:test-driven-development`, `superpowers:writing-plans`,
`superpowers:subagent-driven-development`, `superpowers:using-git-worktrees`,
and `superpowers:verification-before-completion`. If the marketplace installed
a newer version, treat it as an upgrade and complete the upgrade checks before
using this bridge in a real project.

### 2. Initialize or refresh OpenSpec

Initialize the agent surfaces you use:

```bash
openspec init --tools claude "<target>"
openspec init --tools codex "<target>"
openspec init --tools cursor "<target>"
```

To initialize several agents at once, pass a comma-separated list, for example:

```bash
openspec init --tools claude,codex,cursor "<target>"
```

OpenSpec 1.6.0 creates the supported agent command/skill surfaces and
`openspec/config.yaml`. Running the command against an initialized target
refreshes the selected agent surfaces and preserves the existing config. It
does not install the bridge's durable routing rules; add those in step 6.

### 3. Copy the schema

Create the destination first. Without it, `cp -r` may silently rename the
source directory instead of nesting it correctly.

```bash
mkdir -p "<target>/openspec/schemas/spec-tdd"
cp -r "<bridge>/schemas/spec-tdd/." "<target>/openspec/schemas/spec-tdd/"
```

PowerShell equivalent:

```powershell
New-Item -ItemType Directory -Force -Path '<target>\openspec\schemas\spec-tdd' | Out-Null
Copy-Item -Recurse -Force '<bridge>\schemas\spec-tdd\*' '<target>\openspec\schemas\spec-tdd'
```

Expected path:

```text
<target>/openspec/schemas/spec-tdd/schema.yaml
```

### 4. Select the schema

Set the first line of `<target>/openspec/config.yaml`:

```yaml
schema: spec-tdd
```

### 5. Add project context

Add project-specific context and rules to `<target>/openspec/config.yaml`. At
minimum, record the exact test command and the project's non-negotiable
constraints.

```yaml
schema: spec-tdd

context: |
  Tech stack: Python 3.12
  Test command: python -m unittest discover -s tests
  Project constraints:
  - Preserve existing public APIs.
```

Do not duplicate tier criteria here or in an agent instruction file. Tier
selection is centralized in `schema.yaml`.

### 6. Install agent routing instructions

Install the routing asset for each agent initialized in step 2:

- **Claude Code:** create or update `<target>/CLAUDE.md`, then append
  [`<bridge>/CLAUDE.md.fragment.md`](CLAUDE.md.fragment.md) once. Keep it
  outside generated OpenSpec marker blocks.
- **Codex:** create or update `<target>/AGENTS.md`, then append
  [`<bridge>/AGENTS.md.fragment.md`](AGENTS.md.fragment.md) once. Preserve any
  existing repository instructions. Codex loads durable repository guidance from
  [`AGENTS.md`](https://learn.chatgpt.com/docs/agent-configuration/agents-md).
- **Cursor:** copy
  [`<bridge>/agent-rules/cursor/spec-tdd.mdc`](agent-rules/cursor/spec-tdd.mdc)
  to `<target>/.cursor/rules/spec-tdd.mdc`. Cursor's version-controlled Project
  Rules use `.cursor/rules/*.mdc`; `.cursorrules` is deprecated. See [Cursor
  Rules](https://docs.cursor.com/context/rules).

For Cursor:

```bash
mkdir -p "<target>/.cursor/rules"
cp "<bridge>/agent-rules/cursor/spec-tdd.mdc" "<target>/.cursor/rules/spec-tdd.mdc"
```

PowerShell equivalent:

```powershell
New-Item -ItemType Directory -Force -Path '<target>\.cursor\rules' | Out-Null
Copy-Item -Force '<bridge>\agent-rules\cursor\spec-tdd.mdc' '<target>\.cursor\rules\spec-tdd.mdc'
```

These assets contain the same bridge policy in each agent's native routing
surface. They preserve the host agent's bootstrap requirements, then route
feature and bug-fix work through OpenSpec.

### 7. Verify

Run verification from the target project:

```bash
cd "<target>"
openspec schema validate spec-tdd
openspec schemas
grep -Eq '^schema:[[:space:]]+spec-tdd[[:space:]]*$' openspec/config.yaml
```

PowerShell equivalent:

```powershell
Set-Location '<target>'
openspec schema validate spec-tdd
openspec schemas
if (-not (Select-String -Path 'openspec\config.yaml' -Pattern '^schema:\s+spec-tdd\s*$')) {
    throw 'openspec/config.yaml does not select schema: spec-tdd'
}
```

Verification is complete only when:

- `schema validate` succeeds.
- `spec-tdd (project)` appears in `openspec schemas`.
- The shell-appropriate config check succeeds, proving `openspec/config.yaml`
  selects `schema: spec-tdd`.

`schema validate` alone does not prove that `openspec/config.yaml` selects the
schema.

## Daily workflow

### Agent invocation

OpenSpec 1.6.0 exposes the same workflow differently in each agent:

| Agent | Propose | Apply |
|---|---|---|
| Claude Code | `/opsx:propose "describe the change"` | `/opsx:apply` |
| Codex | `Use $openspec-propose to describe the change` | `Use $openspec-apply-change for <change-name>` |
| Cursor | `/opsx-propose "describe the change"` | `/opsx-apply` |

The tables and flows below use **Propose surface** and **Apply surface** to mean
the corresponding entry in this table. Archive remains the same explicit CLI
command for every agent.

### Light tier

```text
Propose surface
        -> review proposal.md and delta specs
Apply surface
        -> TDD implementation, spec conformance, and full verification
        -> stop; no archive or branch integration
openspec archive <change-name> --yes
```

The schema evaluates heavy-change signals before implementation. If the change
looks heavy but has no `tasks.md`, the agent must stop and ask whether to:

1. Promote it to heavy and create the additional artifacts.
2. Continue as light without creating `tasks.md`.

Obvious light changes proceed without another question.

### Promote to heavy

Ask the agent:

> Promote change `<name>` to heavy. Create design when useful, then tasks and
> the change-specific plan. Stop after the artifacts are ready for review.

The underlying instruction commands are:

```bash
openspec instructions design --change <name>
openspec instructions tasks  --change <name>
openspec instructions plan   --change <name>
```

These commands print instructions and output paths; they do not create files by
themselves. The agent follows the returned instructions to write the artifacts.

After review:

```text
Apply surface
        -> choose current checkout or a new worktree when not already isolated
        -> execute the reviewed plan with TDD
        -> run final review, spec conformance, and full verification
        -> stop; no archive or branch integration
openspec archive <change-name> --yes
```

Before Heavy execution, the bridge detects whether the current checkout is
already isolated. If it is not, it asks the user whether to continue in place
or create a worktree. Continuing in place does not trigger a bridge-owned
artifact commit. Only when the user chooses a new worktree and the active
change artifacts are uncommitted may the bridge prepare the artifacts for that
worktree, following the user's instructions and the target project's commit
policy. It never stages unrelated files, and it asks when the policy is
unclear.

After the final whole-branch review, `superpowers:subagent-driven-development`
returns to the active Apply surface. Apply compares implementation and tests
with the reviewed specs, lets the user choose between a code fix and an
approved spec revision if they diverge, runs the complete verification command,
and stops. The user archives with the explicit command shown above.

Task-level implementation commits inside a reviewed Heavy plan retain
Superpowers' default behavior. The bridge separately leaves artifact commits,
archive-related commits, closing commit grouping, and branch integration under
the user's instructions and the target project's commit policy.
`superpowers:finishing-a-development-branch` is invoked only when the user
explicitly asks for integration help and the work is actually on a development
branch or worktree; it is never an automatic part of apply.

### Create a change outside an agent session

```bash
openspec new change <kebab-name>
```

### Inspect state

```bash
openspec list
openspec status --change <name>
openspec validate <name>
openspec show <name>
```

## Commands to avoid

| Command/action | Reason |
|---|---|
| Agent-driven OpenSpec sync (`/opsx:sync`, `/opsx-sync`, or `$openspec-sync-specs`) | It performs an agent-driven merge. `openspec archive` uses the deterministic archive parser and its scenario-drop guard. |
| Creating `tasks.md` merely for completeness | `tasks.md` promotes the change to heavy. |
| Naming every heavy plan `plan.md` | Superpowers derives its scratch workspace from the plan basename; unrelated changes would collide. |

## Artifact graph

```text
proposal -> specs ----------------------> apply gate
               |                            |
               +-> design (optional)        +-> light: in-session TDD
               +-> tasks -> plan            +-> heavy: subagent-driven development
```

Design and tasks independently depend on specs. Plan depends on tasks.

## What this repository ships

```text
schemas/spec-tdd/          OpenSpec schema and templates
CLAUDE.md.fragment.md      Claude Code routing instructions
AGENTS.md.fragment.md      Codex routing instructions
agent-rules/cursor/        Cursor Project Rule
README.md                  Installation and operation guide
```

No installer, package manifest, wrapper command, hook, or CI workflow is
required. Installation is a schema copy plus agent-routing configuration.

## Upgrade checks

After upgrading OpenSpec or Superpowers:

1. Run `openspec schema validate spec-tdd` and verify `openspec/config.yaml`
   still selects `schema: spec-tdd`.
2. Confirm the target agent's Propose surface stops when `proposal` and `specs`
   are complete.
3. Confirm a light change reaches apply with no `tasks.md`.
4. Confirm heavy plan headings still match `### Task N: <name>` and checkboxes
   remain at column zero.
5. Check whether `subagent-driven-development` now activates TDD itself. In
   Superpowers 6.2.0 it does not, so the schema explicitly marks every dispatch
   as TDD-required.
6. Confirm the Claude Code, Codex, and Cursor routing assets still suppress a
   second brainstorming workflow and keep archive/integration outside apply.
7. Run one light and one heavy change in a disposable repository before rolling
   the upgraded bundle into production projects.

## Verified baseline

- OpenSpec CLI 1.6.0
- Superpowers 6.2.0
- Node.js >=20.19.0
- Windows 11 / Git Bash
- Last clean-room verification: 2026-07-27

The clean-room run verified that:

- Apply becomes ready with only `proposal.md` and delta specs.
- The schema's apply instruction is injected unchanged.
- Light archive merges the delta into `openspec/specs/`.
- Heavy instruction commands expose the expected output paths.
- `tasks.md` enables OpenSpec task counting and incomplete-task warnings.
- `openspec archive --json` without `--yes` exits with code 1 and
  `archive_confirmation_required`.
