if (( ! ${+commands[fzf]} )); then
    return 0
fi

source <(fzf --zsh)

export FZF_CTRL_T_OPTS="--style minimal --layout default --preview 'cat {}' --bind 'focus:transform-header:file --brief {}'"
