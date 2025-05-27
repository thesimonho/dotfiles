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

# set env vars
export PATH
export VIRTUAL_ENV_DISABLE_PROMPT=1
