let
  nixpkgs = import <nixpkgs> { };
  /* metafun-src = builtins.fetchGit {
      url = https://github.com/trevorcook/nix-metafun.git ;
      rev = "9901a95a1d995481ffa4d5f101eafc2cbdba7eef"; };
  metafun = import metafun-src {inherit (nixpkgs) lib;}; */
  inherit (nixpkgs) metafun;
  _textgen = import ./textgen.nix {
    inherit (nixpkgs) lib writeTextFile symlinkJoin writeScriptBin;
    inherit metafun;
  };
in

{ envth, callPackage, lib , textgen?_textgen
  ,metafun } :
with envth; with lib; mkEnvironment rec
{ name = "textgen-env";
  definition = ./textgen-env.nix;
  shellHook = ''
    testfile="$( env-call $(env-home-dir)/$definition )"
  '';
  paths = [textgen];
  passthru = callPackage ./examples.nix { inherit textgen; };
    envlib = {
      textgen-examples = {
        desc = "Generate Example documentation from ./examples.nix";
        args = [ { name="example"; type = attrNames passthru.examples; }];
        hook = ''
          textgen generate "$( env-call $(env-home-dir)/$definition )" \
          "examples.$1"
          '';
        };
  };
}
