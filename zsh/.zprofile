# prepend to $PATH unless it is already there
if ! [[ "$PATH" =~ "$HOME/bin" ]]
then
    PATH="$HOME/bin:$PATH"
fi

if ! [[ "$PATH" =~ "$HOME/.local/bin:" ]]
then
    PATH="$HOME/.local/bin:$PATH"
fi

if ! [[ "$PATH" =~ "/usr/local/bin" ]]
then
    PATH="/usr/local/bin:$PATH"
fi

# add homebrew path depending on osx or linux
if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="brew"
else
  if [ -f /opt/homebrew/bin/brew ]; then
    BREW_PREFIX="/opt/homebrew/bin/brew"  # macOS ARM
  elif [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
    BREW_PREFIX="/home/linuxbrew/.linuxbrew/bin/brew"  # Linux
  else
    echo "❌ Homebrew not found. Please install it first." >&2
    exit 1
  fi
  eval "$($BREW_PREFIX shellenv)"
fi

# set env vars
export PATH
export VIRTUAL_ENV_DISABLE_PROMPT=1
