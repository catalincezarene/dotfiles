path=("$HOME/.docker/bin" $path)

alias dpsf='docker ps -qf'
alias dcr='docker compose run --rm'

composer() {
  docker run --rm \
    --interactive \
    --tty \
    --volume "$PWD":/app \
    composer "$@"
}
