export TERM_PROGRAM=ghostty
export EDITOR=nvim
export VISUAL=$EDITOR

export BROWSER=vivaldi
export FILE_MANAGER=yazi
export AUDIO_CONTROL=pulsemixer
export PROCESS_CONTROL=btm

export LAUNCHER=rofi

export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share

export LESSHISTFILE=-
export GNUPGHOME=$XDG_DATA_HOME/gnupg
export PASSWORD_STORE_DIR=$XDG_DATA_HOME/pass
export XAUTHORITY=$XDG_RUNTIME_DIR/Xauthority
export _JAVA_OPTIONS=-Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java
export GOPATH=$XDG_DATA_HOME/go
export GOMODCACHE=$GOPATH/pkg/mod
export PYTHON_HISTORY=$XDG_DATA_HOME/python/history

export QORE=$HOME/.qore
export PATH="$HOME/.local/bin:$QORE/local/bin:$QORE/project/bin:$PATH"

export WLR_NO_HARDWARE_CURSORS=1
export QT_QPA_PLATFORM=wayland 
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export LIBVA_DRIVER_NAME=nvidia
export __GLX_VENDOR_LIBRARY_NAME=nvidia
