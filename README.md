# nix-ai-bubbles

Sandboxed AI coding assistants using bubblewrap.

## Available packages

- `claude-code`
- `opencode`
- `gemini-cli`
- `gemini-cli-bin`

## Usage

### Run directly

```sh
nix run github:maxouverzou/nix-ai-bubbles#claude-code
nix run github:maxouverzou/nix-ai-bubbles#opencode
nix run github:maxouverzou/nix-ai-bubbles#gemini-cli
```

### Using the overlay

Add the overlay to your nixpkgs and access the packages directly:

```nix
{
  inputs.nix-ai-bubbles.url = "github:maxouverzou/nix-ai-bubbles";

  outputs = { nixpkgs, nix-ai-bubbles, ... }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ nix-ai-bubbles.overlays.default ];
      };
    in {
      # pkgs.claude-code-jailed, pkgs.opencode-jailed, etc. are now available
    };
}
```

The overlay exposes:
- `claude-code-jailed`
- `opencode-jailed`
- `gemini-cli-jailed`
- `gemini-cli-bin-jailed`

### Custom bwrap flags

Use `.override` to add extra bubblewrap flags:

```nix
pkgs.claude-code-jailed.override {
  extraBwrapFlags = [
    ''--unsetenv SSH_AUTH_SOCK''
    ''--unsetenv AWS_ACCESS_KEY_ID''
  ];
}
```
