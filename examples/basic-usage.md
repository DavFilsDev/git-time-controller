# Basic Usage Examples

## Quick Start

### Install the tool:
```bash
# Clone and install
git clone https://github.com/yourusername/git-date-modifier.git
cd git-date-modifier
chmod +x install.sh
sudo ./install.sh
```

### Basic commands in your repository:
```bash
# Initialize or use existing repo
cd /path/to/your/repo

# Setup hooks (optional but recommended)
setup-hooks.sh

# Make changes and commit
echo "Hello World" > hello.txt
git add hello.txt
git commit -m "Add hello file"

# Modify the last commit's date
git-date-modifier --date "2024-01-15 14:30:00"
```

## Common Date Formats

### ISO Format (recommended):
```bash
git-date-modifier --date "2024-01-15 14:30:00"
git-date-modifier --date "2024-12-31 23:59:59"
```

### Relative Dates:
```bash
# Hours/days
git-date-modifier --date "2 hours ago"
git-date-modifier --date "3 days ago"
git-date-modifier --date "1 week ago"

# Simple relative
git-date-modifier --date "yesterday"
git-date-modifier --date "tomorrow"
git-date-modifier --date "now"
```

### Natural Language:
```bash
git-date-modifier --date "January 15 2024 14:30"
git-date-modifier --date "15 Jan 2024 2:30 PM"
git-date-modifier --date "next Friday"
```

## Step-by-Step Workflow

### Example 1: Correcting a commit timestamp
```bash
# 1. You made a commit but forgot to set proper date
git add .
git commit -m "Fix bug in login system"

# 2. Realize the date is wrong (shows as today)
git log --oneline -1

# 3. Correct it to when you actually worked on it
git-date-modifier --date "2024-01-10 09:30:00"

# 4. Verify the change
git log --oneline --pretty=fuller -1
```

### Example 2: Backdating documentation updates
```bash
# You wrote docs yesterday but want them to appear
# as if written during the feature release

# 1. Write and commit docs
echo "# API Documentation" > docs.md
git add docs.md
git commit -m "Add API documentation"

# 2. Backdate to feature release date
git-date-modifier --date "2023-12-01 10:00:00"

# 3. Push with corrected timeline
git push
```

### Example 3: Working with hooks enabled
```bash
# 1. Setup hooks in your repository
cd my-project
setup-hooks.sh

# 2. Work normally
git add new-feature.js
git commit -m "Implement new feature"

# 3. When you push, you'll be prompted:
git push
# Output: 
# Git Date Modifier Hook
# =========================
# Last commit: abc123
# Current date: 2024-01-20 15:45:00
# Do you want to modify the commit date? [y/N]:
```

## Tips and Best Practices

1. **Always verify after modification:**
   ```bash
   git log --oneline -1
   git show --pretty=fuller
   ```

2. **Use descriptive dates:**
   ```bash
   # Good - clear and unambiguous
   git-date-modifier --date "2024-01-15 14:30:00"
   
   # Avoid - might have timezone issues
   git-date-modifier --date "1/15/24 2:30 PM"
   ```

3. **Check timezone considerations:**
   ```bash
   # Display dates in your local timezone
   git log --date=local
   
   # Display in ISO format
   git log --date=iso
   ```

4. **For multiple commits, modify one at a time:**
   ```bash
   # Work from newest to oldest
   git rebase -i HEAD~3
   # Then modify each commit date as needed
   ```

## Troubleshooting

### Common Issues:

1. **"Not a git repository" error:**
   ```bash
   # Make sure you're in a git repo
   git status
   # If not, initialize one:
   git init
   ```

2. **Permission denied:**
   ```bash
   # Make scripts executable
   chmod +x /usr/local/bin/git-date-modifier
   chmod +x /usr/local/bin/setup-hooks.sh
   ```

3. **Date format not recognized:**
   ```bash
   # Use ISO format for guaranteed compatibility
   git-date-modifier --date "2024-01-15 14:30:00"
   
   # Or specify custom format
   git-date-modifier --date "Jan 15 2024 2:30 PM" --format "%b %d %Y %I:%M %p"
   ```

### Getting Help:
```bash
# Show all options
git-date-modifier --help

# Show version
git-date-modifier --version 2>/dev/null || echo "Version check not available"
```

## Next Steps

Once you're comfortable with basic usage, explore:
- [Advanced Usage](./advanced-usage.md) for complex scenarios
- Hook configuration for automated workflows
- Integration with CI/CD pipelines