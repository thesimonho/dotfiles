# Public keys select identities held by the native 1Password SSH agent.
{ config, lib, ... }:
let
  ids = config.my._identities;
  socket = config.my.onepassword.agentSocket;
  identitySettings = lib.mapAttrs' (_: id: {
    name = id.sshHost;
    value = {
      HostName = id.sshProxyHost;
      Port = id.sshPort;
      User = "git";
      AddKeysToAgent = "false";
      ForwardAgent = false;
      IdentitiesOnly = true;
      IdentityFile = ''"${config.home.homeDirectory}/.ssh/${id.sshKeyFile}.pub"'';
      IdentityAgent = ''"${socket}"'';
    };
  }) ids;
in
{
  home.sessionVariables.SSH_AUTH_SOCK = socket;
  xdg.configFile."environment.d/ssh.conf" = lib.mkIf (config.my.os != "darwin") {
    text = "SSH_AUTH_SOCK=${socket}\n";
  };
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = identitySettings // {
      workstation = {
        HostName = "workstation.home.arpa";
        User = "simon";
      };
    };
  };
  home.file = {
    ".ssh/config".force = true;
  }
  // lib.mapAttrs' (_: id: {
    name = ".ssh/${id.sshKeyFile}.pub";
    value.text = id.sshPublicKey + "\n";
  }) ids;
  home.activation.fixSshPermissions = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run install -d -m 0700 "$HOME/.ssh"
    if [ -L "$HOME/.ssh/config" ]; then
      src="$(readlink -f "$HOME/.ssh/config")"
      run rm -f "$HOME/.ssh/config"
      run install -m 0600 "$src" "$HOME/.ssh/config"
    fi
  '';
}
