
function _config_shell() {
    arg=$1; [[ -n $1 ]] && shift
    # If no argument, edit the bash zshrc file
    if [ -z "$arg" ]; then
        if [ -f "$HOME/.zshenv" ]; then
            print -P "~/.%F{blue}zshenv%f"
        else
            print -P "~/.%F{red}zshenv%f"
        fi
        if [ -f "$HOME/.zprofile" ]; then
            print -P "~/.%F{blue}zprofile%f"
        else
            print -P "~/.%F{red}zprofile%f"
        fi
        
        if [ -f "$HOME/.zshrc" ]; then
            print -P "~/.%F{blue}zshrc%f"
        else
            print -P "~/.%F{red}zshrc%f"
        fi
        
        # The (N) is a Zsh-specific flag (nullglob) so it doesn't error if the folder is empty
        local files=("${XDG_CONFIG_HOME}/shell/mod"/*.zsh(N))
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
    case "$arg" in
        .zshenv|zshenv|shenv|env)
            $EDITOR "$HOME/.zshenv"
        ;;
        .zprofile|zprofile|profile|prof)
            $EDITOR "$HOME/.zprofile"
        ;;
        .zshrc|zshrc|shrc|rc)
            $EDITOR "$HOME/.zshrc"
        ;;
        *)    
            if [ -f "${XDG_CONFIG_HOME}/shell/mod/$arg.zsh" ]; then
                $EDITOR "${XDG_CONFIG_HOME}/shell/mod/$arg.zsh"
            else
                echo "Shell module $arg not found"
                
                if read -q "REPLY?Would you like to create it? [y/N]: "; then
                    # New modules are authored in the repo (global), then linked by sync
                    mod_file="$QORE/config/shell/mod/$arg.zsh"
                    $EDITOR $mod_file
                    [ -f "$mod_file" ] && "$QORE/sync"
                else
                    return
                fi
            fi
        ;;
    esac
    source $HOME/.zshrc
}

function config() {
    arg=$1; [[ -n $1 ]] && shift
    case $arg in
        shell) _config_shell $@ ;;
        project)
            cwd=$(pwd)
            cd "$QORE/project"
            $EDITOR .
            cd "$cwd"
        ;;
        *) 
            cwd=$(pwd)
            cd "$XDG_CONFIG_HOME/$arg"
            $EDITOR .
            cd "$cwd"
        ;;
    esac
}
