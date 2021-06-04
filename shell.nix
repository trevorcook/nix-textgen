{ definition ? ./textgen-env.nix,
  textgen-src ? ./textgen.nix,
  metafun-src ? (builtins.fetchGit {
      url = https://github.com/trevorcook/nix-metafun.git ;
      rev = "31d86380aa7c8c25647d5409b8f07b96990a42d5"; }),
  envth-src ? builtins.fetchGit {
    url = https://github.com/trevorcook/envth.git;
    rev = "e9c0ce2c6c8fb6a97de80e841fa24d090e4191a0";
  }

  }:
let
  metafun-overlay = self: super: {
    metafun = import metafun-src {inherit (self) lib;}; };
  envth-overlay = self: super: {
    envth = import envth-src self super;
  };
  textgen-overlay = self: super: {
    textgen = super.callPackage textgen-src {};
  };
  overlays = [metafun-overlay envth-overlay textgen-overlay];
  nixpkgs = import <nixpkgs> { inherit overlays; };
in
  nixpkgs.callPackage definition { }
