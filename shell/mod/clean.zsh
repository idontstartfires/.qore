
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
