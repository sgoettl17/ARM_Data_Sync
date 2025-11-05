<#!
.SYNOPSIS
    Automates creation of an agent worktree and opens a new PowerShell session there.

.DESCRIPTION
    Keeps master up to date, generates a sanitized branch name (agent/<agent>/<topic>),
    creates the worktree under worktrees/<agent>/<topic>, and launches a new terminal
    window rooted in that worktree for parallel development.

.PARAMETER Agent
    Identifier for the agent (e.g., "claude", "gemini").

.PARAMETER Topic
    Brief slug for the task (e.g., "schedule-health-report").

.PARAMETER SkipPull
    Skips fetch/pull if you already know master is current.

.EXAMPLE
    pwsh scripts/new-worktree.ps1 -Agent claude -Topic schedule-health

!#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Agent,
    [Parameter(Mandatory = $true)][string]$Topic,
    [switch]$SkipPull
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Git {
    param([string[]]$Arguments)

    & git @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "git $(@Arguments -join ' ') failed with exit code $LASTEXITCODE."
    }
}

function ConvertTo-Slug {
    param([string]$Value)

    return (($Value.Trim().ToLower() -replace '[^a-z0-9]+', '-') -replace '^-+|-+$', '')
}

$repoRoot = Split-Path -Parent $PSCommandPath
Set-Location -LiteralPath $repoRoot

if (-not $SkipPull) {
    Invoke-Git @('fetch', 'origin')
    Invoke-Git @('pull', '--ff-only', 'origin', 'master')
}

$agentSlug = ConvertTo-Slug $Agent
$topicSlug = ConvertTo-Slug $Topic

if (-not $agentSlug) { throw 'Agent slug resolves to empty value.' }
if (-not $topicSlug) { throw 'Topic slug resolves to empty value.' }

$branchName = "agent/$agentSlug/$topicSlug"
$worktreePath = Join-Path -Path $repoRoot -ChildPath (Join-Path -Path 'worktrees' -ChildPath (Join-Path -Path $agentSlug -ChildPath $topicSlug))

if (Test-Path -LiteralPath $worktreePath) {
    throw "Worktree path already exists: $worktreePath"
}

& git rev-parse --verify $branchName *> $null
if ($LASTEXITCODE -eq 0) {
    throw "Branch '$branchName' already exists. Remove it or choose a different topic."
}

New-Item -ItemType Directory -Path (Split-Path -Parent $worktreePath) -Force | Out-Null

Invoke-Git @('worktree', 'add', $worktreePath, '-b', $branchName, 'master')

Write-Host "Created worktree at $worktreePath on branch $branchName" -ForegroundColor Green

$pwsh = (Get-Command pwsh).Source
Start-Process -FilePath $pwsh -ArgumentList '-NoExit', '-NoLogo' -WorkingDirectory $worktreePath | Out-Null

Write-Host 'Opened new PowerShell window in the worktree. Happy hacking!' -ForegroundColor Green
