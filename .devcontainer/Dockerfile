FROM mcr.microsoft.com/devcontainers/base:ubuntu

LABEL org.opencontainers.image.source=https://github.com/thesimonho/dotfiles
LABEL org.opencontainers.image.description="Prebuilt base image for devcontainers."

# Optional args
ARG DOTFILES_REPO=https://github.com/thesimonho/dotfiles
ARG GIT_SSH_REWRITE=off
ENV GIT_SSH_REWRITE=${GIT_SSH_REWRITE}

# Install things
RUN apt-get update && apt-get install -y --no-install-recommends \
  curl \
  wl-clipboard \
  ncurses-term \
  libvterm0 && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  touch /.dockerenv

# Switch to non-root user
RUN usermod --shell "$(which zsh)" vscode
USER vscode
WORKDIR /home/vscode
ENV HOME=/home/vscode
RUN mkdir -p ~/.ssh && mkdir -p ~/.aws

# Homebrew
RUN NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Clone dotfiles repo
RUN git clone --depth=1 $DOTFILES_REPO ~/dotfiles && \
  chmod +x ~/dotfiles/install.sh && \
  chmod +x ~/dotfiles/setup/linux/*.sh || echo "Warn: additional setup scripts not found...skipping" && \
  ~/dotfiles/install.sh

CMD ["/usr/bin/zsh"]
