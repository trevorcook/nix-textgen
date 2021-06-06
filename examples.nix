{ lib, textgen } : with lib;
with textgen.lib;
with textgen.lib.toText; rec {
  inherit lib; inherit textgen;
  inherit (textgen.lib) toText;

  counter = nu {
    inc = self: { count = self.count + 1; };
    dec = self: { count = self.count - 1; };
    set = self: n: { count = n; };
    show = self: "current count: ${toString self.count}";
    } { count = 0; };

  examples = {
    example0 = evalDoc { toText = stdDispatch;
                         name = "example0.md"; } docs.example0;
    example1 = evalDoc { toText = simpleNest {};
                         name = "example1.md"; } docs.example1;
    example2 = evalDoc { toText = simpleXML {};
                         name = "example2.xml"; } docs.example2;
    example3 = evalDoc { toText = doc: simpleXML {} (myXMLPlatform doc);
                         name = "example3.xml"; } docs.example3;
    example4 = joinDocs "example4" (
      let mkName = name: name + ".xml";
          mkiface = {
            inherit mkName;
            toText = doc: simpleXML {} (mkcomponent doc);};
      in evalDocsAttrs {
        platform = {
          inherit mkName;
          toText = doc: simpleXML {} (myXMLPlatform-v2 doc); };
        iface-full = mkiface;
        iface-partial = mkiface;
      } docs.example4);
    example5 = joinDocs "example5" (
      evalDocs { toText = doc: simpleXML {} (myXMLDocs doc);
                 mkName = name: name + ".xml";} docs.example5);
  };

  docs.example0 =
    { item1 = "A simple document for `stdDispatch` renderer. ";
      item2 = [ "Nix structures are traversed "
                [" until basic data is encountered and `toString`-ed. "]
               "All else is lost."];
    };
  docs.example1 =
    [ "- A simple document for `simpleNest` renderer"
      [ ''- Nix was nested lists of lines''
        ''- Output indents lines''
      ]
      "- `simpleNest` is based on `stdDispatch`"
      [ "- Defined as `stdDispatch` with extra attribute elements"
        "- Extra functions to track nesting level and prepending spaces"
        [ (self: self.no-formatting "- Formatting has been turned off for this line.") ]
        ]
    ];
  docs.example2 = {
    description = [''A sample XML built from a Nix expression that mirrors''
                    ''the format of this output XML document. Rendered with''
                    ''`simpleXML`.''];
    platform = {
      children = [
        { interface = {
            attrs = { id = 1; type = "full"; };
            children = [
                { parameter = {
                    attrs = { name = "quality"; };
                    children = "good"; }; }
              ];
            }; }
        { interface = {
            attrs = { id = 2; type = "partial"; };
            children = [
                { parameter = {
                    attrs = { name = "duration"; };
                    children = 0.7; }; }
              ];
            }; }
        ]; }; };
  docs.example3 = {
    description = [''Replication of example2, but based on a much simpler''
                   ''underlying Nix expression ''];
    interfaces = [
      { id = 1; type = "full"; params = {quality = "good";}; }
      { id = 2; type = "half"; params = {duration = 0.7;}; }
      ];
  };
  myXMLPlatform = {interfaces?[],description?"My XML Platform"}:
    let
      mkInterface = {id, type, params}:
        { interface = {
            attrs = {inherit id type; };
            children = mapAttrsToList mkParam params;
          };
        };
      mkParam = name: v: { parameter.attrs = { inherit name; };
                           parameter.children = v; };
    in {inherit description;
        platform.children = map mkInterface interfaces;};

  docs.example4 = {
    platform = ex4: {
      description = [''Expansion of example3 including references to''
                     ''companion configurations''];
      interfaces = [
        { id = 1; type = "full";
          definition = ex4.iface-full.ref;
          params = {quality = "good";}; }
        { id = 2; type = "partial";
          definition = ex4.iface-partial.ref;
          params = {duration = 0.7;}; }
        ];
    };
    iface-full = ex4: {type="full";};
    iface-partial = ex4: {type="partial";};
  };
  myXMLPlatform-v2 = {interfaces?[],description?"My XML Platform"}:
    let
      mkInterface = {id, type, params, definition}:
        { interface = {
            attrs = { inherit id type definition; };
            children = mapAttrsToList mkParam params;
          };
        };
      mkParam = name: v: { parameter.attrs = { inherit name; };
                           parameter.children = v; };
    in {inherit description;
        platform.children = map mkInterface interfaces;};

  mkcomponent = {description?"a platform component",type}: [
    { inherit description; }
    { component.attrs = {
        definition = "/usr/local/myplatform/schema/component-${type}.xml";
        };
      }
    ];
  docs.example5 = {
    platform = ex5: {
      doctype = "platform";
      doc = docs.example4.platform ex5; };
    iface-full = ex5:{
      doctype = "component";
      doc = docs.example4.iface-full ex5; };
    iface-partial = ex5:{
      doctype = "component";
      doc = docs.example4.iface-partial ex5; };
  };
  myXMLDocs = {doctype,doc}:
    if doctype=="platform" then
      myXMLPlatform-v2 doc
    else if doctype == "component" then
      mkcomponent doc
    else
      throw "unrecognized doctype: ${doctype}";



  }
