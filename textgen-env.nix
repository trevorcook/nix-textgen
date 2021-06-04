{ envth, callPackage, lib , textgen } :
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
  env-caller = { definition = ./shell.nix; };
}
