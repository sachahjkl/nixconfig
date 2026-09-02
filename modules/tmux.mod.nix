_: {
  flake.nixosModules.tmux = {pkgs, ...}: {
    programs.tmux = {
      enable = true;
      package = pkgs.tmux;
      terminal = "tmux-256color";
      escapeTime = 10;
      historyLimit = 100000;
      extraConfig = ''
        set -as terminal-features ',xterm-256color:RGB'
        set -as terminal-features ',xterm-ghostty:RGB'
        set -as terminal-features ',xterm-kitty:RGB'

        set -g mouse on
        set -g focus-events on
        set -g set-clipboard on
        set -g renumber-windows on
        set -g detach-on-destroy off

        set -g status-style 'bg=default,fg=default'
      '';
    };
  };
}
