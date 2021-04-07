{ lib, writeTextFile, symlinkJoin, metafun, writeScriptBin } :
  let
    evalDoc = import ./evalDoc.nix { inherit lib writeTextFile symlinkJoin;};
    toText = import ./toText.nix {inherit lib;};
    doclib = evalDoc // { inherit toText; inherit (toText) nu; };
    exe = import ./exe.nix { inherit metafun writeScriptBin; };
  in exe // { lib = doclib; }
