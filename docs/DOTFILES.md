# Mutable configuration with chezmoi

Kobold deliberately does not bake personal Niri or shell configuration into the bootc image. `chezmoi` is installed natively so a new installation can restore user state from a Git repository.

## Suggested first-time workflow

Create a private or public dotfiles repository separately from the Kobold image repository, then initialize it:

```bash
chezmoi init
chezmoi add ~/.config/niri/config.kdl
chezmoi add ~/.config/waybar
chezmoi add ~/.config/fuzzel
chezmoi add ~/.config/mako
chezmoi add ~/.gitconfig
chezmoi cd
git remote add origin <your-dotfiles-repository>
git add .
git commit -m 'Initial dotfiles'
git push -u origin main
```

On a fresh Kobold installation:

```bash
chezmoi init --apply <owner/repository>
```

## Good chezmoi candidates

- `~/.config/niri/`
- `~/.config/waybar/`
- `~/.config/fuzzel/`
- `~/.config/mako/`
- shell configuration and aliases;
- Git/GitHub CLI preferences that contain no secret;
- terminal settings;
- editor configuration;
- user-level systemd units where appropriate.

Do not put machine secrets into a public repository. Chezmoi supports templating and secret-management integrations if that becomes necessary; add such a mechanism intentionally rather than placing credentials in this image.

The image repository and dotfiles repository have different lifecycles: rebuilding Kobold should not be required to change a keybinding, and reinstalling Kobold should not destroy the source of truth for personal configuration.
