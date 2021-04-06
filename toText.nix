{ lib }: with lib;
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

  # Collections of methods suitable for turing into "objects" with nu.
  methods = {
    # Objects that will select option based of an input element's structure.
    stdDispatch = {
      __functor = _: self: self.eval;
      eval = self: arg:
        if isList arg then
          self.evalList arg
        else if isAttrs arg then
          self.evalAttrs arg
        else self.evalOther arg;
    };
    # Based on sdtDispatch, indent eventual string output based
    # on nested-ness inside a structure.
    simpleNest = methods.stdDispatch // {
      evalList = self: ls: self.unlines (map (self.nest "list") ls);
      evalAttrs = self: attrs:
        self.unlines (mapAttrsToList (self.nest "attrs").evalAttr attrs);
      evalAttr = self: name: value: self value;
      evalOther = self: value: self.indent-str (toString value);
      # nest another level if not at the top of the structure or an
      # lsit followed by a attribute set. The reason for this is to
      # allow specific ordering of attributes by breaking attr sets into
      # lists of attribute sets.
      nest = self@{ above?"top", level?0,... }: type:
        if "top" == above || (type == "attrs" && above == "list") then
          { above = type; inherit level;}
        else { above = type; level = level + 1; };
      no-formatting = self: {formatting-off = true;};
      indent-str = self@{level?0,tab?2,formatting-off?false,...}: str:
        if formatting-off
          then str
          else repeatStr level (repeatStr tab " ") + str;
      unlines = self@{formatting-off?false}:
        let sep = if formatting-off then "" else "\n";
        in concatStringsSep sep;

    };
    simpleXML = methods.simpleNest // {
      evalAttr = self: name: value@{attrs?{},children?[]}:
        let
          attrStr = concatStrings (mapAttrsToList nvp attrs);
          nvp = name: value: " ${name}=\"${toString value}\"";
          therest = if isNone children then ''/>''
                    else unlines [
                      ">"
                      ((self.nest "attrs") children)
                      (self.indent-str ''</${name}>'')];
        in (self.indent-str ''<${name}${attrStr}'') + therest;
    };
  };

  simpleNest = nu methods.simpleNest {level=0; tab=2; above="top";};
  simpleXML = nu methods.simpleXML {level=0; tab=2; above="top";};







  docToText = doc: ''
    # ${doc.heading}
    ${doc.body}
    '';


  }
