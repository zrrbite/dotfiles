# shellcheck shell=bash
#
# Which stow packages each OS gets -- the single list read by the installers,
# scripts/verify.sh and reload.sh. Edit here, nowhere else.
#
# Not listed, on purpose:
#   bash      -- linked per OS by the installers (.bashrc-<os> -> ~/.bashrc)
#   fastfetch -- on macOS it is stowed with an ignore pattern and the macOS
#                config linked over config.jsonc (see install_darwin.sh)
#   glazewm, zebar, windowsterminal -- Windows, linked by the PowerShell scripts
#   doc, img, screenshots, scripts, templates -- not packages (.stow-local-ignore)
#
# shellcheck disable=SC2034  # read by the scripts that source this file

PACKAGES_DARWIN=(git clang nvim starship alacritty ghostty aerospace sketchybar autoraise zsh tmux yazi claude)
PACKAGES_ARCH=(hypr foot waybar rofi mako wlogout cava gtk mimeapps discord slack fastfetch alacritty nvim starship git clang gdb tmux yazi typescript claude)
PACKAGES_DEBIAN=(git clang gdb nvim starship tmux claude)
