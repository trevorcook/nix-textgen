{ envth, callPackage, lib, writeTextFile, symlinkJoin } :
with envth; with lib;
let textgen = import ./textgen.nix {
  inherit lib writeTextFile symlinkJoin; }; in
mkEnvironment rec
{ name = "textgen-env";
  definition = ./textgen-env.nix;
  env-caller = ./shell.nix;
  passthru = callPackage ./examples.nix { inherit textgen; }
    // { cfg = callPackage ./emaneconfig {inherit textgen;}; };
    envlib = {
      textgen = {
        desc = "textgen";
        /* args = [ { name="example"; type = attrNames passthru.examples; }];
        hook = ''
          echo $1
          nix-build --attr "examples.$1.out" --out-link "examples" \
            "$( env-call $(env-home-dir)/$definition )"
          ''; */
        args = [ { name="host"; type = attrNames passthru.cfg; }];
        hook = ''
          echo $1
          nix-build --attr "cfg.$1.out" --out-link "emanecfgs" \
            "$( env-call $(env-home-dir)/$definition )"
          '';
      };
  };
}
