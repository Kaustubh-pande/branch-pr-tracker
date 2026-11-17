# Branch PR Tracker

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![GitHub CLI](https://img.shields.io/badge/Requires-GitHub_CLI-blue.svg)](https://cli.github.com/)

A powerful command-line tool to track and manage pull requests across multiple repositories targeting specific branches.

Perfect for managing **multi-repo release workflows**, tracking **feature branches**, or monitoring **hotfix PRs** across your GitHub organization.

![Demo](https://img.shields.io/badge/status-active-success)
![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Scripts](#scripts)
- [Quick Reference](#quick-reference)
- [Contributing](#contributing)
- [License](#license)

## Features

- 🎯 **Multi-repo tracking** - Monitor PRs across multiple repositories from a single command
- ⚡ **Fast scanning** - Configurable repository list for optimal performance
- 📊 **Live progress** - Real-time progress indicators with percentage completion
- 🎨 **Rich output** - Color-coded terminal output with clean table formatting
- 📋 **Clipboard integration** - Copy all PR URLs with one command (macOS)
- ✅ **Automated workflows** - Check PR status and approve with custom commands
- 📁 **Flexible grouping** - Group by repository, PR pattern, or none
- ⚙️ **Fully configurable** - JSON config for organization, repos, and branches
- 🔄 **Any workflow** - Works with releases, features, hotfixes, or any branch naming

## Prerequisites

- **GitHub CLI (`gh`)** - [Install from cli.github.com](https://cli.github.com/)
  ```bash
  # macOS
  brew install gh
  
  # Authenticate
  gh auth login
  ```
- **jq** - JSON processor
  ```bash
  # macOS
  brew install jq
  
  # Linux
  apt-get install jq
  ```

## Installation

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/branch-pr-tracker.git
cd branch-pr-tracker

# Copy the example config and customize it
cp config.example.json config.json

# Edit config.json with your organization, repositories, and default branches
# See Configuration section below

# Make scripts executable
chmod +x *.sh

# Verify installation
make help
```

## Configuration

Edit `config.json` to customize for your organization:

```json
{
  "organization": "your-org-name",
  "repositories": [
    "repo-1",
    "repo-2",
    "repo-3"
  ],
  "default_branches": [
    "main",
    "release-v1.0",
    "hotfix-urgent"
  ]
}
```

**Configuration fields:**

- `organization` - Your GitHub organization name
- `repositories` - List of repository names to scan (without org prefix)
- `default_branches` - Branches to track when no branches specified on CLI
- `pr_patterns` - (Optional) Custom regex patterns for grouping PRs

**Note:** `config.json` is git-ignored. Use `config.example.json` as a template.

## Example Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Open Pull Requests - your-organization
Branches: release-v1.17 release-1.17
Config: config.json
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 Scanning repositories for open PRs...

  # | Repository                    |   PR | Title                                | Link
----|-------------------------------|------|--------------------------------------|----------
  1 | your-org/api-server           | 1234 | Fix authentication bug               | https://...
  2 | your-org/web-ui               |  567 | Update dependencies                  | https://...
  3 | your-org/database             |  890 | Add migration for new schema         | https://...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Found 3 open PRs
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Scripts

### `track-prs.sh`

Tracks all open pull requests targeting specific branches across multiple repositories in your configured GitHub organization.

**Usage:**

```bash
# Using default branches from config.json
./track-prs.sh

# Specify custom branches (overrides config)
./track-prs.sh main develop
./track-prs.sh release-v1.18 hotfix-2024

# Copy all PR URLs to clipboard (macOS)
./track-prs.sh --copy-links
./track-prs.sh -c main

# Check PR status and approve (customize pattern in script)
./track-prs.sh --konflux-lgtm
./track-prs.sh -k release-v1.17

# Group PRs by pattern or repository
./track-prs.sh --group-by pattern
./track-prs.sh -g repo

# Use custom config file
./track-prs.sh --config my-config.json

# Show help
./track-prs.sh --help
```

**Output Format:**

Markdown table:
```
#   | Repository           | PR   | Title                              | Link
----|----------------------|------|------------------------------------|----------
1   | your-org/repo-1      | 123  | Fix critical bug in auth module    | https://...
2   | your-org/repo-2      | 456  | Add new feature XYZ                | https://...
```

**Requirements:**
- GitHub CLI (`gh`) installed and authenticated
- `jq` for JSON processing
- `config.json` file with your organization settings

---

## Makefile Targets

For convenience, use the Makefile instead of calling scripts directly:

```bash
# Show available targets
make help

# List PRs for all default branches (from config.json)
make list-prs

# List PRs for custom branches
make list-prs-all BRANCHES='main develop feature-xyz'

# 📋 Copy PR URLs to clipboard (macOS)
make copy-prs

# Check and approve PRs (customize the approval logic in script)
make konflux-lgtm
```

**Note:** Some Makefile targets may reference specific branch names. Edit the Makefile to match your workflow.

---

## Quick Reference

| Command | Description |
|---------|-------------|
| `./track-prs.sh` | List PRs for default branches (from config) |
| `./track-prs.sh BRANCH...` | List PRs for specific branches |
| `./track-prs.sh -c` | List + copy URLs to clipboard (macOS) |
| `./track-prs.sh -g repo` | List PRs grouped by repository |
| `./track-prs.sh -g pattern` | List PRs grouped by PR type/pattern |
| `./track-prs.sh --config FILE` | Use custom config file |
| `make list-prs` | List all PRs (default branches) |
| `make copy-prs` | List + copy URLs to clipboard |

---

## Automated PR Approval Workflow

The `--konflux-lgtm` (or `-k`) flag demonstrates an **example automated approval workflow**. 

**This is a customizable feature** - you can modify the script to match your own PR approval patterns (e.g., auto-approve dependency updates, security patches, or any PR matching your criteria).

### How it works (Konflux example):

**What it does:**
1. 🔍 **Scans** all PRs for "Update Konflux references" in title
2. ✅ **Checks status** of all CI checks for each Konflux PR
3. 📊 **Shows results**:
   - ✅ All checks passed - asks if you want to approve
   - ❌ Failed - lists which checks failed
   - ⏳ Pending - lists which checks are still running
4. 💬 **Posts comments** (with confirmation):
   - `/lgtm` - Looks Good To Me
   - `/approve` - Approve the PR

**Usage:**
```bash
# Check and approve Konflux PRs for default branches
./track-prs.sh --konflux-lgtm

# Check Konflux PRs for specific release
./track-prs.sh -k release-v1.17

# Combine with grouping to see all PRs first
./track-prs.sh --group-by pattern --konflux-lgtm
```

**Interactive flow:**
```
[1/11] openshift-knative/eventing#1921
[release-v1.17] Update Konflux references
https://github.com/openshift-knative/eventing/pull/1921

🔍 Checking PR status...
✅ Status: ALL CHECKS PASSED

Passed checks:
  ✅ Konflux kflux-prd-rh02 / kn-eventing-controller-117-on-pull-request
  ✅ renovate/stability-days

Skipped checks:
  ⏭️  Update deps

Do you want to approve this PR with /lgtm and /approve? [y/N]: y

Posting /lgtm...
✓ Posted /lgtm
Posting /approve...
✓ Posted /approve
✅ PR approved!
```

**With pending checks:**
```
[2/11] openshift-knative/eventing-istio#891
[release-v1.17] Update Konflux references
https://github.com/openshift-knative/eventing-istio/pull/891

🔍 Checking PR status...
⏳ Status: PENDING

Pending/In-progress checks:
  ⏳ tide

Passed checks:
  ✅ Konflux kflux-prd-rh02 / kn-eventing-istio-controller-117-on-pull-request
  ✅ renovate/stability-days

Skipped checks:
  ⏭️  Update deps

(Skipped - waiting for checks to complete)
```

**Safety features:**
- ✋ **Asks before posting** - Never posts comments automatically
- 🎯 **Targeted** - Only processes "Update Konflux references" PRs
- 📋 **Clear status** - Shows exactly which checks passed/failed
- ⏭️ **Skip option** - Press `n` or Enter to skip any PR

---

## Use Cases & Examples

### Release Management
Track all PRs targeting release branches across multiple repos:

```bash
# List all PRs for release branches (from config.json)
./track-prs.sh

# Track a new release
./track-prs.sh release-v2.0 release-2.0

# Copy all URLs for stakeholder reporting
./track-prs.sh --copy-links release-v2.0
```

### Feature Branch Tracking
Monitor PRs for a specific feature across repos:

```bash
# Track feature branch PRs
./track-prs.sh feature/new-auth-system

# Group by repository to see which teams have PRs
./track-prs.sh --group-by repo feature/new-auth-system
```

### Hotfix Coordination
Quickly see all hotfix PRs that need attention:

```bash
# List all hotfix PRs
./track-prs.sh hotfix-2024-11

# Group by pattern to see types of fixes
./track-prs.sh --group-by pattern hotfix-2024-11
```

### Automated Workflows
Check PR status and approve automatically:

```bash
# Check PR status and optionally approve
./track-prs.sh --konflux-lgtm main

# Customize the approval logic in the script for your workflow
```

### Save Reports
Export PR lists for documentation:

```bash
# Save table only (no progress indicators)
./track-prs.sh > weekly-prs.md 2>/dev/null

# Save with full output including progress
./track-prs.sh > weekly-prs.md
```

### Multi-Config Setup
Manage different organizations or teams:

```bash
# Use different config for different teams
./track-prs.sh --config team-a-config.json
./track-prs.sh --config team-b-config.json
```

---

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Tips & Notes

- **Performance** - Configure only the repositories you need in `config.json` for faster scans
  - Scanning 15 repos is ~3x faster than scanning 50+ repos
  - Add/remove repos as your needs change
- **Progress indicators** - Live progress bar shows scanning status
  - Example: `🔍 [████████████░░░░] 60% (9/15) api-server`
  - Progress goes to stderr, so use `2>/dev/null` for clean file output
- **Pagination** - Automatically handles up to 1000 PRs per branch per repo
- **Branch naming** - Works with any branch naming convention (release-*, feature/*, hotfix/*, etc.)
- **Output streams** - Error messages → stderr, table → stdout (easy to pipe/redirect)
- **Safety** - Read-only operations, no modifications unless using approval flags
- **Clickable links** - Cmd+Click (macOS) or Ctrl+Click (Linux) to open PRs in browser

## Troubleshooting

**"Config file not found" error:**
```bash
cp config.example.json config.json
# Edit config.json with your settings
```

**"gh: command not found":**
```bash
# Install GitHub CLI
brew install gh  # macOS
# Then authenticate
gh auth login
```

**No PRs found:**
- Verify organization name in `config.json`
- Check repository names (no org prefix, e.g., "repo-name" not "org/repo-name")
- Confirm branches exist in those repositories
- Ensure `gh` is authenticated: `gh auth status`
