# Advanced Usage Examples

## Table of Contents
1. [Custom Date Formats](#custom-date-formats)
2. [Modifying Specific Dates](#modifying-specific-dates)
3. [Batch Operations](#batch-operations)
4. [Integration with Other Tools](#integration-with-other-tools)
5. [Hook Configuration](#hook-configuration)
6. [Scripting and Automation](#scripting-and-automation)
7. [Troubleshooting Complex Scenarios](#troubleshooting-complex-scenarios)

## Custom Date Formats

### Using strftime Format Specifiers:
```bash
# Custom format examples
git-date-modifier --date "15/01/2024 14:30" --format "%d/%m/%Y %H:%M"
git-date-modifier --date "01-15-2024 02:30PM" --format "%m-%d-%Y %I:%M%p"
git-date-modifier --date "2024年01月15日 14時30分" --format "%Y年%m月%d日 %H時%M分"
```

### Timezone Manipulation:
```bash
# Convert between timezones
git-date-modifier --date "2024-01-15T14:30:00+00:00" --format "%Y-%m-%d %H:%M:%S %z"
git-date-modifier --date "2024-01-15 14:30:00 EST" --format "%Y-%m-%d %H:%M:%S %Z"
```

### Epoch Timestamps:
```bash
# From Unix timestamp
TIMESTAMP=1705336200  # 2024-01-15 14:30:00 UTC
git-date-modifier --date "@$TIMESTAMP"

# To specific timezone
git-date-modifier --date "@$TIMESTAMP" --format "%Y-%m-%d %H:%M:%S %z"
```

## Modifying Specific Dates

### Author Date vs Committer Date:
```bash
# Modify only author date (when the change was originally made)
git-date-modifier --date "2024-01-10 09:00:00" --author-date

# Modify only committer date (when the commit was applied)
git-date-modifier --date "2024-01-15 14:30:00" --committer-date

# Show both dates for comparison
git log --pretty=fuller -1
```

### Multiple Commits in Rebase:
```bash
# Interactive rebase to modify multiple commits
git rebase -i HEAD~5

# During rebase, for each commit you can:
# 1. Mark as 'edit'
# 2. When stopped at each commit:
git-date-modifier --date "2024-01-01 10:00:00"
git rebase --continue
```

### Specific Commit (not last):
```bash
# Create a script to modify any commit
modify_commit_date() {
    local commit_hash="$1"
    local new_date="$2"
    
    # Checkout the commit
    git checkout "$commit_hash" 2>/dev/null || git checkout -b temp-branch "$commit_hash"
    
    # Modify date
    git-date-modifier --date "$new_date"
    
    # If on temp branch, rebase onto original
    if git branch --show-current | grep -q "temp-branch"; then
        git checkout -
        git rebase temp-branch
        git branch -d temp-branch
    fi
}

# Usage
modify_commit_date abc123 "2024-01-15 14:30:00"
```

## Batch Operations

### Modify All Commits in Range:
```bash
# Script to modify dates for multiple commits
modify_commit_range() {
    local start_ref="$1"
    local end_ref="${2:-HEAD}"
    local new_date_base="$3"
    
    # Get list of commits
    commits=$(git log --reverse --pretty=format:"%H" "$start_ref".."$end_ref")
    count=0
    
    while IFS= read -r commit; do
        # Calculate offset date (e.g., each commit 1 hour apart)
        offset_date=$(date -d "$new_date_base + $count hours" +"%Y-%m-%d %H:%M:%S")
        
        echo "Modifying commit $commit to $offset_date"
        
        # Checkout and modify
        git checkout "$commit"
        git-date-modifier --date "$offset_date" --quiet
        
        ((count++))
    done <<< "$commits"
    
    # Return to original branch
    git checkout -
}

# Usage: space commits 1 hour apart starting from base date
modify_commit_range v1.0.0 HEAD "2024-01-15 09:00:00"
```

### Import Dates from Another Source:
```bash
# Import dates from CSV file
# CSV format: commit_hash,new_date
import_dates_from_csv() {
    local csv_file="$1"
    
    while IFS=',' read -r commit_hash new_date; do
        echo "Processing $commit_hash -> $new_date"
        
        # Create fix branch
        git checkout -b "fix-date-$commit_hash" "$commit_hash"
        
        # Modify date
        git-date-modifier --date "$new_date" --quiet
        
        # Rebase original branch
        original_branch=$(git branch --show-current | sed 's/fix-date-//')
        git checkout "$original_branch"
        git rebase "fix-date-$commit_hash"
        git branch -d "fix-date-$commit_hash"
        
    done < "$csv_file"
}
```

## Integration with Other Tools

### With Git Hooks:
```bash
# .git/hooks/pre-commit example
#!/bin/bash
# Auto-set date based on branch name
BRANCH_NAME=$(git branch --show-current)

if [[ "$BRANCH_NAME" =~ hotfix-.* ]]; then
    # For hotfix branches, use current time
    git-date-modifier --date "now" --quiet
elif [[ "$BRANCH_NAME" =~ release/.* ]]; then
    # For release branches, use start of day
    git-date-modifier --date "$(date +"%Y-%m-%d") 09:00:00" --quiet
fi
```

### With Makefiles:
```makefile
# Makefile example
.PHONY: set-date fix-dates

set-date:
	@read -p "Enter date (YYYY-MM-DD HH:MM:SS): " DATE; \
	git-date-modifier --date "$$DATE"

fix-dates: set-date
	git push --force-with-lease

backdate-release:
	git-date-modifier --date "$$(date -d '1 week ago' +'%Y-%m-%d 10:00:00')"
	git tag -a v1.0.0 -m "Release v1.0.0"
```

### With Python Scripts:
```python
#!/usr/bin/env python3
# date_modifier.py
import subprocess
import sys
from datetime import datetime, timedelta

def modify_commit_dates(start_date, commit_count=5):
    """Modify dates for last N commits"""
    base_date = datetime.strptime(start_date, "%Y-%m-%d %H:%M:%S")
    
    for i in range(commit_count):
        commit_date = base_date + timedelta(hours=i)
        date_str = commit_date.strftime("%Y-%m-%d %H:%M:%S")
        
        cmd = ["git-date-modifier", "--date", date_str, "--quiet"]
        subprocess.run(cmd, check=True)
        
        # Move to previous commit
        subprocess.run(["git", "reset", "--hard", "HEAD~1"], check=True)
    
    print(f"Modified {commit_count} commits starting from {start_date}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        modify_commit_dates(sys.argv[1])
```

## Hook Configuration

### Advanced Hook Configuration:
```bash
# .git/git-date-modifier.conf
ENABLE_PROMPT=true
DEFAULT_DATE_FORMAT="%Y-%m-%d %H:%M:%S %z"
AUTO_DETECT_FORMAT=true
VERBOSE=true

# Per-branch settings
declare -A BRANCH_SETTINGS=(
    ["main"]="strict"
    ["develop"]="flexible"
    ["feature/*"]="prompt"
    ["hotfix/*"]="auto-now"
)

# Date validation
VALIDATE_DATE_RANGE=true
MIN_DATE="2020-01-01"
MAX_DATE="2025-12-31"

# Auto-correction rules
AUTO_CORRECT_WEEKEND=true  # Move weekend commits to Friday
NORMALIZE_BUSINESS_HOURS=true  # Ensure 9 AM - 5 PM
```

### Custom Hook Scripts:
```bash
#!/bin/bash
# .git/hooks/pre-push-custom
# Extend the default hook behavior

# Load default hook
source /usr/local/bin/git-hook.sh

# Custom logic based on environment
if [ "$CI" = "true" ]; then
    # In CI, use timestamps from CI system
    CI_DATE=$(date -d "@${CI_TIMESTAMP}" +"${DEFAULT_DATE_FORMAT}")
    git-date-modifier --date "$CI_DATE" --quiet
fi

# Validate date isn't in future
LAST_COMMIT_DATE=$(git log -1 --format="%cd" --date=format:"%s")
CURRENT_TIMESTAMP=$(date +"%s")
if [ "$LAST_COMMIT_DATE" -gt "$CURRENT_TIMESTAMP" ]; then
    echo "Warning: Commit date is in the future!"
    read -p "Fix to current time? [y/N]: " fix_future
    if [[ "$fix_future" =~ ^[Yy]$ ]]; then
        git-date-modifier --date "now" --quiet
    fi
fi
```

## Scripting and Automation

### Bash Function for Common Tasks:
```bash
# Add to ~/.bashrc or ~/.zshrc
gdm() {
    local date_arg="$1"
    local commit_ref="${2:-HEAD}"
    
    if [ -z "$date_arg" ]; then
        echo "Usage: gdm <date> [commit-ref]"
        echo "Example: gdm '2024-01-15 14:30:00' HEAD~2"
        return 1
    fi
    
    # Save current branch
    current_branch=$(git branch --show-current)
    
    # Checkout target commit
    git checkout "$commit_ref" 2>/dev/null || \
        git checkout -b "temp-$(date +%s)" "$commit_ref"
    
    # Modify date
    git-date-modifier --date "$date_arg"
    
    # Return to original if needed
    if [ "$(git branch --show-current)" != "$current_branch" ]; then
        git checkout "$current_branch"
        git rebase "temp-$(date +%s)"
        git branch -d "temp-$(date +%s)"
    fi
}

# Alias for common patterns
alias gdm-now='git-date-modifier --date "now"'
alias gdm-yesterday='git-date-modifier --date "yesterday 09:00:00"'
alias gdm-lastweek='git-date-modifier --date "1 week ago"'
```

### Scheduled Date Correction:
```bash
#!/bin/bash
# daily-date-fix.sh
# Run as cron job to fix dates daily

# Fix any future-dated commits
git log --since="1 day ago" --pretty=format:"%H %cd" --date=raw | \
while read commit date_seconds _; do
    current_seconds=$(date +%s)
    if [ "$date_seconds" -gt "$current_seconds" ]; then
        echo "Fixing future-dated commit: $commit"
        git checkout "$commit"
        git-date-modifier --date "now" --quiet
        git checkout -
    fi
done

# Normalize business hours for today's commits
TODAY=$(date +"%Y-%m-%d")
git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --pretty=format:"%H" | \
while read commit; do
    commit_hour=$(git log -1 "$commit" --pretty=format:"%cd" --date=format:"%H")
    if [ "$commit_hour" -lt 9 ] || [ "$commit_hour" -gt 17 ]; then
        echo "Normalizing business hours for: $commit"
        git checkout "$commit"
        git-date-modifier --date "$TODAY 09:00:00" --quiet
        git checkout -
    fi
done
```

## Troubleshooting Complex Scenarios

### Merge Commits:
```bash
# Modify merge commit dates carefully
# Get parent commits
PARENTS=$(git log -1 --pretty=format:"%P")

# Modify each parent's date if needed
for parent in $PARENTS; do
    git checkout "$parent"
    # Determine appropriate date for this parent
    parent_date=$(git log -1 --pretty=format:"%cd" --date=iso)
    # Adjust as needed
    git-date-modifier --date "$parent_date" --quiet
done

# Return to merge commit
git checkout -
```

### Signed Commits:
```bash
# Note: Modifying signed commits will break signatures
# You'll need to re-sign after modification

# 1. Modify date
git-date-modifier --date "2024-01-15 14:30:00"

# 2. Re-sign if using GPG
if [ -n "$(git config user.signingkey)" ]; then
    echo "Commit was signed. Re-signing..."
    git commit --amend --no-edit --gpg-sign
fi
```

### Submodule Considerations:
```bash
# When working with submodules, modify dates recursively
modify_submodule_dates() {
    local target_date="$1"
    
    # Main repository
    git-date-modifier --date "$target_date"
    
    # Each submodule
    git submodule foreach --recursive '
        echo "Modifying date in $name"
        git-date-modifier --date "'"$target_date"'" --quiet || true
    '
}
```

### Performance with Large Repositories:
```bash
# Optimize for large repos by disabling unnecessary features
FAST_MODE=true git-date-modifier --date "2024-01-15 14:30:00" --no-verify

# Batch process with xargs for many commits
git log --since="1 month ago" --pretty=format:"%H" | \
xargs -I {} -P 4 bash -c '
    git checkout {} && \
    git-date-modifier --date "$(date -d @$(git log -1 --format="%cd" --date=format:"%s") +"%Y-%m-%d %H:%M:%S")" --quiet
'
```

## Best Practices for Advanced Usage

1. **Always backup before batch operations:**
   ```bash
   git bundle create backup-$(date +%s).bundle --all
   ```

2. **Use dry-run mode when available:**
   ```bash
   # Check what would change
   git-date-modifier --date "2024-01-15 14:30:00" --dry-run
   ```

3. **Document your date modification policies:**
   ```markdown
   # Date Modification Policy
   
   ## When to modify dates:
   - Correcting incorrect timestamps
   - Backdating documentation
   - Aligning with release schedules
   
   ## When NOT to modify dates:
   - Production releases
   - Signed legal documents
   - Audit trails
   ```

4. **Test in a clone first:**
   ```bash
   git clone --mirror original-repo test-repo
   cd test-repo
   # Test modifications here first
   ```

Remember: With great power comes great responsibility. Always consider the implications of date modifications in your specific context.