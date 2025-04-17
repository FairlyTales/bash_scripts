# How to add new bash script

1. Create new `.sh` file in the corresponding directory
2. Add alias for launching this script in the .zshrc file
3. Run `chmod -X /Users/{user}/{bash_scripts_directory}/{CORRESPONDING_DIRECTORY}/*` to give all files in the directory rights to be executed (must be executed for every subdirectory)
4. Run `chmod -755 /Users/{user}/{bash_scripts_directory}/{CORRESPONDING_DIRECTORY}/*` to set access rights to all files in the directory (must be executed for every subdirectory)

# How to Link .zshrc, .p10k.zsh and other files from bash scripts directory to user directory

In order to apply .zshrc and other configs to terminal they should be placed inside the `/Users/{user}` directory. But we don't want to have a git repository there. That is why we use symlinks

1. Navigate to the user directory
2. Execute the following command: `ln -s ~{user}/{bash_scripts_directory}/.zshrc ~/.zshrc`

It will create a symlink allowing us to keep our .zshrc and bash scripts inside a separate directory under git while having a link to this .zshrc in the our user directory