# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"

#zoxide
eval "$(zoxide init zsh)"

# ZSH prompt config
setopt PROMPT_SUBST

format_current_git_branch() {
  local BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [[ -n ${BRANCH} ]] ; then
    echo "(${BRANCH})"
  fi
}

export NEWLINE=$'\n'

export PROMPT='%n@%m %~ $(format_current_git_branch) ${NEWLINE}%# '
