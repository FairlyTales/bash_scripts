# How to add new bash script

1. Create new `.sh` file in the corresponding directory
2. Add alias for launching this script in the .zshrc file
3. Run `chmod -X /Users/{user}/{bash_scripts_directory}/{CORRESPONDING_DIRECTORY}/*` to give all files in the directory rights to be executed (must be executed for every subdirectory)
4. Run `chmod 755 /Users/{user}/{bash_scripts_directory}/{CORRESPONDING_DIRECTORY}/*` to set access rights to all files in the directory (must be executed for every subdirectory)

# How to Link .zshrc, .p10k.zsh and other files from bash scripts directory to user directory

In order to apply .zshrc and other configs to terminal they should be placed inside the `/Users/{user}` directory. But we don't want to have a git repository there. That is why we use symlinks

1. Navigate to the user directory
2. Execute the following command: `ln -s ~{user}/{bash_scripts_directory}/.zshrc ~/.zshrc`

It will create a symlink allowing us to keep our .zshrc and bash scripts inside a separate directory under git while having a link to this .zshrc in the our user directory

# How to enable global .gitignore

Some stuff should be ignored by default and writing it over and over again in every ignore file in every project is a drag. It can be fixed by using global ignore file

1. Create a `.gitignore` file somewhere (bash_scrips_directory for example, cause right now for me it's more like a scripts and settings directory)
2. Execute `git config --global core.excludesfile {user}/{bash_scripts_directory}/.gitignore` command to set this ignore file as global
3. \*Optionally check the global gitconfig (probably located in the user directory). `excludesfile = /Users/user/bash_scripts/.gitignore` should be present under the `[core]` section

# Bash script tests

Use `test-scripts` command to run tests for all bash scripts.
