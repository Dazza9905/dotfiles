# My dotfiles
- I doubt anyone will find this interesting, but here they are anyway."
- some of the changes are just described in this readme file since i cant bother to make som scrips - labeled with 🛠
# Changes

## Hyprland

### monitors.conf

- Single monitor
- Dual monitor
- Mirror (main priority)
- Mirror (secondary priority)

## Yazi

- xopp opener

## Vesktop 🛠
- capputchin theme - mocha
- modern indicators theme

**CSS tweaks**
```css
@import url("https://catppuccin.github.io/discord/dist/catppuccin-mocha-pink.theme.css");


:root {
    --indicator-border-size: 2px;
    --indicator-border-style: solid;
    --indicator-rounding: 0px 12px 12px 0px;
}

.theme-light {
    --indicator-unread: var(--primary-900-hsl);
    --indicator-unread-mention: var(--red-430-hsl);
    --indicator-selected: var(--brand-500-hsl);
    --indicator-connected: var(--green-430-hsl);
}

.theme-dark {
    --indicator-unread: var(--primary-130-hsl);
    --indicator-unread-mention: var(--red-400-hsl);
    --indicator-selected: var(--brand-500-hsl);
    --indicator-connected: var(--green-230-hsl);
}

button[class*=" primary_"] {
  background-color: var(--button-filled-brand-background);
  color: var(--button-filled-brand-text);
}

.visual-refresh.theme-dark div[class^=control_]>div[class^=container_], .visual-refresh .theme-dark div[class^=control_]>div[class^=container_] {
    background-color: #2d2a40 !important;
    transition: background-color .2s;
    border-radius: 8px;
}
```
```
