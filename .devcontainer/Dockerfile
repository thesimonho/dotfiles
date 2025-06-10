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
  gnupg

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl -fsSL https://apt.fury.io/wez/gpg.key | gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg && \
  echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | tee /etc/apt/sources.list.d/wezterm.list && \
  chmod 644 /usr/share/keyrings/wezterm-fury.gpg 

RUN apt-get update && apt-get install -y --no-install-recommends wezterm-nightly && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  touch /.dockerenv

# Switch to non-root user
RUN usermod --shell "$(which zsh)" vscode
USER vscode
WORKDIR /home/vscode
ENV HOME=/home/vscode

# Homebrew
RUN NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Clone dotfiles repo
RUN git clone --depth=1 $DOTFILES_REPO ~/dotfiles && \
  chmod +x ~/dotfiles/install.sh && \
  chmod +x ~/dotfiles/setup/linux/*.sh || echo "Warn: additional setup scripts not found...skipping" && \
  ~/dotfiles/install.sh

CMD ["/usr/bin/zsh"]
