# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a collection of bash scripts and configuration files for automating common development tasks, primarily focused on Git operations, IDE launching, and utility functions. The repository also contains ZSH configuration files (.zshrc, .p10k.zsh) that define aliases and terminal settings.

## Project Structure

- `git/` - Git workflow automation scripts (branching, worktrees, cloning)
- `ide/` - Scripts for launching IDEs (Cursor, WebStorm) in current directory
- `utility/` - Various utility scripts for development tasks
- `.zshrc` - ZSH configuration with extensive aliases and environment setup
- `.p10k.zsh` - Powerlevel10k theme configuration

## Key Commands and Aliases

### Git Operations
- `gcl <ssh_link> <repo_name> <package_manager>` - Clone repository with optional package manager
- `gclb <ssh_link> <repo_name> <package_manager>` - Clone bare repository
- `gta <branch_name> [package_manager]` - Add git worktree with dependencies installation
- `gtd` - Delete worktree interactively
- `gbc` - Interactive branch checkout
- `gbd` - Interactive branch deletion
- `grst` - Git reset soft

### IDE Launching
- `s` - Launch WebStorm in current directory
- `cursor <path>` - Launch Cursor IDE
- `z` - Open bash_scripts directory and .zshrc in Cursor

### Utility Scripts
- `killport:soft <port>` - Kill process on port (soft)
- `killport:hard <port>` - Kill process on port (hard)
- Scripts in utility/ handle various development server operations

## Script Patterns

All bash scripts follow this structure:
1. Start with `#!/usr/bin/env zsh`
2. Use interactive prompts for user input when needed
3. Exit with appropriate codes (0 for success, 1 for error)
4. Scripts in subdirectories can reference other scripts using relative paths

## Adding New Scripts

To add a new bash script:
1. Create `.sh` file in appropriate directory (git/, ide/, or utility/)
2. Add alias in `.zshrc` using path variables like `$GIT_SCRIPTS_PATH`
3. Run `chmod +x /path/to/script.sh` to make executable
4. Scripts should be symlinked from user directory as documented in README.MD

## Environment Variables

Key path variables defined in .zshrc:
- `ROOT_SCRIPTS_PATH="/Users/user/bash_scripts"`
- `UTILITY_SCRIPTS_PATH="$ROOT_SCRIPTS_PATH/utility"`
- `GIT_SCRIPTS_PATH="$ROOT_SCRIPTS_PATH/git"`
- `IDE_SCRIPTS_PATH="$ROOT_SCRIPTS_PATH/ide"`

## Git Worktree Scripts

The worktree scripts (`gta`, `gtar`, etc.) automatically:
- Create new worktree in parent directory
- Install dependencies using specified package manager (defaults to yarn)
- Copy environment files (.env, .env.local, .env.auth, .gemini)
- Copy aider configuration (.aider.conf.yml)
- Launch IDE in the new worktree directory