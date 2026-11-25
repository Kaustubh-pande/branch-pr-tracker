#!/usr/bin/env bash
#
# track-prs.sh - Track pull requests across multiple repositories targeting specific branches
#
# Usage: ./track-prs.sh [OPTIONS] [branch1] [branch2] [branch3] ...
#        ./track-prs.sh release-v1.17 release-1.17 release-1.37
#        ./track-prs.sh --copy-links release-v1.17
#        ./track-prs.sh --group-by repo release-v1.17
#        ./track-prs.sh --group-by pattern release-v1.17
#
# Options:
#   -c, --copy-links         Copy all PR URLs to clipboard (macOS)
#   -g, --group-by MODE      Group PRs by: repo, pattern, or none (default: none)
#   -k, --konflux-lgtm       Check Konflux PRs status and approve with /lgtm and /approve
#   --config FILE           Use custom config file (default: config.json)
#   -h, --help              Show this help message
#
# Configuration is loaded from config.json (or --config FILE)
# If no branches are specified, uses default_branches from config
#

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default config file
CONFIG_FILE="${SCRIPT_DIR}/config.json"

# Parse options
COPY_LINKS=false
GROUP_BY="none"
KONFLUX_LGTM=false
BRANCHES_ARG=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--copy-links)
            COPY_LINKS=true
            shift
            ;;
        -g|--group-by)
            GROUP_BY="$2"
            shift 2
            ;;
        -k|--konflux-lgtm)
            KONFLUX_LGTM=true
            shift
            ;;
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -h|--help)
            grep '^#' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *)
            BRANCHES_ARG+=("$1")
            shift
            ;;
    esac
done

# Load configuration
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found: $CONFIG_FILE" >&2
    echo "Please create config.json (see config.example.json for reference)" >&2
    exit 1
fi

# Read config using jq
ORG=$(jq -r '.organization' "$CONFIG_FILE")

# Read repositories (Bash 3.2 compatible)
TARGET_REPOS=()
while IFS= read -r line; do
    TARGET_REPOS+=("$line")
done < <(jq -r '.repositories[]' "$CONFIG_FILE")

# Read default branches (Bash 3.2 compatible)
DEFAULT_BRANCHES=()
while IFS= read -r line; do
    DEFAULT_BRANCHES+=("$line")
done < <(jq -r '.default_branches[]' "$CONFIG_FILE")

# Use provided branches or defaults from config
if [ ${#BRANCHES_ARG[@]} -eq 0 ]; then
    BRANCHES=("${DEFAULT_BRANCHES[@]}")
else
    BRANCHES=("${BRANCHES_ARG[@]}")
fi

# Colors (only if terminal)
if [ -t 1 ]; then
    BOLD='\033[1m'
    BLUE='\033[34m'
    GREEN='\033[32m'
    YELLOW='\033[33m'
    RESET='\033[0m'
else
    BOLD=''
    BLUE=''
    GREEN=''
    YELLOW=''
    RESET=''
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}" >&2
echo -e "${BOLD}Open Pull Requests - ${ORG}${RESET}" >&2
echo -e "${YELLOW}Branches:${RESET} ${BRANCHES[*]}" >&2
echo -e "${YELLOW}Config:${RESET} ${CONFIG_FILE}" >&2
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}" >&2
echo "" >&2

# Spinner function
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c] %s" "$spinstr" "$2" >&2
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\r" >&2
    done
    printf "    \r" >&2
}

# Use predefined repository list
repo_count=${#TARGET_REPOS[@]}
echo -e "${GREEN}✓ Scanning ${repo_count} target repositories${RESET}" >&2
echo "" >&2

# Collect all PRs into a temporary file
TEMP_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE"' EXIT

# Progress bar function
show_progress() {
    local current=$1
    local total=$2
    local repo_name=$3
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))

    # Build progress bar
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done

    printf "\r${YELLOW}🔍 [%s] %3d%% (%d/%d)${RESET} ${BLUE}%s${RESET}" "$bar" "$percent" "$current" "$total" "$repo_name" >&2
}

# Iterate through each repository with progress
echo -e "${YELLOW}🔍 Scanning repositories for open PRs...${RESET}" >&2
current_repo=0
total_repos=$repo_count

for repo in "${TARGET_REPOS[@]}"; do
    ((current_repo++))
    show_progress $current_repo $total_repos "$repo"

    # Check each branch
    for branch in "${BRANCHES[@]}"; do
        gh pr list \
            --repo "${ORG}/${repo}" \
            --base "$branch" \
            --state open \
            --limit 1000 \
            --json number,title,url 2>/dev/null | \
        jq -r --arg repo "${ORG}/${repo}" \
            '.[] | "\($repo)\t\(.number)\t\(.title)\t\(.url)"' >> "$TEMP_FILE" || true
    done
done

# Clear progress line and show completion
printf "\r%120s\r" "" >&2
echo -e "${GREEN}✓ Scanned all ${total_repos} repositories${RESET}" >&2
echo "" >&2

total_prs=$(wc -l < "$TEMP_FILE" | tr -d ' ')

# Detect PR pattern for grouping
get_pr_pattern() {
    local title="$1"
    if [[ "$title" =~ [Kk]onflux ]]; then
        echo "Konflux Updates"
    elif [[ "$title" =~ \[gomod\]|\[npm\]|\[maven\]|Bump|bump ]]; then
        echo "Dependency Updates"
    elif [[ "$title" =~ [Cc][Vv][Ee]|[Ss]ecurity|[Vv]ulnerability ]]; then
        echo "Security Fixes"
    elif [[ "$title" =~ ^feat:|^feature|Feature ]]; then
        echo "Features"
    elif [[ "$title" =~ ^fix:|Fix ]]; then
        echo "Bug Fixes"
    else
        echo "Other"
    fi
}

# Function to print table with grouping
print_table() {
    local group_mode="$1"

    # Print table header
    printf "%3s | %-45s | %6s | %-70s | %s\n" "#" "Repository" "PR" "Title" "Link"
    printf "%3s-|-%-45s-|-%6s-|-%-70s-|-%s\n" "---" "$(printf '%0.s-' {1..45})" "------" "$(printf '%0.s-' {1..70})" "----"

    if [ "$group_mode" = "repo" ]; then
        # Group by repository
        local current_repo=""
        local repo_count=0
        local serial=0

        sort -t$'\t' -k1,1 "$TEMP_FILE" | while IFS=$'\t' read -r repo_name pr_num pr_title pr_url; do
            if [ "$repo_name" != "$current_repo" ]; then
                if [ -n "$current_repo" ]; then
                    echo ""
                    echo -e "${BLUE}├─ ${current_repo}: ${repo_count} PRs${RESET}" >&2
                    echo ""
                fi
                current_repo="$repo_name"
                repo_count=1
            else
                ((repo_count++))
            fi

            ((serial++))
            if [ ${#pr_title} -gt 70 ]; then
                pr_title="${pr_title:0:67}..."
            fi
            printf "%3d | %-45s | %6s | %-70s | %s\n" "$serial" "$repo_name" "$pr_num" "$pr_title" "$pr_url"
        done

        if [ -n "$current_repo" ]; then
            echo ""
            echo -e "${BLUE}└─ ${current_repo}: ${repo_count} PRs${RESET}" >&2
        fi

    elif [ "$group_mode" = "pattern" ]; then
        # Group by PR pattern
        temp_with_pattern=$(mktemp)

        while IFS=$'\t' read -r repo_name pr_num pr_title pr_url; do
            pattern=$(get_pr_pattern "$pr_title")
            echo -e "${pattern}\t${repo_name}\t${pr_num}\t${pr_title}\t${pr_url}"
        done < "$TEMP_FILE" > "$temp_with_pattern"

        local current_pattern=""
        local pattern_count=0
        local serial=0

        sort -t$'\t' -k1,1 "$temp_with_pattern" | while IFS=$'\t' read -r pattern repo_name pr_num pr_title pr_url; do
            if [ "$pattern" != "$current_pattern" ]; then
                if [ -n "$current_pattern" ]; then
                    echo ""
                    echo -e "${BLUE}└─ ${current_pattern}: ${pattern_count} PRs${RESET}" >&2
                    echo ""
                fi
                echo -e "${YELLOW}╔══ ${pattern}${RESET}" >&2
                current_pattern="$pattern"
                pattern_count=1
            else
                ((pattern_count++))
            fi

            ((serial++))
            if [ ${#pr_title} -gt 70 ]; then
                pr_title="${pr_title:0:67}..."
            fi
            printf "%3d | %-45s | %6s | %-70s | %s\n" "$serial" "$repo_name" "$pr_num" "$pr_title" "$pr_url"
        done

        if [ -n "$current_pattern" ]; then
            echo ""
            echo -e "${BLUE}└─ ${current_pattern}: ${pattern_count} PRs${RESET}" >&2
        fi

    else
        # No grouping - just add serial numbers
        local serial=0
        while IFS=$'\t' read -r repo_name pr_num pr_title pr_url; do
            ((serial++))
            if [ ${#pr_title} -gt 70 ]; then
                pr_title="${pr_title:0:67}..."
            fi
            printf "%3d | %-45s | %6s | %-70s | %s\n" "$serial" "$repo_name" "$pr_num" "$pr_title" "$pr_url"
        done < "$TEMP_FILE"
    fi
}

# Print the table based on grouping mode
print_table "$GROUP_BY"

echo "" >&2
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}" >&2
echo -e "${GREEN}✅ Found ${BOLD}${total_prs}${RESET}${GREEN} open PRs${RESET}" >&2

# Copy links to clipboard if requested
if [ "$COPY_LINKS" = true ]; then
    if command -v pbcopy &> /dev/null; then
        # Extract URLs and copy to clipboard
        awk -F'\t' '{print $4}' "$TEMP_FILE" | pbcopy
        echo -e "${GREEN}📋 Copied ${total_prs} PR URLs to clipboard!${RESET}" >&2
        echo "" >&2
        echo -e "${YELLOW}💡 Individual PR links (easy to copy):${RESET}" >&2
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}" >&2

        # Print each PR with clickable link on separate line
        awk -F'\t' '{printf "  #%s - %s\n         %s\n\n", $2, $1, $4}' "$TEMP_FILE" >&2

        echo -e "${YELLOW}💡 Tip: Cmd+Click on any link to open it directly${RESET}" >&2
        echo -e "${YELLOW}💡 Tip: Triple-click a URL line to select it, then Cmd+C to copy${RESET}" >&2
    else
        echo -e "${YELLOW}⚠️  pbcopy not found (macOS only feature)${RESET}" >&2
    fi
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}" >&2

# Handle Konflux LGTM if requested
if [ "$KONFLUX_LGTM" = true ]; then
    echo "" >&2
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}" >&2
    echo -e "${BOLD}${YELLOW}Konflux PR Check & Approval${RESET}" >&2
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}" >&2
    echo "" >&2

    # Filter Konflux PRs
    KONFLUX_TEMP=$(mktemp)
    while IFS=$'\t' read -r repo_name pr_num pr_title pr_url; do
        if [[ "$pr_title" =~ [Uu]pdate\ [Kk]onflux\ [Rr]eferences ]]; then
            echo -e "${repo_name}\t${pr_num}\t${pr_title}\t${pr_url}"
        fi
    done < "$TEMP_FILE" > "$KONFLUX_TEMP"

    konflux_count=$(wc -l < "$KONFLUX_TEMP" | tr -d ' ')

    if [ "$konflux_count" -eq 0 ]; then
        echo -e "${YELLOW}No Konflux update PRs found${RESET}" >&2
    else
        echo -e "${GREEN}Found ${konflux_count} Konflux update PRs${RESET}" >&2
        echo "" >&2

        pr_index=0
        while IFS=$'\t' read -r repo_name pr_num pr_title pr_url; do
            ((pr_index++))
            echo -e "${BOLD}[${pr_index}/${konflux_count}] ${BLUE}${repo_name}#${pr_num}${RESET}" >&2
            echo -e "${YELLOW}${pr_title}${RESET}" >&2
            echo -e "${pr_url}" >&2
            echo "" >&2

            # Get PR checks status
            echo -e "${YELLOW}🔍 Checking PR status...${RESET}" >&2

            # Temporarily disable exit on error (gh pr checks returns non-zero if checks aren't all passing)
            set +e
            check_output=$(gh pr checks "$pr_url" 2>&1)
            check_exit_code=$?
            set -e

            # Only skip if gh command genuinely failed (not just non-passing checks)
            if [ $check_exit_code -ne 0 ] && [[ "$check_output" =~ "Could not resolve to a PullRequest" ]]; then
                echo -e "${YELLOW}⚠️  Could not fetch PR (PR may not exist)${RESET}" >&2
                echo "" >&2
                continue
            fi

            # Parse check results (tab-separated: name, status, duration, url)
            # Note: Ignore "tide" check as it waits for /lgtm and /approve (chicken-egg problem)
            failed_checks=$(echo "$check_output" | awk -F'\t' '$2 ~ /^(fail|FAIL)$/ {print $1}' || true)
            pending_checks=$(echo "$check_output" | awk -F'\t' '$1 !~ /^tide$/ && $2 ~ /^(pending|PENDING)$/ {print $1}' || true)
            passed_checks=$(echo "$check_output" | awk -F'\t' '$2 ~ /^(pass|PASS)$/ {print $1}' || true)
            skipping_checks=$(echo "$check_output" | awk -F'\t' '$2 ~ /^(skipping|SKIPPING)$/ {print $1}' || true)
            tide_pending=$(echo "$check_output" | awk -F'\t' '$1 ~ /^tide$/ && $2 ~ /^(pending|PENDING)$/ {print $1}' || true)

            if [ -n "$failed_checks" ]; then
                echo -e "${BOLD}❌ Status: FAILED${RESET}" >&2
                echo "" >&2
                echo -e "${YELLOW}Failed checks:${RESET}" >&2
                echo "$check_output" | awk -F'\t' '$2 ~ /^(fail|FAIL)$/ {print "  ❌ " $1}' >&2
                if [ -n "$passed_checks" ]; then
                    echo "" >&2
                    echo -e "${GREEN}Passed checks:${RESET}" >&2
                    echo "$check_output" | awk -F'\t' '$2 ~ /^(pass|PASS)$/ {print "  ✅ " $1}' >&2
                fi
                if [ -n "$pending_checks" ]; then
                    echo "" >&2
                    echo -e "${YELLOW}Pending checks:${RESET}" >&2
                    echo "$check_output" | awk -F'\t' '$1 !~ /^tide$/ && $2 ~ /^(pending|PENDING)$/ {print "  ⏳ " $1}' >&2
                fi
                if [ -n "$tide_pending" ]; then
                    echo "" >&2
                    echo -e "${YELLOW}Waiting for approval:${RESET}" >&2
                    echo "  ⏳ tide" >&2
                fi
                echo "" >&2
            elif [ -n "$pending_checks" ]; then
                echo -e "${BOLD}⏳ Status: PENDING (blocking checks)${RESET}" >&2
                echo "" >&2
                echo -e "${YELLOW}Pending/In-progress checks:${RESET}" >&2
                echo "$check_output" | awk -F'\t' '$1 !~ /^tide$/ && $2 ~ /^(pending|PENDING)$/ {print "  ⏳ " $1}' >&2
                if [ -n "$passed_checks" ]; then
                    echo "" >&2
                    echo -e "${GREEN}Passed checks:${RESET}" >&2
                    echo "$check_output" | awk -F'\t' '$2 ~ /^(pass|PASS)$/ {print "  ✅ " $1}' >&2
                fi
                if [ -n "$skipping_checks" ]; then
                    echo "" >&2
                    echo -e "${YELLOW}Skipped checks:${RESET}" >&2
                    echo "$check_output" | awk -F'\t' '$2 ~ /^(skipping|SKIPPING)$/ {print "  ⏭️  " $1}' >&2
                fi
                if [ -n "$tide_pending" ]; then
                    echo "" >&2
                    echo -e "${YELLOW}Waiting for approval (will pass after /lgtm /approve):${RESET}" >&2
                    echo "  ⏳ tide" >&2
                fi
                echo "" >&2
            else
                # All checks are either pass or skipping (both are acceptable)
                # tide pending is OK - it waits for approval
                echo -e "${BOLD}✅ Status: ALL CHECKS PASSED (ready for approval)${RESET}" >&2
                echo "" >&2
                if [ -n "$passed_checks" ]; then
                    echo -e "${GREEN}Passed checks:${RESET}" >&2
                    echo "$check_output" | awk -F'\t' '$2 ~ /^(pass|PASS)$/ {print "  ✅ " $1}' >&2
                fi
                if [ -n "$skipping_checks" ]; then
                    echo "" >&2
                    echo -e "${YELLOW}Skipped checks:${RESET}" >&2
                    echo "$check_output" | awk -F'\t' '$2 ~ /^(skipping|SKIPPING)$/ {print "  ⏭️  " $1}' >&2
                fi
                if [ -n "$tide_pending" ]; then
                    echo "" >&2
                    echo -e "${YELLOW}Waiting for approval (will pass after /lgtm /approve):${RESET}" >&2
                    echo "  ⏳ tide" >&2
                fi
                echo "" >&2

                # Ask for approval
                echo -n "Do you want to approve this PR with /lgtm and /approve? [y/N]: " >&2
                read -r response < /dev/tty

                if [[ "$response" =~ ^[Yy]$ ]]; then
                    echo "" >&2
                    echo -e "${YELLOW}Posting /lgtm...${RESET}" >&2
                    lgtm_output=$(gh pr comment "$pr_url" --body "/lgtm" 2>&1)
                    lgtm_exit=$?
                    if [ $lgtm_exit -eq 0 ]; then
                        echo -e "${GREEN}✓ Posted /lgtm${RESET}" >&2
                    else
                        echo -e "${YELLOW}⚠️  Failed to post /lgtm${RESET}" >&2
                        echo -e "${YELLOW}Error: $lgtm_output${RESET}" >&2
                    fi

                    echo -e "${YELLOW}Posting /approve...${RESET}" >&2
                    approve_output=$(gh pr comment "$pr_url" --body "/approve" 2>&1)
                    approve_exit=$?
                    if [ $approve_exit -eq 0 ]; then
                        echo -e "${GREEN}✓ Posted /approve${RESET}" >&2
                    else
                        echo -e "${YELLOW}⚠️  Failed to post /approve${RESET}" >&2
                        echo -e "${YELLOW}Error: $approve_output${RESET}" >&2
                    fi

                    if [ $lgtm_exit -eq 0 ] && [ $approve_exit -eq 0 ]; then
                        echo -e "${GREEN}✅ PR approved!${RESET}" >&2
                        echo -e "${GREEN}View PR: $pr_url${RESET}" >&2
                    fi
                else
                    echo -e "${YELLOW}Skipped${RESET}" >&2
                fi
            fi

            echo -e "${BLUE}──────────────────────────────────────────────────────────${RESET}" >&2
            echo "" >&2
        done < "$KONFLUX_TEMP"
    fi

    rm -f "$KONFLUX_TEMP"
fi
