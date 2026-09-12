<!-- Add this section to CLAUDE.md at the target project root. -->
<!-- Keep it outside any generated OpenSpec marker block. -->

## spec-tdd workflow routing

This repository uses the OpenSpec `spec-tdd` schema with Superpowers.
Project context and non-negotiable constraints belong in `openspec/config.yaml`.

### Agent bootstrap and workflow authority

Honor the host agent's mandatory skill-discovery/bootstrap step before taking
project action.

Do not use OpenSpec by default. Activate this workflow only when the user
explicitly asks to use OpenSpec, invokes an OpenSpec command or skill, or asks
to continue an already active OpenSpec change. Merely discussing OpenSpec or
having OpenSpec files in the repository does not authorize its use. Otherwise,
implement the request directly without running OpenSpec commands or creating
OpenSpec artifacts. Once the workflow is activated, run `openspec list` before
selecting a change and follow the routing below.

Do not invoke `superpowers:brainstorming` as a separate workflow. The user
explicitly authorizes this adaptation: `/opsx:propose`, review of `proposal.md`,
and review of the delta specs are this workflow's design and approval gate.
Invoke brainstorming only when the user explicitly asks for exploratory
discovery before creating an OpenSpec change. In that case, redirect its output
into the active change and do not create `docs/superpowers/`.

Tier selection is defined exclusively by `openspec/schemas/spec-tdd/schema.yaml`.
Do not duplicate tier criteria in this file. If the schema detects heavy-change
signals while the change has no `tasks.md`, ask the user whether to promote the
change before creating heavy artifacts.

### Light tier

- Skip `superpowers:writing-plans`; light changes have no plan file.
- Do not create `docs/superpowers/`.

Flow: `/opsx:propose` -> review artifacts -> `/opsx:apply` (implement and
verify, then stop) -> user explicitly runs
`openspec archive <change-name> --yes`.

### Heavy tier

Heavy changes add `tasks.md` and `<change-name>-plan.md`, plus `design.md` only
when the schema's design criteria apply.
`superpowers:writing-plans` writes the plan directly into the active OpenSpec
change directory, never into `docs/superpowers/plans/`.

The plan filename must be `<change-name>-plan.md`, never `plan.md`.
`sdd-workspace` derives its workspace slug from the plan basename; a shared
`plan.md` name would make unrelated changes collide.

### Implementation defaults

- Implement directly in the active agent session by default. Do not use
  subagents or delegate work unless the user explicitly requests it.
- Do not perform code review after individual tasks. After all implementation
  tasks are complete, perform one review of the whole change before final
  verification.
- Prefer straightforward, readable code with clear function and variable
  names. Use the simplest design that satisfies the reviewed requirements;
  avoid unnecessary abstractions and over-engineering.

### Closing rules

- `/opsx:apply` owns implementation and verification only. It must stop before
  archive, sync, branch integration, or closing commits.
- The user closes a verified change explicitly with
  `openspec archive <change-name> --yes`. Do not use `/opsx:sync`; that path
  performs an agent-driven merge without the CLI archive parser's scenario-drop
  guard.
- After archive, leave commit grouping to the user's instructions and the
  project's commit policy. Never stage unrelated changes.
- Invoke `superpowers:finishing-a-development-branch` only when the user asks
  for integration help and the work is actually on a development branch or
  worktree. Never invoke it automatically or treat main/master as a feature
  branch.
- `ADDED` means absent from the current OpenSpec, not absent from the code. If
  `openspec/specs/` starts empty, the first delta for an existing capability is
  usually `ADDED`. Using `MODIFIED` for a requirement absent from the living
  spec causes archive to fail.
- Do not backfill the entire existing system. Specify only the behavior about
  to change.
