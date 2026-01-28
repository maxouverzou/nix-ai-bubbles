# nix-ai-bubbles

Sandboxed AI coding assistants using bubblewrap.

## Available packages

- `claude-code`
- `opencode`
- `gemini-cli`
- `gemini-cli-bin`
- `codex`

## Usage

### Run directly

```sh
nix run github:maxouverzou/nix-ai-bubbles#claude-code
nix run github:maxouverzou/nix-ai-bubbles#opencode
nix run github:maxouverzou/nix-ai-bubbles#gemini-cli
nix run github:maxouverzou/nix-ai-bubbles#codex
```

### Using the overlay

Add the overlay to your nixpkgs and access the packages directly:

```nix
{
  inputs.nix-ai-bubbles.url = "github:maxouverzou/nix-ai-bubbles";
  inputs.nix-ai-bubbles.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { nixpkgs, nix-ai-bubbles, ... }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ nix-ai-bubbles.overlays.default ];
      };
    in {
      # pkgs.claude-code-jailed, pkgs.mkBwrapJail, etc. are now available
    };
}
```

The overlay exposes:
- `claude-code-jailed`
- `opencode-jailed`
- `gemini-cli-jailed`
- `gemini-cli-bin-jailed`
- `codex-jailed`
- `mkBwrapJail` (builder function)

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

## Creating custom jails

You can use `mkBwrapJail` to sandbox any package.

### Via Overlay

```nix
pkgs.mkBwrapJail {
  package = pkgs.hello;
  bwrapFlags = [ "--bind $HOME/.hello .hello" ];
}
```

### Via Lib

```nix
inputs.nix-ai-bubbles.lib.mkBwrapJail pkgs {
  package = pkgs.hello;
  bwrapFlags = [ "--bind $HOME/.hello .hello" ];
}
```
