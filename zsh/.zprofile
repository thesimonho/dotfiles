export ZPROFILE_SOURCED=true

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
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew/bin"
    PATH="$HOMEBREW_PREFIX:$PATH"
else
    # macOS
    HOMEBREW_PREFIX="/opt/homebrew/bin"
    PATH="$HOMEBREW_PREFIX:$PATH"
fi

export PATH

# set env vars
export VIRTUAL_ENV_DISABLE_PROMPT=1
