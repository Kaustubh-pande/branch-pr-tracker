# Contributing to Branch PR Tracker

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/branch-pr-tracker.git`
3. Copy the example config: `cp config.example.json config.json`
4. Configure for testing (use a test organization or your own repos)
5. Create a feature branch: `git checkout -b feature/your-feature-name`

## Prerequisites

- **GitHub CLI (`gh`)**: Install from [cli.github.com](https://cli.github.com/)
- **jq**: JSON processor - `brew install jq` (macOS) or `apt-get install jq` (Linux)
- **bash**: Version 4.0+ recommended

## Making Changes

1. Make your changes in your feature branch
2. Test your changes thoroughly
3. Ensure scripts are executable: `chmod +x *.sh`
4. Update documentation (README.md) if needed

## Code Style

- Follow existing bash scripting style
- Use meaningful variable names
- Add comments for complex logic
- Use `set -euo pipefail` for safer bash scripts
- Keep the tool generic - avoid hardcoding organization-specific logic
- Use `config.json` for configurable values, not hardcoded constants

## Testing

Before submitting:

1. Test with your own GitHub organization/repos
2. Verify the script works with:
   - Default config branches
   - Custom branches via CLI
   - Grouping options (--group-by repo, --group-by pattern)
   - Clipboard copy (if on macOS)
3. Ensure error handling works for missing config, invalid repos, etc.

## Submitting Changes

1. Ensure `config.json` is NOT committed (git-ignored)
2. Update `config.example.json` if you add new config fields
3. Update README.md with any new features or usage changes
4. Commit your changes with a clear message:
   ```bash
   git commit -m "Add: Brief description of your changes"
   ```
5. Push to your fork: `git push origin feature/your-feature-name`
6. Create a Pull Request with:
   - Clear description of changes
   - Any relevant issue numbers
   - Testing details (which org/repos you tested with)

## Reporting Issues

- Use GitHub Issues to report bugs or request features
- Include:
  - Clear description of the issue
  - Steps to reproduce (for bugs)
  - Expected vs actual behavior
  - Your environment (OS, bash version, gh version)

## Questions?

Feel free to open an issue for any questions or discussions.
