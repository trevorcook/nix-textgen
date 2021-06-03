{ lib }: with lib;
let
  unlines = concatStringsSep "\n" ;
  repeatStr = n: str: concatStrings (map (_: str) (range 1 n));
  isNone = arg: isNull arg || arg == {} || arg == [];
  makeOverridable = f: args: f args // { override = args':
    makeOverridable f (args // args');};

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
        else if isFunction arg then
          self.evalFunction arg
        else self.evalOther arg;
      evalList = self: ls: concatStringsSep "\n" (map self ls);
      evalAttrs = self: mapAttrsToList self.evalAttr;
      evalAttr = self: name: value: self value;
      evalOther = self: value: toString value;
      evalFunction = self: f: f self;
    };
    # Based on sdtDispatch, indent eventual string output based
    # on nested-ness inside a structure.
    simpleNest = methods.stdDispatch // {
      # Overwriting stdDispatch methods
      evalList = self: ls: self.unlines (map (self.nest "list") ls);
      evalAttrs = self: attrs:
        self.unlines (mapAttrsToList (self.nest "attrs").evalAttr attrs);
      evalAttr = self: n: v: self v;
      evalOther = self: value: self.indent-str (toString value);
      # nest provides indents:
      # nests a level if not at the top of the structure or an
      # list followed by a attribute set. The reason for this is to
      # allow specific ordering of attributes by breaking attr sets into
      # lists of attribute sets.
      nest = self@{ above?"top", level?0,... }: type:
        if "top" == above || (type == "attrs" && above == "list") then
          { above = type; inherit level;}
        else { above = type; level = level + 1; };
      # no-formatting will turn off indents and added line breaks.
      no-formatting = self: {formatting-off = true;};
      indent-str = self@{level?0,tab?2,formatting-off?false,...}: str:
        if formatting-off
          then str
          else repeatStr level (repeatStr tab " ") + str;
      unlines = self@{formatting-off?false,...}:
        let sep = if formatting-off then "" else "\n";
        in concatStringsSep sep;

    };
    simpleXML = methods.simpleNest // {
      evalAttr = self: name: value:
        let
          attrsAndChildren = {attrs?{},children?[]}:
            if isNone children then
              (self.indent-str ''<${name}${attrStr attrs}/>'')
            else if isList children || isAttrs children then
              self.unlines [
                (self.indent-str ''<${name}${attrStr attrs}>'')
                ((self.nest "attrs") children)
                (self.indent-str ''</${name}>'')]
             else self.indent-str (concatStrings
               [ ''<${name}${attrStr attrs}>''
                 (self.no-formatting children)
                 ''</${name}>''] );
          attrStr = attrs: concatStrings (mapAttrsToList nvp attrs);
          nvp = name: value: " ${name}=\"${toString value}\"";
        in if isFunction value then
             value self
           else if isAttrs value then
             attrsAndChildren value
           else if isList value then
             self.unlines [
                (self.indent-str ''<${name}>'')
                ((self.nest "attrs") value)
                (self.indent-str ''</${name}>'')]
           else self.indent-str (concatStrings [ ''<${name}>''
                                                 (self.no-formatting value)
                                                 ''</${name}>''] );
       };
  };

  simpleNest = {level?0,tab?2,above?"top"}:
    nu methods.simpleNest {inherit level tab above;};
  simpleXML = {level?0,tab?2,above?"top"}:
    nu methods.simpleXML {inherit level tab above;};

  docToText = doc: ''
    # ${doc.heading}
    ${doc.body}
    '';

  }
