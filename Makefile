.PHONY: help list-prs list-prs-117 list-prs-137 list-prs-all copy-prs copy-prs-117 copy-prs-137
.PHONY: group-by-repo group-by-repo-117 group-by-repo-137 group-by-pattern group-by-pattern-117 group-by-pattern-137
.PHONY: konflux-lgtm konflux-lgtm-117 konflux-lgtm-137

# Default target
help:
	@echo "Branch PR Tracker - Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  list-prs           - List PRs for default branches (from config.json)"
	@echo "  list-prs-117       - List PRs for release 1.17 branches only"
	@echo "  list-prs-137       - List PRs for release 1.37 branches only"
	@echo "  list-prs-all       - List PRs with custom branches (use BRANCHES variable)"
	@echo ""
	@echo "  copy-prs           - List PRs + copy all URLs to clipboard (macOS)"
	@echo "  copy-prs-117       - List 1.17 PRs + copy URLs to clipboard"
	@echo "  copy-prs-137       - List 1.37 PRs + copy URLs to clipboard"
	@echo ""
	@echo "  group-by-repo      - Group PRs by repository with counts"
	@echo "  group-by-repo-117  - Group 1.17 PRs by repository"
	@echo "  group-by-repo-137  - Group 1.37 PRs by repository"
	@echo ""
	@echo "  group-by-pattern   - Group PRs by type (Konflux, Dependencies, Security, etc.)"
	@echo "  group-by-pattern-117 - Group 1.17 PRs by pattern"
	@echo "  group-by-pattern-137 - Group 1.37 PRs by pattern"
	@echo ""
	@echo "  konflux-lgtm       - Check and approve Konflux PRs (asks before posting)"
	@echo "  konflux-lgtm-117   - Check and approve 1.17 Konflux PRs"
	@echo "  konflux-lgtm-137   - Check and approve 1.37 Konflux PRs"
	@echo ""
	@echo "Examples:"
	@echo "  make list-prs"
	@echo "  make group-by-repo-117                             # See PRs organized by repo"
	@echo "  make group-by-pattern                              # See PRs grouped by type"
	@echo "  make copy-prs-117                                  # Copy release-1.17 PR links"
	@echo "  make konflux-lgtm                                  # Check & approve Konflux PRs"
	@echo "  make list-prs-all BRANCHES='release-v1.18 release-1.18'"
	@echo ""
	@echo "💡 Tip: All output includes serial numbers (#) for easy reference!"
	@echo "💡 Tip: Use Cmd+Click to open links directly in your terminal!"
	@echo "💡 Tip: konflux-lgtm shows CI status and asks before approving each PR!"
	@echo ""

# List PRs for all default release branches
list-prs:
	@./track-prs.sh

# List PRs for release 1.17 branches only
list-prs-117:
	@./track-prs.sh release-v1.17 release-1.17

# List PRs for release 1.37 branches only
list-prs-137:
	@./track-prs.sh release-1.37

# List PRs for custom branches (use BRANCHES variable)
list-prs-all:
	@./track-prs.sh $(BRANCHES)

# Copy PR links to clipboard
copy-prs:
	@./track-prs.sh --copy-links

copy-prs-117:
	@./track-prs.sh --copy-links release-v1.17 release-1.17

copy-prs-137:
	@./track-prs.sh --copy-links release-1.37

# Group PRs by repository
group-by-repo:
	@./track-prs.sh --group-by repo

group-by-repo-117:
	@./track-prs.sh --group-by repo release-v1.17 release-1.17

group-by-repo-137:
	@./track-prs.sh --group-by repo release-1.37

# Group PRs by pattern/type
group-by-pattern:
	@./track-prs.sh --group-by pattern

group-by-pattern-117:
	@./track-prs.sh --group-by pattern release-v1.17 release-1.17

group-by-pattern-137:
	@./track-prs.sh --group-by pattern release-1.37

# Check and approve Konflux PRs
konflux-lgtm:
	@./track-prs.sh --konflux-lgtm

konflux-lgtm-117:
	@./track-prs.sh --konflux-lgtm release-v1.17 release-1.17

konflux-lgtm-137:
	@./track-prs.sh --konflux-lgtm release-1.37
