{ lib, writeTextFile, symlinkJoin } : with lib; rec {
  # evaluation of a nix object, `doc`, via a certain renderer.
  # evalDoc_ :: doc -> {toText,name,path,mkRef} -> out
  evalDoc_ = doc: let
    makeOverridable = f: args: f args // { override = args':
      makeOverridable f (args // args');};
    f = {  name, toText,path?"", mkRef?(self: self.name)}:
      let
        destination =  path + "/" + name;
        text = toText doc;
        out = writeTextFile { inherit name text destination; };
        outPath = out.outPath + destination;
        self = { inherit doc name toText path mkRef
                 destination text out outPath; };
      in {ref = mkRef self;} // self;
    in makeOverridable f;
  evalDoc = attrs: doc: evalDoc_ doc attrs;

  # fixAttrs: The fixed point of a set of functions which all require
  # the whole set as inputs.
  fixAttrs = attrs: fix (self: mapAttrs (_ : f: f self) attrs);

  # Eval mutually dependent documents with a common set of evalDoc attributes.
  # Input docs should be functions from the set of eventual "evaled" documents
  # to a document that is ready for evaluation.
  evalDocs = attrs@{ toText, path?"", mkRef?(self: self.name)
                   , mkName?id}: docs:
   let
     mkAttr = name: doc: self: evalDoc_ (doc self) {
       inherit toText path mkRef;
       name = mkName name; };
    in
      fixAttrs (mapAttrs mkAttr docs);

  # Eval mutually dependent documents with a common set of evalDoc attributes.
  # Input docs should be functions from the set of eventual "evaled" documents
  # to a document that is ready for evaluation.
  evalDocsAttrs = evalSpecs: docs:
    let
      mkAttr = name: doc: self:
        let spec =
          if hasAttr name evalSpecs then
            getAttr name evalSpecs
          else if hasAttr "__default" evalSpecs then
            getAttr "__default" evalSpecs
          else throw ''No evalSpec for ${name} nor "__default" found.'';
        in evalDoc (spec // { name = mkName name; }) (doc self);
    in
      fixAttrs (mapAttrs mkAttr docs);


  # Join evaluated docs into a symlink tree (access with .out)
  # Unlike evalDoc(s) this
  joinDocs = name: docs:
    let
      paths = mapAttrsToList (n: v: v.out) docs;
      out  = symlinkJoin { inherit paths name;};
    in { inherit docs name out paths; };

  }
