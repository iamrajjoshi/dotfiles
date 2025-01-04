#!/usr/bin/env fish

# Get absolute path of the dotfiles directory
set DOTFILES_DIR (realpath (dirname (status --current-filename)))

# Define the source and destination directories
set CONFIG_DIR ~/.config/fish
set STARSHIP_CONFIG_DIR ~/.config

# Create necessary directories
mkdir -p $CONFIG_DIR
mkdir -p $STARSHIP_CONFIG_DIR

# List of files to symlink for fish
set files_to_link \
    alias.fish \
    config.fish \
    fish_plugins \
    git.fish \
    sentry.fish

# Create symlinks for fish files
for file in $files_to_link
    set source_file "$DOTFILES_DIR/fish/$file"
    set target_file "$CONFIG_DIR/$file"
    
    # Check if source file exists
    if not test -e $source_file
        echo "Warning: Source file doesn't exist: $source_file"
        continue
    end
    
    # Handle existing target
    if test -e $target_file
        if test -L $target_file
            rm $target_file
            echo "Removed existing symlink: $target_file"
        else
            mv $target_file "$target_file.backup"
            echo "Backed up existing file: $target_file.backup"
        end
    end
    
    # Create the symlink with absolute paths
    ln -s $source_file $target_file
    echo "Created symlink: $target_file -> $source_file"
end

# Setup Starship
set starship_source "$DOTFILES_DIR/starship.toml"
set starship_target "$STARSHIP_CONFIG_DIR/starship.toml"

# Check if starship.toml exists in source
if not test -e $starship_source
    echo "Error: starship.toml not found at $starship_source"
    exit 1
end

# Handle existing starship config
if test -e $starship_target
    if test -L $starship_target
        rm $starship_target
        echo "Removed existing starship symlink: $starship_target"
    else
        mv $starship_target "$starship_target.backup"
        echo "Backed up existing starship config: $starship_target.backup"
    end
end

# Create starship symlink
ln -s $starship_source $starship_target
echo "Created starship symlink: $starship_target -> $starship_source"

# Install Fisher if not present
if not functions -q fisher
    echo "Installing Fisher package manager..."
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
    fisher update
end

# Install Starship if not present
if not command -v starship >/dev/null
    echo "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh
end

# Ensure starship init is in config.fish
if not grep -q "starship init fish | source" $CONFIG_DIR/config.fish
    echo "starship init fish | source" >> $CONFIG_DIR/config.fish
end

echo "Fish and Starship configuration files have been symlinked successfully!"