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

export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

# Source shell modules
for mod_file in `ls $QORE/shell/mod/`; do 
    source "$QORE/shell/mod/$mod_file"
done
