path=("$HOME"/.local/opt/*/bin(N) "$HOME/.local/bin" $path)
fpath=("$HOME/.config/zsh/site-functions" $fpath)

setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

setopt autocd
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' hosts off

autoload -Uz vcs_info add-zsh-hook
zstyle ':vcs_info:git:*' formats '(%b%c%u)'
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr '*'
zstyle ':vcs_info:git:*' stagedstr '+'
add-zsh-hook precmd vcs_info

setopt prompt_subst
prompt='%n@%m %~ %F{yellow}${vcs_info_msg_0_}%f
> '

alias ls='ls --color=auto'
alias ll='ls -alh'
alias dpsf='docker ps -qf'
alias dcr='docker compose run --rm'

composer() {
  docker run --rm \
    --interactive \
    --tty \
    --volume "$PWD":/app \
    composer "$@"
}

() { for f; do source "$f"; done } "$HOME/.config/zsh/zshrc.d/"*.zsh(N)
