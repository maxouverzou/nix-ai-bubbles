{
  description = "Sandboxed AI coding assistants using bubblewrap";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs

  outputs =
    { self, ... }@inputs:

    let
      supportedSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
        "aarch64-linux" # 64-bit ARM Linux
        "x86_64-darwin" # 64-bit Intel macOS
        "aarch64-darwin" # 64-bit ARM macOS
      ];

      forEachSupportedSystem =
        f:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import inputs.nixpkgs { inherit system; config.allowUnfree = true; };
          }
        );
    in
    {
      packages = forEachSupportedSystem (
        { pkgs }:
        let
          mkAiWrapper = name: package: bwrapFlags:
            pkgs.writeShellScriptBin name ''
              ${pkgs.bubblewrap}/bin/bwrap \
                --unshare-all \
                --share-net \
                --die-with-parent \
                --new-session \
                --proc /proc \
                --dev /dev \
                --bind /tmp /tmp \
                --ro-bind /nix /nix \
                --ro-bind-try /usr /usr \
                --ro-bind-try /lib /lib \
                --ro-bind-try /lib64 /lib64 \
                --ro-bind "$(readlink -f /etc/resolv.conf)" /etc/resolv.conf \
                --ro-bind /etc/ssl /etc/ssl \
                --ro-bind /etc/hosts /etc/hosts \
                --ro-bind "$(readlink -f /etc/nsswitch.conf)" /etc/nsswitch.conf \
                --ro-bind-try /etc/pki /etc/pki \
                --ro-bind-try "$HOME/.nix-profile" "$HOME/.nix-profile" \
                --setenv PATH "$PATH" \
                ${pkgs.lib.concatStringsSep " " bwrapFlags} \
                --bind "$(pwd)" "$(pwd)" \
                --chdir "$(pwd)" \
                -- ${pkgs.lib.getExe package} "$@"
            '';
        in
        {
          claude-code = mkAiWrapper "claude-code" pkgs.claude-code [
            ''--bind "$HOME/.claude" "$HOME/.claude"''
          ];
          opencode = mkAiWrapper "opencode" pkgs.opencode [
            ''--bind "$HOME/.config/opencode" "$HOME/.config/opencode"''
          ];
          gemini-cli = mkAiWrapper "gemini-cli" pkgs.gemini-cli [
            ''--setenv GEMINI_SANDBOX false''
            ''--bind "$HOME/.gemini" "$HOME/.gemini"''
          ];
          gemini-cli-bin = mkAiWrapper "gemini-cli-bin" pkgs.gemini-cli-bin [
            ''--setenv GEMINI_SANDBOX false''
            ''--bind "$HOME/.gemini" "$HOME/.gemini"''
          ];
        }
      );
    };
}
