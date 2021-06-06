{ envth, callPackage, lib } :
with envth; with lib;
let textgen = callPackage ./textgen.nix {}; in
mkEnvironment rec
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
  env-caller = { definition = ./shell.nix;
                 /* textgen-src = ./textgen.nix; */
                 /* metafun-src = (builtins.fetchGit {
                     url = https://github.com/trevorcook/nix-metafun.git ;
                     rev = "31d86380aa7c8c25647d5409b8f07b96990a42d5"; });
                 envth-src = builtins.fetchGit {
                   url = https://github.com/trevorcook/envth.git;
                   rev = "e9c0ce2c6c8fb6a97de80e841fa24d090e4191a0";
                 }; */
   };
}
