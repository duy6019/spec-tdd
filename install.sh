#!/usr/bin/env bash
# Installs the spec-tdd bridge into a target OpenSpec project.
# See README.md for the full manual procedure this script automates
# (steps 3-7; step 1 [Superpowers] and step 5 [project context] stay manual).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE_DIR="$SCRIPT_DIR"

TARGET=""
AGENTS=""
DRY_RUN=0
FORCE=0

usage() {
  cat <<'EOF'
Usage: install.sh --target <path> --agents <list> [--dry-run] [--force]

  --target <path>   Path to the project receiving the spec-tdd bridge.
  --agents <list>   Comma-separated agents to install routing for.
                     Valid values: claude, codex, cursor
  --dry-run         Print planned actions; write nothing.
  --force           Allow overwriting an existing, different schema selection.

Example:
  ./install.sh --target ../my-project --agents claude,cursor
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --target)
      TARGET="${2:-}"
      shift 2
      ;;
    --target=*)
      TARGET="${1#--target=}"
      shift
      ;;
    --agents)
      AGENTS="${2:-}"
      shift 2
      ;;
    --agents=*)
      AGENTS="${1#--agents=}"
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --force)
      FORCE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unrecognized argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -z "$TARGET" ] || [ -z "$AGENTS" ]; then
  echo "error: --target and --agents are required" >&2
  usage >&2
  exit 1
fi

IFS=',' read -r -a AGENT_LIST <<< "$AGENTS"
for agent in "${AGENT_LIST[@]}"; do
  case "$agent" in
    claude|codex|cursor) ;;
    *)
      echo "error: unknown agent '$agent' (valid: claude, codex, cursor)" >&2
      exit 1
      ;;
  esac
done

log_step() {
  echo "[$1/5] $2"
}

MARKER_BEGIN="<!-- BEGIN spec-tdd bridge — managed by install; do not edit inside -->"
MARKER_END="<!-- END spec-tdd bridge -->"

strip_installer_comment() {
  # Drops leading "<!-- ... -->" installer-instruction lines and the blank
  # lines that follow, up to the first real content line.
  awk '
    BEGIN { skipping = 1 }
    skipping && /^<!--.*-->[[:space:]]*$/ { next }
    skipping && /^[[:space:]]*$/ { next }
    { skipping = 0; print }
  ' "$1"
}

check_marker_integrity() {
  # Verifies dest_file has either no managed block, or exactly one
  # well-formed BEGIN/END pair with BEGIN before END. Must run before any
  # writes: a missing/duplicated/misordered marker means the file was
  # manually edited or left in a partial state, and blindly rewriting
  # "between the markers" would silently drop everything after a truncated
  # block.
  local dest_file="$1"

  if [ ! -f "$dest_file" ]; then
    return 0
  fi

  local begin_count end_count
  begin_count="$(grep -cF -- "$MARKER_BEGIN" "$dest_file" || true)"
  end_count="$(grep -cF -- "$MARKER_END" "$dest_file" || true)"

  if [ "$begin_count" -eq 0 ] && [ "$end_count" -eq 0 ]; then
    return 0
  fi

  if [ "$begin_count" -ne 1 ] || [ "$end_count" -ne 1 ]; then
    echo "error: $dest_file has a malformed spec-tdd managed block (found $begin_count BEGIN marker(s) and $end_count END marker(s); expected exactly one of each, or none)" >&2
    echo "Fix or remove the existing block by hand, then re-run the installer." >&2
    return 1
  fi

  local begin_line end_line
  begin_line="$(grep -nF -- "$MARKER_BEGIN" "$dest_file" | head -n1 | cut -d: -f1)"
  end_line="$(grep -nF -- "$MARKER_END" "$dest_file" | head -n1 | cut -d: -f1)"

  if [ "$begin_line" -ge "$end_line" ]; then
    echo "error: $dest_file has a misordered spec-tdd managed block (BEGIN at line $begin_line, END at line $end_line)" >&2
    echo "Fix or remove the existing block by hand, then re-run the installer." >&2
    return 1
  fi

  return 0
}

# --- Preconditions ---------------------------------------------------------

for asset in \
  "schemas/spec-tdd/schema.yaml" \
  "CLAUDE.md.fragment.md" \
  "AGENTS.md.fragment.md" \
  "agent-rules/cursor/spec-tdd.mdc"
do
  if [ ! -e "$BRIDGE_DIR/$asset" ]; then
    echo "error: bridge asset missing: $BRIDGE_DIR/$asset" >&2
    exit 1
  fi
done

if [ ! -d "$TARGET" ]; then
  echo "error: --target '$TARGET' does not exist or is not a directory" >&2
  exit 1
fi

TARGET="$(cd "$TARGET" && pwd)"

if [ ! -f "$TARGET/openspec/config.yaml" ]; then
  echo "error: $TARGET/openspec/config.yaml not found" >&2
  echo "Run this first: openspec init --tools $AGENTS \"$TARGET\"" >&2
  exit 1
fi

if [ ! -d "$TARGET/.git" ]; then
  echo "warning: $TARGET is not a Git repository" >&2
fi

CONFIG="$TARGET/openspec/config.yaml"
EXISTING_SCHEMA_LINE="$(grep -E '^schema:[[:space:]]*.*$' "$CONFIG" | head -n1 || true)"

if [ -n "$EXISTING_SCHEMA_LINE" ]; then
  EXISTING_VALUE="$(echo "$EXISTING_SCHEMA_LINE" | sed -E 's/^schema:[[:space:]]*//' | sed -E 's/[[:space:]]*$//')"
  if [ "$EXISTING_VALUE" != "spec-tdd" ] && [ "$FORCE" -ne 1 ]; then
    echo "error: $CONFIG already selects schema '$EXISTING_VALUE'" >&2
    echo "Pass --force to overwrite it with 'spec-tdd'." >&2
    exit 1
  fi
fi

for agent in "${AGENT_LIST[@]}"; do
  case "$agent" in
    claude)
      check_marker_integrity "$TARGET/CLAUDE.md" || exit 1
      ;;
    codex)
      check_marker_integrity "$TARGET/AGENTS.md" || exit 1
      ;;
  esac
done

if [ "$DRY_RUN" -eq 1 ]; then
  echo "-- dry run: no files will be written --"
fi

# --- Step 3: copy schema ----------------------------------------------------

log_step 1 "Copy schema into $TARGET/openspec/schemas/spec-tdd"
if [ "$DRY_RUN" -eq 1 ]; then
  echo "  would: mkdir -p \"$TARGET/openspec/schemas/spec-tdd\""
  echo "  would: copy \"$BRIDGE_DIR/schemas/spec-tdd/.\" -> \"$TARGET/openspec/schemas/spec-tdd/\""
else
  mkdir -p "$TARGET/openspec/schemas/spec-tdd"
  cp -r "$BRIDGE_DIR/schemas/spec-tdd/." "$TARGET/openspec/schemas/spec-tdd/"
fi

# --- Step 4: select schema ---------------------------------------------------

log_step 2 "Select schema in $TARGET/openspec/config.yaml"

if [ "$DRY_RUN" -eq 1 ]; then
  if [ -n "$EXISTING_SCHEMA_LINE" ]; then
    echo "  would: rewrite existing 'schema:' line in $CONFIG to 'schema: spec-tdd'"
  else
    echo "  would: prepend 'schema: spec-tdd' as the first line of $CONFIG"
  fi
else
  TMP_CONFIG="$(mktemp)"
  if [ -n "$EXISTING_SCHEMA_LINE" ]; then
    awk '
      !done && /^schema:[[:space:]]*.*$/ { print "schema: spec-tdd"; done=1; next }
      { print }
    ' "$CONFIG" > "$TMP_CONFIG"
  else
    { echo "schema: spec-tdd"; cat "$CONFIG"; } > "$TMP_CONFIG"
  fi
  mv "$TMP_CONFIG" "$CONFIG"
fi

# --- Step 5: project context (manual, print only) ---------------------------

log_step 3 "Project context (manual step, not written)"
cat <<'EOF'
  Add project-specific context to openspec/config.yaml by hand, e.g.:

    schema: spec-tdd

    context: |
      Tech stack: <language/framework and version>
      Test command: <exact command that runs the full test suite>
      Project constraints:
      - <non-negotiable constraint>
EOF

# --- Step 6: routing instructions -------------------------------------------

log_step 4 "Install agent routing instructions"

install_fragment() {
  local fragment_file="$1"
  local dest_file="$2"

  local body
  body="$(strip_installer_comment "$fragment_file")"

  if [ "$DRY_RUN" -eq 1 ]; then
    if [ -f "$dest_file" ] && grep -qF "$MARKER_BEGIN" "$dest_file"; then
      echo "  would: replace managed block in $dest_file"
    else
      echo "  would: append managed block to $dest_file (created if absent)"
    fi
    return
  fi

  if [ ! -f "$dest_file" ]; then
    : > "$dest_file"
  fi

  if grep -qF "$MARKER_BEGIN" "$dest_file"; then
    local tmp_file
    tmp_file="$(mktemp)"
    awk -v begin="$MARKER_BEGIN" -v end="$MARKER_END" -v body="$body" '
      $0 == begin { print; print body; skipping = 1; next }
      skipping && $0 == end { print; skipping = 0; next }
      skipping { next }
      { print }
    ' "$dest_file" > "$tmp_file"
    mv "$tmp_file" "$dest_file"
  else
    {
      printf '\n%s\n' "$MARKER_BEGIN"
      printf '%s\n' "$body"
      printf '%s\n' "$MARKER_END"
    } >> "$dest_file"
  fi
}

for agent in "${AGENT_LIST[@]}"; do
  case "$agent" in
    cursor)
      if [ "$DRY_RUN" -eq 1 ]; then
        echo "  would: mkdir -p \"$TARGET/.cursor/rules\""
        echo "  would: copy \"$BRIDGE_DIR/agent-rules/cursor/spec-tdd.mdc\" -> \"$TARGET/.cursor/rules/spec-tdd.mdc\""
      else
        mkdir -p "$TARGET/.cursor/rules"
        cp "$BRIDGE_DIR/agent-rules/cursor/spec-tdd.mdc" "$TARGET/.cursor/rules/spec-tdd.mdc"
      fi
      ;;
    claude)
      install_fragment "$BRIDGE_DIR/CLAUDE.md.fragment.md" "$TARGET/CLAUDE.md"
      ;;
    codex)
      install_fragment "$BRIDGE_DIR/AGENTS.md.fragment.md" "$TARGET/AGENTS.md"
      ;;
  esac
done

# --- Step 7: verify ----------------------------------------------------------

log_step 5 "Verify"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "  would: run verification (openspec schema validate, openspec schemas, config check)"
  echo ""
  echo "Dry run complete. No files were written."
  exit 0
fi

VERIFY_FAILED=0

if command -v openspec >/dev/null 2>&1; then
  if ! (cd "$TARGET" && openspec schema validate spec-tdd); then
    echo "error: 'openspec schema validate spec-tdd' failed" >&2
    VERIFY_FAILED=1
  fi

  if ! (cd "$TARGET" && openspec schemas) | grep -q 'spec-tdd (project)'; then
    echo "error: 'openspec schemas' does not list 'spec-tdd (project)'" >&2
    VERIFY_FAILED=1
  fi
else
  echo "warning: 'openspec' CLI not found on PATH; skipping CLI verification checks" >&2
fi

if ! grep -Eq '^schema:[[:space:]]+spec-tdd[[:space:]]*$' "$CONFIG"; then
  echo "error: $CONFIG does not select 'schema: spec-tdd'" >&2
  VERIFY_FAILED=1
fi

if [ "$VERIFY_FAILED" -ne 0 ]; then
  echo "" >&2
  echo "Verification failed. See errors above." >&2
  exit 1
fi

cat <<EOF

Installed spec-tdd bridge into: $TARGET
Agents configured: $AGENTS
Verification passed.

Remaining manual steps:
  1. Install Superpowers 6.2.0 for each agent above (harness-specific; see
     README.md "Install Superpowers for each agent"). Restart the agent and
     confirm the plugin version afterward.
  2. Add project context to $CONFIG (see step 3 output above).
EOF
