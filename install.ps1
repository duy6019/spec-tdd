# Installs the spec-tdd bridge into a target OpenSpec project.
# See README.md for the full manual procedure this script automates
# (steps 3-7; step 1 [Superpowers] and step 5 [project context] stay manual).

param(
    [Parameter(Mandatory = $false)]
    [string]$Target,

    [Parameter(Mandatory = $false)]
    [string]$Agents,

    [switch]$DryRun,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Show-Usage {
    @'
Usage: install.ps1 -Target <path> -Agents <list> [-DryRun] [-Force]

  -Target <path>   Path to the project receiving the spec-tdd bridge.
  -Agents <list>   Comma-separated agents to install routing for.
                    Valid values: claude, codex, cursor
  -DryRun          Print planned actions; write nothing.
  -Force           Allow overwriting an existing, different schema selection.

Example:
  .\install.ps1 -Target ..\my-project -Agents claude,cursor
'@ | Write-Output
}

function Write-Utf8NoBom {
    param([string]$Path, [string]$Content)
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Write-Step {
    param([int]$Number, [string]$Message)
    Write-Output "[$Number/5] $Message"
}

$MarkerBegin = '<!-- BEGIN spec-tdd bridge — managed by install; do not edit inside -->'
$MarkerEnd = '<!-- END spec-tdd bridge -->'

function Get-StrippedFragment {
    param([string]$Path)
    $lines = Get-Content -Path $Path -Encoding UTF8
    $skipping = $true
    $result = @()
    foreach ($line in $lines) {
        if ($skipping) {
            if ($line -match '^<!--.*-->\s*$') { continue }
            if ($line -match '^\s*$') { continue }
            $skipping = $false
        }
        $result += $line
    }
    return ($result -join "`n")
}

function Test-MarkerIntegrity {
    # Verifies DestFile has either no managed block, or exactly one
    # well-formed BEGIN/END pair with BEGIN before END. Must run before any
    # writes: a missing/duplicated/misordered marker means the file was
    # manually edited or left in a partial state, and blindly rewriting
    # "between the markers" would silently drop everything after a truncated
    # block.
    param([string]$DestFile)

    if (-not (Test-Path $DestFile)) {
        return $true
    }

    $content = Get-Content -Path $DestFile -Raw -Encoding UTF8
    if ($null -eq $content) { $content = '' }

    $beginCount = ([regex]::Matches($content, [regex]::Escape($MarkerBegin))).Count
    $endCount = ([regex]::Matches($content, [regex]::Escape($MarkerEnd))).Count

    if ($beginCount -eq 0 -and $endCount -eq 0) {
        return $true
    }

    if ($beginCount -ne 1 -or $endCount -ne 1) {
        Write-Error "$DestFile has a malformed spec-tdd managed block (found $beginCount BEGIN marker(s) and $endCount END marker(s); expected exactly one of each, or none)`nFix or remove the existing block by hand, then re-run the installer."
        return $false
    }

    $beginIndex = $content.IndexOf($MarkerBegin)
    $endIndex = $content.IndexOf($MarkerEnd)
    if ($beginIndex -ge $endIndex) {
        Write-Error "$DestFile has a misordered spec-tdd managed block (BEGIN appears after END)`nFix or remove the existing block by hand, then re-run the installer."
        return $false
    }

    return $true
}

if (-not $Target -or -not $Agents) {
    Write-Error "-Target and -Agents are required"
    Show-Usage
    exit 1
}

$AgentList = $Agents -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
foreach ($agent in $AgentList) {
    if ($agent -ne 'claude' -and $agent -ne 'codex' -and $agent -ne 'cursor') {
        Write-Error "unknown agent '$agent' (valid: claude, codex, cursor)"
        exit 1
    }
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BridgeDir = $ScriptDir

# --- Preconditions ----------------------------------------------------------

$RequiredAssets = @(
    'schemas\spec-tdd\schema.yaml',
    'CLAUDE.md.fragment.md',
    'AGENTS.md.fragment.md',
    'agent-rules\cursor\spec-tdd.mdc'
)
foreach ($asset in $RequiredAssets) {
    $assetPath = Join-Path $BridgeDir $asset
    if (-not (Test-Path $assetPath)) {
        Write-Error "bridge asset missing: $assetPath"
        exit 1
    }
}

if (-not (Test-Path $Target -PathType Container)) {
    Write-Error "-Target '$Target' does not exist or is not a directory"
    exit 1
}

$Target = (Resolve-Path $Target).Path

$ConfigPath = Join-Path $Target 'openspec\config.yaml'
if (-not (Test-Path $ConfigPath)) {
    Write-Error "$ConfigPath not found`nRun this first: openspec init --tools $Agents `"$Target`""
    exit 1
}

if (-not (Test-Path (Join-Path $Target '.git'))) {
    Write-Warning "$Target is not a Git repository"
}

$ConfigLines = @(Get-Content -Path $ConfigPath -Encoding UTF8)
$ExistingIndex = -1
for ($i = 0; $i -lt $ConfigLines.Length; $i++) {
    if ($ConfigLines[$i] -match '^schema:\s*.*$') {
        $ExistingIndex = $i
        break
    }
}

if ($ExistingIndex -ge 0) {
    $ExistingValue = ($ConfigLines[$ExistingIndex] -replace '^schema:\s*', '').Trim()
    if ($ExistingValue -ne 'spec-tdd' -and -not $Force) {
        Write-Error "$ConfigPath already selects schema '$ExistingValue'`nPass -Force to overwrite it with 'spec-tdd'."
        exit 1
    }
}

foreach ($agent in $AgentList) {
    switch ($agent) {
        'claude' {
            if (-not (Test-MarkerIntegrity (Join-Path $Target 'CLAUDE.md'))) { exit 1 }
        }
        'codex' {
            if (-not (Test-MarkerIntegrity (Join-Path $Target 'AGENTS.md'))) { exit 1 }
        }
    }
}

if ($DryRun) {
    Write-Output "-- dry run: no files will be written --"
}

# --- Step 3: copy schema -----------------------------------------------------

Write-Step 1 "Copy schema into $Target\openspec\schemas\spec-tdd"
$SchemaDest = Join-Path $Target 'openspec\schemas\spec-tdd'
$SchemaSrc = Join-Path $BridgeDir 'schemas\spec-tdd'
if ($DryRun) {
    Write-Output "  would: New-Item -ItemType Directory -Force -Path '$SchemaDest'"
    Write-Output "  would: copy '$SchemaSrc\*' -> '$SchemaDest'"
} else {
    New-Item -ItemType Directory -Force -Path $SchemaDest | Out-Null
    Copy-Item -Recurse -Force (Join-Path $SchemaSrc '*') $SchemaDest
}

# --- Step 4: select schema ----------------------------------------------------

Write-Step 2 "Select schema in $ConfigPath"

if ($DryRun) {
    if ($ExistingIndex -ge 0) {
        Write-Output "  would: rewrite existing 'schema:' line in $ConfigPath to 'schema: spec-tdd'"
    } else {
        Write-Output "  would: prepend 'schema: spec-tdd' as the first line of $ConfigPath"
    }
} else {
    if ($ExistingIndex -ge 0) {
        $ConfigLines[$ExistingIndex] = 'schema: spec-tdd'
        $NewConfig = ($ConfigLines -join "`n")
    } else {
        $NewConfig = "schema: spec-tdd`n" + ($ConfigLines -join "`n")
    }
    Write-Utf8NoBom -Path $ConfigPath -Content ($NewConfig + "`n")
}

# --- Step 5: project context (manual, print only) ---------------------------

Write-Step 3 "Project context (manual step, not written)"
@'
  Add project-specific context to openspec/config.yaml by hand, e.g.:

    schema: spec-tdd

    context: |
      Tech stack: <language/framework and version>
      Test command: <exact command that runs the full test suite>
      Project constraints:
      - <non-negotiable constraint>
'@ | Write-Output

# --- Step 6: routing instructions -------------------------------------------

Write-Step 4 "Install agent routing instructions"

function Install-Fragment {
    param([string]$FragmentFile, [string]$DestFile)

    $body = Get-StrippedFragment -Path $FragmentFile

    if ($DryRun) {
        if ((Test-Path $DestFile) -and ((Get-Content -Path $DestFile -Raw -Encoding UTF8) -like "*$MarkerBegin*")) {
            Write-Output "  would: replace managed block in $DestFile"
        } else {
            Write-Output "  would: append managed block to $DestFile (created if absent)"
        }
        return
    }

    if (-not (Test-Path $DestFile)) {
        Write-Utf8NoBom -Path $DestFile -Content ''
    }

    $existing = Get-Content -Path $DestFile -Raw -Encoding UTF8
    if ($null -eq $existing) { $existing = '' }

    if ($existing -like "*$MarkerBegin*") {
        $lines = $existing -split "`n"
        $out = @()
        $skipping = $false
        foreach ($line in $lines) {
            $trimmed = $line.TrimEnd("`r")
            if ($trimmed -eq $MarkerBegin) {
                $out += $trimmed
                $out += $body
                $skipping = $true
                continue
            }
            if ($skipping -and $trimmed -eq $MarkerEnd) {
                $out += $trimmed
                $skipping = $false
                continue
            }
            if ($skipping) { continue }
            $out += $trimmed
        }
        Write-Utf8NoBom -Path $DestFile -Content (($out -join "`n") + "`n")
    } else {
        $block = "`n$MarkerBegin`n$body`n$MarkerEnd`n"
        Write-Utf8NoBom -Path $DestFile -Content ($existing.TrimEnd("`n", "`r") + $block)
    }
}

foreach ($agent in $AgentList) {
    switch ($agent) {
        'cursor' {
            $CursorDest = Join-Path $Target '.cursor\rules'
            $CursorFile = Join-Path $CursorDest 'spec-tdd.mdc'
            $CursorSrc = Join-Path $BridgeDir 'agent-rules\cursor\spec-tdd.mdc'
            if ($DryRun) {
                Write-Output "  would: New-Item -ItemType Directory -Force -Path '$CursorDest'"
                Write-Output "  would: copy '$CursorSrc' -> '$CursorFile'"
            } else {
                New-Item -ItemType Directory -Force -Path $CursorDest | Out-Null
                Copy-Item -Force $CursorSrc $CursorFile
            }
        }
        'claude' {
            Install-Fragment -FragmentFile (Join-Path $BridgeDir 'CLAUDE.md.fragment.md') -DestFile (Join-Path $Target 'CLAUDE.md')
        }
        'codex' {
            Install-Fragment -FragmentFile (Join-Path $BridgeDir 'AGENTS.md.fragment.md') -DestFile (Join-Path $Target 'AGENTS.md')
        }
    }
}

# --- Step 7: verify ----------------------------------------------------------

Write-Step 5 "Verify"

if ($DryRun) {
    Write-Output "  would: run verification (openspec schema validate, openspec schemas, config check)"
    Write-Output ""
    Write-Output "Dry run complete. No files were written."
    exit 0
}

$VerifyFailed = $false

$openspecCmd = Get-Command openspec -ErrorAction SilentlyContinue
if ($openspecCmd) {
    Push-Location $Target
    try {
        & openspec schema validate spec-tdd
        if ($LASTEXITCODE -ne 0) {
            Write-Error "'openspec schema validate spec-tdd' failed"
            $VerifyFailed = $true
        }

        $schemasOutput = & openspec schemas
        if (-not ($schemasOutput -join "`n").Contains('spec-tdd (project)')) {
            Write-Error "'openspec schemas' does not list 'spec-tdd (project)'"
            $VerifyFailed = $true
        }
    } finally {
        Pop-Location
    }
} else {
    Write-Warning "'openspec' CLI not found on PATH; skipping CLI verification checks"
}

$FinalConfig = Get-Content -Path $ConfigPath -Encoding UTF8
$SchemaLineOk = $false
foreach ($line in $FinalConfig) {
    if ($line -match '^schema:\s+spec-tdd\s*$') {
        $SchemaLineOk = $true
        break
    }
}
if (-not $SchemaLineOk) {
    Write-Error "$ConfigPath does not select 'schema: spec-tdd'"
    $VerifyFailed = $true
}

if ($VerifyFailed) {
    Write-Output ""
    Write-Error "Verification failed. See errors above."
    exit 1
}

Write-Output ""
Write-Output "Installed spec-tdd bridge into: $Target"
Write-Output "Agents configured: $Agents"
Write-Output "Verification passed."
Write-Output ""
Write-Output "Remaining manual steps:"
Write-Output "  1. Install Superpowers 6.2.0 for each agent above (harness-specific; see"
Write-Output "     README.md `"Install Superpowers for each agent`"). Restart the agent and"
Write-Output "     confirm the plugin version afterward."
Write-Output "  2. Add project context to $ConfigPath (see step 3 output above)."
