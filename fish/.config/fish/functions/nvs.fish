function nvs --description 'Neovim configuration switcher'
    set -l nvim_path (set -q XDG_CONFIG_HOME; and echo "$XDG_CONFIG_HOME"; or echo "$HOME/.config")/nvim
    set -l nvim_configs (set -q XDG_CONFIG_HOME; and echo "$XDG_CONFIG_HOME"; or echo "$HOME/.config")/nvims

    # Get configuration list using fzf
    set -l config (fd -d 1 -t d . "$nvim_configs" | xargs -n1 basename | fzf --border --exit-0 --height=~50% --layout=reverse --prompt ' Neovim configuration switcher  ')

    if test -z "$config"
        printf "%s\n" "No configuration selected."
        return 0
    end

    set -l target "$nvim_configs/$config"

    # Handle existing nvim path
    if test -L "$nvim_path"
        command rm "$nvim_path"
    else if test -e "$nvim_path"
        printf "%s\n" "Error: $nvim_path exists and is not a symlink. Move it to nvims/ first."
        return 1
    end

    # Create symlink and launch nvim
    command ln -s "$target" "$nvim_path"
    printf "%s\n" "Switched to: $config"
    
    # Launch nvim with any passed arguments
    command nvim $argv
end
