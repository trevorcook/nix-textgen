let
  nixpkgs = import <nixpkgs> { };
  metafun-src = builtins.fetchGit {
      url = https://github.com/trevorcook/nix-metafun.git ;
      rev = "9901a95a1d995481ffa4d5f101eafc2cbdba7eef"; };
  metafun = import metafun-src {inherit (nixpkgs) lib;};
  textgen = import ./textgen {
    inherit (nixpkgs) lib writeTextFile symlinkJoin writeScriptBin;
    inherit metafun;
  };
in
{definition ? ./textgen-env.nix }:
  nixpkgs.callPackage definition { inherit metafun textgen;
    /* inherit envth; */
  }
