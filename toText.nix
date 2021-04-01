{ lib, }: with lib;
let
  unlines = concatStringsSep "\n" ;
  repeatStr = n: str: concatStrings (map (_: str) (range 1 n));
  isNone = arg: isNull arg || arg == {} || arg == [];

in rec {
  nu = methods: attrs:
    let
      ap = arg:
        if isFunction arg
          then arg': ap (arg arg')
          else if isAttrs arg then
            nu methods (attrs // arg)
          else arg;
      mkMethod = name: f: ap (f out);
      out = attrs // (mapAttrs mkMethod methods);
    in out;

  methods = {
    stdDispatch.eval = self: arg:
      if isList arg then
        self.evalList arg
      else if isAttrs arg then
        self.evalAttrs arg
      else self.evalOther arg;
    simpleNest = {
      __functor = _: self: self.eval;
      inherit (methods.stdDispatch) eval;
      evalList = self: ls: unlines (map (self.nest "list") ls);
      evalAttrs = self: attrs:
        unlines (mapAttrsToList (self.nest "attrs").evalAttr attrs);
      evalAttr = self: name: value: self value;
      evalOther = self: value: self.indent-str (toString value);
      nest = self@{ above?"top", level?0,... }: type:
        if "top" == above || (type == "attrs" && above == "list") then
          { above = type; inherit level;}
        else { above = type; level = level + 1; };
      indent-str = self@{level?0,tab?2,...}: str:
        repeatStr level (repeatStr tab " ") + str;
    };
    simpleXML = {
      __functor = _: self: self.eval;
      inherit (methods.stdDispatch) eval;
      inherit (methods.simpleNest) evalList evalAttrs nest indent-str;
      evalAttr = self: name: value@{attrs?{},children?[]}:
        let
          attrStr = concatStrings (mapAttrsToList nvp attrs);
          nvp = name: value: '' ${name}="${toString value}"'';
          therest = if isNone children then ''/>''
                    else unlines [
                      ">"
                      ((self.nest "attrs") children)
                      ''</${name}>''];
        in (self.indent-str ''<${name}${attrStr}'') + therest;
    };
  };

  simpleNest = nu methods.simpleNest {level=0; tab=2; above="top";};
  simpleXML = nu methods.simpleXML {level=0; tab=2; above="top";};







  docToText = doc: ''
    # ${doc.heading}
    ${doc.body}
    '';

  /* # This evaluation funcition will indent nested levels of attribute
  # sets and lists, casting all else to strings.
  evalIndentNesting =
    let
      unlines = concatStringsSep "\n" ;
    in {
      above = "top";
      tab = 2;
      level = 0;
      __functor = self: body:
        if isList body then
          unlines (map (self.inc "list" self) body)
        else if isAttrs body then
          self.evalAttrs self body
        else self.indent self (toString body);
      evalAttrs = self: value:
         unlines (mapAttrsToList (self.evalAttr (self.inc "attrs" self)) value);
      evalAttr = self: name: value: self value;
      # increase indent level with some special cases.
      inc = type: self:
        if "top" == self.above || (type == "attrs" && self.above == "list") then
          self // { above = type; }
        else
          self // { above = type;
                    level = self.level + 1; };
      # Indent a string according to its current level and tab width.
      indent = self@{level,tab, ...}: str:
        let
          repeat = n: a: concatStrings (map (_: a) (range 1 n));
        in repeat level (repeat tab " ") + str;

      }; */

   eval-attr-doc1 = self: name: value:
    let
      unlines = concatStringsSep "\n" ;
      shSt = self: ''st=${toString self.level},${self.above}'';
    in
        if isString value then
          self.indent self ''<${name} ${value} ${shSt self}/>''
        else
          unlines [
            (self.indent self ''<${name} ${shSt self}>'')
            (self value)
            (self.indent self ''</${name} ${shSt self}>'')
            ];

   /* eval-attrs-doc1 = self: attrs:
    if attrs ? "entity"
    let
      unlines = concatStringsSep "\n" ;
      shSt = self: ''st=${toString self.level},${self.above}'';
    in
        if isString value then
          self.indent self ''<${name} ${value} ${shSt self}/>''
        else
          unlines [
            (self.indent self ''<${name} ${shSt self}>'')
            (self value)
            (self.indent self ''</${name} ${shSt self}>'')
            ]; */



  }




/* # Old attempta
ap = evaldoc evalFun1 "ap" apdoc {};

# The texts.
hibye = evaldocs "xx" evalFun1 {inherit hidoc apdoc byedoc;};
  evalFun1 = {
    toText = docToText;
    path = "";
    makeReference = self : rec {
      local = self.destination + self.name;
      global = self.outPath + local;
    };
  };


  # Evaluation of a doc according to a certain rendering
  # and depending on other evaluated docs.
  evaldoc = ef: name: doc: docs:
    let
      a = {
        inherit (ef) path;
        destination = a.path + "/" + name;
        text = ef.toText (doc docs);
        file = writeTextFile { inherit (a) name text destination; };
        outPath = a.file.outPath;
        inherit name;
        };
    in { reference = ef.makeReference a; } // a;

  # Evaluation of aset of recursively dependendent docs a la evaldoc.
  evaldocs =  name: ef: docs_ :
    let
      mkdocs = self: mapAttrs (name: doc: evaldoc ef name doc self) docs_;
      docs = fix mkdocs;
      paths = mapAttrsToList (n: v: v.file) docs;
      files  = symlinkJoin { inherit paths name; passthru = {inherit docs;};};
      texts = mapAttrs (n: v: v.text) docs;
    in { inherit docs files paths texts; }; */


  /* # Evaluation of aset of recursively dependendent docs a la evaldoc.
  # Joins the docs in symlink, thinking bad approach.
  evalDocs1 =  attrs@{ toText, name, path?"", mkRef?(self: self.outPath)}: docs_ :
    let
      mkdocs = self:
        mapAttrs (name: doc: evalDoc (attrs//{inherit name;}) (doc self)) docs_;
      docs = fix mkdocs;
      paths = mapAttrsToList (n: v: v.file) docs;
      files  = symlinkJoin { inherit paths name;};
      texts = mapAttrs (n: v: v.text) docs;
    in { inherit docs files paths texts; };
 */
