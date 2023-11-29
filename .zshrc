export MY_UID=$(id -u)
export MY_GID=$(id -g)

autoload -Uz compinit promptinit
compinit
zstyle ':completion:*' hosts off
promptinit
prompt adam1 none
