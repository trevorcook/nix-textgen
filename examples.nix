{ lib, textgen } : with lib; with textgen; with textgen.toText; rec {
  inherit lib; inherit textgen;

  # A nix expression representing a document, a "textgen"
  mydocs = {
    hi = self@{bye, ... }: {
      heading = "Hi";
      body = "Whats next? see [${bye.ref}]";
    };
    bye = self: {
      heading = "Goodbye";
      body = ''
        Did you come from [${self.hi.ref}]?
        Lets get together again soon.
        '';
    };
    ap = self: {
      heading = "Awkward Pause";
      body = ''
        Call me [${self.ap.ref}]
        '';
    };
  };
  /* reflocal = self: self.destination; */
  hiBye = evalDocs { toText = docToText; path = "/hibye";
                     } mydocs;
  hiByeAttr = evalDocsAttrs {
    __default = { toText = docToText; path = "/hibye";} ;
    ap = { toText = docToText;
           path = "/convo";
           mkRef = self: "${self.name}";
    };
  } mydocs;
  hiByeJoin = joinDocs "allHiBye" hiBye;

  # A function for rendering the document to text.
  /* docToText = doc: ''
    # ${doc.heading}
    ${doc.body}
    ''; */

  examples = {
    example1 = evalDoc { toText = indentNesting.eval;
                        name = "example1.txt"; } (docs.example1 {});
    example2 = evalDoc { toText = simpleXML.eval;
                         name = "example2.xml"; } (docs.example2 {});
  };

  docs.example1 = {}:
    [ "- Top Level Idea"
      [ ''- Supporting idea "a"''
        ''- Supporting idea "b"''
      ]
    ];
  docs.example2 = {}:{
    elem = {
      attrs = {id = "plat1";};
      children = [ ];
    };
  simpleXML =
  let unlines = concatStringsSep "/n"; in
  nu {
    __functor = self: self.eval;
    eval = self: body: unlines (mapAttrsToList (self.nest "attrs").evalElem body);
    evalElem = self: name: value@{attrs?{},children?[]}:
      if children == [] then
        ''<${name} ${self.makeAttrs attrs}/>''
      else
      unlines (
        [''<${name} ${self.makeAttrs attrs}>'' ] ++
        (map (self.nest "list").eval children) ++
        [''</${name}>'']
        );
    nest = self@{ above?"top", level?0,... }: type:
      if "top" == above || (type == "attrs" && above == "list") then
        { above = type; inherit level;}
      else { above = type; level = level + 1; };
    indent-str = self@{level?0,tab?2,...}: str:
      repeatStr level (repeatStr tab " ") + str;
    makeAttrs = self: attrs:
      concatStringsSep " " (mapAttrsToList (n: v: ''${n}="${v}"'') attrs);
  } {};

  indentdoc.main = self:
    [
    {a = "[0].a.val";
     b = [ { b1 = ''[0].b[0].b1.val"'';
             b2 = "[0].b[0].b2.val";}
           "[0].b[1].string" ];
         }
    "[1].string"
    ]
    ;

  indenttxt = evalDocs {toText = indentNesting.eval; path=""; } indentdoc;


  xmldoc.doc1 = self:
    [
    {a = "a.val";
     b = [ { b1 = ''b[0].b1.val"'';
             b2 = "b[0].b2.val";}
           "b[1].string" ];}
    "string"
    ]
    ;

  /* xmldoc.doc2 = self: [
   ''<?xml version="1.0" encoding="UTF-8"?>''
   {entity = { params = { p1 = 1; p2 = 2; };
               subentity = {};}; }
  ''
<platform>
  <param name="otamanagerchannelenable" value="on"/>
  <param name="otamanagerdevice" value="eth0"/>
  <param name="otamanagergroup" value="224.1.2.8:45702"/>
  <param name="eventservicegroup" value="224.1.2.8:45703"/>
  <param name="eventservicedevice" value="eth0"/>

  <nem id="1" definition="rfpipenem.xml">
    <transport definition="transvirtual.xml">
      <param name="address" value="fd53:dc9a:f36d:4950:0:0:0:1"/>
    </transport>
  </nem>
</platform>  ''
  ]; */


  /* myxml = evalDocsAttrs {
    doc1 = {
      toText = evalIndentNesting // {
        evalAttr = eval-attr-doc1; }; };
    doc2 = {
      toText = evalIndentNesting // {
        evalAttr = eval-attr-doc2; }; };
    } xmldoc; */

  }
