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
5. Ask user  `chmod -X /Users/{user}/{bash_scripts_directory}/{CORRESPONDING_DIRECTORY}/*` and `chmod 755 /Users/{user}/{bash_scripts_directory}/{CORRESPONDING_DIRECTORY}/*` to give all files in the directory rights to be executed (must be executed for every subdirectory). You don't have the rights to do this, so MUST ask user to do it
6. Add tests for the script in the appropriate `tests/` directory

## Updating Existing Scripts

To update an existing bash script:
1. Update the script in the appropriate directory (git/, ide/, or utility/)
2. Update the tests in the appropriate `tests/` directory
3. Run `test-scripts` to run the tests and ensure they pass

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

## Testing

This repository includes a comprehensive test suite for bash scripts using [bats-core](https://bats-core.readthedocs.io/).

### Test Structure

- `test/` - Main test directory containing test runner and bats helpers
- `git/tests/` - Tests for git workflow scripts
- `utility/tests/` - Tests for utility scripts (when added)
- `ide/tests/` - Tests for IDE launcher scripts (when added)

### Running Tests

```bash
# Run all tests
./test/run_tests.sh

# Run specific test file
bats git/tests/reset_soft.bats

# Run tests with verbose output
bats --verbose-run git/tests/
```

### Test Dependencies

- **bats-core**: Main testing framework (`brew install bats-core`)
- **bats-support**: Additional helper functions (included in `test/bats-helpers/`)
- **bats-assert**: Assertion helpers (included in `test/bats-helpers/`)
- **bats-file**: File-related assertions (included in `test/bats-helpers/`)

### Writing New Tests

When adding a new script, create a corresponding `.bats` test file:

1. Create `script_name.bats` in the appropriate `tests/` directory
2. Load the test helper: `load test_helper`
3. Use `setup()` and `teardown()` functions for test preparation/cleanup
4. Write test cases using `@test "description" { ... }` blocks

Example test structure:
```bash
#!/usr/bin/env bats

load test_helper

setup() {
    create_test_repo
}

teardown() {
    teardown_test_repo
}

@test "script does expected behavior" {
    run "$GIT_SCRIPTS_PATH/script.sh" arg1
    assert_success
    assert_output --partial "expected output"
}
```

### Test Utilities

The `test_helper.bash` provides common utilities:
- `create_test_repo()` - Creates isolated git repository for testing
- `create_branch(name)` - Creates and switches back from test branch
- `assert_current_branch(name)` - Verifies current git branch
- `setup_package_manager_mocks()` - Mocks yarn/npm commands
- `simulate_user_input(input)` - Provides input for interactive scripts
