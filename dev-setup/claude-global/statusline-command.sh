#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract values from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')
transcript_path=$(echo "$input" | jq -r '.transcript_path')

# Get current user and hostname
user=$(whoami)
host=$(hostname -s)

# Shorten home directory to ~
display_dir="${cwd/#$HOME/\~}"

# Get git branch and status if in a git repo
git_info=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" branch --show-current 2>/dev/null || echo "detached")

    # Get git status (skip optional locks to avoid conflicts)
    git_status=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)

    if [ -n "$git_status" ]; then
        # Has changes
        git_info=$(printf " \033[33m(git:%s*)\033[0m" "$branch")
    else
        # Clean
        git_info=$(printf " \033[32m(git:%s)\033[0m" "$branch")
    fi
fi

# Calculate context usage percentage from actual token usage in transcript
context_info=""
usage_percent=-1
tokens_used=0
tokens_max=200000

# Function to extract token usage from a transcript file
extract_token_usage() {
    local file="$1"
    if [ -f "$file" ]; then
        # Extract last "Token usage: X/Y" from the file
        local token_line=$(grep -o "Token usage: [0-9]*/[0-9]*" "$file" 2>/dev/null | tail -1)
        if [ -n "$token_line" ]; then
            tokens_used=$(echo "$token_line" | grep -o "[0-9]*" | head -1)
            tokens_max=$(echo "$token_line" | grep -o "[0-9]*" | tail -1)
            if [ -n "$tokens_used" ] && [ -n "$tokens_max" ] && [ "$tokens_max" -gt 0 ]; then
                usage_percent=$((tokens_used * 100 / tokens_max))
                return 0
            fi
        fi
    fi
    return 1
}

# Try to get token usage from the specified transcript file
if [ -n "$transcript_path" ] && [ "$transcript_path" != "null" ]; then
    extract_token_usage "$transcript_path"
fi

# If that didn't work, try to find the largest session file in the project
if [ $usage_percent -lt 0 ]; then
    project_dir=$(echo "$input" | jq -r '.workspace.project_dir // empty' 2>/dev/null)
    if [ -n "$project_dir" ]; then
        # Get the project-specific transcript directory
        project_name=$(echo "$project_dir" | sed 's/\//-/g')
        transcript_dir="$HOME/.claude/projects/$project_name"

        if [ -d "$transcript_dir" ]; then
            # Find the largest session file (likely the current one)
            largest_file=$(find "$transcript_dir" -name "*.jsonl" -type f ! -name "agent-*.jsonl" -exec ls -l {} \; 2>/dev/null | sort -k5 -rn | head -1 | awk '{print $9}')

            if [ -n "$largest_file" ]; then
                extract_token_usage "$largest_file"
            fi
        fi
    fi
fi

# Only show if we have valid data
if [ $usage_percent -ge 0 ]; then
    # Color based on usage: green (<50%), yellow (50-80%), red (>80%)
    if [ $usage_percent -lt 50 ]; then
        context_color="\033[32m"
    elif [ $usage_percent -lt 80 ]; then
        context_color="\033[33m"
    else
        context_color="\033[31m"
    fi

    context_info=$(printf " ${context_color}[%d%%]\033[0m" "$usage_percent")
fi

# Model info (shortened)
model_short=$(echo "$model" | sed 's/Claude //' | sed 's/ /-/g')
model_info=$(printf " \033[35m[%s]\033[0m" "$model_short")

# Build the status line with colors (dimmed in terminal)
# Using bright white (97m) for path to ensure visibility on blue-green background
printf "\033[36m%s@%s\033[0m:\033[97m%s\033[0m%s%s%s" "$user" "$host" "$display_dir" "$git_info" "$context_info" "$model_info"
