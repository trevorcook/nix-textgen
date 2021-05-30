let
  metafun-src = builtins.fetchGit {
      url = https://github.com/trevorcook/nix-metafun.git ;
      rev = "9901a95a1d995481ffa4d5f101eafc2cbdba7eef"; };
  metafun-overlay = self: super: {
    metafun = import metafun-src {inherit (self) lib;}; };
in [metafun-overlay]
