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
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
              overlays = [ self.overlays.default ];
            };
          }
        );
    in
    {
      lib.mkBwrapJail =
        pkgs:
        pkgs.lib.makeOverridable (
          {
            package,
            name ? baseNameOf (pkgs.lib.getExe package),
            bwrapFlags,
            extraBwrapFlags ? [ ],
            version ? package.version or "unstable",
          }:
          pkgs.writeShellApplication {
            name = "${name}-jailed";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.bubblewrap
            ];
            text = ''
              bwrap \
                --unshare-all \
                --share-net \
                --die-with-parent \
                --new-session \
                --proc /proc \
                --dev /dev \
                --bind /tmp /tmp \
                --ro-bind /nix /nix \
                --ro-bind-try /usr /usr \
                --ro-bind-try /bin /bin \
                --ro-bind-try /lib /lib \
                --ro-bind-try /lib64 /lib64 \
                --ro-bind "$(readlink -f /etc/resolv.conf)" /etc/resolv.conf \
                --ro-bind /etc/ssl /etc/ssl \
                --ro-bind /etc/hosts /etc/hosts \
                --ro-bind "$(readlink -f /etc/nsswitch.conf)" /etc/nsswitch.conf \
                --ro-bind-try /etc/pki /etc/pki \
                --ro-bind-try "$HOME/.nix-profile" "$HOME/.nix-profile" \
                --ro-bind-try "$HOME/.gitconfig" "$HOME/.gitconfig" \
                --ro-bind-try "$HOME/.config/git" "$HOME/.config/git" \
                --setenv PATH "$PATH" \
                ${pkgs.lib.concatStringsSep " " bwrapFlags} \
                ${pkgs.lib.concatStringsSep " " extraBwrapFlags} \
                --bind "$(pwd)" "$(pwd)" \
                --chdir "$(pwd)" \
                -- ${pkgs.lib.getExe package} "$@"
            '';
            derivationArgs = {
              name = "${pkgs.lib.getName package}-jailed-${version}";
              inherit version;
            };
          }
        );

      overlays.default =
        final: prev:
        let
          mkBwrapJail = self.lib.mkBwrapJail final;
        in
        {
          inherit mkBwrapJail;
          claude-code-jailed = mkBwrapJail {
            package = final.claude-code;
            bwrapFlags = [
              ''--bind "$HOME/.claude" "$HOME/.claude"''
              ''--bind "$HOME/.claude.json" "$HOME/.claude.json"''
            ];
          };
          opencode-jailed = mkBwrapJail {
            package = final.opencode;
            bwrapFlags = [ ''--bind "$HOME/.config/opencode" "$HOME/.config/opencode"'' ];
          };
          gemini-cli-jailed = mkBwrapJail {
            package = final.gemini-cli;
            bwrapFlags = [
              "--setenv GEMINI_SANDBOX false"
              ''--bind "$HOME/.gemini" "$HOME/.gemini"''
            ];
          };
          gemini-cli-bin-jailed = mkBwrapJail {
            package = final.gemini-cli-bin;
            bwrapFlags = [
              "--setenv GEMINI_SANDBOX false"
              ''--bind "$HOME/.gemini" "$HOME/.gemini"''
            ];
          };
          codex-jailed = mkBwrapJail {
            package = final.codex;
            bwrapFlags = [ ''--bind "$HOME/.codex" "$HOME/.codex"'' ];
          };
        };

      packages = forEachSupportedSystem (
        { pkgs }:
        {
          claude-code = pkgs.claude-code-jailed;
          opencode = pkgs.opencode-jailed;
          gemini-cli = pkgs.gemini-cli-jailed;
          gemini-cli-bin = pkgs.gemini-cli-bin-jailed;
          codex = pkgs.codex-jailed;
        }
      );
    };
}
