export ZSH_CUSTOM=$HOME/.oh-my-zsh/custom

# autoupdate
DIR="$ZSH_CUSTOM/plugins/autoupdate"
if [ -d "$DIR/.git" ]; then
  echo "✔ autoupdate already cloned"
else
  echo "➕ Cloning autoupdate"
  git clone https://github.com/TamCore/autoupdate-oh-my-zsh-plugins $DIR
fi

# zsh-autosuggestions
DIR="$ZSH_CUSTOM/plugins/zsh-autosuggestions"
if [ -d "$DIR/.git" ]; then
  echo "✔ zsh-autosuggestions already cloned"
else
  echo "➕ Cloning zsh-autosuggestions"
  git clone https://github.com/zsh-users/zsh-autosuggestions $DIR
fi

# syntax-highlighting
DIR="$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
if [ -d "$DIR/.git" ]; then
  echo "✔ zsh-syntax-highlighting already cloned"
else
  echo "➕ Cloning zsh-syntax-highlighting"
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $DIR
fi

# cd-ls
DIR="$ZSH_CUSTOM/plugins/cd-ls"
if [ -d "$DIR/.git" ]; then
  echo "✔ cd-ls already cloned"
else
  echo "➕ Cloning cd-ls"
  git clone https://github.com/zshzoo/cd-ls $DIR
fi

# dot-up
DIR="$ZSH_CUSTOM/plugins/zsh-dot-up"
if [ -d "$DIR/.git" ]; then
  echo "✔ zsh-dot-up already cloned"
else
  echo "➕ Cloning zsh-dot-up"
  git clone https://github.com/toku-sa-n/zsh-dot-up $DIR
fi

# fzf tab
DIR="$ZSH_CUSTOM/plugins/fzf-tab"
if [ -d "$DIR/.git" ]; then
  echo "✔ fzf-tab already cloned"
else
  echo "➕ Cloning fzf-tab"
  git clone https://github.com/Aloxaf/fzf-tab $DIR
fi


echo "✅ Zsh plugins installed."
