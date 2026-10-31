# Public identity registry for Git and 1Password SSH routing.
# Private keys and current API values live in 1Password.

{
  identities = {
    personal = {
      name = "Simon Ho";
      email = "simonho.ubc@gmail.com";
      sshKeyFile = "id_personal";
      sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIInxAupJx0YQwBRFLN/gPQCc2my21GwU6CQet62Dww8y simonho.ubc@gmail.com";
      sshHost = "github.com";
      sshProxyHost = "ssh.github.com";
      sshPort = 443;
      remotePatterns = [
        "git@github.com:*/**"
        "ssh://git@github.com/**"
        "https://github.com/**"
      ];
    };
  };
}
