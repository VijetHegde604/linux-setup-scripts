# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

# Aliases
alias cd="z"
alias ls='lsd'
alias lt='lsd --tree'
alias start-docker='sudo systemctl start docker'
alias stop-docker='sudo systemctl stop docker && sudo systemctl stop docker.socket'

# Starship
eval "$(starship init bash)"

# Mise
eval "$(/home/vijeth/.local/bin/mise activate bash)"

# zoxide
eval "$(zoxide init bash)"

# TERM
export TERM=xterm-256color
