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

### Home Manager

```nix
{
  inputs.nix-ai-bubbles.url = "github:maxouverzou/nix-ai-bubbles";

  # In your home configuration:
  home.packages = [
    inputs.nix-ai-bubbles.packages.${pkgs.system}.claude-code
  ];
}
```
