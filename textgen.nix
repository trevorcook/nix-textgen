{ lib, writeTextFile, symlinkJoin } :
  let
    evalDoc = import ./evalDoc.nix { inherit lib writeTextFile symlinkJoin;};
    toText = import ./toText.nix {inherit lib;};
    doclib = evalDoc // { inherit toText; };
  in doclib
