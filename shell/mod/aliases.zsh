
# Concise!
alias pac='doas pacman'
alias sys='doas systemctl'
alias firefox='firefox-developer-edition'

# Modern replacements for classic commands
alias ls='lsd'
alias cat='bat'
alias fzf='fzf --preview "bat --color=always --style=numbers --line-range=:100 {}"'
alias diff='delta'
alias dog='doggo'
alias vim="nvim"

# It's rare that I'd want to avoid making subdirectories...
alias mkdir='mkdir -pv'

# Changing default file locations to clean my home directory
alias mbsync='mbsync -c $XDG_CONFIG_HOME/isync/mbsyncrc'
alias gpg2='gpg2 --homedir $XDG_DATA_HOME/gnupg'
