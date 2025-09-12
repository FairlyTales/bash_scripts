#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# ///

import json
import re
import sys
from pathlib import Path

"""
Comprehensive detection of dangerous rm commands.
Matches various forms of rm -rf and similar destructive patterns.
"""
def is_dangerous_rm_command(command):
    # Normalize command by removing extra spaces and converting to lowercase
    normalized = ' '.join(command.lower().split())
    
    # Pattern 1: Standard rm -rf variations
    patterns = [
        r'\brm\s+.*-[a-z]*r[a-z]*f',  # rm -rf, rm -fr, rm -Rf, etc.
        r'\brm\s+.*-[a-z]*f[a-z]*r',  # rm -fr variations
        r'\brm\s+--recursive\s+--force',  # rm --recursive --force
        r'\brm\s+--force\s+--recursive',  # rm --force --recursive
        r'\brm\s+-r\s+.*-f',  # rm -r ... -f
        r'\brm\s+-f\s+.*-r',  # rm -f ... -r
    ]
    
    # Check for dangerous patterns
    for pattern in patterns:
        if re.search(pattern, normalized):
            return True
    
    # Pattern 2: Check for rm with recursive flag targeting dangerous paths
    dangerous_paths = [
        r'/',           # Root directory
        r'/\*',         # Root with wildcard
        r'~',           # Home directory
        r'~/',          # Home directory path
        r'\$HOME',      # Home environment variable
        r'\.\.',        # Parent directory references
        r'\*',          # Wildcards in general rm -rf context
        r'\.',          # Current directory
        r'\.\s*$',      # Current directory at end of command
    ]
    
    if re.search(r'\brm\s+.*-[a-z]*r', normalized):  # If rm has recursive flag
        for path in dangerous_paths:
            if re.search(path, normalized):
                return True
    
    return False

"""
Check if any tool is trying to access .env files containing sensitive data.
"""
def is_env_file_access(tool_name, tool_input):
    if tool_name in ['Read', 'Edit', 'MultiEdit', 'Write', 'Bash']:
        # Check file paths for file-based tools
        if tool_name in ['Read', 'Edit', 'MultiEdit', 'Write']:
            file_path = tool_input.get('file_path', '')
            if '.env' in file_path and not file_path.endswith('.env.sample'):
                return True
        
        # Check bash commands for .env file access
        elif tool_name == 'Bash':
            command = tool_input.get('command', '')
            # Pattern to detect .env file access (but allow .env.sample)
            env_patterns = [
                r'\b\.env\b(?!\.sample)',  # .env but not .env.sample
                r'cat\s+.*\.env\b(?!\.sample)',  # cat .env
                r'echo\s+.*>\s*\.env\b(?!\.sample)',  # echo > .env
                r'touch\s+.*\.env\b(?!\.sample)',  # touch .env
                r'cp\s+.*\.env\b(?!\.sample)',  # cp .env
                r'mv\s+.*\.env\b(?!\.sample)',  # mv .env
            ]
            
            for pattern in env_patterns:
                if re.search(pattern, command):
                    return True
    
    return False

"""
Check if any tool is trying to modify .claude/settings.json containing security configuration.
"""
def is_claude_settings_access(tool_name, tool_input):
    if tool_name in ['Read', 'Edit', 'MultiEdit', 'Write', 'Bash']:
        # Check file paths for file-based tools
        if tool_name in ['Edit', 'MultiEdit', 'Write']:
            file_path = tool_input.get('file_path', '')
            if '.claude/settings.json' in file_path:
                return True
        
        # Check bash commands for .claude/settings.json access
        elif tool_name == 'Bash':
            command = tool_input.get('command', '')
            # Pattern to detect .claude/settings.json modification
            settings_patterns = [
                r'\.claude/settings\.json',              # Direct file reference
                r'echo\s+.*>\s*\.claude/settings\.json', # echo > .claude/settings.json
                r'cat\s+.*>\s*\.claude/settings\.json',  # cat > .claude/settings.json
                r'sed\s+.*\.claude/settings\.json',      # sed modifications
                r'awk\s+.*\.claude/settings\.json',      # awk modifications
                r'touch\s+.*\.claude/settings\.json',    # touch .claude/settings.json
                r'cp\s+.*\.claude/settings\.json',       # cp to .claude/settings.json
                r'mv\s+.*\.claude/settings\.json',       # mv to .claude/settings.json
                r'rm\s+.*\.claude/settings\.json',       # rm .claude/settings.json
                r'>\s*\.claude/settings\.json',          # redirect to settings file
                r'>>\s*\.claude/settings\.json',         # append to settings file
            ]
            
            for pattern in settings_patterns:
                if re.search(pattern, command):
                    return True
    
    return False

"""
Comprehensive detection of system-critical commands that could break the OS or cause data loss.
"""
def is_dangerous_system_command(command):
    # Normalize command
    normalized = ' '.join(command.lower().split())
    
    # System control commands
    system_patterns = [
        r'\bshutdown\b',
        r'\breboot\b', 
        r'\bhalt\b',
        r'\bpoweroff\b',
        r'\bsystemctl\s+(stop|disable)\b',
        r'\bservice\s+\w+\s+stop\b',
    ]
    
    # Process control patterns (dangerous killing)
    process_patterns = [
        r'\bkill\s+-9\s+[^0-9]',  # kill -9 with non-specific target
        r'\bpkill\s+-f\s+\.\*',   # pkill with broad patterns
        r'\bkillall\s+\w+',       # killall commands
    ]
    
    # Direct disk operations
    disk_patterns = [
        r'\bdd\s+if=.*of=/dev/',   # Direct disk writes
        r'\bmkfs\.',               # Filesystem creation
        r'\bfdisk\b',              # Partition management
        r'\bparted\b',             # Partition management
        r'>\s*/dev/(?!null)',      # Writes to device files (except /dev/null)
    ]
    
    all_patterns = system_patterns + process_patterns + disk_patterns
    
    for pattern in all_patterns:
        if re.search(pattern, normalized):
            return True
    
    return False

"""
Detection of privilege escalation commands that could bypass security controls.
"""
def is_privilege_escalation_command(command):
    normalized = ' '.join(command.lower().split())
    
    # Privilege escalation patterns
    privilege_patterns = [
        r'\bsudo\b',               # sudo command (most common)
        r'\bsu\s+',                # switch user with target
        r'\bsu\s*$',               # switch to root (no target)
        r'\bdoas\b',               # doas (OpenBSD sudo alternative)
        r'\bpkexec\b',             # PolicyKit execute
        r'\brunas\b',              # Windows runas equivalent
        r'\bsetuid\b',             # Set user ID programs
        r'\bsetgid\b',             # Set group ID programs
        r'\bsudo\s+-[A-Za-z]*i',   # sudo with interactive flags (-i, -s, etc.)
        r'\bsudo\s+-[A-Za-z]*s',   # sudo with shell flags
        r'\bsudo\s+-[A-Za-z]*u',   # sudo with user specification
    ]
    
    for pattern in privilege_patterns:
        if re.search(pattern, normalized):
            return True
    
    return False

"""
Detection of dangerous file permission and ownership changes.
"""
def is_dangerous_permission_command(command):
    normalized = ' '.join(command.lower().split())
    
    # Block ALL chmod commands (no exceptions - prevents any permission changes)
    chmod_patterns = [
        r'\bchmod\b',                   # Any chmod command
    ]
    
    # Block ALL chflags commands (no exceptions - prevents file flag changes)
    chflags_patterns = [
        r'\bchflags\b',                 # Any chflags command
    ]
    
    # Dangerous chown patterns (keep existing selective blocking)
    chown_patterns = [
        r'\bchown\s+-r\s+root\b',       # Change ownership to root recursively
        r'\bchown\s+-r\s+.*\s+/',       # Recursive chown on root paths
    ]
    
    # Umask patterns
    umask_patterns = [
        r'\bumask\s+000\b',             # Make new files world writable
    ]
    
    all_patterns = chmod_patterns + chflags_patterns + chown_patterns + umask_patterns
    
    for pattern in all_patterns:
        if re.search(pattern, normalized):
            return True
    
    return False

"""
Detection of database destructive operations.
"""
def is_dangerous_database_command(command):
    normalized = ' '.join(command.lower().split())
    
    # Database destruction patterns
    db_patterns = [
        r'\bmysql\s+.*-e\s+["\'].*drop\s+database',       # MySQL DROP DATABASE
        r'\bpsql\s+.*-c\s+["\'].*drop\s+database',        # PostgreSQL DROP DATABASE
        r'\bmongo\s+.*--eval.*dropdatabase',              # MongoDB drop database
        r'\bredis-cli\s+.*flushall',                      # Redis flush all
        r'\bredis-cli\s+.*flushdb',                       # Redis flush database
        r'\bmysql\s+.*-e\s+["\'].*truncate\s+table',      # MySQL TRUNCATE
        r'\bpsql\s+.*-c\s+["\'].*truncate\s+table',       # PostgreSQL TRUNCATE
    ]
    
    for pattern in db_patterns:
        if re.search(pattern, normalized):
            return True
    
    return False

"""
Detection of Docker/container destructive operations.
"""  
def is_dangerous_docker_command(command):
    normalized = ' '.join(command.lower().split())
    
    # Docker destructive patterns
    docker_patterns = [
        r'\bdocker\s+system\s+prune\s+-a',               # Remove all containers/images
        r'\bdocker\s+rm\s+-f\s+\$\(',                    # Force remove containers with command substitution
        r'\bdocker\s+rmi\s+-f\s+\$\(',                   # Force remove images with command substitution
        r'\bdocker\s+volume\s+prune',                    # Remove volumes (data loss)
        r'\bdocker-compose\s+down\s+.*-v',               # Remove volumes with docker-compose
        r'\bdocker\s+container\s+prune',                 # Remove stopped containers
        r'\bdocker\s+image\s+prune\s+-a',                # Remove all unused images
    ]
    
    for pattern in docker_patterns:
        if re.search(pattern, normalized):
            return True
    
    return False

"""
Detection of dangerous package management operations.
"""
def is_dangerous_package_command(command):
    normalized = ' '.join(command.lower().split())
    
    # Package removal patterns
    package_patterns = [
        r'\bnpm\s+uninstall\s+-g',                       # Global npm uninstall
        r'\byarn\s+global\s+remove',                     # Global yarn remove
        r'\bpip\s+uninstall.*--yes',                     # Forced pip uninstall
        r'\bapt-get\s+(remove|purge)',                   # APT package removal
        r'\byum\s+remove',                               # YUM package removal
        r'\bbrew\s+uninstall',                           # Homebrew uninstall
        r'\bnpm\s+install\s+-g\s+\*',                    # Global install with wildcard
        r'\brm\s+-rf\s+node_modules.*production',        # Delete node_modules in production
    ]
    
    for pattern in package_patterns:
        if re.search(pattern, normalized):
            return True
    
    return False

"""
Comprehensive detection of dangerous git commands.
Blocks git push, rebase, merge, checkout, reset, and clean commands.
"""
def is_dangerous_git_command(command):
    # Normalize command by removing extra spaces and converting to lowercase
    normalized = ' '.join(command.lower().split())
    
    # Define patterns for dangerous git commands with specific error types
    git_patterns = {
        'push': [
            r'\bgit\s+push\s+.*-[a-z]*f',  # git push with -f flag
            r'\bgit\s+push\s+.*--force',   # git push --force
            r'\bgit\s+push\s+-[a-z]*f',    # git push -f
            r'\bgit\s+push(?=\s|$)',       # any git push (general block)
        ],
        'reset': [
            r'\bgit\s+reset',               # any git reset
            r'\bgit\s+.*\s+reset',         # git ... reset
        ],
        'clean': [
            r'\bgit\s+clean',               # any git clean
            r'\bgit\s+.*\s+clean',         # git ... clean
        ],
        'merge': [
            r'\bgit\s+merge',               # any git merge
            r'\bgit\s+.*\s+merge',         # git ... merge
        ],
        'rebase': [
            r'\bgit\s+rebase',              # any git rebase
            r'\bgit\s+.*\s+rebase',        # git ... rebase
        ],
        'checkout': [
            r'\bgit\s+checkout',            # any git checkout
            r'\bgit\s+.*\s+checkout',      # git ... checkout
        ],
        'filter-branch': [
            r'\bgit\s+filter-branch',       # git filter-branch (history rewriting)
        ],
        'reflog': [
            r'\bgit\s+reflog\s+expire',     # git reflog expire (removes safety net)
        ],
        'gc': [
            r'\bgit\s+gc\s+.*--prune=now',  # aggressive garbage collection
        ],
        'stash': [
            r'\bgit\s+stash\s+(drop|clear)', # git stash drop/clear (loses work)
        ]
    }
    
    # Check each pattern and return the command type if matched
    for cmd_type, patterns in git_patterns.items():
        for pattern in patterns:
            if re.search(pattern, normalized):
                return True, cmd_type
    
    return False, None

def main():
    try:
        # Read JSON input from stdin
        input_data = json.load(sys.stdin)
        
        tool_name = input_data.get('tool_name', '')
        tool_input = input_data.get('tool_input', {})
        
        # Check for .env file access (blocks access to sensitive environment files)
        if is_env_file_access(tool_name, tool_input):
            print("BLOCKED: Access to .env files containing sensitive data is prohibited", file=sys.stderr)
            print("Use .env.sample for template files instead", file=sys.stderr)
            sys.exit(2)  # Exit code 2 blocks tool call and shows error to Claude
        
        # Check for .claude/settings.json access (blocks access to security configuration)
        if is_claude_settings_access(tool_name, tool_input):
            print("BLOCKED: Modification of .claude/settings.json is prohibited to maintain security configuration", file=sys.stderr)
            print("This file contains critical security settings including permissions and hooks", file=sys.stderr)
            sys.exit(2)  # Exit code 2 blocks tool call and shows error to Claude
        
        # Check for dangerous rm -rf commands
        if tool_name == 'Bash':
            command = tool_input.get('command', '')

            # SELF-PROTECTION: Block attempts to change the immutable flag on the hook itself.
            if 'chflags' in command and '.claude/hooks/pre_tool_use.py' in command:
                print("BLOCKED: Attempt to modify the security hook's immutability has been prevented.", file=sys.stderr)
                sys.exit(2)
            
            # Block rm -rf commands with comprehensive pattern matching
            if is_dangerous_rm_command(command):
                print("BLOCKED: Dangerous rm command detected and prevented", file=sys.stderr)
                sys.exit(2)  # Exit code 2 blocks tool call and shows error to Claude
            
            # Block dangerous git commands (push, rebase, merge, checkout, reset, clean)
            is_git_dangerous, git_cmd_type = is_dangerous_git_command(command)
            if is_git_dangerous:
                error_messages = {
                    'push': "BLOCKED: git push commands are prohibited to prevent accidental force pushes and protect remote repositories",
                    'reset': "BLOCKED: git reset commands are prohibited to prevent loss of commits and working changes",
                    'clean': "BLOCKED: git clean commands are prohibited to prevent deletion of untracked files",
                    'merge': "BLOCKED: git merge commands are prohibited to prevent unintended merges that could cause conflicts",
                    'rebase': "BLOCKED: git rebase commands are prohibited to prevent history rewriting that could cause issues",
                    'checkout': "BLOCKED: git checkout commands are prohibited to prevent accidental branch switches or file overwrites",
                    'filter-branch': "BLOCKED: git filter-branch commands are prohibited to prevent dangerous history rewriting",
                    'reflog': "BLOCKED: git reflog expire commands are prohibited to prevent removal of commit history safety net",
                    'gc': "BLOCKED: aggressive git garbage collection commands are prohibited to prevent loss of recent commits",
                    'stash': "BLOCKED: git stash drop/clear commands are prohibited to prevent loss of stashed work"
                }
                print(error_messages.get(git_cmd_type, "BLOCKED: Dangerous git command detected and prevented"), file=sys.stderr)
                print("Use git status to safely check repository state instead", file=sys.stderr)
                sys.exit(2)  # Exit code 2 blocks tool call and shows error to Claude
            
            # Block system-critical commands (shutdown, reboot, disk operations, etc.)
            if is_dangerous_system_command(command):
                print("BLOCKED: System-critical command detected and prevented", file=sys.stderr)
                print("This command could cause system instability or data loss", file=sys.stderr)
                sys.exit(2)  # Exit code 2 blocks tool call and shows error to Claude
            
            # Block dangerous file permission and ownership commands
            if is_dangerous_permission_command(command):
                print("BLOCKED: File permission/ownership command detected and prevented", file=sys.stderr)
                print("ALL chmod and chflags commands are prohibited to prevent security bypass attempts", file=sys.stderr)
                sys.exit(2)  # Exit code 2 blocks tool call and shows error to Claude
            
            # Block privilege escalation commands (sudo, su, doas, etc.)
            if is_privilege_escalation_command(command):
                print("BLOCKED: Privilege escalation command detected and prevented", file=sys.stderr)
                print("Commands like sudo, su, and doas are prohibited to prevent security bypass attempts", file=sys.stderr)
                sys.exit(2)  # Exit code 2 blocks tool call and shows error to Claude
            
            # Block database destructive operations
            if is_dangerous_database_command(command):
                print("BLOCKED: Database destructive operation detected and prevented", file=sys.stderr)
                print("This command could result in permanent data loss", file=sys.stderr)
                sys.exit(2)  # Exit code 2 blocks tool call and shows error to Claude
            
            # Block Docker/container destructive operations
            if is_dangerous_docker_command(command):
                print("BLOCKED: Docker destructive operation detected and prevented", file=sys.stderr)
                print("This command could remove containers, images, or volumes causing data loss", file=sys.stderr)
                sys.exit(2)  # Exit code 2 blocks tool call and shows error to Claude
            
            # Block dangerous package management operations
            if is_dangerous_package_command(command):
                print("BLOCKED: Dangerous package management operation detected and prevented", file=sys.stderr)
                print("This command could remove critical system packages or cause dependency issues", file=sys.stderr)
                sys.exit(2)  # Exit code 2 blocks tool call and shows error to Claude
        
        # Ensure log directory exists
        log_dir = Path.cwd() / '.logs'
        log_dir.mkdir(parents=True, exist_ok=True)
        log_path = log_dir / 'pre_tool_use.json'
        
        # Read existing log data or initialize empty list
        if log_path.exists():
            with open(log_path, 'r') as f:
                try:
                    log_data = json.load(f)
                except (json.JSONDecodeError, ValueError):
                    log_data = []
        else:
            log_data = []
        
        # Append new data
        log_data.append(input_data)
        
        # Write back to file with formatting
        with open(log_path, 'w') as f:
            json.dump(log_data, f, indent=2)
        
        sys.exit(0)
        
    except json.JSONDecodeError:
        # Gracefully handle JSON decode errors
        sys.exit(0)
    except Exception:
        # Handle any other errors gracefully
        sys.exit(0)

if __name__ == '__main__':
    main()