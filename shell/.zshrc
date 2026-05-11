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

export QORE=$HOME/.qore
export PATH=$PATH:~/.local/bin:$QORE/local/bin:$QORE/project/scripts

export TERM=kitty
export EDITOR=nvim
export VISUAL=$EDITOR

export BROWSER=firefox-developer-edition
export FM=yazi
export AUDIO_CTRL=pulsemixer
export PROC_CTRL=btm

export LAUNCHER=wofi

export XDG_RUNTIME_HOME=$HOME/.local/runtime
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share

HISTFILE=~/.cache/zsh-histfile
HISTSIZE=1000
SAVEHIST=1000

export LESSHISTFILE=-
export GNUPGHOME=$XDG_DATA_HOME/gnupg
export PASSWORD_STORE_DIR=$XDG_DATA_HOME/pass
export XAUTHORITY=$XDG_RUNTIME_DIR/Xauthority
export _JAVA_OPTIONS=-Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java
alias mbsync='mbsync -c $XDG_CONFIG_HOME/isync/mbsyncrc'
alias gpg2='gpg2 --homedir $XDG_DATA_HOME/gnupg'
export GOPATH=$XDG_DATA_HOME/go
export GOMODCACHE=$GOPATH/pkg/mod
export PYTHON_HISTORY=~/.local/share/python/history

# Source shell modules
for mod_file in `ls $QORE/shell/mod/`; do 
    source "$QORE/shell/mod/$mod_file"
done
