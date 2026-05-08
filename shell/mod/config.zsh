
function _config_shell() {
    # If no argument, edit the bash zshrc file
    if [ -z "$2" ]; then
        print -P "~/.%F{blue}zshrc%f"
        print -P "~/.%F{blue}zprofile%f"
        
        # The (N) is a Zsh-specific flag (nullglob) so it doesn't error if the folder is empty
        local files=("$QORE/shell/mod"/*.zsh(N))
        if (( ${#files[@]} > 0 )); then
            for file in "${files[@]}"; do
                # Strip the path and the .zsh extension for clean output
                print -P "mod/%F{blue}$(basename "$file" .zsh)%f.zsh"
            done
        else
            echo "  ----  "
        fi
        
        # Exit the helper without reloading the shell
        return 0
    fi 
    case "$2" in
        .zshrc|zshrc|shrc|rc)
            $EDITOR "$HOME/.zshrc"
        ;;
        .zprofile|zprofile|profile|prof)
            $EDITOR "$HOME/.zprofile"
        ;;
        *)    
            if [ -f "$QORE/shell/mod/$2.zsh" ]; then
                $EDITOR "$QORE/shell/mod/$2.zsh"
            else
                echo "Shell module $2 not found"
                
                if read -q "REPLY?Would you like to create it? [y/N]: "; then
                    mod_file="$QORE/shell/mod/$2.zsh"
                    $EDITOR $mod_file
                else
                    return
                fi
            fi
        ;;
    esac
    source $HOME/.zshrc
}

function config() {
    case $1 in
        shell)        
            _config_shell $@
        ;;
        *)
            cd "$XDG_CONFIG_HOME/$1"
            $EDITOR
        ;;
    esac
}
