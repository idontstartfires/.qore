
[[ "$COLORTERM" == "(24bit|truecolor)" || "${terminfo[colors]}" -eq '16777216' ]] || zmodload zsh/nearcolor

COLOR_USER="blue"
COLOR_HOST="blue"
COLOR_TEXT="white"

PS1="%B%F{$COLOR_USER}%n%F{$COLOR_TEXT}@%F{$COLOR_HOST}%m%b%F{$COLOR_TEXT} %~> "
