let
  pkgs =  import <nixpkgs> {};
  /* inherit (pkgs.envth) metafun; */
  /* envth = pkgs.envth.override {metafun = pkgs.metafun.override {debug=true;};}; */
  /* nixdoc_ = import ./nixdoc.nix {
  inherit (pkgs) lib writeTextFile symlinkJoin; }; */
in
{definition ? ./textgen-env.nix }:
  pkgs.callPackage definition {
    /* inherit envth; */
  }
