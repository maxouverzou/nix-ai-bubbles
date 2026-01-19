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
      overlays.default = final: prev:
        let
          mkAiWrapper = final.lib.makeOverridable (
            {
              name,
              package,
              bwrapFlags,
              extraBwrapFlags ? [ ],
              version ? package.version or "unstable",
            }:
            final.writeShellApplication {
              inherit name;
              runtimeInputs = [
                final.coreutils
                final.bubblewrap
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
                  --ro-bind-try /lib /lib \
                  --ro-bind-try /lib64 /lib64 \
                  --ro-bind "$(readlink -f /etc/resolv.conf)" /etc/resolv.conf \
                  --ro-bind /etc/ssl /etc/ssl \
                  --ro-bind /etc/hosts /etc/hosts \
                  --ro-bind "$(readlink -f /etc/nsswitch.conf)" /etc/nsswitch.conf \
                  --ro-bind-try /etc/pki /etc/pki \
                  --ro-bind-try "$HOME/.nix-profile" "$HOME/.nix-profile" \
                  --setenv PATH "$PATH" \
                  ${final.lib.concatStringsSep " " bwrapFlags} \
                  ${final.lib.concatStringsSep " " extraBwrapFlags} \
                  --bind "$(pwd)" "$(pwd)" \
                  --chdir "$(pwd)" \
                  -- ${final.lib.getExe package} "$@"
              '';
              derivationArgs = {
                name = "${name}-${version}";
                inherit version;
              };
            }
          );
        in
        {
          claude-code-jailed = mkAiWrapper {
            name = "claude-code-jailed";
            package = final.claude-code;
            bwrapFlags = [ ''--bind "$HOME/.claude" "$HOME/.claude"'' ];
          };
          opencode-jailed = mkAiWrapper {
            name = "opencode-jailed";
            package = final.opencode;
            bwrapFlags = [ ''--bind "$HOME/.config/opencode" "$HOME/.config/opencode"'' ];
          };
          gemini-cli-jailed = mkAiWrapper {
            name = "gemini-cli-jailed";
            package = final.gemini-cli;
            bwrapFlags = [
              "--setenv GEMINI_SANDBOX false"
              ''--bind "$HOME/.gemini" "$HOME/.gemini"''
            ];
          };
          gemini-cli-bin-jailed = mkAiWrapper {
            name = "gemini-cli-bin-jailed";
            package = final.gemini-cli-bin;
            bwrapFlags = [
              "--setenv GEMINI_SANDBOX false"
              ''--bind "$HOME/.gemini" "$HOME/.gemini"''
            ];
          };
          codex-jailed = mkAiWrapper {
            name = "codex-jailed";
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
