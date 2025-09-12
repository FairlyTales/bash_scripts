#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "python-dotenv",
# ]
# ///

import json
import os
import sys
from datetime import datetime
from pathlib import Path

try:
    from dotenv import load_dotenv

    load_dotenv()
except ImportError:
    pass  # dotenv is optional


"""Log status line event to .logs directory."""
def log_status_line(input_data, status_line_output, error_message=None):
    # Ensure .logs directory exists
    log_dir = Path(".logs")
    log_dir.mkdir(parents=True, exist_ok=True)
    log_file = log_dir / "status_line.json"

    # Read existing log data or initialize empty list
    if log_file.exists():
        with open(log_file, "r") as f:
            try:
                log_data = json.load(f)
            except (json.JSONDecodeError, ValueError):
                log_data = []
    else:
        log_data = []

    # Create log entry with input data and generated output
    log_entry = {
        "timestamp": datetime.now().isoformat(),
        "version": "v1",
        "input_data": input_data,
        "status_line_output": status_line_output,
    }

    if error_message:
        log_entry["error"] = error_message

    # Append the log entry
    log_data.append(log_entry)

    # Write back to file with formatting
    with open(log_file, "w") as f:
        json.dump(log_data, f, indent=2)

"""Get session data including agent name, prompts, and extras."""
def get_session_data(session_id):
    session_file = Path(f".claude/data/sessions/{session_id}.json")

    if not session_file.exists():
        return None, f"Session file {session_file} does not exist"

    try:
        with open(session_file, "r") as f:
            session_data = json.load(f)
            return session_data, None
    except Exception as e:
        return None, f"Error reading session file: {str(e)}"

"""Truncate prompt to specified length."""
def truncate_prompt(prompt, max_length=75):
    # Remove newlines and excessive whitespace
    prompt = " ".join(prompt.split())

    if len(prompt) > max_length:
        return prompt[: max_length - 3] + "..."
    return prompt

"""Get icon based on prompt type."""
def get_prompt_icon(prompt):
    if prompt.startswith("/"):
        return "⚡"
    elif "?" in prompt:
        return "❓"
    elif any(word in prompt.lower() for word in ["plan", "analyze", "think"]):
        return "📋"
    elif any(
        word in prompt.lower()
        for word in ["create", "write", "add", "implement", "build"]
    ):
        return "💡"
    elif any(word in prompt.lower() for word in ["fix", "debug", "error", "issue"]):
        return "🪲"
    elif any(word in prompt.lower() for word in ["refactor", "improve", "optimize"]):
        return "♻️"
    else:
        return "💬"

"""Format extras dictionary into a compact string."""
def format_extras(extras):
    if not extras:
        return None
    
    # Format each key-value pair
    pairs = []
    for key, value in extras.items():
        # Truncate value if too long
        str_value = str(value)
        if len(str_value) > 20:
            str_value = str_value[:17] + "..."
        pairs.append(f"{key}:{str_value}")
    
    return " ".join(pairs)

"""Get max context based on model name."""
def get_max_context(model_name):
    model_lower = model_name.lower()
    
    if any(term in model_lower for term in ["opus 4", "opus"]):
        return 200000  # 200K for all Opus versions
    elif any(term in model_lower for term in ["sonnet 4", "sonnet 3.5", "sonnet"]):
        return 200000  # 200K for Sonnet 3.5+ and 4.x
    elif any(term in model_lower for term in ["haiku 3.5", "haiku 4"]):
        return 200000  # 200K for modern Haiku
    elif "claude 3 haiku" in model_lower:
        return 100000  # 100K for original Claude 3 Haiku
    else:
        return 200000  # Default to 200K

"""Get color code based on remaining context percentage."""
def get_context_color(remaining_pct):
    if remaining_pct <= 20:
        return "\033[38;5;203m"  # coral red
    elif remaining_pct <= 40:
        return "\033[38;5;215m"  # peach
    else:
        return "\033[38;5;158m"  # mint green


"""Extract token usage from session JSONL file."""
def get_context_usage(session_id, current_dir):
    try:
        # Convert current dir to session file path format (matches Claude Code's naming)
        # Replace forward slashes with dashes, then underscores with dashes too
        project_dir = current_dir.replace("/", "-").replace("_", "-")
        if not project_dir.startswith("-"):
            project_dir = f"-{project_dir}"
        
        session_file = Path.home() / ".claude" / "projects" / project_dir / f"{session_id}.jsonl"
        
        if not session_file.exists():
            return None, None
        
        # Read last 20 lines to get latest token usage
        with open(session_file, 'r') as f:
            lines = f.readlines()
            
        # Process last 20 lines (or all if fewer)
        recent_lines = lines[-20:] if len(lines) > 20 else lines
        
        latest_tokens = None
        for line in reversed(recent_lines):
            try:
                data = json.loads(line.strip())
                message = data.get('message', {})
                usage = message.get('usage', {})
                
                if usage:
                    input_tokens = usage.get('input_tokens', 0)
                    cache_read_tokens = usage.get('cache_read_input_tokens', 0)
                    total_tokens = input_tokens + cache_read_tokens
                    
                    if total_tokens > 0:
                        latest_tokens = total_tokens
                        break
            except (json.JSONDecodeError, KeyError):
                continue
        
        return latest_tokens, None
        
    except Exception as e:
        return None, str(e)

"""Generate the status line with agent name, most recent prompt, and extras."""
def generate_status_line(input_data):
    # Extract session ID from input data
    session_id = input_data.get("session_id", "unknown")

    # Get model name
    claude_version = input_data.get("version")
    model_info = input_data.get("model", {})
    model_name = model_info.get("display_name", "Claude")
    output_style = input_data.get("output_style")
    output_style_name = output_style.get("name")

    # Get session data
    session_data, error = get_session_data(session_id)

    # Get current directory
    current_dir_full = input_data['workspace']['current_dir']
    current_dir = os.path.basename(current_dir_full)

    # Extract agent name, prompts, and extras (with fallbacks for missing session data)
    if session_data and not error:
        prompts = session_data.get("prompts", [])
        extras = session_data.get("extras", {})
    else:
        prompts = []
        extras = {}

    # Build status line components
    parts = []

    # Claude version - Yellow
    parts.append(f"\033[93m{claude_version}\033[0m")

    # Model name - 
    parts.append(f"\033[95m{model_name}\033[0m")

    # Output style - Cyan
    parts.append(f"\033[36m{output_style_name}\033[0m")

    # Current directory - Bright Light Blue
    parts.append(f"\033[38;5;117m{current_dir}\033[0m")

    # Context usage calculation
    if session_id != "unknown":
        max_context = get_max_context(model_name)
        latest_tokens, context_error = get_context_usage(session_id, current_dir_full)
        
        if latest_tokens and latest_tokens > 0:
            context_used_pct = (latest_tokens * 100) // max_context
            context_remaining_pct = 100 - context_used_pct
            
            context_color = get_context_color(context_remaining_pct)
            
            parts.append(f"{context_color}{context_used_pct}%\033[0m")
        else:
            parts.append("\033[37m00%\033[0m")
    else:
        parts.append("\033[37m00%\033[0m")

    # Cost and performance metrics
    # cost_data = input_data.get("cost", {})
    
    # Lines of code added/removed
    # lines_added = cost_data.get("total_lines_added", 0)
    # lines_removed = cost_data.get("total_lines_removed", 0)
    # if lines_added > 0 or lines_removed > 0:
    #     parts.append(f"\033[92m+{lines_added}\033[0m/\033[91m-{lines_removed}\033[0m")

    # Most recent prompt
    if prompts:
        current_prompt = prompts[-1]
        icon = get_prompt_icon(current_prompt)
        truncated = truncate_prompt(current_prompt, 300)
        parts.append(f"{icon} \033[97m{truncated}\033[0m")
    else:
        parts.append("\033[90m💭 No prompts yet\033[0m")

    # Add extras if they exist
    if extras:
        extras_str = format_extras(extras)
        if extras_str:
            # Display extras in cyan with brackets
            parts.append(f"\033[36m[{extras_str}]\033[0m")

    # Join with separator
    status_line = " | ".join(parts)

    return status_line


def main():
    try:
        # Read JSON input from stdin
        input_data = json.loads(sys.stdin.read())

        # Generate status line
        status_line = generate_status_line(input_data)

        # Log the status line event (without error since it's successful)
        log_status_line(input_data, status_line)

        # Output the status line (first line of stdout becomes the status line)
        print(status_line)

        # Success
        sys.exit(0)

    except json.JSONDecodeError:
        # Handle JSON decode errors gracefully - output basic status
        print("\033[31m[Agent] [Claude] 💭 JSON Error\033[0m")
        sys.exit(0)
    except Exception as e:
        # Handle any other errors gracefully - output basic status
        print(f"\033[31m[Agent] [Claude] 💭 Error: {str(e)}\033[0m")
        sys.exit(0)


if __name__ == "__main__":
    main()