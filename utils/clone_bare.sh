#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

usage() {
  cat <<EOF # remove the space between << and EOF, this is due to web plugin issue
Usage: $(
    basename "${BASH_SOURCE[0]}"
  ) [-h] [-v] [-l] repository

Clone a bare git repo and set up environment for working comfortably and exclusively from worktrees.

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-l, --location  Location of the bare repo contents (default: .bare)
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  location='.bare'

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --no-color) NO_COLOR=1 ;;
    -l | --location)
      location="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")

  # check required params and arguments
  # [[ -z "${param-}" ]] && die "Missing required parameter: param"
  [[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"

  return 0
}

parse_params "$@"

msg "Cloning bare repository to $location..."
git clone --bare "${args[@]}" "$location"
pushd "$location" >/dev/null

msg "Adjusting origin fetch locations..."
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
git fetch

msg "Setting .git file contents..."
popd >/dev/null
echo "gitdir: ./$location" >.git

msg "Set config..."
git config --add core.logallrefupdates true

msg "Create initial worktree..."
git show-ref --verify --quiet refs/heads/main
if [ $? -eq 0 ]; then
  # 'main' branch exists, add worktree for 'main'
  git worktree add main main
else
  # 'main' branch does not exist, check for 'master'
  git show-ref --verify --quiet refs/heads/master
  if [ $? -eq 0 ]; then
    # 'master' branch exists, add worktree for 'master'
    git worktree add main master
  else
    # Neither 'main' nor 'master' branch exists
    echo "Neither 'main' nor 'master' branch exists."
    exit 1
  fi
fi

msg "Success."
