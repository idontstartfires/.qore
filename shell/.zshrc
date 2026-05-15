#!/bin/zsh
# SILENCE!
unsetopt beep
# Zsh Completion
autoload -Uz compinit && compinit
zstyle ':completion::complete:*' gain-privileges 1
# Zsh Plugins
ZSH_PLUGINS=/usr/share/zsh/plugins
source $ZSH_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh
#source $ZSH_PLUGINS/zsh-autocomplete/zsh-autocomplete.plugin.zsh

HISTFILE=$XDG_CACHE_HOME/.zsh_history
HISTSIZE=1000
SAVEHIST=1000

export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

if [ -d "$QORE" ]; then
    # Source shell modules
    for mod_file in `ls $QORE/shell/mod/`; do 
        source "$QORE/shell/mod/$mod_file"
    done
fi
