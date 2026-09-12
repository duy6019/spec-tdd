# <!-- Change Name --> Implementation Plan

> **For the implementing agent:** Execute this plan directly in the active session. Do not delegate to subagents unless the user explicitly requests it. Use TDD for every implementation task, and perform code review once after all tasks are complete rather than after each task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** <!-- One sentence describing what this builds -->

**Architecture:** <!-- 2-3 sentences about approach -->

**Tech Stack:** <!-- Key technologies and libraries -->

## Global Constraints

<!-- Project-wide requirements copied verbatim from the specs and design:
     version floors, dependency limits, naming rules, platform requirements.
     One line each. Every task's requirements implicitly include this section. -->

- Prefer straightforward, readable code and clear function and variable names.
- Use the simplest design that satisfies the requirements. Avoid unnecessary
  abstractions and over-engineering.

---

### Task 1: <!-- Component Name -->

**Files:**
- Create: `<!-- exact/path/to/file -->`
- Test: `<!-- exact/path/to/test -->`

**Interfaces:**
- Consumes: <!-- exact signatures this task uses from earlier tasks -->
- Produces: <!-- exact function names, parameter and return types later tasks rely on -->

- [ ] **Step 1: Write the failing test**

<!-- actual test code, not a description -->

- [ ] **Step 2: Run the test and watch it fail**

Run: `<!-- exact command -->`
Expected: FAIL with `<!-- expected message -->`

- [ ] **Step 3: Write the minimal implementation**

<!-- actual code, not a description -->

- [ ] **Step 4: Run the test and watch it pass**

Run: `<!-- exact command -->`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add <!-- paths --> && git commit -m "<!-- message -->"
```

<!--
FORMAT RULES — these are machine contracts, not style:
  1. Task headings MUST be `### Task N: <name>`, matching
     superpowers:writing-plans 6.2.0. task-brief accepts one or more # characters
     but still requires Task N at the start of the heading text.
  2. Every checkbox MUST start at column 0.
     OpenSpec's checkbox regexes anchor ^ directly to [-*]; indented checkboxes are invisible.
  3. No placeholders in a finished plan. "TBD", "add error handling", "similar to Task N",
     and steps without code are plan failures — the implementer sees only their own task.
-->
