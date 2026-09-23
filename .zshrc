# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo

# Load completions
autoload bashcompinit && bashcompinit
autoload -Uz compinit && compinit

# Load edit command line plugin
autoload -z edit-command-line
zle -N edit-command-line

## Load uv autocompletion if exists
if [[ -a /etc/bash_completion.d/uv ]]; then
  source /etc/bash_completion.d/uv
fi

## Load uvx autocompletion if exists
if [[ -a /etc/bash_completion.d/uvx ]]; then
  source /etc/bash_completion.d/uvx
fi

## Load rabbitmqadmin autocompletion if exists
if [[ -a /etc/bash_completion.d/rabbitmqadmin ]]; then
  source /etc/bash_completion.d/rabbitmqadmin
fi

complete -C '/usr/local/bin/aws_completer' aws

zinit cdreplay -q

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Keybindings
bindkey -v
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^y' autosuggest-accept
bindkey '^e' edit-command-line


# History
HISTSIZE=20000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias pof='poweroff'
alias :q='exit'
alias ls='ls --color'
alias lla='ls -lah'
alias nvim='nvim'
alias c='clear'
alias aenv='source .venv/bin/activate'
alias cenv='python -m venv .venv'
alias denv='rm -r -I -v .venv'
alias bat=batcat
alias xsell='xsel --clipboard'
alias n='nvim'
alias j='just'

# Shell integrations
[ -f /usr/share/fzf/shell/key-bindings.zsh ] && source /usr/share/fzf/shell/key-bindings.zsh
eval "$(zoxide init --cmd cd zsh)"

# asdf
. "$HOME/.asdf/asdf.sh"
. "$HOME/.asdf/completions/asdf.bash"

# Paths
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:/usr/local/go/bin"
export GOPATH=$HOME/go
export PATH="$PATH:$GOPATH/bin"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="$PATH:$HOME/.node/bin"

export PATH=$PATH:/home/rgpb/.spicetify

# Set neovim as the default editor
export EDITOR=nvim

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

[ -f "/home/rgpb/.ghcup/env" ] && . "/home/rgpb/.ghcup/env" # ghcup-envexport PATH="$HOME/.ghcup/bin:$PATH"


# Avoid warning message
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

# Automatice task
FLAG_FILE="$HOME/usrtmp/.task_daily_done"
LOGS_FILE="$HOME/usrtmp/daily.logs"
BIN_FILE="$HOME/personal/run_task_daily.sh"

if [ ! -f "$FLAG_FILE" ] || [ "$(date +%Y-%m-%d)" != "$(cat $FLAG_FILE)" ]; then
    echo "Running daily task: $(date +%Y-%m-%d)" >> "$LOGS_FILE"
    if [ -f "$BIN_FILE" ]; then
      bash "$BIN_FILE" &
    fi
    date +%Y-%m-%d > "$FLAG_FILE"
else
    echo "Task already ran today" >> "$LOGS_FILE"
fi


# BEGIN opam configuration
# This is useful if you're using opam as it adds:
#   - the correct directories to the PATH
#   - auto-completion for the opam binary
# This section can be safely removed at any time if needed.
[[ ! -r '/home/rgpb/.opam/opam-init/init.zsh' ]] || source '/home/rgpb/.opam/opam-init/init.zsh' > /dev/null 2> /dev/null
# END opam configuration

[ -f "/home/rgpb/.ghcup/env" ] && . "/home/rgpb/.ghcup/env" # ghcup-env
# opencode
export PATH=/home/rgpb/.opencode/bin:$PATH
