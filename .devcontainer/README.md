# devcontainer

devcontainer definition for a container with base tools and config. Functions as a prebuild for other project-specific containers.

```sh
make check
make build
make push
make clean
```

The package repo itself is [here](ghcr.io/thesimonho/devcontainer-prebuild).

## Usage

When creating new devcontainers, specify this image as the base:

```json
{
  "image": "ghcr.io/thesimonho/devcontainer-prebuild:latest",
  "features": {
    ...
  }
}
```

You can use the `latest` tag, or any of the commit or dated tags. This will ensure that this prebuild is used as a base image.

Containers created from this prebuild need to set their own mounts/variables/etc, as they don't get passed through from parent containers, eg.:

```json
{
  "$schema": "https://raw.githubusercontent.com/devcontainers/spec/refs/heads/main/schemas/devContainer.base.schema.json",
  "image": "ghcr.io/thesimonho/devcontainer-prebuild:latest",
  "postStartCommand": "cd ~/dotfiles && git pull --ff-only",
  "runArgs": ["--network=host"],
  "features": {},
  "customizations": {},
  "workspaceMount": "source=${localWorkspaceFolder},target=/home/vscode/Projects/${localWorkspaceFolderBasename},type=bind,consistency=cached",
  "workspaceFolder": "/home/vscode/Projects/${localWorkspaceFolderBasename}",
  "mounts": [
    "source=${localEnv:HOME}/.ssh,target=/home/vscode/.ssh,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.aws,target=/home/vscode/.aws,type=bind,consistency=cached",
    "source=/tmp/.X11-unix,target=/tmp/.X11-unix,type=bind",
    "type=bind,source=${env:SSH_AUTH_SOCK},target=/home/vscode/.ssh/ssh-agent"
  ],
  "containerEnv": {
    "CONTAINER_NAME": "${localWorkspaceFolderBasename}"
  },
  "remoteEnv": {
    "TZ": "America/Vancouver",
    "SSH_AUTH_SOCK": "/home/vscode/.ssh/ssh-agent",
    "DISPLAY": "${localEnv:DISPLAY}"
  }
}
```
